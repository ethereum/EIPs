# GitHub Actions Security Improvement Plan

## Scope and current state

This plan is based on an audit of all workflows under `.github/workflows` and the composite action under `.github/actions`.

Current controls already present:

- External actions are pinned to full 40-character commit SHAs.
- `actions/checkout` uses `persist-credentials: false`.
- Workflow permissions are explicitly declared.
- Main CI and workflow-security jobs use concurrency cancellation and timeouts.
- Actionlint is downloaded into a temporary directory and verified with a published SHA-256 checksum.
- Dependency review runs on pull requests.
- GitHub Pages uses native GitHub OIDC through `id-token: write`.
- `./scripts/verify` runs actionlint, the workflow security audit, artifact regression tests, manifest checks, and `git diff --check`.
- Auto Review Bot failures are surfaced instead of being masked by `continue-on-error`.

The audit also found that this repository has no AWS, GCP, Azure, or other external cloud deployment. The current deployment target is GitHub Pages. `secrets.TOKEN` is used by GitHub bot workflows and is a GitHub API credential, not a cloud credential; it needs GitHub App or fine-grained-token migration rather than cloud OIDC.

External prerequisites are tracked in the [Security Migration Guide](SECURITY_MIGRATION_GUIDE.md). They include repository-admin access for required checks and secret-scanning settings, GitHub organization approval for a bot App, a selected cloud account if publishing moves off Pages, coordinated ERCs access, and release-owner decisions for attestations and SBOMs.

## Prioritized improvements

### P0: prevent false-green validation

The CodeSpell and Markdownlint workflows currently allow `gh pr diff` to fail and then gate the real check on the discovery step outcome. A GitHub API failure can therefore skip validation while the workflow remains green.

Replace outcome-based gating with explicit discovery output:

```yaml
- name: Get Changed Files
  id: changed
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    PR_NUMBER: ${{ github.event.number }}
  run: |
    set -euo pipefail
    changed_files="$(gh pr diff "$PR_NUMBER" --name-only)"
    {
      echo 'CHANGED_FILES<<EOF'
      printf '%s\n' "$changed_files"
      echo EOF
    } >> "$GITHUB_ENV"
    if [[ -n "$changed_files" ]]; then
      echo 'has_files=true' >> "$GITHUB_OUTPUT"
    else
      echo 'has_files=false' >> "$GITHUB_OUTPUT"
    fi

- name: Run check
  if: steps.changed.outputs.has_files == 'true'
  uses: <pinned-action-sha>
```

Acceptance criterion: a simulated `gh` failure exits non-zero; a PR with no matching files exits successfully and explicitly skips the check.

### P0: narrow deployment permissions

The Pages workflow currently declares deployment permissions at workflow scope. Keep the build read-only and grant deployment permissions only to the deployment job:

```yaml
name: Deploy Jekyll site to Pages

on:
  push:
    branches: [master]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build:
    permissions:
      contents: read
    # build steps...

  deploy:
    needs: build
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    permissions:
      pages: write
      id-token: write
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e # v4
```

Acceptance criterion: the build job cannot mint deployment tokens or write Pages artifacts; only the protected deploy job has `pages: write` and `id-token: write`.

### P0: replace long-lived bot credentials

`secrets.TOKEN` is used by Auto Review Bot and Auto Stagnant Bot. Migrate each bot independently:

1. Inventory the API operations performed by the pinned bot action.
2. Create a GitHub App with only the required repository permissions.
3. Install it only on the EIPs repository.
4. Store the App ID and private key in the approved secret store, or use an organization token broker.
5. Generate a short-lived installation token in a dedicated step.
6. Pass only that token to the bot action.
7. Exercise scheduled, pull-request, review, and failure paths.
8. Revoke `secrets.TOKEN` after successful canary runs.

For a temporary fallback, use a fine-grained token with repository restriction, minimum permissions, an expiry date, an owner, and a rotation record. Do not broaden the token to compensate for an undocumented bot requirement.

Acceptance criterion: no workflow references `secrets.TOKEN`; the replacement credential expires or is short-lived and its permissions are documented.

### P1: make every workflow bounded

Add `timeout-minutes` to the remaining bot, Pages, stale, label, trigger, and Post CI jobs. Use a longer limit only for Jekyll build/proofing jobs. Do not use retries for linting, validation, or publishing failures.

Retry only transient downloads, and make retries bounded and visible:

```yaml
- name: Download external tool
  uses: <pinned-download-action-sha>
  with:
    retry-count: 2
```

Acceptance criterion: every job has an explicit timeout, and deterministic validation failures are not retried.

### P1: validate manual inputs

The workflow-dispatch PR number must be numeric before it is written to an artifact:

```yaml
- name: Validate PR number
  if: github.event_name == 'workflow_dispatch'
  env:
    PR_NUMBER: ${{ inputs.pr_number }}
  run: |
    if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
      echo 'pr_number must contain digits only' >&2
      exit 1
    fi
```

Acceptance criterion: malformed, empty, and non-numeric manual inputs fail with an actionable message.

### P1: add dedicated workflow security analysis

Keep actionlint for syntax, expressions, shell analysis, and action metadata. Add a dedicated security scanner such as Zizmor and CodeQL's Actions analysis when repository administration and runner support are available.

The security gate should inspect:

