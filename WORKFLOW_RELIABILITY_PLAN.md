# Workflow Reliability and Supply-Chain Plan

## Purpose

EIPs and ERCs share enough CI setup that copied workflow files can drift while still appearing individually healthy. The target property is reproducibility:

```text
same input revision + same workflow version => same validation outcome
```

This plan keeps repository-specific wrappers small and moves common validation into a versioned reusable workflow. The ERCs repository must adopt the caller side separately; this repository cannot make that change on its behalf.

## Current deployment audit

The current workflows do not configure AWS, Google Cloud, Azure, or another external cloud provider. The deployment target is GitHub Pages in `.github/workflows/jekyll.yml`. That workflow already uses GitHub Pages' native OIDC path through `id-token: write`, a protected `github-pages` environment, and `actions/deploy-pages`; it should remain separate from pull-request validation.

The repository does use long-lived GitHub credentials in `secrets.TOKEN` for the review and stagnation bots. Cloud OIDC cannot replace a GitHub API credential. Migrate those consumers to a GitHub App installation token with narrowly scoped repository permissions, or to a fine-grained token with an owner, expiry, and documented rotation procedure. Do not pass a broad personal access token to an action when the action only needs a small set of GitHub API operations.

The current artifact flow transfers PR metadata and the generated Pages site, but it does not produce a verifiable build attestation. The examples below address that gap without claiming that an external cloud provider is already configured.

## Shared workflow contract

Create a dedicated workflow repository or a maintained workflow in one canonical repository with a callable entry point:

```yaml
name: Shared standards validation

on:
  workflow_call:
    inputs:
      repository-kind:
        required: true
        type: string
      merge-external-repository:
        required: false
        default: false
        type: boolean
    secrets:
      github-token:
        required: true

jobs:
  validate:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      pull-requests: read
    steps:
      - name: Checkout source
        uses: actions/checkout@<full-commit-sha>
        with:
          persist-credentials: false
      # Shared setup, lint, validation, link, and fixture checks follow.
```

Each repository should retain only a wrapper that owns its triggers, path filters, repository-specific merge inputs, and secrets. The wrapper calls the shared workflow at the job level:

```yaml
jobs:
  shared-validation:
    uses: ethereum/ci-workflows/.github/workflows/standards-validation.yml@<full-commit-sha>
    with:
      repository-kind: eips
      merge-external-repository: true
    secrets: inherit
```

The shared workflow reference must be a full commit SHA. Updates should be tested on a dedicated branch and then through a canary caller before both repositories move to the new version. The contract should document supported runners, runtime/tool versions, required permissions, inputs, outputs, and failure semantics.

## Behavioral test contract

Static actionlint coverage is necessary but does not prove event behavior. Add fixture-driven tests for the shared workflow and retain one representative caller test in each repository:

- Trigger tests cover pull request, push, schedule, manual dispatch, and release events, including intended branch restrictions.
- Path-filter tests change representative EIP/ERC files, shared templates, configuration, documentation, and unrelated files, then verify which jobs run or skip.
- Failure-mode tests submit intentionally malformed EIP/ERC fixtures and assert a non-zero result with an actionable diagnostic.
- Cross-repository tests cover a clean ERC checkout, a conflicting file, a missing directory, and a merge failure.
- Matrix tests run one smoke case for every supported runtime, operating system, and tool-version combination.
- Concurrency tests verify that a newer commit cancels obsolete validation for the same change series.

The test harness should report counts by category and run the same fixture suite from both repositories. A CI failure should identify the event, fixture, expected result, and observed result.

## Supply-chain controls

The controls already present on this branch should remain continuously enforced:

- External actions use immutable full commit-SHA pins.
- Downloaded binaries are checksum-verified before execution; the release URL, version, platform, and expected digest are recorded in the wrapper.
- Workflow and job `GITHUB_TOKEN` permissions are explicit and scoped to the job that needs them.
- Checkout uses `persist-credentials: false` unless a later authenticated Git operation is intentional.
- Dependency-review runs on dependency-changing pull requests. Its vulnerability and license policy should be reviewed when the dependency manifests or policy changes.
- Maintain an explicit action allowlist. The security audit should fail for an external action not listed in that allowlist, with a documented exception process.
- Generate an SBOM for release packages or generated artifacts.
- Produce GitHub artifact attestations for built binaries, containers, or generated site assets when those artifacts become release inputs.
- Use Dependabot or Renovate to propose pinned action updates and keep the pin comment synchronized with the reviewed release.

