# Pull request demos

`demo-deploy.yaml` and `demo-cleanup.yaml` are reusable workflows for
repositories onboarded to the Canonical demos controller.

The caller supplies:

- the pull request number;
- the exact commit SHA to build;
- the controller API URL;
- a repository-specific bearer token.

The deploy workflow packs the caller's root `rockcraft.yaml` by default,
publishes an immutable repository-scoped GHCR digest, submits an authenticated
deployment request, waits for readiness, and updates one persistent pull
request comment.

The cleanup workflow submits an authenticated destruction request and deletes only
single-tag GHCR versions matching the pull request tag prefix only after the
controller confirms destruction.

Both workflows call the internal `demo-api.yaml` reusable workflow, which
contains the shared Python bearer-token client inline. Relative workflow calls use the
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
    secrets:
      demos-api-token: ${{ secrets.DEMOS_API_TOKEN }}

  cleanup:
    if: github.event.action == 'closed'
    uses: canonical/webteam-devops/.github/workflows/demo-cleanup.yaml@<workflow-commit-sha>
    with:
      pr-number: ${{ github.event.pull_request.number }}
      api-url: ${{ vars.DEMOS_API_URL }}
    secrets:
      demos-api-token: ${{ secrets.DEMOS_API_TOKEN }}
```

For fork pull requests, callers should add a condition that prevents passing
the repository secret to untrusted branches.

The workflows and client contain no embedded controller credentials. Bearer
tokens remain in the caller repository's Actions secrets and are sent in the
`Authorization: Bearer ...` header over HTTPS. The controller checks that the
token belongs to `X-Demos-Repository` and that the operation targets that repository.

Use a distinct token generated from at least 32 cryptographically random bytes
for each repository. Store the identical value in the controller's Juju
`api-tokens-secret` credential map. Vault AppRole credentials are separate and
must not be supplied to these workflows.

The client requires HTTPS with normal certificate validation, refuses redirects,
and does not include HTTP error response bodies in logs or PR comments because
they could echo credentials. Never enable Authorization-header logging at ingress.

## Migrating from HMAC

This is a breaking change requiring a coordinated controller/client rollout:

1. Prepare repository-specific bearer tokens in Juju and GitHub using your
   approved secret-handling process. The Juju secret retains its `credentials`
   field containing a JSON repository-to-token map.
2. Update the controller to bearer authentication and configure
   `api-tokens-secret`, granting the Juju application access to that secret.
   The controller environment variable is now `API_TOKENS`; the old signature
   age setting is removed.
3. Pin callers to the audited bearer-token workflow commit and replace
   `demos-hmac-key: secrets.DEMOS_HMAC_KEY` with
   `demos-api-token: secrets.DEMOS_API_TOKEN` as shown above.
4. Verify deployment, authenticated status polling, and cleanup before retiring
   the old configuration and GitHub secret.

Existing sufficiently random HMAC key values can be reused as token values if
approved; their storage names and the request protocol still change. There is
no automatic fallback to HMAC. Pause demo workflow triggers during the cutover
if necessary; existing demo workloads do not need to be deleted.

Payload `delivery_id` values remain in use for operation retries. Timestamps,
signature headers, and authentication nonces are removed. A bearer token does
not provide signature freshness or stolen-token replay protection; rotate it
in both Juju and GitHub if compromised.
