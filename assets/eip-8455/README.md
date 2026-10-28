# Assets for the RESERVOIR Opcode

This directory contains a reference implementation of the `RESERVOIR` opcode and the test fillers that generate its consensus tests.

## Files

`execution-specs.patch` applies to the execution specifications at commit `c9781fa5ac92b3e22becdf05b734917e685d47f8` (branch `eips/bogota/eip-8141`), which implements EIP-8037, EIP-2780 and EIP-8141. It adds the opcode to the Bogota fork, registers it in the testing framework, and adds the fillers in `tests/bogota/eip_reservoir`.

`go-ethereum.patch` applies to go-ethereum at commit `2006f0836b30b8f689cd1df5620a9f64421c9f84`. It implements the reservoir model behavior only, since that revision does not include EIP-8141, and adds a `Bogota` entry to the state test forks.

`reproduce.sh` downloads both revisions, applies the patches, fills the fixtures with the execution specifications and, if Go is installed, builds go-ethereum and runs the reservoir model state tests against it.

## Usage

```sh
./reproduce.sh
```

The fixtures are written to `reservoir-repro/fixtures`. Filling produces 47 test cases in state test and blockchain test formats.

The blockchain tests for system calls and the EIP-8141 frame transaction cases run on the execution specifications only; `reproduce.sh` skips them for go-ethereum.

## Execution contexts

The fillers cover the following contexts. Every successful read costs 2 execution gas and no state gas.

| Context | `RESERVOIR` returns | Filler |
| --- | --- | --- |
| EIP-8037 transaction with `tx.gas` at most `TX_MAX_GAS_LIMIT` | `0` until a refill lands in the reservoir | `test_read[below_cap]`, `test_cross_frame_refill_merge[below_cap]` |
| EIP-8037 transaction with `tx.gas` above the cap | The frame's `state_gas_reservoir` | `test_read`, `test_new_slot_charge`, `test_child_*`, `test_create_*` |
| EIP-8037 system call | `STORAGE_SET × SYSTEM_MAX_SSTORES_PER_CALL = 1,566,720` at entry | `test_system_call` |
| EIP-8141 frame transaction | The frame's `state_gas_left`, equal to `TXPARAM(0x0C)` | `test_frame_*`, `test_portability_frame` |
| Before activation | Undefined opcode, exceptional halt | not filled; `0x4d` is `INVALID`-equivalent in Amsterdam |

`GAS + RESERVOIR` is a measurement of the frame's remaining budget, not a statement that the two pools are interchangeable. Under EIP-8037 a state charge beyond the reservoir is paid from `gas_left`; under EIP-8141 it fails.

## Bundle ledger

`test_bundle_ledger` is an EntryPoint-like caller that meters two operations with `GAS + RESERVOIR` and stores the signed deltas. Operation 1 creates a storage slot in a shared contract and operation 2 clears it. Values are before minus after, in gas, from the filled fixtures; the fixtures store them with an offset of 2^128 so that no result slot is cleared.

| Variant | op 1 `ΔGAS` | op 1 `ΔRESERVOIR` | op 1 sum | op 2 `ΔGAS` | op 2 `ΔRESERVOIR` | op 2 sum | tx gas used |
| --- | --- | --- | --- | --- | --- | --- | --- |
| create, clear; `R = 500,000` | 18,275 | 97,920 | 116,195 | 3,375 | −97,920 | −94,545 | 99,826 |
| create, clear; `tx.gas ≤ TX_MAX_GAS_LIMIT` | 116,195 | 0 | 116,195 | −94,545 | 0 | −94,545 | 99,826 |
| create only; `R = 500,000` | 18,275 | 97,920 | 116,195 | 3,044 | 0 | 3,044 | 207,415 |
| control (no state change) | 3,044 | 0 | 3,044 | 3,044 | 0 | 3,044 | 94,264 |

The per-operation sums do not depend on which pool funded the slot. Relative to the control, the sums rise by 15,562 for create-and-clear and by 113,151 for create-only, which equal the additional gas the transaction uses before the refund counter. "Tx gas used" is after the refund counter: the create-and-clear transaction is refunded a further 10,000 for restoring the slot, which neither opcode reports. The execution components depend on this test's bytecode and on the gas schedule of the pinned revision.
