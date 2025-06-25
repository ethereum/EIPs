---
title: Ed25519 transaction support
description: Adds a EIP-7932 algorithm type for Ed25519 support of type `0x0`
author: James Kempton (@SirSpudlington)
discussions-to: todo
status: Draft
type: Standards Track
category: Core
created: 2025-06-25
requires: 7932
---

## Abstract
This EIP adds a new [EIP-7932](../../EIPS/eip-7932.md) algorithm of type `0x0` for supporting Ed25519 signatures.

## Motivation
Ed25519 is one of the most widely used forms of Elliptic Curve Cryptography and is one of the defaults for SSH keys,
this makes it a good contender to be able to sign transactions with. It also provides an algorithm to write test
cases against during the implemenation phase of [EIP-7932](../../EIPS/eip-7932.md).

## Specification

This EIP defines a new [EIP-7932](../../EIPS/eip-7932.md) algorithmic type with the following parameters:
| Constant | Value |
| - | - |
| `ALG_TYPE` | `Bytes1(0x0)` |
| `GAS_PENALTY`| `19000` |
| `MAX_SIZE` | `96` |

```python
def verify(signature_info: bytes, parent_hash: bytes32) -> bytes20:
  assert(len(signature_info) == 96)

  signature = signature_info[:64]
  public_key = signature_info[64:]
  
  # This is the `Verify` function described in [RFC 8032 Section 5.1.7](https://datatracker.ietf.org/doc/html/rfc8032#section-5.1.7),
  # This MUST be processed as raw `Ed25519` and not `Ed25519ctx` or `Ed25519ph`
  assert(ed25519_verify(signature, public_key))

  return keccak256(signature)[:-20]
```

## Rationale

### High gas penalty

As this algorithm's primary objective is serving as a testing-tool for [EIP-7932](../../EIPS/eip-7932.md), a large
gas penalty is in place to prevent excessive use of this algorithm.

### Why Ed25519?

Ed25519 has significant tooling backing it, this makes it a good candidate for using as a "dummy" algorithm.
This allows it to be an algorithm for client teams to easily test [EIP-7932](../../EIPS/eip-7932.md).

It may also be useful for signing in Hardware security modules in server environments designed for serving
as ERC-4337 bundlers.

### Appending the public key to the signature

Currently, without changing the algorithm itself, it is impossible to efficiently recover the public key
from a signature and message.

## Backwards Compatibility
No backward compatibility issues found.

## Security Considerations
Needs discussion.

## Copyright
Copyright and related rights waived via [CC0](../../LICENSE.md).
