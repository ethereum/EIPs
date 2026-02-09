---
title: Private Key Deactivation Aware ecRecover
description: Modify ecRecover precompile to return zero address for keys deactivated per EIP-7851
author: Liyi Guo (@colinlyguo), Nicolas Consigny (@nconsigny)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-02-09
requires: 7851
---

## Abstract

This EIP modifies the `ecRecover` precompile at address `0x0000000000000000000000000000000000000001` to respect [EIP-7851](./eip-7851.md) key deactivation. After performing ECDSA public key recovery, the precompile checks whether the recovered address has a deactivated private key. If so, it returns the zero address instead of the recovered address.

## Motivation

[EIP-7851](./eip-7851.md) enables delegated EOAs (per [EIP-7702](./eip-7702.md)) to deactivate their private keys, preventing those keys from authorizing transactions or new delegation authorizations. However, the `ecRecover` precompile is currently a pure cryptographic function with no awareness of account state. Even after an EOA's key is deactivated, on-chain signature verification through `ecRecover` continues to succeed for that key. This affects contracts that rely on `ecRecover` for signature-based authorization, such as ERC-20 contracts implementing `permit` ([EIP-2612](./eip-2612.md)). Since many such contracts are immutable and cannot be updated to add deactivation checks, modifying `ecRecover` at the protocol level is a practical path.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

| Constant | Value |
|---|---|
| `ECRECOVER_ADDRESS` | `0x0000000000000000000000000000000000000001` |
| `COLD_ACCOUNT_ACCESS_COST` | 2600 |
| `WARM_ACCOUNT_ACCESS_COST` | 100 |
| `FORK_TIMESTAMP` | TBD |

### Modified `ecRecover` Behavior

After `FORK_TIMESTAMP`, the `ecRecover` precompile at address `ECRECOVER_ADDRESS` MUST perform the following steps:

1. Perform ECDSA public key recovery from the input `(hash, v, r, s)` as currently specified, yielding a `recovered_address`.
2. If recovery fails, return 32 zero bytes and consume `3000` gas.
3. If recovery succeeds, read the account code of `recovered_address` and determine whether the key is deactivated per [EIP-7851](./eip-7851.md).
4. If `recovered_address` has a deactivated key, return 32 zero bytes.
5. Otherwise, return `recovered_address` left-padded to 32 bytes.

### Deactivation Check

An address is considered to have a deactivated key if and only if its account code has a prefix of `0xef0100` and a length of exactly 24 bytes, consistent with the deactivated state `0xef0100 || delegate_address || 0x00` defined in [EIP-7851](./eip-7851.md):

```python
code = state.get_code(recovered_address)
is_deactivated = len(code) == 24 and code[:3] == bytes.fromhex("ef0100")
```

### Gas Cost

When ECDSA recovery fails, no state access is performed and the gas cost
remains `3000`.

When ECDSA recovery succeeds, the precompile MUST access the account of
`recovered_address` to read its code. This access MUST follow the
[EIP-2929](./eip-2929.md) warm/cold rules:

- If `recovered_address` is already in the transaction's `accessed_addresses` set, the additional cost is `WARM_ACCOUNT_ACCESS_COST` (100).
- Otherwise, the additional cost is `COLD_ACCOUNT_ACCESS_COST` (2600), and `recovered_address` MUST be added to the `accessed_addresses` set, making it warm for subsequent operations within the same transaction.

## Backwards Compatibility

For addresses whose private key has been deactivated under [EIP-7851](./eip-7851.md), `ecRecover` now returns the zero address where it previously returned the recovered address.

On every successful ECDSA recovery, the precompile now performs an additional account access, adding either `WARM_ACCOUNT_ACCESS_COST` (100) or `COLD_ACCOUNT_ACCESS_COST` (2600) to the base cost of `3000`. Transactions that invoke `ecRecover` near their gas limit MAY fail with an out-of-gas error after activation.

## Test Cases

To be added.

## Reference Implementation

```python
COLD_ACCOUNT_ACCESS_COST = 2600
WARM_ACCOUNT_ACCESS_COST = 100
BASE_GAS = 3000

def ecrecover_gas(state, recovered_address):
    if recovered_address is None:
        return BASE_GAS
    if recovered_address in state.accessed_addresses:
        return BASE_GAS + WARM_ACCOUNT_ACCESS_COST
    state.accessed_addresses.add(recovered_address)
    return BASE_GAS + COLD_ACCOUNT_ACCESS_COST

ZERO_BYTES32 = b'\x00' * 32
DELEGATED_CODE_PREFIX = b'\xef\x01\x00'
DEACTIVATED_CODE_LEN = 24  # len(0xef0100 || address || 0x00)

def ecrecover(state, hash: bytes, v: int, r: int, s: int) -> bytes:
    # None means recovery failure
    recovered_address = ecdsa_recover(hash, v, r, s)

    if recovered_address is None:
        return ZERO_BYTES32

    # Check EIP-7851 deactivation
    code = state.get_code(recovered_address)
    if len(code) == DEACTIVATED_CODE_LEN and code[:3] == DELEGATED_CODE_PREFIX:
        return ZERO_BYTES32

    return recovered_address.rjust(32, b'\x00')
```

## Security Considerations

### Multi-Chain Considerations

Key deactivation under EIP-7851 is per-chain state. A key deactivated on one chain remains active on other chains. Users SHOULD NOT assume that deactivating their key on one chain protects them across all EVM-compatible chains.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
