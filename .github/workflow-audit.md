# GitHub Actions Workflow Audit

**Date:** 2026-08-17
**Branch:** `ci/actions-node24`
**Scope:** all 8 workflows in `.github/workflows/` plus the local composite action `.github/actions/merge-repos`

Context: GitHub is deprecating the Node 20 actions runtime. Workflows now emit
`Node 20 is being deprecated. This workflow is running with Node 24 by default.`
Actions declaring `node12`, `node16` or `node20` are all force-executed on Node 24,
so any of them can break without warning.

---

## 1. Changes applied

All recommendations below have been implemented. Summary of the diff:

| File | Change |
| --- | --- |
| `auto-review-bot.yml` | download-artifact → v23; pinned `eip-review-bot@dist` to a SHA; added `permissions` |
| `auto-review-trigger.yml` | upload-artifact → v7.0.1; added `permissions` |
| `auto-stagnate-bot.yml` | checkout → v7.0.1; setup-node → v7.0.0; `node-version` 14 → 20; added `permissions` |
| `ci.yml` | unified checkout → v7.0.1 (×5); upload-artifact → v7.0.1; setup-ruby → v1.321.0; markdownlint-cli2 → v24.2.0; added `permissions`; hardened both heredocs; removed duplicate Jekyll build |
| `jekyll-label-bot.yml` | added `permissions` |
| `jekyll.yml` | checkout → v7.0.1; setup-ruby → v1.321.0; SHA-pinned + bumped the three Pages actions |
| `post-ci.yml` | download-artifact → v23 + `if_no_artifact_found: ignore` + gating; replaced both `node12` label actions with `gh` CLI; sticky-comment → v3.0.5; added `permissions` and `concurrency` |
| `stale.yml` | actions/stale → v11.0.0 |
| `actions/merge-repos/action.yml` | checkout → v7.0.1 |

Every workflow file re-validated as parseable YAML after the changes.

### Root cause of the original failure

`dawidd6/action-download-artifact` was pinned to `246dbf43…` = **v2.27.0 (2023-04-14, `using: node16`)**.
It is now `57aa996fc1713cc1579039614f4645a7f4841fd4` = **v23 (`using: node24`)**.

Besides the runtime fix, v23 also sets the `found_artifact` output to `false` on the
not-found path. v2.27.0 returned early without setting it, so `if_no_artifact_found: ignore`
left the output empty rather than `false`.

---

## 2. Runtime inventory

Every action pinned across the repository, with the JS runtime it declares, before and
after this audit.

### Resolved: `node12` (runtime fully removed)

| Action | Old pin (date) | Resolution |
| --- | --- | --- |
| `marocchino/sticky-pull-request-comment` | `39c5b5d` (2021-10-20) | → `5770ad5` v3.0.5 (`node24`) |
| `actions-ecosystem/action-add-labels` | `288072f` (2021-10-09) | replaced with `gh pr edit --add-label` |
| `actions-ecosystem/action-remove-labels` | `d051625` (2022-09-16) | replaced with `gh pr edit --remove-label` |

The `actions-ecosystem/*` pair has no `node24` release upstream, so bumping was not an
option; both were replaced with `gh` CLI steps using the job's `github.token`.

### Resolved: `node16`

| Action | Old pin (date) | Resolution |
| --- | --- | --- |
| `actions/checkout` (v3.5.2) | `47fbe2d` (2023-04-14) | → `3d3c42e` v7.0.1 (`node24`) |
| `actions/setup-node` | `d98fa11` (2023-04-11) | → `8207627` v7.0.0 (`node24`) |
| `actions/stale` | `03af7c3` (2023-04-12) | → `4391f3d` v11.0.0 (`node24`) |
| `DavidAnson/markdownlint-cli2-action` | `f5cf187` (2023-04-10) | → `21c1be1` v24.2.0 (`node24`) |
| `dawidd6/action-download-artifact` (v2.27.0) | `246dbf4` (2023-04-14) | → `57aa996` v23 (`node24`) |

### Resolved: `node20`

