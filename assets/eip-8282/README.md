# EIP-8282: Builder Execution Requests — Assets

Reference Solidity for the proposal, plus a Foundry test suite.

## Files

| File | Purpose |
| --- | --- |
| `builder_requests.sol` | The two proposed predeploys plus a shared base: `RequestQueue` (EIP-7002-style queue + EIP-1559 fee + `EXCESS_INHIBITOR` + `SYSTEM_ADDRESS` end-of-block read), `BuilderDepositContract` (`deposit(...)`, request type `0x03`, serves first deposits and top-ups), and `BuilderExitContract` (`exit(...)`, request type `0x04`). Neither performs on-chain BLS; the deposit's signature is carried in the record for the consensus layer to verify. |
| `test/TestHarness.sol` | `BuilderDepositHarness` / `BuilderExitHarness` — inherit the predeploys and expose the pending-queue depth, the current fee, and (for the exit harness) the raw head/tail indices. |
| `test/BuilderRequests.t.sol` | Foundry tests. |
| `foundry.toml` | Foundry configuration (solc `0.6.11`, EVM `istanbul`). |

## Running the tests

Prerequisites — Foundry only (no Python / `py_ecc`, since the contracts perform no on-chain BLS):

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

Run the test suite:

```bash
forge test -vv
```

The contracts use only basic EVM features (no precompiles), so the suite runs on any post-Byzantium EVM; `foundry.toml` targets `istanbul`, the newest version solc `0.6.11` supports.

## Test coverage

| Test | What it covers |
| --- | --- |
| `testDepositEnqueuesAndReads` | `deposit(...)` enqueues; the `SYSTEM_ADDRESS` read returns the exact 184-byte `pubkey ++ withdrawal_credentials ++ amount ++ signature` record |
| `testDepositRejectsTooSmallStake` | `amount_gwei * 1 gwei < BUILDER_MIN_DEPOSIT` (1 ETH) is rejected; nothing enqueued |
| `testDepositRejectsInsufficientValue` | `msg.value == stake` (no room for the fee) reverts; nothing enqueued |
| `testDepositRejectsWrongPubkeyLength` | `pubkey.length != 48` is rejected; nothing enqueued |
| `testDepositRejectsWrongSignatureLength` | `signature.length != 96` is rejected; nothing enqueued |
| `testExitEnqueuesAndReads` | `exit(pubkey)` enqueues; the system read returns the exact 68-byte `source_address ++ pubkey` record |
| `testExitRecordsCaller` | The recorded `source_address` is the caller (`msg.sender`), the field the CL checks against the builder's `execution_address` |
| `testExitRejectsInsufficientFee` | `msg.value` below the fee reverts; nothing enqueued |
| `testExitRejectsWrongPubkeyLength` | `exit` with `pubkey.length != 48` is rejected; nothing enqueued |
| `testFeeStartsAtMinimum` | The fee is `MIN_REQUEST_FEE` (1 wei) at `excess == 0` |
| `testFeeRisesWithExcess` | A block of 18 requests then a system call sets `excess = 16`, so `fake_exponential(1, 16, 17) == 2` |
| `testFeeGetterFallbackMatches` | A non-system empty-calldata call returns the current fee |
| `testSystemReadRequiresSystemAddress` | A non-`SYSTEM_ADDRESS` empty-calldata call is the fee getter and does NOT drain the queue |
| `testPerBlockCapAndFifo` | 17 queued → first read drains the 16-record cap, second drains the remainder (FIFO) |
| `testQueueResetsWhenDrained` | When the queue fully drains, head and tail reset to 0 so slots are reused; the next request restarts at index 0 |
| `testFallbackRejectsNonEmptyCalldata` | The empty-calldata fallback rejects non-empty junk calldata; the empty-calldata fee getter still works |
| `testFeeGetterRevertsWhileInhibited` | A freshly deployed contract is inhibited (`excess == EXCESS_INHIBITOR`); the fee getter reverts |
| `testRequestRevertsWhileInhibited` | A request before the first system call reverts on the inhibited fee; nothing enqueued |
| `testFirstSystemCallClearsInhibitor` | The first `SYSTEM_ADDRESS` call clears the inhibitor; the fee is then `MIN_REQUEST_FEE` |
