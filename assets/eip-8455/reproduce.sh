#!/usr/bin/env bash
# Fill the RESERVOIR test fixtures with the execution specifications and,
# when Go is available, run the reservoir model state tests on go-ethereum.
set -euo pipefail

EELS_SHA=c9781fa5ac92b3e22becdf05b734917e685d47f8
GETH_SHA=2006f0836b30b8f689cd1df5620a9f64421c9f84
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-$PWD/reservoir-repro}"
mkdir -p "$WORK"
cd "$WORK"

curl -sL "https://codeload.github.com/ethereum/execution-specs/tar.gz/$EELS_SHA" | tar xz
cd "execution-specs-$EELS_SHA"
patch -p1 < "$HERE/execution-specs.patch"
python3 -m venv .venv
. .venv/bin/activate
pip install -q -e . -e packages/testing
fill tests/bogota/eip_reservoir --fork Bogota --output "$WORK/fixtures" --clean
deactivate
cd "$WORK"

if ! command -v go >/dev/null 2>&1; then
  echo "Go not found, skipping go-ethereum" >&2
  exit 0
fi

curl -sL "https://codeload.github.com/ethereum/go-ethereum/tar.gz/$GETH_SHA" | tar xz
cd "go-ethereum-$GETH_SHA"
patch -p1 < "$HERE/go-ethereum.patch"
go test ./core/vm/...
for f in "$WORK"/fixtures/state_tests/for_bogota/bogota/eip_reservoir/*/*.json; do
  case "$(basename "$f")" in
    frame_*|portability_frame*) continue ;;
  esac
  go run ./cmd/evm statetest "$f"
done
