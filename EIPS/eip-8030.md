---
eip: 8030
title: P256 algorithm support
description: Adds an EIP-7932 algorithm type for P256 support of type `0x0`
author: James Kempton (@SirSpudlington)
discussions-to: https://ethereum-magicians.org/t/discussion-topic-for-eip-8030/25557
status: Draft
type: Standards Track
category: Core
created: 2025-09-20
requires: 7932, 7951
---

## Abstract

This EIP adds a new [EIP-7932](./eip-7932.md) algorithm of type `0x0` for supporting P256 signatures.

## Motivation

P256 (a.k.a secp256r1) is a widely-used NIST standardized algorithm that already has a presence within the Ethereum codebase. This makes it a great algorithm to write test
cases against implementations of [EIP-7932](./eip-7932.md).

## Specification

This EIP defines a new [EIP-7932](./eip-7932.md) algorithmic type with the following parameters:

| Constant | Value |
| - | - |
| `ALG_TYPE` | `Bytes1(0x0)` |
| `SIZE`| `129` |

```python
N = 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551

def gas_cost(signing_data: Bytes) -> Uint64:
    # This is the precompile cost from [EIP-7951](./eip-7951.md) with 3000 gas
    # subtracted (the cost of the secp256k1 precompile)
    BASE_GAS = Uint64(3900)

    # Calculate extra overhead for keccak256 hashing
    if len(signing_data) == 32:
        return BASE_GAS
    else:
        minimum_word_size = (len(signing_data) + 31) // 32
        return BASE_GAS + Uint64(30 + (6 * minimum_word_size))

def validate(signature: Bytes) -> None | Error:
    # This function is a noop as there is no
    # exposed function defined in [EIP-7951](./eip-7951.md)

def verify(signature: Bytes, signing_data: Bytes) -> Bytes | Error:
    if len(signing_data) != 32:
        # Hash if non-standard size
        signing_data = keccak256(signing_data)

    # Ignore initial alg_type byte
    signature = signature[1:]

    (r, s, x, y) = (signature[0:32], signature[32:64], signature[64:96], signature[96:128])

    # This is similar to [EIP-2](./eip-2.md)'s malleability verification.
    assert(s <= N/2)

    # This is defined in [P256Verify Function](#p256verify-function)
    assert(P256Verify(signing_data, r, s, x, y) == Bytes("0x0000000000000000000000000000000000000000000000000000000000000001"))
        
    return x.to_bytes(32, "big") + y.to_bytes(32, "big")
```


### `P256Verify` Function

The `P256Verify` function is the logic of the precompile defined in [EIP-7951](./eip-7951.md), the only exception is that this function MUST NOT charge any gas.

## Rationale

### Why P256?

P256 or secp256r1, is used globally but (more importantly) has an existing implementation in all execution clients. This allows easy implementation of a known-safe algorithm, which is perfect for a test algorithm.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

Needs discussion.
<!-- TODO -->

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
