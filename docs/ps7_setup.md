# Setting up PS7 CI/CD

This guide will take you through all the needed steps to set up the necessary GH Actions for
building and deploying a project to PS7.

Deployments in PS7 are done using Terraform. With this approach, instead of running commands
via a script or manually, you define in configuration files how do you want your infrastructure
to be. Then you run `terraform apply` and Terraform takes care of all the necessary actions
to make sure that what you defined is deployed.

This makes the configuration files the *source of truth* for the state of your deployments.
How so? Because IS runs continuously a script that via Terraform makes sure that what you
define in the configuration is what there'll be in the real environment. If someone SSHs in
the PS7 bastion and modifies things manually without updating the configuration files, those
changes will be reverted the next time the synchronization script runs (if you need to do
that temporarilly you can disable the synchronization via the `enabled` property at
[infrastructure-services](https://github.com/canonical/infrastructure-services)).

## Setting up the config folder

To have a Terraform deployment to PS7 you'll first need a place where to store the
configuration files. This folder is what IS will watch and will be the configuration
your environment is synchronized to.

For this purpose we have a private repository:
[webteam-terraform-plans](https://github.com/canonical/webteam-terraform-plans)
You can follow the README to set up your configuration folder.

If it's your first time using Terraform check
[terraform.md](https://github.com/canonical/webteam-terraform-plans/blob/main/terraform.md)
to get a quick intro and useful resources to learn more (should you be interested in that).

You can also copy an existing working example from
[terraform/ps7/k8s-stg-marketplace-rocks](https://github.com/canonical/webteam-terraform-plans/blob/main/terraform/ps7/k8s-stg-marketplace-rocks)
and modify it to your needs.

## Workflows

First of all you'll need to set up 3 secrets in your GitHub project repository. It is best
to set them as "Repository Secrets" so that all Actions have access to them without needing
to configure any Environment.

- CHARMHUB_TOKEN: run [charmcraft login](https://canonical.com/juju/docs/charmcraft/latest/reference/commands/login/)
with the `--export` option to get it and set it.
- VAULT_APPROLE_ROLE_ID: follow steps in
[Accessing Service Account Credentials](https://documentation.ubuntu.com/canonical-information-systems-documentation/products/devopsenv/how-to/jaas-terraform-gitops/#accessing-the-service-account-credentials)
- VAULT_APPROLE_SECRET_ID: same as above.

> For the two Vault credentials, you'll need the "group name". That's the key `iam_groups` found
> in the [infrastructure-services](https://github.com/canonical/infrastructure-services) compute
> definition for your cluster.

There are 2 approaches to deployments, based on the requirements of your team.

### Continuous Delivery

With this approach you don't need a deployment job, just a build one. You configure the
build job to run when there are changes in a given branch and call the
`/.github/workflows/pack_release.yaml` workflow to take care of the build, pack and release
of the application.

You can make the Terraform configuration point to the latest revision of a given channel.
When the synchronization mechanism runs, your application will be updated to the last
build done. Optionally, if you don't want to wait for the synchronization to run, you can
manually trigger a synchronization job by calling `/.github/workflows/terraform_apply.yaml`.

You can see an example of this approach at
[rocks-storefront project](https://github.com/canonical/rocks-storefront/tree/main/.github).

### Manual Releases

If you want to control when and what to release, then you might want to trigger the releases
manually instead of whenever something gets merged into a branch.

The approach is very similar to above. The differences in the build job are:
- It needs to be configured so that changes in `main` are released to the testing channel
(i.e. latest/beta), instead of the stable one.
- It needs to have a manual way to be triggered so that you can release to the stable branch.
This is usually achieved with `workflow_dispatch` in GH Actions.

The approach for the Continuous Delivery is like this (source at
`/terraform/ps7/k8s-stg-marketplace-rocks/main.tf`):

```terraform
data "juju_charm" "rocks_storefront_charm" {
  charm   = var.charm_name
  channel = "latest/beta"
  base    = "ubuntu@24.04"
}

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

The "data" object pulls the info for the given charm from charmcraft API and contains the
latest revision for the given channel.

For a manual release process you have 2 options, depending on the level of control you want:
1. Keep the same config as for the Continuous Delivery case. If you make sure the "data"
object points to your stable channel, the deployment will happen only after you manually
trigger the build/release for that channel. It will be an automatic deployment; whenever IS
synchronization happens (or you could add a `/docs/workflows/terraform_apply.md` job to
force a manual synchronization without having to wait).
2. Remove the "data" section and manually fill the revision and resources for the
"juju_application". This means that when you want to do a release, you'll have to first
trigger the build and then open a PR to change the revisions in your Terraform configuration
to update them.
