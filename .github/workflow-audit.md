# GitHub Actions Workflow Audit

**Date:** 2026-08-17
**Branch:** `ci/actions-node24`
**Scope:** all 8 workflows in `.github/workflows/` plus the local composite action `.github/actions/merge-repos`

Context: GitHub is deprecating the Node 20 actions runtime. Workflows now emit
`Node 20 is being deprecated. This workflow is running with Node 24 by default.`
Actions declaring `node12`, `node16` or `node20` are all force-executed on Node 24,
so any of them can break without warning.

---

## 1. Change applied in this audit

`dawidd6/action-download-artifact` was pinned to `246dbf43…` = **v2.27.0 (2023-04-14, `using: node16`)**.
It is now pinned to `57aa996fc1713cc1579039614f4645a7f4841fd4` = **v23 (`using: node24`)** in both consumers:

- `.github/workflows/auto-review-bot.yml`
- `.github/workflows/post-ci.yml`

Besides the runtime fix, v23 also sets the `found_artifact` output to `false` on the
not-found path. v2.27.0 returned early without setting it, so `if_no_artifact_found: ignore`
left the output empty rather than `false`.

---

## 2. Runtime inventory

Every action pinned across the repository, with the JS runtime it declares.

### Blocking — `node12` (runtime fully removed)

| Action | Pin | Pin date | Used by |
| --- | --- | --- | --- |
| `marocchino/sticky-pull-request-comment` | `39c5b5d` | 2021-10-20 | `post-ci.yml` |
| `actions-ecosystem/action-add-labels` | `288072f` | 2021-10-09 | `post-ci.yml` |
| `actions-ecosystem/action-remove-labels` | `d051625` | 2022-09-16 | `post-ci.yml` |

All three are >3 years behind their own upstream releases.

### High — `node16`

| Action | Pin | Pin date | Used by |
| --- | --- | --- | --- |
| `actions/checkout` (v3.5.2) | `47fbe2d` | 2023-04-14 | `ci.yml` (×3), `auto-stagnate-bot.yml` |
| `actions/setup-node` | `d98fa11` | 2023-04-11 | `auto-stagnate-bot.yml` |
| `actions/stale` | `03af7c3` | 2023-04-12 | `stale.yml` |
| `DavidAnson/markdownlint-cli2-action` | `f5cf187` | 2023-04-10 | `ci.yml` |
| `Pandapip1/jekyll-label-action` | `4b7cce7` | 2024-07-09 | `jekyll-label-bot.yml` |

### Medium — `node20`

| Action | Pin | Pin date | Used by |
| --- | --- | --- | --- |
| `actions/checkout` (v4.2.2) | `11bd719` | 2024-10-23 | `ci.yml`, `jekyll.yml`, `merge-repos` |
| `actions/upload-artifact` (v4.6.0) | `65c4c4a` | 2025-01-09 | `ci.yml`, `auto-review-trigger.yml` |
| `ruby/setup-ruby` (v1.232.0) | `fb404b9` | 2025-04-16 | `ci.yml` |
| `ruby/setup-ruby` (v1.196.0) | `f269373` | 2024-10-07 | `jekyll.yml` |
| `ethereum/eipw-action` | `b858a0f` | 2026-07-10 | `ci.yml` |
| `actions/configure-pages` | `@v5` (floating) | — | `jekyll.yml` |
| `actions/deploy-pages` | `@v4` (floating) | — | `jekyll.yml` |

### Not runtime-affected

| Action | Type | Note |
| --- | --- | --- |
| `dawidd6/action-download-artifact` | `node24` | fixed in this audit |
| `gaurav-nelson/github-action-markdown-link-check` | `docker` | upstream repo is **archived** |
| `codespell-project/actions-codespell` | `docker` | fine |
| `ethereum/EIP-Bot` | `composite` | runs `yarn install && yarn build` under the job's Node |
| `actions/upload-pages-artifact` | `composite` | fine |
| `.github/actions/merge-repos` | `composite` | wraps `checkout` v4.2.2 |

### Upgrade targets (all `node24`, latest releases as of audit date)

```text
actions/checkout                        3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
actions/upload-artifact                 043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
actions/setup-node                      820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
actions/stale                           4391f3da665fdf50b6810c1a66712fb9ba21aa93 # v11.0.0
DavidAnson/markdownlint-cli2-action     21c1be1b93ad9ed58fa840aacc3f279cde2a72ff # v24.2.0
marocchino/sticky-pull-request-comment  5770ad5eb8f42dd2c4f34da00c94c5381e49af88 # v3.0.5
dawidd6/action-download-artifact        57aa996fc1713cc1579039614f4645a7f4841fd4 # v23  (applied)
```

