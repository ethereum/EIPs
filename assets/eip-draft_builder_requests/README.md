# EIP-XXXX: Builder Execution Requests — Assets

Reference Solidity for the proposal, plus cross-verification tests.

## Files

| File | Purpose |
| --- | --- |
| `builder_requests.sol` | The three proposed predeploys plus a shared base: `RequestQueue` (EIP-7002-style queue + EIP-1559 fee + `SYSTEM_ADDRESS` end-of-block read), `BuilderDepositContract` (`deposit(...)`, BLS-verified, request type `0x03`), `BuilderTopUpContract` (`top_up(...)`, unverified, request type `0x04`), and `BuilderWithdrawalContract` (`withdraw(...)`, EIP-7002-style withdrawal/exit, request type `0x05`). |
| `gen_vectors.py` | Python script that uses `py_ecc` (the canonical Eth2 reference) to produce cross-verification test vectors. |
| `test/Vectors.sol` | Auto-generated Solidity library of test vectors. Regenerate by running `gen_vectors.py`. |
| `test/TestHarness.sol` | `BuilderDepositHarness` / `BuilderTopUpHarness` / `BuilderWithdrawalHarness` — inherit the predeploys and expose the pending-queue depth (and the SSZ signing-root helper) for the tests. |
| `test/BuilderRequests.t.sol` | Foundry tests. |
| `foundry.toml` | Foundry configuration (solc `0.6.11`, EVM `prague` by default). |

## Running the tests

Prerequisites:

```bash
# Foundry (forge / cast / anvil)
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Python with py_ecc for regenerating vectors
python3 -m venv venv && ./venv/bin/pip install py_ecc
```

Run the test suite:

```bash
forge test -vv
```

`evm_version = "prague"` in `foundry.toml` enables the EIP-2537 BLS precompiles, required for the three tests that exercise the pairing path. To run only the queue, system-read, and input-validation tests on an older EVM (no EIP-2537 needed):

```bash
forge test -vv --evm-version cancun --no-match-test 'Deposit(EnqueuesAndReads|AmountNotBound|RejectsTamperedSignature)'
```

## Regenerating vectors

```bash
./venv/bin/python gen_vectors.py > test/Vectors.sol
```

The script is deterministic: the secret key is hard-coded so the output is byte-stable across runs. `py_ecc.bls.G2ProofOfPossession.Sign` (the Eth2 ciphersuite) produces the deposit signature; `py_ecc.optimized_bls12_381.normalize` extracts the canonical affine (X, Y) coordinates.

## Test coverage

| Test | What it covers | EIP-2537 required? |
| --- | --- | --- |
| `testComputeSigningRoot` | `_computeDepositSigningRoot` matches `py_ecc`-derived SSZ `compute_signing_root` | no |
| `testDepositEnqueuesAndReads` | A `py_ecc`-produced deposit is accepted, enqueued, and the `SYSTEM_ADDRESS` read returns the exact 88-byte record | **yes** |
| `testTopUpEnqueuesAndReads` | `top_up(...)` enqueues; the system read returns the exact 56-byte record | no |
| `testFeeStartsAtMinimum` | The fee is `MIN_REQUEST_FEE` (1 wei) at `excess == 0` | no |
| `testFeeRisesWithExcess` | A block of 18 requests then a system call sets `excess = 16`, so `fake_exponential(1, 16, 17) == 2` | no |
| `testFeeGetterFallbackMatches` | A non-system empty-calldata call returns the current fee | no |
| `testDepositAmountNotBoundToSignature` | The same signature is accepted with a different `amount_gwei` (the amount is unsigned); the record reflects the passed amount | **yes** |
| `testDepositRejectsInsufficientValue` | `msg.value == stake` (no room for the fee) reverts; nothing enqueued | no |
| `testSystemReadRequiresSystemAddress` | A non-`SYSTEM_ADDRESS` empty-calldata call is the fee getter and does NOT drain the queue | no |
| `testPerBlockCapAndFifo` | 17 queued → first read drains the 16-record cap, second drains the remainder (FIFO) | no |
| `testQueueResetsWhenDrained` | When the queue fully drains, head and tail reset to 0 so slots are reused; the next request restarts at index 0 | no |
| `testFallbackRejectsNonEmptyCalldata` | The empty-calldata fallback rejects non-empty junk calldata; the empty-calldata fee getter still works | no |
| `testDepositRejectsTamperedSignature` | Flipping a signature bit is rejected (subgroup/pairing failure); nothing enqueued | **yes** |
| `testDepositRejectsPubkeySignBitFlip` | Flipping only the pubkey sign flag is rejected by the sign-bit binding (audit Finding 2 regression); nothing enqueued | no |
| `testDepositRejectsSignatureSignBitFlip` | Flipping only the signature sign flag is rejected by the sign-bit binding; nothing enqueued | no |
| `testDepositRejectsInfinityPubkey` | `pubkey` with infinity flag is rejected before BLS work; nothing enqueued | no |
| `testDepositRejectsTooSmallStake` | `amount_gwei * 1 gwei < 1 ether` is rejected; nothing enqueued | no |
| `testDepositRejectsWrongPubkeyLength` | `pubkey.length != 48` is rejected; nothing enqueued | no |
| `testTopUpRejectsTooSmallStake` | `top_up` stake `< 1 ether` is rejected; nothing enqueued | no |
| `testTopUpRejectsWrongPubkeyLength` | `top_up` with `pubkey.length != 48` is rejected; nothing enqueued | no |
| `testWithdrawalEnqueuesAndReads` | A partial withdrawal (`amount > 0`) enqueues `source ++ pubkey ++ amount`; the system read returns the exact 76-byte record | no |
| `testExitEnqueuesWithZeroAmount` | `withdraw(pubkey, 0)` (full-exit sentinel) is accepted and recorded with a zero amount | no |
| `testWithdrawalRecordsCaller` | The recorded `source_address` is the caller (`msg.sender`), the field the CL checks against the builder's `execution_address` | no |
| `testWithdrawalRequiresNoStake` | A withdrawal sends only the fee — no staked value — even for a large `amount_gwei` | no |
| `testWithdrawalRejectsInsufficientFee` | `msg.value` below the fee reverts; nothing enqueued | no |
| `testWithdrawalRejectsWrongPubkeyLength` | `withdraw` with `pubkey.length != 48` is rejected; nothing enqueued | no |
| `testFeeGetterRevertsWhileInhibited` | A freshly deployed contract is inhibited (`excess == EXCESS_INHIBITOR`); the fee getter reverts | no |
| `testRequestRevertsWhileInhibited` | A request before the first system call reverts on the inhibited fee; nothing enqueued | no |
| `testFirstSystemCallClearsInhibitor` | The first `SYSTEM_ADDRESS` call clears the inhibitor; the fee is then `MIN_REQUEST_FEE` | no |
