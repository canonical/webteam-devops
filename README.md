This repository contains a collection of scripts/GitHub Actions workflows for deploying and managing deployments of webteam applications.

# `deploy.yaml`

This GitHub Action workflow is designed to automate the packing, publishing and deployment of a charm and its associated OCI image (rock) for a flask 12-factor application. 

This action assumes the following:
1. a `rockcraft.yaml` file exists in the root of the repository
2. the charm source code and `charmcraft.yaml` are in the `charm/` directory.
3. the charm is published on charmhub.io

 📥 Inputs

These inputs must be provided by the workflow that calls this one:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `charm_name` | `string` | ✅ | Name of the charm to package and release. |
| `channel` | `string` | ✅ | Channel to release the charm to (e.g., `edge`, `beta`). |
| `juju_controller_name` | `string` | ✅ | Name of the Juju controller to deploy to (on PS6). |
| `juju_model_name` | `string` | ✅ | Name of the Juju model to deploy to (on PS6). |
| `environment` | `string` | ❌ | If using [Github Deployment Environments](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) pass the environment here to use it (to get secrets for example) |

---

## 🔐 Secrets

The following secrets must be defined in the calling workflow or repository (either at the repository level, in a deployment environment, or in the workflow itself). These secrets are used to authenticate with Vault and Charmhub, and to pass necessary credentials to juju for deployment:

| Secret | Required | Description |
|--------|----------|---------|
| `VAULT_APPROLE_ROLE_ID` | ✅ | Get this from your PS6 model `echo $VAULT_APPROLE_ROLE_ID` |
| `VAULT_APPROLE_SECRET_ID` | ✅ | Get this from your PS6 model `echo $VAULT_APPROLE_SECRET_ID` |
| `CHARMHUB_TOKEN` | ✅ | Auth token used by Charmcraft to interact with Charmhub. Use `charmcraft login` [docs](https://canonical-charmcraft.readthedocs-hosted.com/en/stable/reference/commands/login/) to get the token  |

---

## Example Usage

```yaml
  deploy:
    needs: setup
    name: Deploy
    uses: canonical/webteam-devops/.github/workflows/deploy.yaml@main
    with:
      charm_name: snapcraft
      channel: edge
      juju_controller_name: juju-controller-36-production-ps6
      juju_model_name: prod-snapcraft
    secrets:
      VAULT_APPROLE_ROLE_ID: ${{ secrets.VAULT_APPROLE_ROLE_ID }}
      VAULT_APPROLE_SECRET_ID: ${{ secrets.VAULT_APPROLE_SECRET_ID }}
      CHARMHUB_TOKEN: ${{ secrets.CHARMHUB_TOKEN }}
```
