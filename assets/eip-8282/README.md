# EIP-8282: Builder Execution Requests — Assets

Reference implementation of the two proposed predeploys, plus a Foundry test
suite.

Both contracts are written in geas and are
line-level derivatives of the deployed EIP-7002 / EIP-7251 system contracts
maintained in `ethereum/sys-asm` (whose
source assembles byte-identically to the runtime code on mainnet). The
dispatch, EIP-1559-style fee, queue, storage layout, system subroutine, and
request logging carry over unchanged; the header of each `main.eas` enumerates
its full diff against the parent contract.

## Files

| File | Purpose |
| --- | --- |
| `src/deposits/main.eas` | Builder deposit request contract (request type `0x03`, serves first deposits and top-ups). The EIP-7002/7251 skeleton with a 184-byte record (`pubkey ++ withdrawal_credentials ++ amount ++ signature`, no source address), two added value checks (`amount >= 1 ETH` in gwei; `callvalue - fee >= amount * 1 gwei`), and EIP-7002's big-endian-in / little-endian-out amount conversion. No on-chain BLS; the signature is opaque calldata carried into the record for the consensus layer to verify. |
| `src/exits/main.eas` | Builder exit request contract (request type `0x04`). The EIP-7002 withdrawals contract with the amount field removed: input is the bare 48-byte pubkey, the record is `source_address ++ pubkey` (68 bytes). |
| `src/deposits/ctor.eas`, `src/exits/ctor.eas` | Deployment constructors (verbatim from `sys-asm`): store the excess inhibitor and return the runtime code. |
| `src/common/fake_expo.eas` | The EIP-7002/7251 `fake_exponential` fee routine, verbatim from `sys-asm`. |
| `test/BuilderRequests.t.sol` | Foundry tests: assemble the geas sources via FFI, etch them, and exercise both predeploys. |
| `test/Geas.sol` | Minimal FFI wrapper around the `geas` assembler (the harness pattern `sys-asm`'s own suite uses). |
| `foundry.toml` | Foundry configuration (EVM `prague`, `ffi = true`). |

## Running the tests

Prerequisites — Foundry (`forge`) and the geas assembler on `PATH`, each
installed from its upstream project (no Python / `py_ecc`, since the contracts
perform no on-chain BLS).

Run the test suite (the tests assemble `src/**/main.eas` through `geas` at
run time, so changes to the sources are picked up automatically):

```bash
forge test -vv
```

To assemble the runtime bytecode directly:

```bash
geas src/deposits/main.eas   # 566-byte runtime
geas src/exits/main.eas      # 396-byte runtime
```

## Test coverage

| Test | What it covers |
| --- | --- |
| `testDepositEnqueuesAndReads` | Deposit happy path: the `SYSTEM_ADDRESS` read returns the exact 184-byte record with the amount little-endian; the accepted input is emitted as an anonymous log; count/head/tail reset |
| `testDepositAmountConvertedToLittleEndian` | A non-palindromic amount (`0x0102030405060708`) round-trips big-endian in, little-endian out; all other bytes verbatim |
| `testDepositRejectsAmountBelowMinimum` | `amount < 10^9` gwei (1 ETH) is rejected; nothing enqueued |
| `testDepositRejectsValueBelowStakePlusFee` | `msg.value == stake` (no room for the fee) and `msg.value == 0` revert; `stake + fee` succeeds |
| `testDepositRejectsBadInputSize` | 183/185-byte and ABI-style (selector-prefixed) calldata revert |
| `testQueueCapFifoAndReset` | 17 queued → first read drains the 16-record cap FIFO, second drains the remainder; head/tail reset to 0 and the slots are reused |
| `testFeeMatchesFakeExponentialAndDecays` | A block of 18 requests sets `excess = 16`; the fee getter matches `fake_exponential(1, 16, 17)`; empty blocks decay `excess` by the target |
| `testFeeGetterRejectsValue` (both suites) | The empty-calldata fee getter reverts when value is attached |
| `testInhibitorBlocksRequestsUntilFirstSystemCall` (both suites) | Freshly deployed state (excess = inhibitor): fee getter and requests revert; the first system call clears the inhibitor and the fee is the 1-wei minimum |
| `testSystemCallDrainsRegardlessOfCalldata` | The `SYSTEM_ADDRESS` caller check precedes calldata dispatch |
| `testExitEnqueuesAndReads` | Exit happy path: the read returns the exact 68-byte `source_address ++ pubkey` record, also emitted as a log |
| `testExitRecordsCaller` | The recorded `source_address` is the caller, the field the CL checks against the builder's `execution_address` |
| `testExitRejectsBadInputSize` | 47/49-byte and selector-prefixed calldata revert |
| `testExitRejectsInsufficientFee` | `msg.value` below the fee reverts; nothing enqueued |
| `testQueueCapAndFifo` | Per-block cap and FIFO order on the exit queue; reset when drained |
