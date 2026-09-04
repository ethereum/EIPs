#!/usr/bin/env bash
# Run all regression tests. Pass --update to refresh generated baselines.

set -uo pipefail

cd "$(dirname "$0")/.."

status=0

run() {
  local label="$1"; shift
  echo "--- $label"
  if "$@"; then
    return 0
  fi
  status=1
}

run "workflow artifact handoff" ruby test/workflow_artifacts_test.rb
run "Gemfile.lock / CI Ruby compatibility" ./test/gemfile_lock_test.sh
run "markdownlint drift" ./test/markdownlint_drift_test.sh "$@"

echo
if (( status == 0 )); then
  echo "all tests passed"
else
  echo "some tests failed"
fi
exit $status