Migration caveats:

- `upload-artifact` v4 → v7 and `checkout` v3 → v7 are major bumps. v4+ artifacts are
  immutable, so a re-run that re-uploads the same artifact name now fails instead of
  overwriting.
- `actions-ecosystem/*` have no `node24` release; they need replacing (e.g. an inline
  `gh issue edit --add-label` / `--remove-label` step) rather than bumping.

---

## 3. Non-runtime findings

### 3.1 Node 14 requested on a Node-14-EOL runner — `auto-stagnate-bot.yml`

`.github/workflows/auto-stagnate-bot.yml` pins `node-version: '14'`. Node 14 went EOL in
April 2023 and is no longer in the `ubuntu-latest` (24.04) tool cache, so `setup-node`
must download it from the Node dist archive on every run. Combined with the `node16`
`setup-node` pin, this job is the most fragile in the repo.

### 3.2 `post-ci.yml` has the same artifact bug that was just fixed in `auto-review-bot.yml`

`.github/workflows/post-ci.yml` downloads `pr_number` with the default
`if_no_artifact_found: fail` and no `found_artifact` gate. `ci.yml` sets
`cancel-in-progress: true`, so a rapid second push cancels the `save-pr` job while the
`workflow_run` event still fires — producing the identical `Error: no artifacts found`.

The following `Save PR Data` step then `cat`s three files with no existence check, so a
partial artifact yields empty outputs that are passed straight to the label actions as
`number:`.

### 3.3 Unpinned mutable ref carrying a PAT

`.github/workflows/auto-review-bot.yml` uses `ethereum/eip-review-bot@dist`. `dist` is a
branch, not a tag or SHA. That step receives `secrets.TOKEN` (a write-scoped PAT — the
default `GITHUB_TOKEN` would not be stored as a secret). Anyone who can push to that
branch obtains the PAT. Every other action in the repository is SHA-pinned; this is the
single exception.

### 3.4 No `permissions:` blocks

None of the 8 workflows declare `permissions:`, so every job inherits the repository
default token scope. `ci.yml` runs on `pull_request` and executes `bundle install` against
a PR-controlled `Gemfile.lock` plus `jekyll build` over PR-authored content. Adding
`permissions: contents: read` at the top of `ci.yml` and `jekyll.yml` is low-risk
hardening.

### 3.5 Heredoc injection surface in `ci.yml`

`ci.yml` builds `$GITHUB_ENV` entries with a fixed `EOF` heredoc delimiter fed from
`gh pr diff --name-only` (the `codespell` and `markdownlint` jobs). A PR that adds a file
whose name is exactly `EOF` closes the block early and lets the author inject arbitrary
environment variables into the job. Use `$GITHUB_OUTPUT` with a random delimiter, or write
the list to a file instead.

### 3.6 Archived dependency

`gaurav-nelson/github-action-markdown-link-check` is archived (read-only) upstream. It is
SHA-pinned so it will not change, but it will never be fixed. Candidate replacements:
`lycheeverse/lychee-action`, `umbrelladocs/action-linkspector`.

### 3.7 Consistency nits

- `ci.yml` uses **two different `checkout` pins** in one file: v4.2.2 at the `htmlproofer`
  job, v3.5.2 at `link-check` / `codespell` / `eipw-validator` / `markdownlint`.
- `ruby/setup-ruby` is split across versions: v1.232.0 in `ci.yml`, v1.196.0 in `jekyll.yml`.
- `jekyll.yml` uses floating major tags (`@v5`, `@v3`, `@v4`) for the Pages actions while
  every other action in the repo is SHA-pinned.
- The `htmlproofer` job builds Jekyll twice: `Build with Jekyll` runs `jekyll build`, then
  `Build Website` runs `jekyll doctor` + `jekyll build` again.
- `post-ci.yml` declares no `concurrency` group, so rapid pushes can race two comment and
  label updates against the same PR.

---

## 4. Recommended order of work

1. Add `if_no_artifact_found: ignore` + `found_artifact` gate to `post-ci.yml` (§3.2).
2. Replace the three `node12` actions in `post-ci.yml` (§2).
3. SHA-pin `ethereum/eip-review-bot@dist` (§3.3).
4. Bump the `node16` actions and fix `node-version: '14'` (§2, §3.1).
5. Unify the duplicate `checkout` / `setup-ruby` pins (§3.7).
6. Add `permissions:` blocks (§3.4) and fix the heredoc delimiters (§3.5).
