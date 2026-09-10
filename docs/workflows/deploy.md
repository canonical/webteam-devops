# `deploy.yaml`

This GitHub Action workflow is designed to automate the packing, publishing and deployment of a charm and its associated OCI image (rock) 
for a flask 12-factor application. This action can handle any deployment to our environments - currently PS6 and PS7.

This action assumes the following:
1. a `rockcraft.yaml` file exists in the root of the repository
2. the charm source code and `charmcraft.yaml` are in the `charm/` directory.
3. the charm is published on charmhub.io

 📥 Inputs

These inputs must always be provided by the workflow that calls this one:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `charm_name` | `string` | ✅ | Name of the charm to package and release. |
| `channel` | `string` | ✅ | Channel to release the charm to (e.g., `edge`, `beta`). |
| `environment` | `string` | ❌ | If using [Github Deployment Environments](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) pass the environment here to use it (to get secrets for example) |
| `deploy_method` | `string` | ❌ | Defaults to 'juju', which deploys to PS6. Set to 'terraform' to trigger deployments to PS7 using Terraform |

By default, the job deploys to PS6 environment. It needs some specific inputs:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `juju_controller_name` | `string` | ✅ | Name of the Juju controller to deploy to (on PS6). |
| `juju_model_name` | `string` | ✅ | Name of the Juju model to deploy to (on PS6). |

When `deploy_method` is set to 'terraform' the workflow changes the last step; instead of using `juju` commands to deploy to PS6, 
it relies on Terraform and configuration files to do the deployments to PS7+.
In this case the additional inputs needed are:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `terraform_dir` | `string` | ✅ | The directory where the Terraform configuration to be deployed is. |

---

## 🔐 Secrets

The following secrets must be defined in the calling workflow or repository (either at the repository level, in a deployment environment, or in the workflow itself). These secrets are used to authenticate with Vault and Charmhub, and to pass necessary credentials to juju for deployment:

| Secret | Required | Description |
|--------|----------|---------|
| `VAULT_APPROLE_ROLE_ID` | ✅ | Get this from your model `echo $VAULT_APPROLE_ROLE_ID` |
| `VAULT_APPROLE_SECRET_ID` | ✅ | Get this from your model `echo $VAULT_APPROLE_SECRET_ID` |
| `CHARMHUB_TOKEN` | ✅ | Auth token used by Charmcraft to interact with Charmhub. Use `charmcraft login` [docs](https://canonical-charmcraft.readthedocs-hosted.com/en/stable/reference/commands/login/) to get the token  |

---

## Example Usage (PS6)

```yaml
  deploy:
    needs: setup
    name: Deploy
    uses: canonical/webteam-devops/.github/workflows/deploy.yaml@main
    with:
      charm_name: snapcraft
      channel: latest/edge
      juju_controller_name: juju-controller-36-production-ps6
      juju_model_name: prod-snapcraft
    secrets:
      VAULT_APPROLE_ROLE_ID: ${{ secrets.VAULT_APPROLE_ROLE_ID }}
      VAULT_APPROLE_SECRET_ID: ${{ secrets.VAULT_APPROLE_SECRET_ID }}
      CHARMHUB_TOKEN: ${{ secrets.CHARMHUB_TOKEN }}
```

## Example Usage (PS7)

```yaml
  deploy:
    needs: setup
    name: Deploy PS7
    uses: canonical/webteam-devops/.github/workflows/deploy.yaml@main
    with:
      charm_name: rocks-storefront
      channel: latest/stable
      deploy_method: terraform
      terraform_dir: terraform/ps7/k8s-prod-marketplace
```
