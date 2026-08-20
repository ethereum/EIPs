#!/usr/bin/env bash
#
# Tests the artifact-fetch resilience of auto-review-bot.yml and post-ci.yml.
#
# Both workflows consume a PR-number artifact that is legitimately absent for
# some trigger events. Before the fix, a missing artifact made the whole job
# fail (dawidd6/action-download-artifact defaults to if_no_artifact_found:
# fail). These tests pin the static shape of the fix so a future edit can't
# silently reintroduce a hard failure on a missing artifact.
#
# Usage:
#   tests/workflows/run.sh
#
# Exits non-zero on the first failed assertion.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workflows="$repo_root/.github/workflows"

failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; failures=$((failures + 1)); }

load_workflow() {
  ruby -ryaml -rjson -e '
    workflow = YAML.safe_load(File.read(ARGV[0]), aliases: true, permitted_classes: [Symbol])
    puts workflow.to_json
  ' "$1"
}

step_named() {
  # step_named <job.json> <name> -- prints the step object as JSON, or nothing
  ruby -rjson -e '
    job = JSON.parse(STDIN.read)
    step = (job["steps"] || []).find { |s| s["name"] == ARGV[0] }
    puts step.to_json if step
  ' "$2" <<< "$1"
}

job_json() {
  # job_json <workflow.json> <job-key> -- prints the job object as JSON
  ruby -rjson -e '
    workflow = JSON.parse(STDIN.read)
    puts workflow.fetch("jobs", {}).fetch(ARGV[0], {}).to_json
  ' "$2" <<< "$1"
}

echo "auto-review-bot.yml"
arb_json="$(load_workflow "$workflows/auto-review-bot.yml")"
arb_job="$(job_json "$arb_json" "auto-review-bot")"

if ruby -rjson -e 'exit(JSON.parse(STDIN.read).dig("permissions", "actions") == "read" ? 0 : 1)' <<< "$arb_job"; then
  pass "auto-review-bot job requests actions:read permission"
else
  fail "auto-review-bot job is missing actions:read permission"
fi

fetch_step="$(step_named "$arb_job" "Fetch PR Number")"
if [[ -n "$fetch_step" ]] && grep -q 'exit 0' <<< "$fetch_step"; then
  pass "Fetch PR Number exits 0 when the artifact is absent"
else
  fail "Fetch PR Number does not exit 0 on a missing artifact"
fi

if [[ -n "$fetch_step" ]] && grep -q '"continue-on-error":true' <<< "$fetch_step"; then
  pass "Fetch PR Number does not fail the job on a gh api error"
else
  fail "Fetch PR Number can still fail the job on a gh api error (missing continue-on-error)"
fi

bot_step="$(step_named "$arb_job" "Auto Review Bot")"
if [[ -n "$bot_step" ]] && grep -q "check-pr-number.outputs.exists == 'true'" <<< "$bot_step"; then
  pass "Auto Review Bot step is gated on the PR number actually being found"
else
  fail "Auto Review Bot step is not gated on artifact presence"
fi
echo

echo "post-ci.yml"
post_json="$(load_workflow "$workflows/post-ci.yml")"
post_job="$(job_json "$post_json" "on-failure")"

if ruby -rjson -e '
    perms = JSON.parse(STDIN.read).fetch("permissions", {})
    required = {"actions" => "read", "contents" => "read", "issues" => "write", "pull-requests" => "write"}
    exit(required.all? { |k, v| perms[k] == v } ? 0 : 1)
  ' <<< "$post_job"; then
  pass "on-failure job requests the permissions needed for cross-run artifact downloads"
else
  fail "on-failure job is missing a required permission"
fi

fetch_step="$(step_named "$post_job" "Fetch PR Data")"
if [[ -n "$fetch_step" ]] \
  && grep -q 'actions/download-artifact' <<< "$fetch_step" \
  && ! grep -q 'dawidd6/action-download-artifact' <<< "$fetch_step" \
  && grep -q '"continue-on-error":true' <<< "$fetch_step"; then
  pass "Fetch PR Data uses actions/download-artifact with continue-on-error"
else
  fail "Fetch PR Data does not use a non-failing artifact download"
fi

for step_name in "Add Comment" "Add Waiting Label" "Remove Waiting Label"; do
  step="$(step_named "$post_job" "$step_name")"
  if [[ -n "$step" ]] && grep -q "fetch-pr-data.outcome == 'success'" <<< "$step"; then
    pass "$step_name is gated on the artifact fetch having succeeded"
  else
    fail "$step_name is not gated on the artifact fetch having succeeded"
  fi
done
echo

# --- Summary -----------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "all workflow tests passed"
else
  echo "$failures assertion(s) failed"
  exit 1
fi
