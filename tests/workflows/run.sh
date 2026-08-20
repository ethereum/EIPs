#!/usr/bin/env bash
#
# Tests the invariants established by the GitHub Actions audit.
#
# These are cheap, offline structural checks. They exist because every issue
# asserted below was a real defect found in this repository, and each would
# reappear silently under a careless edit or an automated dependency bump.
#
# Usage:
#   tests/workflows/run.sh
#   ACTIONLINT=/path/to/actionlint tests/workflows/run.sh
#
# Exits non-zero on the first failed assertion.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

workflow_dir=".github/workflows"
mapfile -t workflows < <(find "$workflow_dir" -maxdepth 1 -name '*.yml' | sort)
mapfile -t action_files < <(find .github/actions -name 'action.yml' | sort)

failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; failures=$((failures + 1)); }

echo "workflows found: ${#workflows[@]}"
echo

# --- 1. Every workflow is parseable YAML ------------------------------------
echo "yaml validity"
for f in "${workflows[@]}" "${action_files[@]}"; do
  if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" 2> /dev/null; then
    pass "$f parses"
  else
    fail "$f is not valid YA
echo

# --- 2. Third-party actions are pinned to a full SHA -------------------------
# A mutable ref (branch or tag) lets an upstream compromise reach our secrets.
# ethereum/eip-review-bot@dist was exactly this, and it receives a PAT.
echo "sha pinning"
if pin_out=$(python3 - <<'PY'
import pathlib, re, sys

pattern = re.compile(r"uses:\s*(\S+)")
bad = []
for path in sorted(pathlib.Path(".github").rglob("*.yml")):
    for lineno, line in enumerate(path.read_text().splitlines(), 1):
        # Strip trailing "# v1.2.3" version comments before inspecting the ref.
        line = line.split("#")[0]
        m = pattern.search(line)
        if not m:
            continue
        ref = m.group(1)
        if ref.startswith("./"):
            continue  # local actions are versioned with the repo
        _, _, version = ref.partition("@")
        if not re.fullmatch(r"[0-9a-f]{40}", version):
            bad.append(f"{path}:{lineno}: {ref}")

for entry in bad:
    print(entry)
sys.exit(1 if bad else 0)
PY
); then
  pass "all third-party actions are pinned to a full SHA"
else
  while read -r entry; do
    [ -n "$entry" ] && fail "not SHA-pinned: $entry"
  done <<< "$pin_out"
fi
echo

# --- 3. Every workflow declares permissions ---------------------------------
# Without an explicit block a job inherits the repository default token scope,
# which for a repo of this age is typically write-all.
echo "token permissions"
for f in "${workflows[@]}"; do
  if grep -qE '^permissions:' "$f"; then
    pass "$(basename "$f") declares permissions"
  else
    fail "$(basename "$f") has no top-level permissions block"
  fi
done
echo

# --- 4. No predictable heredoc delimiter feeding $GITHUB_ENV -----------------
# A PR author controls filenames. With a predictable delimiter, a file named
# after it closes the block early and injects arbitrary environment variables.
# Both spellings must be caught: a literal `NAME<<EOF`, and a delimiter variable
# assigned a constant.
echo "github_env injection"
injection=0
if grep -rnE '[A-Za-z_][A-Za-z0-9_]*<<[A-Za-z_"'"'"']' "$workflow_dir" | grep -q 'GITHUB_ENV\|echo'; then
  while read -r hit; do
    [ -z "$hit" ] && continue
    fail "literal heredoc delimiter: $hit"
    injection=$((injection + 1))
  done < <(grep -rnE '[A-Za-z_][A-Za-z0-9_]*<<[A-Za-z_"'"'"']' "$workflow_dir" || true)
fi
while read -r hit; do
  [ -z "$hit" ] && continue
  if ! echo "$hit" | grep -qE 'rand|RANDOM|uuidgen|date \+%s%N'; then
    fail "delimiter is not randomized: $hit"
    injection=$((injection + 1))
  fi
done < <(grep -rnE '^\s*[A-Za-z_]*delimiter=' "$workflow_dir" || true)
[ "$injection" -eq 0 ] && pass "every \$GITHUB_ENV heredoc delimiter is randomized"
echo

