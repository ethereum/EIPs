#!/usr/bin/env bash
# Markdownlint drift ratchet.
#
# The Markdown Linter CI job only lints files changed in a PR, so violations in
# untouched EIPs accumulate silently. A full gate is not possible (master has
# thousands of pre-existing violations), so this compares per-file, per-rule
# counts against a checked-in baseline and fails only on new or worsened ones.
#
# Run with --update to regenerate the baseline after intentionally fixing files.

set -uo pipefail

cd "$(dirname "$0")/.."

BASELINE="test/markdownlint-baseline.txt"
current="$(mktemp)"
trap 'rm -f "$current"' EXIT

npx --yes markdownlint-cli2 --config config/.markdownlint.yaml "EIPS/*.md" 2>&1 \
  | grep -oE '^EIPS/eip-[0-9]+\.md:[0-9]+ [a-z]+ (MD[0-9]+)' \
  | sed -E 's|^(EIPS/[^:]+):[0-9]+ [a-z]+ (MD[0-9]+)$|\1 \2|' \
  | sort | uniq -c | awk '{print $2, $3, $1}' | sort > "$current"

if [[ "${1:-}" == "--update" ]]; then
  cp "$current" "$BASELINE"
  echo "updated $BASELINE ($(wc -l < "$BASELINE") entries)"
  exit 0
fi

if [[ ! -f "$BASELINE" ]]; then
  echo "FAIL: $BASELINE is missing; run '$0 --update' to create it" >&2
  exit 1
fi

status=0

# Report any (file, rule) pair whose count grew, or that is entirely new.
while read -r file rule count; do
  baseline_count="$(awk -v f="$file" -v r="$rule" '$1 == f && $2 == r {print $3}' "$BASELINE")"
  baseline_count="${baseline_count:-0}"
  if (( count > baseline_count )); then
    echo "FAIL: $file has $count $rule violation(s), baseline allows $baseline_count" >&2
    status=1
  fi
done < "$current"

if (( status == 0 )); then
  fixed="$(comm -13 <(cut -d' ' -f1,2 "$current" | sort) <(cut -d' ' -f1,2 "$BASELINE" | sort) | wc -l)"
  echo "ok: no new markdownlint violations ($(wc -l < "$current") tracked, $fixed baseline entr(y/ies) now clean)"
  (( fixed > 0 )) && echo "note: run '$0 --update' to tighten the baseline"
fi

exit $status