- Dangerous `pull_request_target` and `workflow_run` trust boundaries
- Untrusted event data in shell commands
- Missing or excessive permissions
- Mutable action references
- Secret exposure to third-party actions
- Unsafe artifact download and upload behavior

Acceptance criterion: security scanning runs on workflow changes and fails the check for a new high-confidence security finding.

### P1: enforce required checks

Repository administrators should protect `master` and require the workflow checks before merge:

- Workflow Checks
- Actionlint
- Workflow Security Audit
- Core EIP validation jobs relevant to the changed paths

Required checks must be configured in branch-protection settings. A workflow file alone cannot enforce this policy.

Acceptance criterion: a pull request cannot merge when a required security or validation check fails, is missing, or is bypassed outside the documented administrator process.

### P2: attest build provenance

The repository currently deploys GitHub Pages but does not attest a deterministic archive of the generated site. When the site archive becomes a release or downstream input, add provenance:

```yaml
permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      id-token: write
      attestations: write
    steps:
      - name: Build site
        run: bundle exec jekyll build --baseurl ""
      - name: Package exact deployment input
        run: tar -czf eips-site.tar.gz _site
      - name: Attest deployment input
        uses: actions/attest-build-provenance@96b4a1ef7235a096b17240c259729fdd70c83d45 # v2
        with:
          subject-path: eips-site.tar.gz
      - name: Upload deployment input
        uses: actions/upload-artifact@65c4c4a1ddee5b72f698fdd19549f0f0fb45cf08
        with:
          name: eips-site
          path: eips-site.tar.gz
```

Acceptance criterion: the promoted archive has a verifiable attestation tied to the reviewed source revision and workflow identity; consumers verify the attestation before use.

## OIDC migration for a future external cloud

No external cloud provider is currently configured. If publication later moves to AWS, use a separate protected deployment job:

```yaml
permissions:
  contents: read

jobs:
  publish:
    if: github.event_name == 'push' && github.ref == 'refs/heads/master'
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - name: Configure AWS credentials with OIDC
        uses: aws-actions/configure-aws-credentials@7474bc4690e29a8392af63c5b98e7449536d5c3a # v4.3.1
        with:
          role-to-assume: arn:aws:iam::<account-id>:role/eips-production-publisher
          aws-region: <region>
          role-session-name: eips-${{ github.run_id }}
      - name: Publish
        run: aws s3 sync ./_site s3://<bucket-name> --delete
```

Migration steps:

1. Create a non-production IAM role with only the required bucket permissions.
2. Trust `token.actions.githubusercontent.com` only for this repository, workflow, protected environment, branch, and expected audience.
3. Test from a canary branch and record the OIDC subject and denied permissions.
4. Move the role to the protected production environment after the canary passes.
5. Remove any cloud access key from GitHub Secrets.
6. Verify that pull-request jobs cannot assume the production role.
7. Monitor failed role assumptions and unexpected subjects.

The same model applies to GCP Workload Identity Federation or Azure federated credentials: short-lived tokens, exact repository/workflow/environment trust, and no long-lived cloud secret fallback.

## Before and after posture

| Area | Before | After | Risk reduced |
| --- | --- | --- | --- |
| Validation reliability | Discovery API failures can silently skip CodeSpell or Markdownlint | Discovery failures fail; no-file cases use explicit outputs | False-green pull requests |
| Pages permissions | Build and deploy permissions are shared at workflow scope | Build is read-only; deploy alone receives Pages OIDC permissions | Unauthorized publication from build code |
| Bot credentials | Long-lived `secrets.TOKEN` | Short-lived GitHub App installation token or expiring fine-grained token | Credential theft and stale access |
| Action integrity | Full-SHA pins are enforced | Full-SHA pins plus automated update review and security scanning | Mutable or compromised action versions |
| Workflow execution | Several jobs lack explicit timeouts | Every job is bounded; only transient downloads may retry | Hung jobs and concealed defects |
| Manual inputs | Dispatch PR numbers are not strictly validated | Numeric validation fails malformed inputs early | Confusing artifact and downstream behavior |
| Build provenance | Generated assets can be uploaded without attestation | Exact promoted archive carries verifiable provenance | Artifact substitution |
| Merge policy | Checks exist but required status configuration is external | Protected branches require security and validation checks | Bypassed CI controls |

## Ownership and rollout order

| Priority | Owner | Acceptance criterion |
| --- | --- | --- |
| P0 | CI maintainers | Discovery failures cannot produce a green skipped lint job |
| P0 | Pages maintainers | Only the deploy job has Pages write and OIDC permissions |
| P0 | Bot maintainers | `secrets.TOKEN` is removed or replaced by a documented short-lived credential |
| P1 | CI maintainers | All jobs have timeouts and manual inputs have fixture coverage |
| P1 | Security maintainers | CodeQL/Zizmor or an approved equivalent runs on workflow changes |
| P1 | Repository administrators | Required checks are enabled on protected branches |
| P2 | Release maintainers | Promoted site/release archives have verifiable attestations and SBOM metadata |
| P2 | Platform maintainers | Any external cloud deployment uses scoped OIDC federation with no static cloud keys |

The existing [Workflow Reliability and Supply-Chain Plan](WORKFLOW_RELIABILITY_PLAN.md) covers shared EIPs/ERCs workflows, synchronization, behavioral fixtures, and cross-repository rollout. This document focuses on the current GitHub Actions security boundary and its concrete migration sequence.