# --- 5. workflow_run consumers tolerate a missing artifact -------------------
# The trigger workflow legitimately skips its upload, and ci.yml sets
# cancel-in-progress. A consumer defaulting to if_no_artifact_found: fail then
# errors with "no artifacts found" on unrelated events.
echo "artifact download safety"
while read -r f; do
  [ -z "$f" ] && continue
  if grep -q 'if_no_artifact_found:[[:space:]]*ignore' "$f"; then
    pass "$(basename "$f") tolerates a missing artifact"
  else
    fail "$(basename "$f") downloads an artifact without if_no_artifact_found: ignore"
  fi
  # Reading artifacts from the triggering run goes through the Actions API. A
  # workflow that declares permissions but omits actions: read gets a 403 that
  # if_no_artifact_found: ignore then silently swallows.
  if grep -q '^permissions:' "$f" && ! grep -q '^[[:space:]]*actions:[[:space:]]*read' "$f"; then
    fail "$(basename "$f") downloads a cross-run artifact without actions: read"
  else
    pass "$(basename "$f") grants actions: read for the cross-run download"
  fi
done < <(grep -rl 'action-download-artifact' "$workflow_dir" || true)
echo

# --- 5b. A skipped check must mean "nothing to check" ------------------------
# Gating a check on `steps.<id>.outcome` of a continue-on-error discovery step
# conflates "no relevant files changed" with "gh pr diff failed", so a transient
# API error silently disables the check while CI still reports success.
echo "quality gates fail loudly"
if grep -q 'steps\.[a-z_-]*\.outcome' "$workflow_dir/ci.yml"; then
  fail "ci.yml gates a check on a step outcome instead of an explicit output"
else
  pass "ci.yml gates checks on explicit outputs, not step outcome"
fi
if grep -q 'continue-on-error' "$workflow_dir/ci.yml"; then
  fail "ci.yml uses continue-on-error, which can mask a failed check"
else
  pass "ci.yml has no continue-on-error"
fi
echo

# --- 6. No action declares a removed Node runtime ----------------------------
# node12 and node16 are past end of life; GitHub force-runs them on Node 24.
echo "local action runtimes"
for f in "${action_files[@]}"; do
  runtime="$(grep -oE "using:[[:space:]]*['\"]?node[0-9]+" "$f" | grep -oE 'node[0-9]+' || true)"
  if [ -z "$runtime" ]; then
    pass "$(basename "$(dirname "$f")") is not a JavaScript action"
  elif [ "$runtime" = "node24" ]; then
    pass "$(basename "$(dirname "$f")") uses $runtime"
  else
    fail "$(basename "$(dirname "$f")") uses $runtime"
  fi
done
echo

# --- 7. Link checker config is wired up consistently -------------------------
echo "link checker wiring"
if [ -f config/lychee.toml ]; then
  pass "config/lychee.toml exists"
else
  fail "config/lychee.toml is missing"
fi
if [ -f config/mlc_config.json ]; then
  fail "config/mlc_config.json still exists but nothing consumes it"
else
  pass "obsolete config/mlc_config.json is gone"
fi
if grep -q 'tests/link-check/' "$workflow_dir/ci.yml" \
  || grep -q "grep -v '\^tests/'" "$workflow_dir/ci.yml"; then
  pass "link check job excludes tests/ fixtures"
else
  fail "link check job does not exclude tests/, whose fixtures are broken by design"
fi
if grep -qE '^\s+- tests$' _config.yml; then
  pass "jekyll excludes tests/ from the site build"
else
  fail "jekyll does not exclude tests/ from the site build"
fi
echo

# --- 8. actionlint ------------------------------------------------------------
echo "actionlint"
actionlint_bin="${ACTIONLINT:-actionlint}"
if command -v "$actionlint_bin" > /dev/null 2>&1; then
  if actionlint_out=$("$actionlint_bin" 2>&1); then
    pass "actionlint reports no issues"
  else
    fail "actionlint reported issues"
    printf '%s\n' "$actionlint_out" | sed 's/^/       /'
  fi
else
  printf '  skip actionlint not installed (set ACTIONLINT=/path/to/actionlint)\n'
fi
echo

# --- Summary -----------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "all workflow tests passed"
else
  echo "$failures assertion(s) failed"
  exit 1
fi
