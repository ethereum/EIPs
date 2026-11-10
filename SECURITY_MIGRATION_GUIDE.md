# GitHub Actions Security Migration Guide

This guide migrates the EIPs workflows from the audited current state to a least-privilege, reproducible, and provenance-aware setup.

## Current baseline

Before starting, record the current state:

- GitHub Pages is the only configured deployment target.
- GitHub Pages already uses native OIDC through `id-token: write`.
- `secrets.TOKEN` is still used by the Auto Review Bot and Auto Stagnant Bot.
- External actions are pinned to full commit SHAs.
- Checkout credential persistence is disabled.
- `./scripts/verify` is the local and CI validation entry point.
- Build artifact attestations and SBOM publication are not yet enabled.
- EIPs/ERCs shared-workflow adoption is not complete.
- Auto Review Bot failures are now visible and no longer masked by `continue-on-error`.

Do not delete or rotate existing credentials until the corresponding replacement has passed its canary tests.

## External prerequisites

The following items cannot be completed by editing this checkout alone. Assign an owner and obtain the required access before starting the corresponding migration phase.

| Prerequisite | Required access or decision | Needed for | Owner |
| --- | --- | --- | --- |
| Protected branch settings | Repository administrator access to `ethereum/EIPs` | Making Workflow Checks, Actionlint, security, and content validation required before merge | Repository administrators |
| GitHub App credentials | GitHub organization or repository owner approval, App creation rights, and secure private-key storage | Replacing long-lived `secrets.TOKEN` in bot workflows | Bot maintainers and organization administrators |
| GitHub App permission design | Confirmation of every API operation required by `eip-review-bot` and `EIP-Bot` | Least-privilege installation token configuration | Bot maintainers |
| GitHub environment protection | Administrator access to the `github-pages` environment and approval policy | Restricting production Pages deployment to reviewed jobs | Pages maintainers |
| Artifact attestations | Repository support for attestations and permission to grant `id-token: write` and `attestations: write` to the build job | Verifiable build provenance | Release maintainers |
| SBOM format and storage | Agreement on CycloneDX or SPDX, retention, and publication location | Reproducible dependency and artifact records | Security and release maintainers |
| External cloud provider | A selected AWS, GCP, or Azure account/project/subscription and a non-production target | OIDC federation migration if publishing leaves GitHub Pages | Platform maintainers |
| Cloud trust policy | Authority to create a narrowly scoped role and trust policy for this repository, workflow, branch, and environment | Removing long-lived cloud access keys | Cloud administrators |
| ERCs repository checkout | A coordinated ERCs branch or workspace with matching `config/shared-workflow-manifest.yml` | Cross-repository sync and compatibility tests | EIPs and ERCs maintainers |
| Shared workflow host | Canonical repository, release owner, and reviewed commit SHA for the reusable workflow | Removing duplicated EIPs/ERCs CI logic | EIPs and ERCs maintainers |
| Security scanner policy | Decision to adopt CodeQL, Zizmor, or an approved equivalent and authority to enable its workflow | Dedicated workflow security scanning | Security maintainers |
| Secret scanning settings | Repository administrator access to enable secret scanning and push protection | Early detection and prevention of credential commits | Repository administrators |

Do not mark a prerequisite complete because a YAML example exists. Mark it complete only after the owning administrator or external system has been configured and a canary run proves the expected boundary.

## Phase 0: establish a safe baseline

1. Create a migration branch from the current default branch.
2. Record the current workflow run IDs for CI, Pages, Auto Review Bot, Post CI, and scheduled bot workflows.
3. Run the baseline checks:

   ```sh
   ./scripts/verify
   npx --no-install markdownlint-cli2 --config config/.markdownlint.yaml README.md SECURITY_IMPROVEMENT_PLAN.md
   git diff --check
   ```

4. Save the output as migration evidence, including the actionlint version and checksum result.
5. Confirm that `master` is protected and that workflow changes require review.
6. Create a rollback branch or tag pointing to the pre-migration revision.

Rollback: stop here and restore the migration branch if the baseline is not green.

## Phase 1: enforce workflow validation

