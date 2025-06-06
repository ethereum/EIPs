# List of test cases for EIP-7932

All test cases contain a `name` field which can be used to identify failing cases.

The testing only algorithm types are:
- `0x0`: secp256k1,
- `0xfe`: returns always `0x0`, has no max size and `GAS_PENALTY = 0`

## TX test cases

These test cases contain a `tx: bytes` and a `output: null | bytes`, if the output is `null` that means the tx is invalid.

The tx test cases can be found [here](./test_cases/transactions.json).

In addition there are [additional info](./test_cases/additional_info.json) test cases for EIP-7702 compatibilty (and future multi-signature transaction types), these have the same `tx: bytes` input, however the output is `output: null | bytes[]` with the first index being the tx signer and then any following signatures as they appear.

## Precompile test cases

These precompile test cases can be found [here](./test_cases/precompile.json), these test cases contain `argument` which should be the argument sent to the precompile and `output: bytes20`.