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
single-tag GHCR versions matching the pull request tag prefix only after the
controller confirms destruction.

Both workflows call the internal `demo-api.yaml` reusable workflow, which
contains the shared Python HMAC client inline. Relative workflow calls use the
same revision as the calling workflow, so no separate client checkout or
client revision input is needed.

Pin the public workflows to an audited commit SHA to pin the API client too.
Replace `<workflow-commit-sha>` in the example caller below with that SHA:

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
    uses: canonical/webteam-devops/.github/workflows/demo-deploy.yaml@<workflow-commit-sha>
    with:
      pr-number: ${{ github.event.pull_request.number }}
      commit-sha: ${{ github.event.pull_request.head.sha }}
      api-url: ${{ vars.DEMOS_API_URL }}
      api-connect-url: ${{ vars.DEMOS_API_CONNECT_URL }}
      api-insecure: ${{ vars.DEMOS_API_INSECURE == 'true' }}
    secrets:
      demos-hmac-key: ${{ secrets.DEMOS_HMAC_KEY }}

  cleanup:
    if: github.event.action == 'closed'
    uses: canonical/webteam-devops/.github/workflows/demo-cleanup.yaml@<workflow-commit-sha>
    with:
      pr-number: ${{ github.event.pull_request.number }}
      api-url: ${{ vars.DEMOS_API_URL }}
      api-connect-url: ${{ vars.DEMOS_API_CONNECT_URL }}
      api-insecure: ${{ vars.DEMOS_API_INSECURE == 'true' }}
    secrets:
      demos-hmac-key: ${{ secrets.DEMOS_HMAC_KEY }}
```

For fork pull requests, callers should add a condition that prevents passing
the repository secret to untrusted branches.

The workflows and client contain no controller credentials. HMAC keys remain
in the caller repository's Actions secrets.

`api-connect-url` is useful where the public API hostname has no DNS record.
Requests connect to that endpoint while retaining the signed API hostname in
the HTTP `Host` header. TLS verification is enabled by default. Set the
repository variable `DEMOS_API_INSECURE` to `true` only for an exceptional
trusted connection endpoint whose certificate cannot be validated.
