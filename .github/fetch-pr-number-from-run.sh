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

if gh run download "$RUN_ID" --repo "$REPO" -n pr-number -D "$TMP_DIR" >/dev/null 2>&1; then
  if [[ -f "$TMP_DIR/pr-number.txt" ]]; then
    tr -d '\n' < "$TMP_DIR/pr-number.txt"
    echo
    exit 0
  fi

  echo "error: artifact downloaded but pr-number.txt is missing" >&2
  exit 1
fi

echo "error: pr-number artifact not found for run $RUN_ID in $REPO" >&2
echo "hint: ensure auto-review-trigger uploaded artifact name 'pr-number'" >&2
exit 1
