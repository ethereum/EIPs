---
title: Example EIP to add secp256k1 curve as an algorithmic type
description: Example EIP to add secp256k1 curve as an algorithmic type
Author: ExampleAuthor
discussions-to: fakeurl
status: Draft
type: Standards Track
category: Core
created: 2025-04-12
requires: 7932
---

## Abstract
This example EIP adds secp256k1 curve as an algorithmic type.

## Motivation
secp256k1 is the commonly used curve, therefore it should be added.

## Specification

This EIP defines a new [EIP-7932](../../EIPS/eip-7932.md) algorithmic type with the following parameters.

| Constant | Value |
| - | - |
| `ALG_TYPE` | `Bytes1(0x0)` |
| `GAS_PENALTY`| `0` |
| `MAX_SIZE` | `65` |

```python
def verify(signature_info: bytes, parent_hash: bytes32) -> bytes20:
  assert(len(signature_info) == 65)
  r, s, v = signature_info[0:32], signature_info[32:64], signature_info[64]

  # This assumes `ecrecover` is identical to the `ecrecover` function in solidity.
  signer = ecrecover(parent_hash, v, r, s)

  return signer
```

## Rationale
secp256k1 is the commonly used curve, therefore it should be added.

## Backwards Compatibility
No backward compatibility issues found.

## Security Considerations
Needs discussion.

## Copyright
Copyright and related rights waived via [CC0](../../LICENSE.md).
