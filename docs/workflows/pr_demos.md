# Pull request demos

`demo-deploy.yaml` and `demo-cleanup.yaml` are reusable workflows for
repositories onboarded to the Canonical demos controller.

The caller supplies:

- the pull request number;
- the exact commit SHA to build;
- the controller API URL;
- a repository-specific HMAC secret.

The deploy workflow packs the caller's root `rockcraft.yaml` by default,
publishes an immutable repository-scoped GHCR digest, submits a signed
deployment request, waits for readiness, and updates one persistent pull
request comment.

The cleanup workflow submits a signed destruction request and deletes only
single-tag GHCR versions matching the pull request tag prefix.

Example caller:

```yaml
name: PR demo

on:
  pull_request:
    types: [opened, reopened, synchronize, closed]

permissions:
  contents: read
  packages: write
  pull-requests: write

jobs:
  deploy:
    if: github.event.action != 'closed'
    uses: canonical/webteam-devops/.github/workflows/demo-deploy.yaml@main
    with:
      pr-number: ${{ github.event.pull_request.number }}
      commit-sha: ${{ github.event.pull_request.head.sha }}
      api-url: ${{ vars.DEMOS_API_URL }}
    secrets:
      demos-hmac-key: ${{ secrets.DEMOS_HMAC_KEY }}

  cleanup:
    if: github.event.action == 'closed'
    uses: canonical/webteam-devops/.github/workflows/demo-cleanup.yaml@main
    with:
      pr-number: ${{ github.event.pull_request.number }}
      api-url: ${{ vars.DEMOS_API_URL }}
    secrets:
      demos-hmac-key: ${{ secrets.DEMOS_HMAC_KEY }}
```

For fork pull requests, callers should add a condition that prevents passing
the repository secret to untrusted branches.

The workflows and client contain no controller credentials. HMAC keys remain
in the caller repository's Actions secrets.
