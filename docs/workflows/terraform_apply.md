# `terraform_apply.yaml`

This GitHub Action workflow is designed to force the synchronization of an environment with its configuration (via `terraform apply`).
Most of the times this should happen automatically through IS's provided GitOps Management. Unfortunately, it may take a long time
for that synchronization to happen (people have seen up to 2h delay); so for urgent cases there is this job which can be called
manually to force the deployment to happen at the moment.

This action assumes the following:
1. the charm is published on charmhub.io
2. the Terraform configuration to be deployed is in this repository

 📥 Inputs

These inputs must always be provided by the workflow that calls this one:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `terraform_dir` | `string` | ✅ | Path to the directory that contains the terraform configuration to deploy. |
| `terraform_github_repo` | `string` | ❌ | If you have your configuration files in a different GitHub repository, specify it with this input. |
| `vault_model_name` | `string` | ❌ | Name for the model as found in Canonical Vault. |

The `vault_model_name` input is not necessary if you are following the conventions specified at
[webteam-terraform-plans](https://github.com/canonical/webteam-terraform-plans/blob/main/docs/gitops.md),
because we can obtain it programmatically. If you follow a different approach then you need to pass
it so that the script can properly get the needed S3 credentials from your Vault.

---

## 🔐 Secrets

The following secrets must be defined in the calling workflow or repository (either at the repository level, in a deployment environment,
or in the workflow itself). These secrets are used to authenticate with Vault:

| Secret | Required | Description |
|--------|----------|---------|
| `VAULT_APPROLE_ROLE_ID` | ✅ | Get this from your model `echo $VAULT_APPROLE_ROLE_ID` |
| `VAULT_APPROLE_SECRET_ID` | ✅ | Get this from your model `echo $VAULT_APPROLE_SECRET_ID` |
||

To get these secrets from Vault follow the steps
[here](https://documentation.ubuntu.com/canonical-information-systems-documentation/products/devopsenv/how-to/jaas-terraform-gitops/#accessing-the-service-account-credentials).

---

## Example Usage

```yaml
  apply:
    needs: [setenv, setup]
    name: Terraform Apply
    uses: canonical/webteam-devops/.github/workflows/terraform_apply.yaml@main
    permissions:
      packages: write
      id-token: write
      contents: read
    with:
      terraform_dir: ${{ needs.setup.outputs.terraform_dir }}
      terraform_github_repo: canonical/my-project-terraform-config-repo
    secrets:
      VAULT_APPROLE_ROLE_ID: ${{ secrets.VAULT_APPROLE_ROLE_ID }}
      VAULT_APPROLE_SECRET_ID: ${{ secrets.VAULT_APPROLE_SECRET_ID }}
```

You can see a full example at [rocks-storefront](https://github.com/canonical/rocks-storefront/blob/main/.github/workflows/terraform_apply.yaml).
