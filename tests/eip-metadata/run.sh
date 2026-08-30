#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="$repo_root/tests/eip-metadata/check.py"
fixtures="$repo_root/tests/eip-metadata/fixtures"

python3 "$checker" --strict "$fixtures/valid.md"
if python3 "$checker" --strict "$fixtures/invalid.md"; then
  echo "invalid fixture unexpectedly passed" >&2
  exit 1
fi
python3 "$checker" "$repo_root/EIPS/eip-8080.md"
echo "metadata tests passed"