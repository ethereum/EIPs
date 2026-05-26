# EIP-XXXX: Builder Deposit Contract — Assets

Reference Solidity for the proposal, plus cross-verification tests.

## Files

| File | Purpose |
| --- | --- |
| `builder_deposit_contract.sol` | The two proposed predeploys plus a shared base: `RequestQueue` (EIP-7002-style queue + `SYSTEM_ADDRESS` end-of-block read), `BuilderDepositContract` (`deposit(...)`, BLS-verified, request type `0x03`), and `BuilderTopUpContract` (`top_up(...)`, unverified, request type `0x04`). |
| `gen_vectors.py` | Python script that uses `py_ecc` (the canonical Eth2 reference) to produce cross-verification test vectors. |
| `test/Vectors.sol` | Auto-generated Solidity library of test vectors. Regenerate by running `gen_vectors.py`. |
| `test/TestHarness.sol` | `BuilderDepositHarness` / `BuilderTopUpHarness` — inherit the predeploys and expose the pending-queue depth (and the SSZ signing-root helper) for the tests. |
| `test/BuilderDeposit.t.sol` | Foundry tests. |
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
forge test -vv --evm-version cancun --no-match-test '(DepositEnqueuesAndReads|Tampered)'
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
| `testSystemReadRequiresSystemAddress` | An empty-calldata read from a non-`SYSTEM_ADDRESS` caller reverts | no |
| `testPerBlockCapAndFifo` | 17 queued → first read drains the 16-record cap, second drains the remainder (FIFO) | no |
| `testDepositRejectsTamperedAmount` | A different `msg.value` than was signed fails the pairing check; nothing enqueued | **yes** |
| `testDepositRejectsTamperedSignature` | Flipping a signature bit is rejected (subgroup/pairing failure); nothing enqueued | **yes** |
| `testDepositRejectsPubkeySignBitFlip` | Flipping only the pubkey sign flag is rejected by the sign-bit binding (audit Finding 2 regression); nothing enqueued | no |
| `testDepositRejectsSignatureSignBitFlip` | Flipping only the signature sign flag is rejected by the sign-bit binding; nothing enqueued | no |
| `testDepositRejectsInfinityPubkey` | `pubkey` with infinity flag is rejected before BLS work; nothing enqueued | no |
| `testDepositRejectsTooSmallAmount` | `msg.value < 1 ether` is rejected; nothing enqueued | no |
| `testDepositRejectsWrongPubkeyLength` | `pubkey.length != 48` is rejected; nothing enqueued | no |
| `testTopUpRejectsTooSmallAmount` | `top_up` with `msg.value < 1 ether` is rejected; nothing enqueued | no |
| `testTopUpRejectsWrongPubkeyLength` | `top_up` with `pubkey.length != 48` is rejected; nothing enqueued | no |
