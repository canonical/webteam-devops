# `pack_release.yaml`

This GitHub Action workflow is designed to automate the packing and releasing/publishing of a charm and its associated OCI image (rock) 
for a flask 12-factor application.

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
| `force_charm_build` | `boolean` | ❌ | Defaults to 'false', which means the job decides builds and releases the charm only if there are changes inside the `charm/` directory. If set to 'true' it forces always the build and release of the charm. |

---

## 🔐 Secrets

The following secret must be defined in the calling workflow or repository (either at the repository level, in a deployment environment,
or in the workflow itself). This secret is used to authenticate with Charmhub:

| Secret | Required | Description |
|--------|----------|---------|
| `CHARMHUB_TOKEN` | ✅ | Auth token used by Charmcraft to interact with Charmhub. Use `charmcraft login` [docs](https://canonical-charmcraft.readthedocs-hosted.com/en/stable/reference/commands/login/) to get the token  |

---

## Example Usage

```yaml
  build:
    needs: setup
    name: Build
    uses: canonical/webteam-devops/.github/workflows/pack_release.yaml@main
    permissions:
      packages: write
      id-token: write
      contents: read
    with:
      charm_name: ${{ needs.setup.outputs.charm_name }}
      channel: ${{ needs.setup.outputs.channel }}
      environment: ${{ needs.setenv.outputs.environment }}
      # Force conversion to boolean
      force_charm_build: ${{ needs.setenv.outputs.force_charm_build == 'true' }}
    secrets:
      CHARMHUB_TOKEN: ${{ secrets.CHARMHUB_TOKEN }}
```

You can see a full example at [rocks-storefront](https://github.com/canonical/rocks-storefront/blob/main/.github/workflows/build.yaml).
