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

# Demo preview workflows (`start-demo.yaml` and `cleanup-demo.yaml`)

These reusable workflows create and destroy PR preview demos on Juju/Terraform.

`start-demo.yaml` builds the demo image/charm , deploys or refreshes the Juju app, imports it into Terraform state, applies Terraform, and can post a PR comment with the preview URL.

`cleanup-demo.yaml` destroys Terraform-managed demo resources, deletes remote Terraform state, and removes the GHCR image tag (used when a PR is closed).

## Assumptions

The calling repository should contain:
1. `rockcraft.yaml` in repo root.
2. charm source (default `charm/`).
3. Terraform config defining all resources required for a demo (default `terraform/demo/`).

## Start demo inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `juju-model-uuid` | `string` | ✅ | Juju model UUID used for Terraform import. |
| `juju-model-name` | `string` | ✅ | Juju model in owner/name form (e.g. `owner/model`) used by Juju and Terraform. |
| `demo-id` | `string` | ❌ | Optional explicit demo ID (otherwise auto-generated from PR information in the format: `project-name-pr123`). |
| `post-pr-comment` | `boolean` | ❌ | Post/update PR status comment. Default `true`. |
| `terraform-dir` | `string` | ❌ | Terraform directory. Default `terraform/demo`. |

## Cleanup inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `juju-model-name` | `string` | ✅ | Juju model in owner/name form (e.g. `owner/model`) used by Terraform provider data source. |
| `demo-id` | `string` | ❌ | Demo ID to destroy (auto generated based on PR information by default). |
| `terraform-dir` | `string` | ❌ | Terraform directory. Default `terraform/demo`. |
| `ghcr-package-name` | `string` | ❌ | Optional GHCR package override. |

## Demo workflow secrets

| Secret | Required | Description |
|---|---|---|
| `DEMOS_JUJU_CLIENT_ID` | ✅ | JAAS service account client ID |
| `DEMOS_JUJU_CLIENT_SECRET` | ✅ | JAAS service account client secret |
| `DEMOS_S3_ACCESS_KEY_ID` | ✅ | S3 access key for Terraform backend |
| `DEMOS_S3_SECRET_ACCESS_KEY` | ✅ | S3 secret key for Terraform backend |

## Example usage

```yaml
name: Demo
on:
  pull_request:
    types: [opened, reopened, synchronize]

permissions:
  pull-requests: write
  packages: write

jobs:
  start-demo:
    uses: canonical/webteam-devops/.github/workflows/start-demo.yaml@main
    with:
      juju-model-name: "<owner>/<model>"
      juju-model-uuid: "<your-juju-model-uuid>"
    secrets:
      demos_juju_client_id: ${{ secrets.DEMOS_JUJU_CLIENT_ID }}
      demos_juju_client_secret: ${{ secrets.DEMOS_JUJU_CLIENT_SECRET }}
      demos_s3_access_key_id: ${{ secrets.DEMOS_S3_ACCESS_KEY_ID }}
      demos_s3_secret_access_key: ${{ secrets.DEMOS_S3_SECRET_ACCESS_KEY }}
```

```yaml
name: Demo Cleanup
on:
  pull_request:
    types: [closed]

permissions:
  pull-requests: write
  packages: write

jobs:
  cleanup-demo:
    uses: canonical/webteam-devops/.github/workflows/cleanup-demo.yaml@main
    with:
      juju-model-name: "<owner>/<model>"
    secrets:
      demos_juju_client_id: ${{ secrets.DEMOS_JUJU_CLIENT_ID }}
      demos_juju_client_secret: ${{ secrets.DEMOS_JUJU_CLIENT_SECRET }}
      demos_s3_access_key_id: ${{ secrets.DEMOS_S3_ACCESS_KEY_ID }}
      demos_s3_secret_access_key: ${{ secrets.DEMOS_S3_SECRET_ACCESS_KEY }}
```
