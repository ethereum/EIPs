# Assets for the RESERVOIR Opcode

This directory contains a reference implementation of the `RESERVOIR` opcode and the test fillers that generate its consensus tests.

## Files

`execution-specs.patch` applies to the execution specifications at commit `c9781fa5ac92b3e22becdf05b734917e685d47f8` (branch `eips/bogota/eip-8141`), which implements EIP-8037, EIP-2780 and EIP-8141. It adds the opcode to the Bogota fork, registers it in the testing framework, and adds the fillers in `tests/bogota/eip_reservoir`. The fork mixin uses `99999` in place of the EIP number until one is assigned.

`go-ethereum.patch` applies to go-ethereum at commit `2006f0836b30b8f689cd1df5620a9f64421c9f84`. It implements the reservoir model behavior only, since that revision does not include EIP-8141, and adds a `Bogota` entry to the state test forks.

`reproduce.sh` downloads both revisions, applies the patches, fills the fixtures with the execution specifications and, if Go is installed, builds go-ethereum and runs the reservoir model state tests against it.

## Usage

```sh
./reproduce.sh
```

The fixtures are written to `reservoir-repro/fixtures`. Filling produces 37 test cases in state test and blockchain test formats.
