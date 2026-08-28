---
eip: 8151
title: Account Code Restricted ecRecover
description: Restrict ecRecover results to accounts with empty code or a delegation indicator
author: Liyi Guo (@colinlyguo), Nicolas Consigny (@nconsigny)
discussions-to: https://ethereum-magicians.org/t/eip-8151-account-code-restricted-ecrecover/27690
status: Draft
type: Standards Track
category: Core
created: 2026-02-09
requires: 2929, 3607, 7702
---

## Abstract

This EIP modifies the `ecRecover` precompile at address `0x0000000000000000000000000000000000000001` to apply the [EIP-3607](./eip-3607.md) account-code restriction, except for delegation indicators specified by [EIP-7702](./eip-7702.md). After performing ECDSA public key recovery, the precompile returns the recovered address only if its current raw account code is empty, or exactly an EIP-7702 delegation indicator. Otherwise, it returns 32 zero bytes (the existing zero return value of `ecRecover`).

## Motivation

EOAs can use [EIP-7702](./eip-7702.md) as a bridge to post-quantum authorization. After migration, the account's non-empty code no longer matches the EIP-7702 delegation format `0xef0100 || delegate_address`, so [EIP-3607](./eip-3607.md) disables its ECDSA transaction authority at the protocol level. However, `ecRecover` ignores account state. A quantum-capable attacker deriving the old ECDSA private key could still authorize token transfers through contracts, including [ERC-20](./eip-20.md) `permit` implementations ([ERC-2612](./eip-2612.md)). This EIP applies the same rule to `ecRecover`: recovery returns zero when the account has non-empty raw code that is not a valid EIP-7702 delegation indicator. As a result, after the account has migrated to post-quantum authorization, the old ECDSA private key can no longer be used for contract authorization that relies on `ecRecover`.

## Specification

### Modified `ecRecover` Behavior

Starting at the activation of this EIP, the `ecRecover` precompile at address `0x0000000000000000000000000000000000000001` must perform the following steps:

1. Perform ECDSA public key recovery from the input `(hash, v, r, s)` as currently specified, yielding a `recovered_address`.
2. If recovery fails, return 32 zero bytes and consume `3000` gas.
3. If recovery succeeds, consume `3000` gas plus the [EIP-2929](./eip-2929.md) warm/cold account-access cost for `recovered_address`, then check whether its raw code is empty or a valid EIP-7702 delegation indicator, without following any delegation.
4. If the account passes the check, return `recovered_address` left-padded to 32 bytes.
5. Otherwise, return 32 zero bytes.

### Account Code Check

The check uses the raw account code stored in state for `recovered_address`, without following a delegation indicator. An absent account is treated as having empty code.

```python
code = state.get_raw_code(recovered_address)
is_permitted = len(code) == 0 or (len(code) == 23 and code[:3] == bytes.fromhex("ef0100"))
```

Thus, the recovered address is returned only when its raw code is empty or exactly `0xef0100 || delegate_address`.

### Gas Cost

When ECDSA recovery fails, no state access is performed and the gas cost remains `3000`.

When ECDSA recovery succeeds, the precompile must access the account of `recovered_address` to read its code. This access must follow the [EIP-2929](./eip-2929.md) warm/cold rules:

- If `recovered_address` is already in the transaction's `accessed_addresses` set, the additional cost is 100 gas.
- Otherwise, the additional cost is 2600 gas, and `recovered_address` must be added to the `accessed_addresses` set, making it warm for subsequent operations within the same transaction.

## Rationale

### Protocol-Level Modification

Modifying `ecRecover` at the protocol level is chosen because many deployed contracts that rely on `ecRecover` for signature-based authorization (e.g., [ERC-20](./eip-20.md) `permit` implementations) are immutable and cannot be updated to check the recovered account's code. A protocol-level change ensures these existing contracts automatically apply the same restriction without requiring redeployment.

### Returning 32 Zero Bytes

When the recovered account does not pass the account-code check, the precompile returns 32 zero bytes rather than triggering an execution failure (`success = 0`). Currently, malformed `v`, out of range `r`/`s`, and failed recovery all return 32 zero bytes with `success = 1`, and `ecRecover` has never used execution failure to signal invalid input. Treating a disallowed recovered account as another form of "recovery failed" keeps this convention intact.

Furthermore, introducing an execution failure path would break deployed contracts that wrap `ecRecover` with a low level `staticcall` and `require(success)`, turning a "signature not valid" result into an unexpected revert. Contracts that already check for a zero return will naturally reject disallowed accounts without any code changes.

### EIP-2929 Gas Accounting

Since the precompile now reads account state, the additional gas cost follows the existing [EIP-2929](./eip-2929.md) warm/cold access pattern for consistency with the rest of the protocol. This avoids introducing a new gas model. It also ensures that the cost of state access is fairly accounted for.

## Backwards Compatibility

For addresses whose raw code is neither empty nor exactly an EIP-7702 delegation indicator, `ecRecover` now returns 32 zero bytes where it previously returned the recovered address.

On every successful ECDSA recovery, the precompile now performs an additional account access, adding 100 gas for a warm account or 2600 gas for a cold account to the base cost of `3000`. Transactions that invoke `ecRecover` near their gas limit may fail with an out-of-gas error after activation. Recovery failures are unchanged.

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
DELEGATION_PREFIX = b'\xef\x01\x00'
DELEGATION_CODE_LEN = 23

def permits_ecrecover(state, recovered_address):
    code = state.get_raw_code(recovered_address)
    return len(code) == 0 or (len(code) == DELEGATION_CODE_LEN and code[:3] == DELEGATION_PREFIX)

def ecrecover(state, hash: bytes, v: int, r: int, s: int) -> bytes:
    # None means recovery failure
    recovered_address = ecdsa_recover(hash, v, r, s)

    if recovered_address is None:
        return ZERO_BYTES32

    if not permits_ecrecover(state, recovered_address):
        return ZERO_BYTES32

    return recovered_address.rjust(32, b'\x00')
```

## Security Considerations

### Contracts Not Checking for Zero Return

When an account fails the account-code check, `ecrecover` returns the same 32 zero bytes used for an invalid signature, so contracts that already check for zero continue to behave correctly. Contracts that use `ecrecover` but do not verify the result is non-zero are already vulnerable to accepting invalid signatures.

### Application-Level ECDSA Verification

This EIP only modifies the `ecrecover` precompile. Contracts that perform ECDSA recovery in application-level code (e.g., pure Solidity implementations) bypass the precompile and will not observe the account-code restriction.

### Cross-Domain / L2 Fault Proof Implications

Some systems re-execute `ecrecover` in a different context (different chain, different layer, or asynchronously at a later time) and assume it is a pure function of `(hash, v, r, s)`. Because this EIP introduces a read of the recovered account's current raw code, that assumption no longer holds.

In particular, L2 fault proof systems that obtain the final `ecrecover` result by executing the L1 precompile may become incorrect when L1 and L2 state differ. An L2 adopting this EIP must recover the address and then apply the account-code check and EIP-2929 accounting using its own raw account code and transaction access status. Systems that need recovery to remain independent of account state must use a separate secp256k1 recovery implementation instead of this precompile.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
