# Quick Terraform introduction

Deploying your project with Terraform requires a bit of knowledge about Terraform
(Elementary, my dear reader). This document aims to give a quick introduction and
present some of the tools which are specific to our projects.

## What is Terraform?

Terraform is an *API manager*. Anything that offers an API can be managed through 
Terraform through the use of the corresponding 'provider' for that API.

An example: Spotify has an API. And the Terraform Community has created a
[Spotify Provider](https://registry.terraform.io/providers/conradludgate/spotify/latest/docs)
that lets you manage your Spotify Playlists with Terraform configuration files.

Terraform follows a similar concept to Kubernetes, if you're familiar with that.
You specify in configuration files your desired state and Terraform takes care of
diffing the *actual state* with your *desired state*, after which it runs the necessary
API commands to make both match (this process is called reconciliation).

The configuration language for Terraform configuration files is called HCL (which
stands for Hashicorp Configuration Language). You can read more about Terraform
and HCL in the [official docs](https://developer.hashicorp.com/terraform/docs).

Another resource that could be useful to learn more about Terraform is
[KodeKloud platform](https://learn.kodekloud.com/learn/courses/terraform-basics-training-course).

## Where is state stored?

Terraform stores the *actual state* (which it checks every time `terraform` command is run).
When Terraform runs locally the actual state of the deployment is stored in the computer
disk (`.terraform/` and `terraform.tfstate`), but if you want to share state among
multiple developers and CI/CD it is not enough.

That's why remote state is needed, called *backend* in Terraform lingo.
At Canonical we use an S3 bucket in the cloud that holds the information.
The credentials for that storage can be found in the company's
[Vault](https://vault.ps7.admin.canonical.com/ui/vault/secrets/secret/kv/list).

The remote state has a locking mechanism so that there are no race condition issues.
If multiple deployments are triggered at the same time they will be handled one by one.

You can see how it is configured by looking at the `backend.tf` file that is generated
by [bootstraping the GitOps model](https://github.com/canonical/webteam-devops/blob/main/docs/gitops.md).

## Initializing Terraform

Before starting to work with Terraform you'll need to run one command to perform the
initialization that it needs: `terraform init`. This command takes care of setting up the
backend that Terraform will use for storing the state. But given that we are using a remote
S3 bucket for that, you'll need to authenticate properly.

Authenticating to S3 means running the `s3_credentials_jaas.sh` script, which will prompt
for a Vault login and then will extract and export the access credentials for the S3 bucket.
The script should be a bit modified from the default one (see `/docs/gitops.md`), allowing
you to use it from your local PC (needs VPN activated) and from CI/CD workflows as well.

Once you have the needed credentials for the S3 backend, then you can run `terraform init`
and it will work. The command will initialize the state AND will download any needed
providers.

### Providers we use

Like explained with the Spotify Provider example above, a provider is some kind of plugin
that Terraform uses to handle the management of a specific API. It allows Terraform
to query the API for the actual state and also to perform actions like creating or
destroying resources.

Looking again at the output generated automatically by
[bootstraping the GitOps model](https://github.com/canonical/webteam-devops/blob/main/docs/gitops.md),
you can see the providers used by looking at the `providers.tf` file; the versions
for said providers can be found in `versions.tf`.

The `locals` section is just to define "Terraform local variables". You'll then see a Vault and a
Juju provider. The [Vault provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
is used to pull the `juju_client_id` and `juju_client_secret` key-values (which in current PS6 deployments
you had to set manually as environment secrets in the GitHub repository).
The [Juju provider](https://registry.terraform.io/providers/juju/juju/latest/docs)
is what it is actually used to handle the configuration of our environments.

## Configuration

Terraform configuration files can become quite complex. Luckily most of our Juju models and
applications are quite simple. You can get everything ready by defining resources and data objects,
along with some variables.

### Data definitions

Data definitions tells Terraform to pull some data in without having it defined in the configuration.
In the generated `main.tf` file you'll see this:

```terraform
data "juju_model" "service_model" {
  owner = local.juju_model_owner
  name  = local.juju_model_name
}
```

To specify a data block you start with the "data" keyword, then the type you want Terraform to
know about and finally the name you give to the object (in this case `service_model`). The types
allowed are found in the [Juju provider](https://registry.terraform.io/providers/juju/juju/latest/docs)
documentation, under the left navigation "Data sources" dropdown.

The above example is used to tell Terraform that there is a Juju model already defined. Why is it
so? Because IS generates this model through the information in
[infrastructure-services](https://github.com/canonical/infrastructure-services) using a different
Terraform pipeline. So as far as your Terraform configuration is concerned, that model already
exists and it's outside of its "control"; the data source just makes Terraform aware that the
given object is there.

Another example is this snippet:

```terraform
data "juju_charm" "rocks_storefront_charm" {
  charm   = var.charm_name
  channel = "latest/beta"
  base    = "ubuntu@24.04"
}
```

This data source will automatically query charmcraft API to retrieve information about the given charm.
You specify the name, channel and base for the charm you want to deploy and it will retrieve
all the information about it, like the latest revision for the charm and which resources (OCI image)
it uses along with their revisions.

### Resource definitions

The resource definition is how you tell Terraform that you want something in your infrastructure.
For example:

```terraform
resource "juju_application" "rocks_storefront" {
  model_uuid = data.juju_model.service_model.uuid
  units      = 2

  charm {
    name     = var.charm_name
    channel  = var.charm_channel
    revision = data.juju_charm.rocks_storefront_charm.revision
  }

  resources = data.juju_charm.rocks_storefront_charm.resources
}
```

The above example specifies that in the deployment you want a resource of type "juju_application"
(the types can be found in the [Juju provider](https://registry.terraform.io/providers/juju/juju/latest/docs)
docs, under "Resources" on the left navigation) and gives that a name of "rocks_storefront".
The details of what goes inside of the block can be checked in the documentation for the given
type; in the case of a "juju_application" you can give the model in which it will be deployed,
the units you want to have, the charm to deploy and the resources that the charm needs.

As you can notice, you may reference information from other declared objects and Terraform
manages the implicit dependencies automatically. In the example you can see that the model UUID is
being referenced from the "juju_model data" object explained in the above section. Same for the
charm revision and resources.

### Variables

You'll notice among the GitOps generated files one called `variables.tf`. In reality the names of
the files are just conventions IS has put in place. Terraform doesn't care how you name files or
where you define objects; it simply takes all files ended in `.tf` of the directory and parses all
of them (you could have a single file with all the configuration in it, or organize them as you want).
The only requirement is that they need to be all in the same directory (there is the concept of
modules for code reusability, but that's a topic for a different time). 

With Terraform you can define variables to reuse certain values. If you find yourself hardcoding the
same value more than once it is likely you'll do better with a variable. You can define one like this:

```terraform
variable "charm_name" {
  description = "Name of the charmed application."
  type        = string
  default     = "rocks-storefront"
}
```

If you don't give the variable a default value you'll then have to pass it when running the Terraform
command, so I'll avoid that unless you know what you're doing - and I assume you don't, given that you
are reading this.

You can then use a variable you've defined by simply typing `var.[variable name]`. With the above
example variable it would be: var.charm_name.

## Example

Our models and applications in its most simple form will have:
- An application
- An ingress-controller
- A relation between the application and the ingress-controller
- A relation between the ingress-controller and the HAProxy ingress

You can see an example of a working configuration at `/terraform/ps7/k8s-stg-marketplace-rocks`.