| Action | Old pin (date) | Resolution |
| --- | --- | --- |
| `actions/checkout` (v4.2.2) | `11bd719` (2024-10-23) | → `3d3c42e` v7.0.1 (`node24`) |
| `actions/upload-artifact` (v4.6.0) | `65c4c4a` (2025-01-09) | → `043fb46` v7.0.1 (`node24`) |
| `ruby/setup-ruby` (v1.232.0 / v1.196.0) | `fb404b9` / `f269373` | → `95ef2b0` v1.321.0 (`node24`), unified |
| `actions/configure-pages` | `@v5` (floating) | → `45bfe01` v6.0.0 (`node24`) |
| `actions/deploy-pages` | `@v4` (floating) | → `cd2ce8f` v5.0.0 (`node24`) |
| `actions/upload-pages-artifact` | `@v3` (floating) | → `fc324d3` v5.0.0 (composite) |

### Remaining (third-party, no newer release available)

| Action | Runtime | Note |
| --- | --- | --- |
| `Pandapip1/jekyll-label-action` | `node16` | latest tag is v0.0.4; pin left as-is |
| `ethereum/eipw-action` | `node20` | pinned 2026-07; needs an upstream node24 build |
| `gaurav-nelson/github-action-markdown-link-check` | `docker` | upstream repo is **archived** |
| `codespell-project/actions-codespell` | `docker` | fine |
| `ethereum/EIP-Bot` | `composite` | runs `yarn install && yarn build` under the job's Node |

Migration caveats accepted:

- `upload-artifact` v4 → v7 and `checkout` v3/v4 → v7 are major bumps. v4+ artifacts are
  immutable, so a re-run that re-uploads the same artifact name now fails instead of
  overwriting.
- `ruby-version` moved `'3.1'` (EOL) → `'3.3'`. See §5 for why 3.4 is not viable.
- `auto-stagnate-bot.yml` now requests Node 20 instead of Node 14 for the `EIP-Bot`
  composite build; that build has not been exercised against a modern Node.

---

## 3. Non-runtime findings

### 3.1 Node 14 requested on a Node-14-EOL runner — `auto-stagnate-bot.yml` — RESOLVED

`node-version` was pinned to `'14'`. Node 14 went EOL in April 2023 and is no longer in
the `ubuntu-latest` (24.04) tool cache, so `setup-node` had to download it from the Node
dist archive on every run. Now `'20'`, with `setup-node` on v7.0.0.

### 3.2 `post-ci.yml` had the same artifact bug as `auto-review-bot.yml` — RESOLVED

It downloaded `pr_number` with the default `if_no_artifact_found: fail` and no
`found_artifact` gate. `ci.yml` sets `cancel-in-progress: true`, so a rapid second push
cancels the `save-pr` job while the `workflow_run` event still fires — producing the
identical `Error: no artifacts found`.

Now gated on `found_artifact == 'true'`, with the `Save PR Data` step checking that all
three files are non-empty and that `pr_number` is numeric before emitting outputs. Each
downstream step additionally requires `pr_number != ''`, so a partial artifact degrades to
a warning instead of passing empty values to the label steps.

### 3.3 Unpinned mutable ref carrying a PAT — RESOLVED

`auto-review-bot.yml` used `ethereum/eip-review-bot@dist`. `dist` is a branch, not a tag or
SHA, and that step receives `secrets.TOKEN` (a write-scoped PAT — the default
`GITHUB_TOKEN` would not be stored as a secret). Anyone able to push to that branch could
obtain the PAT. Now pinned to `bbc63d4bd02da30703f166f15283ae2eed05916b`.

Note: that action itself still declares `using: node16` upstream; pinning fixes the supply
chain exposure but the runtime warning persists until upstream rebuilds.

### 3.4 No `permissions:` blocks — RESOLVED

Only `jekyll.yml` and `stale.yml` declared `permissions:`; the other six inherited the
repository default token scope. Least-privilege blocks added:

| Workflow | Permissions |
| --- | --- |
| `ci.yml` | `contents: read`, `pull-requests: read` (needs `gh pr diff`) |
| `post-ci.yml` | `contents: read`, `pull-requests: write` (comments + labels) |
| `jekyll-label-bot.yml` | `contents: read`, `pull-requests: write` |
| `auto-review-bot.yml`, `auto-review-trigger.yml`, `auto-stagnate-bot.yml` | `contents: read` |

### 3.5 Heredoc injection surface in `ci.yml` — RESOLVED