1. Confirm that the `Workflow Checks`, `Actionlint`, and `Workflow Security Audit` jobs exist in the branch-protection required-check configuration.
2. Add the core content checks that are required for changed files.
3. Verify that a deliberately malformed workflow causes actionlint to fail in a test branch.
4. Verify that a simulated `gh pr diff` failure fails CodeSpell or Markdownlint discovery rather than skipping the check.
5. Verify that a PR with no matching files produces `has_files=false` and exits successfully without running an irrelevant linter.
6. Require the checks in branch protection only after both failure cases are observed.

Acceptance: a failing security or validation job blocks merge; an intentionally irrelevant check skips explicitly and does not become a false green.

Rollback: remove the new required-check rule while preserving the workflow jobs, then investigate the failing check.

## Phase 2: remove long-lived GitHub bot credentials

`secrets.TOKEN` is a GitHub API credential, so cloud OIDC is not a direct replacement.

1. Inventory the API operations required by `ethereum/eip-review-bot` and `ethereum/EIP-Bot`.
2. Create a GitHub App dedicated to EIPs automation.
3. Grant only the required repository permissions, such as read-only contents and narrowly scoped pull-request, issue, or metadata access.
4. Install the App only on `ethereum/EIPs`.
5. Store the App ID and private key in the approved organization secret store.
6. Generate a short-lived installation token in a dedicated, pinned action or trusted script.
7. Pass that installation token to the bot action through an environment variable or documented input.
8. Run a canary for:
   - `pull_request_target`
   - `pull_request_review`
   - `issue_comment`
   - scheduled stagnation processing
   - failed CI feedback through Post CI
9. Confirm that the App cannot write unrelated repository resources.
10. Revoke and delete `secrets.TOKEN` only after the canary workflows pass.
11. Record the App permission set, owner, rotation procedure, and expiration review date.

Temporary fallback: use an expiring fine-grained token restricted to this repository and the minimum required permissions. Record its owner and expiry. Do not create a broad replacement token.

Acceptance: no workflow references `secrets.TOKEN`; bot authentication is short-lived or has an enforced expiry and documented minimum permissions.

Rollback: restore the previous credential only for the failed bot path, with an incident note and a new retirement date. Do not restore it globally.

## Phase 3: keep GitHub Pages deployment least-privileged

The current Pages deployment should remain separate from validation.

1. Set workflow-level permissions to read-only:

   ```yaml
   permissions:
     contents: read
   ```

2. Keep the build job read-only:

   ```yaml
   build:
     permissions:
       contents: read
   ```

3. Grant deployment permissions only to the protected deployment job:

   ```yaml
   deploy:
     environment:
       name: github-pages
       url: ${{ steps.deployment.outputs.page_url }}
     permissions:
       pages: write
       id-token: write
   ```

4. Require approval for the `github-pages` environment if production documentation requires human review.
5. Confirm that pull-request workflows cannot access the deployment environment.
6. Confirm that `actions/checkout` keeps `persist-credentials: false`.
7. Run a master deployment canary and verify the generated Pages URL.

Acceptance: only the deployment job has `pages: write` and `id-token: write`; the build job cannot deploy.

Rollback: restore the prior Pages permission layout only long enough to diagnose the deployment, then reapply job-level scoping.

## Phase 4: add artifact provenance

Use this phase when the generated site archive or another build artifact is consumed outside the immediate Pages deployment.

1. Define the exact artifact to attest, for example `eips-site.tar.gz`.
2. Make the build deterministic: pin Ruby/tool versions, use the lockfile, and record the source revision.
3. Package the exact bytes that will be uploaded or promoted.
4. Grant provenance permissions only to the build job:

   ```yaml
   permissions:
     contents: read

   jobs:
     build:
       permissions:
         contents: read
         id-token: write
         attestations: write
   ```