Zizmor is a useful complementary follow-up: actionlint emphasizes workflow correctness, while a dedicated security linter can identify permission, trust-boundary, and action-pinning risks that are not syntax errors.

## OIDC and artifact provenance

### GitHub Pages deployment

This is the configuration currently appropriate for this repository. Keep the deployment job isolated and grant `id-token: write` only to the workflow that deploys Pages:

```yaml
permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
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

The Pages environment should require approval if the repository's protection policy treats production documentation as a controlled release. No cloud-provider trust policy is needed for this native Pages deployment.

### Future AWS deployment

If a future build publishes to AWS, use a dedicated deployment job and an IAM role trusted only for this repository, workflow, protected environment, and release branch. Replace the account and role placeholders during rollout and keep the action pinned:

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
      - name: Publish generated site
        run: aws s3 sync ./_site s3://<bucket-name> --delete
```

The IAM trust policy must constrain `token.actions.githubusercontent.com:sub` to the exact repository and protected environment, require the expected audience, and deny all other branches and workflows. The publishing role should have write access only to the target bucket and distribution invalidation it actually needs.

### Build attestation

For a generated site or release archive, attest the exact file that consumers will verify. The attestation action requires `id-token: write` and `attestations: write`; keep those permissions on the build job only:

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

For each release, publish the archive digest and attestation reference alongside the artifact. Consumers should verify both before deployment or redistribution. A Pages deployment can keep its native Pages artifact while also attesting a deterministic archive of the same `_site` contents; the packaging step must be reproducible and documented so the attested subject cannot diverge from the deployed files.

## Migration sequence

1. Inventory every secret, deployment job, artifact, and external action. Record whether each credential is a GitHub API credential, a cloud credential, or a build input. This audit found GitHub API secrets and native Pages OIDC, but no external cloud credentials.
2. Create or select the protected production environment and require reviewers for publishing jobs. Keep pull-request workflows unable to access it.
3. For a future cloud target, create a dedicated OIDC trust relationship and least-privilege role. Test it in a non-production environment with a canary branch, then constrain the trust subject to the final repository, workflow, environment, and branch.
4. Replace each cloud secret with the provider's pinned OIDC credential action. Confirm the job has `id-token: write` and no broader token permissions than required.
5. Replace `secrets.TOKEN` consumers with a GitHub App installation token or expiring fine-grained token. Rotate and revoke the old secret only after the bot workflows pass on scheduled, pull-request, and failure paths.
6. Package the exact build output, generate an attestation, upload it, and verify the attestation in a canary consumer job before enabling production publication.
7. Add attestation verification and SBOM checks to release promotion. A successful build alone is not proof that the promoted bytes came from the reviewed source.
8. Roll out the reusable workflow to EIPs first, then ERCs, using a pinned commit and a canary caller. Compare outcomes for the same input revision before removing copied logic.
9. Monitor failed OIDC exchanges, unexpected workflow subjects, denied role actions, missing attestations, and secret usage. Treat any fallback to a long-lived cloud secret as a deployment failure.

## Security posture comparison

| Area | Before this migration | After this migration | Risk mitigated |
| --- | --- | --- | --- |
| Cloud authentication | No external provider is configured; any future provider would need its own secret migration | Short-lived OIDC credentials, provider trust scoped to repository/workflow/environment/branch | Theft and reuse of long-lived cloud keys |
| GitHub bot authentication | `secrets.TOKEN` is long-lived and its scope is not encoded in the workflow | GitHub App or expiring fine-grained token with documented minimal permissions and rotation | Broad or stale GitHub API credentials |
| Deployment authority | Pages is isolated, but future publishing boundaries are not yet a shared contract | Validation has read-only access; protected deployment jobs alone receive publish authority | Pull requests publishing or modifying production assets |
| Build provenance | Artifacts can be uploaded without proof of how they were built | Exact deployment inputs carry verifiable GitHub attestations and SBOM metadata | Artifact substitution and unverifiable release bytes |
| Workflow consistency | EIPs and ERCs can drift through copied CI files | Both call one versioned reusable workflow and compare canary outcomes | Silent cross-repository validation divergence |
| Dependency and action integrity | SHA pins and dependency review are checked, but updates still require policy follow-through | Immutable pins, automated update proposals, dependency review, allowlist, and continuous audit | Compromised mutable actions and risky dependency updates |

