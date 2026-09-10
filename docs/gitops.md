# GitOps

The IS team has a proposed 
[GitOps solution](https://documentation.ubuntu.com/canonical-information-systems-documentation/products/devopsenv/how-to/jaas-terraform-gitops/) 
for teams that want to get automatic deployments through Terraform in any desired GitHub project repository.
These deployments happen through the automatic run of `terraform apply` in a specified repository path every X minutes
(we have found the automatic runs to have a somewhat unstable schedule, leading to update times between 5 mins and 2 hours).

There are some steps in the previous documentation that can be skipped:
- Provisioning a service account: there exist one for the web engineering department that you could use called
`is-platform-services-webdesign`.
- Accessing the service account credentials: the Vault GUI is recommended, as this just needs to be done once to set
`VAULT_APPROLE_ROLE_ID` and `VAULT_APPROLE_SECRET_ID` in the project repository.
- Authenticating with the service account credentials: not needed

## GitOps model management

The section where you have to add the `gitops_model_management` information to 
[infrastructure-services](https://github.com/canonical/infrastructure-services) repository will ask some information
regarding where the Terraform configuration will live.

The convention followed in this repository is the following:

```
terraform/
 |_ [cloud]/
 |   |_ [model name]/
 |   |   |_ main.tf
 |   |   |_ ...
 |   |_ ...
```

At the time of writing there's only PS7, but we expect future ProdStack environments to follow the same approach; 
so we could have `ps8`, `ps9` and so on to keep the Terraform configuration files relative to each deployment. This
also grants us the advantage to be able to deploy to 2 different environments easily, which may be helpful when 
performing migrations.

### Which 'model name' to use?

The `model name` from the above specification can be taken from 2 places.

#### infrastructure-services

Take this example for *rocks-storefront* GitOps (only the relevant sections of the file are included here, you can check the
[full source here](https://github.com/canonical/infrastructure-services/blob/main/services/definitions/compute/k8s-prod-marketplace.yaml)):

```yaml
service_primitive: compute
service_class: kubernetes_cluster
name: k8s-prod-marketplace
owner: is
requester: webdesign
...
k8s_models:
- name: default
  iam_groups:
  - is-platform-services-webdesign
  - is-platform-services-webdesign-marketplace
- name: rocks
  ingress_addresses:
  - address: rocks.ubuntu.com
    ingress: ingress-ps7-webdesign
  iam_groups:
  - is-platform-services-webdesign
  - is-platform-services-webdesign-marketplace
```

The file defines a ProdStack compute cluster, the actual servers where everything is deployed. In addition, it configures
several abstraction layers on top of the hardware: K8s, Juju, Charms and Rocks.
It also defines the K8s and Juju models that will be created on that cluster. In the above example you can see 2 of them:
default and rocks. This file will end up giving you 2 models, formed by connecting `[cluster name]-[model simple name]`.
So the resulting model names in this case will be:
- k8s-prod-marketplace-default
- k8s-prod-marketplace-rocks

#### PS7 commands

Another way to see the name of your models is by connecting to the environment's bastion (see IS's 
[docs](https://documentation.ubuntu.com/canonical-information-systems-documentation/products/devopsenv/how-to/access-devops-environment/))
and then running:

```bash
juju models
# This will output a table with all the models you have access to
# The first column 'Model' contains the user-owner/model-name
# Example
795798e4-922f-49c7-9169-004ffc17df90@serviceaccount/k8s-stg-marketplace-default*
795798e4-922f-49c7-9169-004ffc17df90@serviceaccount/k8s-staging-ubuntu-com-web-default
795798e4-922f-49c7-9169-004ffc17df90@serviceaccount/k8s-stg-marketplace-rocks
795798e4-922f-49c7-9169-004ffc17df90@serviceaccount/k8s-prod-marketplace-rocks
...
```

The `model name` is everything that comes after the `/`. In the above cases it would be: k8s-stg-marketplace-rocks,
k8s-prod-marketplace-rocks, etc.

### Example

This is the *rocks-storefront* GitOps example for Prod:

```yaml
  gitops_model_management:
    repository_url: https://github.com/canonical/webteam-devops.git
    path: terraform/ps7/k8s-prod-marketplace-rocks
    branch: main
    create_repository: false
    enabled: true
    auto_approve: true
```

If you follow the steps on requesting a GitOps solution you'll get the above output by running the
following script:

```bash
./scripts/manage_gitops_model_config.py -m ${MODEL_NAME} \
   --repo "${REPOSITORY_URL}" \
   --path "${PATH}" \
```

The `model name` we already explained how to get it.
The repository URL it's going to be always the same: https://github.com/canonical/webteam-devops.git
The path will be determined following the specified repository convention. In the above example, the
GitOps model is for a PS7 environment for the k8s-prod-marketplace-rocks model, so the path to give to
the script is `terraform/ps7/k8s-prod-marketplace-rocks`. 

## Bootstraping

The next section of IS's docs explain how to 'bootstrap the repository'. After you follow that section
you'll end up with a PR like this one: https://github.com/canonical/webteam-devops/pull/18

That contains all the common config for Terraform models. Sadly, it is not perfect for our deployments
and you'll need to do a couple tweaks:
1. In `versions.tf` you'll need to update Terraform required version to ">= 1.10.0" and the juju provider
version to "~> 1.5.6".
2. To be able to run deployments manually (instead of waiting for the automated IS script to run) you'll
need to modify a bit the `s3_credentials_jaas.sh` script. Be sure to give it execution permissions if not
already present and then check the changes at `terraform/ps7/k8s-stg-marketplace-rocks/s3_credentials_jaas.sh`
example and apply them.

After that you can start configuring your model's applications in `main.tf` file so that they are
always deployed.