The `codespell` and `markdownlint` jobs built `$GITHUB_ENV` entries with a fixed `EOF`
heredoc delimiter fed from `gh pr diff --name-only`. A PR adding a file named exactly `EOF`
would close the block early and inject arbitrary environment variables into the job. Both
steps now use a random delimiter (`EOF_$(openssl rand -hex 16)`) and pass the PR number
via `env:` rather than interpolating `${{ }}` directly into shell.

### 3.6 Archived dependency — OPEN

`gaurav-nelson/github-action-markdown-link-check` is archived (read-only) upstream. It is
SHA-pinned so it will not change, but it will never be fixed. Evaluated and deferred —
see §4.2.

### 3.7 Consistency nits — RESOLVED

- `ci.yml` used **two different `checkout` pins** in one file (v4.2.2 at `htmlproofer`,
  v3.5.2 elsewhere). All five call sites plus `merge-repos` now use one v7.0.1 pin.
- `ruby/setup-ruby` was split across v1.232.0 (`ci.yml`) and v1.196.0 (`jekyll.yml`); both
  now on v1.321.0.
- `jekyll.yml` used floating major tags for the three Pages actions; all now SHA-pinned,
  matching the rest of the repo.
- The `htmlproofer` job built Jekyll twice (`Build with Jekyll` ran `jekyll build`, then
  `Build Website` ran `jekyll doctor` + `jekyll build` again). Collapsed into one step that
  keeps `JEKYLL_ENV: production`.
- `post-ci.yml` had no `concurrency` group, so rapid pushes could race two comment and
  label updates. Now grouped on `github.event.workflow_run.id`.

---

## 4. Follow-ups

### 4.1 Third-party actions still on old runtimes — BLOCKED UPSTREAM

Checked every branch of each repo; none publishes a `node24` build, so these cannot be
fixed from this repository:

| Action | Runtime | Branches checked |
| --- | --- | --- |
| `ethereum/eipw-action` | `node20` | `master`, `dist`, `develop` |
| `ethereum/eip-review-bot` | `node16` | `main`, `dist`, `eips-wg-dist` |
| `Pandapip1/jekyll-label-action` | `node16` | `main`, `dist` |

These need upstream releases. `eip-review-bot` is at least SHA-pinned now (§3.3).

### 4.2 Archived link checker — NOT SWAPPED, DELIBERATELY

`gaurav-nelson/github-action-markdown-link-check` is archived but functional and
SHA-pinned. A replacement was evaluated (`lychee` 0.24.2, run locally against the real
corpus) and **not** adopted, because a drop-in swap is flaky:

- `EIPS/eip-1.md`: 49 links, 0 errors — clean.
- First 12 EIPs: 3 errors + 1 timeout, all false positives — `medium.com` returns `403`
  to datacenter IPs, and `pdaian.com` timed out.

Adopting it therefore requires an exclusion list and retry/timeout tuning first. Shipping
it untuned would fail CI on unrelated PRs. Candidates remain `lycheeverse/lychee-action`
(`e747777` v2.9.0) and `umbrelladocs/action-linkspector` (`568ec8d` v1.5.5).

### 4.3 Watch the first run after merge

`checkout` v3→v7 and `upload-artifact` v4→v7 are major bumps, and the `EIP-Bot` composite
has not previously run under Node 20.

---

## 5. Ruby version: why 3.3, not 3.4

`ruby-version` was `'3.1'`, EOL since March 2025. Testing against the repo's actual
`Gemfile.lock` on Ruby 3.4.7:

```
bundle install                  # succeeds, nokogiri 1.14.3 builds fine
bundle exec jekyll build        # LoadError: cannot load such file -- csv
```

Ruby 3.4 moved a set of stdlib libraries from default gems to bundled gems. Working
through them one at a time, jekyll 3.9.3 (via `github-pages 228`) needs all of:

```
csv  base64  bigdecimal  logger  ostruct  mutex_m  drb  abbrev
```

Adding those eight to the `Gemfile` does make Ruby 3.4 work (verified: `jekyll 3.9.3 OK on
ruby 3.4.7`), but it diverges the `Gemfile` from the `github-pages` gem set that GitHub
Pages itself runs, and affects every contributor's local setup.

All eight are still *default* gems in Ruby 3.3, so `'3.3'` needs no `Gemfile` change and is
supported until March 2027. That is the change applied. Moving to 3.4+ later means adding
those gems, or upgrading off `github-pages 228` / jekyll 3.9.