## Security and deployment boundaries

Validation and publishing should remain separate workflows. Pull-request validation must not receive publish authority. For any future package, site, tag, or cloud deployment:

- Use OIDC federation and short-lived credentials instead of long-lived cloud secrets.
- Scope the cloud trust policy to this repository, workflow, branch or environment, and deployment job.
- Put production publishing behind a protected environment with required approvals.
- Keep repository defaults read-only and elevate permissions only on the publishing job.
- Restrict deployment triggers to trusted branches or release events.

## Measurable follow-ups

| Priority | Improvement | Owner | Acceptance criterion | Risk reduced |
| --- | --- | --- | --- | --- |
| P0 | Enforce actionlint in CI | CI maintainers | Every PR or push affecting workflow validation runs the pinned checksum-verified linter and blocks merge on failure | Invalid or unsafe workflow changes can merge unnoticed |
| P0 | Harden action references | CI maintainers | The security audit reports zero external `uses:` references without full 40-character commit SHAs, and every checkout explicitly handles credentials | Mutable action tags or leaked checkout credentials change CI behavior unexpectedly |
| P1 | Create shared CI workflow | EIPs and ERCs maintainers | Both repositories call one versioned reusable validation workflow through a canary rollout, with copied setup logic removed from wrappers | EIPs and ERCs produce different results because their workflows drift |
| P1 | Add workflow fixtures | CI maintainers | Trigger, path, failure-mode, cross-repository, matrix, and concurrency fixtures pass from both repositories with category counts in CI output | Event-specific regressions and merge failures remain untested |
| P2 | Add dependency review | Security maintainers | Dependency-changing pull requests run dependency review with an agreed vulnerability and license policy | Risky dependency changes enter unnoticed |
| P2 | Publish provenance | Release maintainers | Release artifacts include an SBOM and verifiable GitHub build attestation | Consumers cannot verify what source and workflow produced an artifact |

The first two P0 items are implemented by the workflow-security checks on this branch. The P1 and P2 items require coordination with the ERCs repository and release owners.

## Rollout checklist

The repository now provides `./scripts/verify` as the single local and CI entry point. It runs checksum-verified actionlint, the workflow security audit, artifact-handoff regression tests, the shared-file manifest check, and `git diff --check`. The CI workflow invokes this same command.

Before merging the next phase, repository administrators should:

1. Mark the `Workflow Checks`, `Actionlint`, `Workflow Security Audit`, and core EIP validation jobs as required status checks on protected branches. The required-check configuration is a GitHub repository setting and is not encoded by a workflow file.
2. Add valid and intentionally invalid EIP/ERC fixtures, including expected diagnostics, and run them from both repositories.
3. Run `ERCs_ROOT=/path/to/ERCs ./scripts/verify` in a coordinated integration workspace and require the manifest comparison to pass.
4. Publish the shared workflow from a dedicated repository or canonical branch, pin it by commit SHA, and canary the EIPs caller before updating ERCs.
5. Add a migration adapter for the existing ERC checkout/merge action and retire it only when both repositories consume shared workflow version 2.
6. Enable secret scanning and push protection in repository settings, and add a pre-commit scanner once the repository's approved secret-scanning tool is selected.
7. Keep the weekly scheduled health check enabled so runner images, remote dependencies, action releases, and external merge inputs are exercised without a source change.

The intended final policy is: workflow changes require the security and actionlint jobs; content changes require the relevant validation jobs; publishing requires a protected environment and independently verified artifact provenance.
