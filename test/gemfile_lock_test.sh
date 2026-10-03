#!/usr/bin/env bash
# Gemfile.lock must resolve as-is under the Ruby version CI uses.
#
# Regression: resolving the lockfile on a newer local Ruby bumped nokogiri to
# 1.19.4 (requires >= 3.2) and broke `bundle install` on CI's Ruby 3.1.

set -uo pipefail

cd "$(dirname "$0")/.."

status=0
fail() { echo "FAIL: $*" >&2; status=1; }

ci_ruby="$(grep -oP "ruby-version:\s*'\K[0-9.]+" .github/workflows/ci.yml | head -n 1)"
[[ -n "$ci_ruby" ]] || fail "could not determine the Ruby version used by ci.yml"

# nokogiri ships platform-specific precompiled gems. Collapsing them into a
# single source build forces native compilation on every CI run.
platform_specific="$(grep -cE '^    nokogiri \([0-9.]+-' Gemfile.lock)"
[[ "$platform_specific" -ge 2 ]] || fail "Gemfile.lock lost its platform-specific nokogiri entries (found $platform_specific, expected >= 2)"

if grep -qE '^    nokogiri \(1\.(1[5-9]|[2-9][0-9])' Gemfile.lock; then
  fail "Gemfile.lock pins a nokogiri release that requires Ruby >= 3.2, but CI runs Ruby ${ci_ruby:-unknown}"
fi

# `bundle lock` under BUNDLE_FROZEN verifies the lockfile satisfies the Gemfile
# without permitting re-resolution, so a stale or hand-edited lock is caught.
before="$(git hash-object Gemfile.lock)"
if ! BUNDLE_FROZEN=true bundle lock >/dev/null 2>&1; then
  fail "BUNDLE_FROZEN=true bundle lock failed; Gemfile.lock does not satisfy Gemfile"
fi
after="$(git hash-object Gemfile.lock)"
[[ "$before" == "$after" ]] || fail "Gemfile.lock is not in its resolved form; commit the result of 'BUNDLE_FROZEN=true bundle lock'"

[[ $status -eq 0 ]] && echo "ok: Gemfile.lock is frozen-consistent and compatible with Ruby $ci_ruby"
exit $status
