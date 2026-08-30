#!/usr/bin/env bash
#
# Tests config/lychee.toml, the link-checker configuration used by the
# "Link Check" job in .github/workflows/ci.yml.
#
# The exclusion list in that config suppresses hosts that return 403 to
# datacenter IPs. That is necessary to stop false positives failing CI, but an
# over-broad exclusion would silently stop real breakage being detected. These
# tests pin both directions: valid links (and excluded hosts) must pass, and
# genuinely broken links must still be reported.
#
# Usage:
#   tests/link-check/run.sh            # requires network access
#   LYCHEE=/path/to/lychee tests/link-check/run.sh
#
# Exits non-zero on the first failed assertion.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixtures="$repo_root/tests/link-check/fixtures"
config="$repo_root/config/lychee.toml"

lychee_bin="${LYCHEE:-lychee}"
if ! command -v "$lychee_bin" > /dev/null 2>&1; then
  echo "error: lychee not found. Install it, or set LYCHEE=/path/to/lychee." >&2
  echo "       https://github.com/lycheeverse/lychee#installation" >&2
  exit 127
fi

failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; failures=$((failures + 1)); }

run_lychee() {
  "$lychee_bin" --config "$config" --root-dir "$repo_root" --no-progress "$@" 2>&1
}

echo "lychee: $("$lychee_bin" --version)"
echo "config: $config"
echo

# --- 1. Config is valid ------------------------------------------------------
# lychee rejects unknown config keys, so this also catches typos and any key
# removed by a future lychee upgrade.
echo "config validity"
if run_lychee --offline "$fixtures/valid.md" > /dev/null 2>&1; then
  pass "config/lychee.toml is accepted by lychee"
else
  fail "config/lychee.toml was rejected by lychee"
  run_lychee --offline "$fixtures/valid.md" || true
fi
echo

# --- 2. Rate limiting is configured -----------------------------------------
# These keys are the reason CI stopped seeing throttling-induced failures.
# Losing them would not break any assertion below, so assert them directly.
echo "rate limiting"
for key in max_concurrency host_concurrency host_request_interval max_retries retry_wait_time timeout; do
  if grep -qE "^${key}[[:space:]]*=" "$config"; then
    pass "$key is set"
  else
    fail "$key is missing from config/lychee.toml"
  fi
done
if grep -qE '^\[hosts\."github\.com"\]' "$config"; then
  pass "per-host override for github.com is present"
else
  fail "per-host override for github.com is missing"
fi
echo

# --- 3. Valid and excluded links pass ---------------------------------------
echo "valid fixture (expect zero errors)"
if valid_out=$(run_lychee "$fixtures/valid.md"); then
  pass "valid.md reports no errors"
else
  fail "valid.md reported errors"
  printf '%s\n' "$valid_out" | sed 's/^/       /'
fi
echo

# --- 4. Broken links are still detected -------------------------------------
# Deliberately inverted: a zero exit here means the checker has gone blind.
echo "broken fixture (expect every link to fail)"
broken_out=$(run_lychee "$fixtures/broken.md" || true)
if printf '%s\n' "$broken_out" | grep -qE '🚫 [1-9]|[1-9][0-9]* Errors'; then
  pass "broken.md is reported as failing"
else
  fail "broken.md was NOT reported as failing - exclusions may be too broad"
  printf '%s\n' "$broken_out" | sed 's/^/       /'
fi

while read -r url; do
  [ -z "$url" ] && continue
  if printf '%s\n' "$broken_out" | grep -qF "$url"; then
    pass "detected: $url"
  else
    fail "not detected: $url"
  fi
done <<'URLS'
https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getbalance
https://github.com/ethereum/EIPs/this-path-does-not-exist-9f8e7d6c
https://nonexistent-host-8a7b6c5d4e3f.ethereum.org/
URLS
echo

# --- Summary -----------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "all link-check config tests passed"
else
  echo "$failures assertion(s) failed"
  exit 1
fi
