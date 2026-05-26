# EIP-XXXX: Builder Deposit Contract — Assets

Reference Solidity for the proposal, plus cross-verification tests.

## Files

| File | Purpose |
| --- | --- |
| `builder_deposit_contract.sol` | The proposed predeploy. Two entrypoints: `deposit(...)` (BLS-verified, requires affine Y coordinates) and `top_up(...)` (unverified, CL re-validates). |
| `gen_vectors.py` | Python script that uses `py_ecc` (the canonical Eth2 reference) to produce cross-verification test vectors. |
| `test/Vectors.sol` | Auto-generated Solidity library of test vectors. Regenerate by running `gen_vectors.py`. |
| `test/TestHarness.sol` | Thin wrapper that inherits `BuilderDepositContract` and exposes its `internal` SSZ signing-root helper + the `deposit_count` storage slot, for use by the tests. |
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

`evm_version = "prague"` in `foundry.toml` enables the EIP-2537 BLS precompiles, required for the deposit-verification path. To run only the input-shape and signing-root tests on an older EVM (no EIP-2537 needed):

```bash
forge test -vv --evm-version cancun --no-match-test 'Deposit(Valid|Rejects(Tampered|Infinity))'
```

## Regenerating vectors

```bash
./venv/bin/python gen_vectors.py > test/Vectors.sol
```

The script is deterministic: the secret key is hard-coded so the output is byte-stable across runs. `py_ecc.bls.G2ProofOfPossession.Sign` (the Eth2 ciphersuite) produces the deposit signature; `py_ecc.optimized_bls12_381.normalize` extracts the canonical affine (X, Y) coordinates.

## Test coverage

| Test | What it cross-verifies | EIP-2537 required? |
| --- | --- | --- |
| `testComputeSigningRoot` | `_computeDepositSigningRoot` matches `py_ecc`-derived SSZ `compute_signing_root` | no |
| `testDepositValid` | A `py_ecc.G2ProofOfPossession.Sign`-produced signature is accepted; `deposit_count` increments | **yes** |
| `testTopUpValid` | `top_up(...)` accepts a non-signed call; `deposit_count` increments | no |
| `testMonotonicIndex` | Deposit + top_up + top_up increment the counter by 1 each | **yes** (for the deposit step) |
| `testDepositRejectsTamperedAmount` | Sending a different `msg.value` than was signed fails the pairing check | **yes** |
| `testDepositRejectsTamperedSignature` | Flipping a bit in the signature is rejected (subgroup or pairing failure) | **yes** |
| `testDepositRejectsPubkeySignBitFlip` | Flipping only the pubkey sign flag (keeping Y) is rejected by the sign-bit binding — regression for audit Finding 2 | no |
| `testDepositRejectsSignatureSignBitFlip` | Flipping only the signature sign flag (keeping Y) is rejected by the sign-bit binding | no |
| `testDepositRejectsInfinityPubkey` | `pubkey` with infinity flag is rejected before BLS work | no |
| `testDepositRejectsInfinitySignature` | `signature` with infinity flag is rejected before BLS work | no |
| `testDepositRejectsTooSmallAmount` | `msg.value < 1 ether` is rejected | no |
| `testDepositRejectsNonGweiAmount` | `msg.value` not aligned to 1 gwei is rejected | no |
| `testDepositRejectsWrongPubkeyLength` | `pubkey.length != 48` is rejected | no |
| `testDepositRejectsWrongSignatureLength` | `signature.length != 96` is rejected | no |
| `testTopUpRejectsTooSmallAmount` | `top_up` with `msg.value < 1 ether` is rejected | no |
| `testTopUpRejectsWrongPubkeyLength` | `top_up` with `pubkey.length != 48` is rejected | no |
