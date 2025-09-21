---
title: P256 transaction support
description: Adds an EIP-7932 algorithm type for P256 support of type `0x0`
author: James Kempton (@SirSpudlington)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2025-09-20
requires: 7932
---

## Abstract

This EIP adds a new [EIP-7932](./eip-7932.md) algorithm of type `0x0` for supporting P256 signatures.

## Motivation

P256 (a.k.a secp256r1) is a widely-used NIST standardized algorithm that already has a presence within the Ethereum codebase. This makes it a great algorithm to write test
cases against implementations of [EIP-7932](./eip-7932.md).

## Specification

This EIP defines a new [EIP-7932](../../EIPS/eip-7932.md) algorithmic type with the following parameters:
| Constant | Value |
| - | - |
| `ALG_TYPE` | `Bytes1(0x0)` |
| `GAS_PENALTY`| `500` |
| `MAX_SIZE` | `128` |

```python
N = 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551


def verify(signature_info: bytes, payload_hash: Hash32) -> Bytes:
    assert(len(signature_info) == 128)
    (r, s, x, y) = (signature_info[0:32], signature_info[32:64], signature_info[64:96], signature_info[96:128])

    # This is similar to [EIP-2](./eip-2.md)'s malleability verification.
    assert(s <= N/2)

    # This performs the verification specified in [RIP-7212](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md) under `Elliptic Curve Signature Verification Steps` and `Required Checks in Verification`.
    assert(P256Verify(r, s, x, y))
        
    return x.to_bytes(32, "big") + y.to_bytes(32, "big")
```

## Rationale

### Additional 500 gas penalty

Much of this proposal is drawn from [RIP-7212](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md). Some of the test cases in [RIP-7212](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md) show that P256 is slower than secp256k1 and as such, a small penalty has been added to combat the slowdown of verification.

### Why P256?

P256 or secp256r1, is used globally but (more importantly) has an existing implementation in all execution clients. This allows easy implementation of a known-safe algorithm, which is perfect for a test algorithm.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

Needs discussion.
<!-- TODO -->

## Copyright

Copyright and related rights waived via [CC0](../../LICENSE.md).
