#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required" >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <run-id> [owner/repo]" >&2
  echo "example: $0 30730905214 ethereum/EIPs" >&2
  exit 1
fi

RUN_ID="$1"
REPO="${2:-ethereum/EIPs}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for artifact_name in pr-number pr_number; do
  if ! gh run download "$RUN_ID" --repo "$REPO" -n "$artifact_name" -D "$TMP_DIR" >/dev/null 2>&1; then
    continue
  fi

  pr_number_file="$(find "$TMP_DIR" -type f \( -name 'pr-number.txt' -o -name 'pr_number.txt' \) -print -quit)"
  if [[ -n "$pr_number_file" ]]; then
    tr -d '\n' < "$pr_number_file"
    echo
    exit 0
  fi

  echo "error: artifact downloaded but pr-number.txt is missing" >&2
  exit 1
done

echo "error: pr-number artifact not found for run $RUN_ID in $REPO" >&2
echo "hint: ensure auto-review-trigger uploaded artifact name 'pr-number' or 'pr_number'" >&2
exit 1