5. Build and attest the same file:

   ```yaml
   - name: Build site
     run: bundle exec jekyll build --baseurl ""

   - name: Package deployment input
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

6. Generate an SBOM for the artifact or its build dependencies.
7. Publish the SHA-256 digest and attestation reference with the artifact metadata.
8. Add a canary verification job that rejects an altered archive and accepts the attested archive.
9. Require attestation verification before release promotion or external redistribution.

Acceptance: the promoted artifact has a verifiable attestation tied to the expected source revision, workflow, and repository identity.

Rollback: retain the artifact but stop promotion; never bypass verification by silently accepting an unattested replacement.

## Phase 5: add external-cloud OIDC only if needed

No external cloud provider is currently configured. If EIPs later publishes to AWS, migrate in a non-production environment first.

1. Create a dedicated AWS IAM role with only the required bucket or distribution permissions.
2. Configure a trust policy for `token.actions.githubusercontent.com` with:
   - exact repository subject
   - exact protected environment
   - exact deployment workflow
   - `aud` set to AWS STS
   - production branch restriction
3. Add the pinned credential action:

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
   ```

4. Test the role from a canary branch and confirm pull requests cannot assume it.
5. Remove AWS access keys from GitHub Secrets.
6. Monitor denied assumptions, unexpected OIDC subjects, and role usage.
7. Apply the same controls to GCP Workload Identity Federation or Azure federated credentials if the provider changes.

Acceptance: no long-lived cloud access key exists, and only the protected production workflow can assume the publishing role.

Rollback: disable the federated trust relationship and stop publishing while the role subject or permissions are corrected. Do not reintroduce static cloud keys as an untracked fallback.

## Phase 6: synchronize EIPs and ERCs

1. Publish the shared reusable workflow from a canonical repository at a versioned commit.
2. Keep the EIPs and ERCs wrapper responsible only for triggers, path filters, repository kind, and merge inputs.
3. Add the same `config/shared-workflow-manifest.yml` to both repositories.
4. Run the local sync check with both repositories available:

   ```sh
   ERCs_ROOT=/path/to/ERCs ./scripts/verify
   ```

5. Test the compatibility matrix:
   - EIPs default branch plus ERCs default branch
   - EIPs PR plus ERCs default branch
   - EIPs default branch plus ERCs PR
   - conflicting shared infrastructure revisions
   - missing ERCs files
6. Compare results for the same source revision and shared workflow version.
7. Canary the EIPs caller first, then update ERCs to the same commit.
8. Retire the existing merge adapter only after both repositories consume shared workflow version 2.

Acceptance: the manifests match, the compatibility matrix has actionable failures, and the invariant holds:

```text
same input revision + same workflow version => same validation outcome
```

Rollback: pin both repositories to the last known-good shared workflow commit and retain the adapter until the compatibility failure is resolved.

## Phase 7: operate and review

1. Run `./scripts/verify` locally before every workflow change.
2. Keep Dependabot PRs enabled for GitHub Actions and Bundler dependencies.
3. Review action SHA updates and their release notes before merging.
4. Run the weekly workflow-security health check.
5. Review secret usage, OIDC exchanges, denied permissions, artifact attestations, and deployment environment approvals monthly.
6. Re-run the full migration checklist after changing runners, deployment targets, shared workflows, or bot permissions.
7. Record incidents with the affected workflow revision, source revision, runner image, tool versions, and artifact digest.

## Final security posture

| Area | Before migration | After migration |
| --- | --- | --- |
| Validation | API failures can potentially skip changed-file checks | Discovery failures fail; legitimate no-file cases are explicit |
| Bot access | Long-lived `secrets.TOKEN` | Short-lived GitHub App token or expiring fine-grained token |
| Pages deployment | OIDC permissions may be broader than necessary | Only protected deploy job receives Pages OIDC permissions |
| Cloud publishing | Any future provider could depend on static keys | Provider trust uses short-lived OIDC and exact workflow/environment scope |
| Build artifacts | Uploaded bytes may lack provenance | Exact promoted bytes carry attestations and SBOM metadata |
| Workflow consistency | EIPs/ERCs can drift through copied files | Versioned shared workflow plus manifest and compatibility tests |
| Merge enforcement | Checks may exist without being required | Protected branches require the documented security and validation checks |
| Recovery | Rollback behavior is implicit | Each migration phase has a defined rollback and retirement criterion |
