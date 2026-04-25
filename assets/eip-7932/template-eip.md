---
title: Example EIP to add generic algorithm as an algorithmic type
description: Example EIP to add generic algorithm as an algorithmic type
Author: ExampleAuthor
discussions-to: fakeurl
status: Draft
type: Standards Track
category: Core
created: 2025-04-12
requires: 7932
---

## Abstract
This example EIP adds generic algorithm as an algorithmic type.

## Motivation
Generic algorithm has a good reason to be in Ethereum, therefore it should be.

## Specification

This EIP defines a new [EIP-7932](../../EIPS/eip-7932.md) algorithmic type with the following parameters.

```python
ALG_TYPE = 0x7E

DETACHED_SIZE = 64
AUTONOMOUS_SIZE = 128
PUBLIC_KEY_SIZE = 64

def gas_cost(signing_data_len: uint64) -> uint64:
    # This is an adaptation from the KECCAK256 opcode
    # as this algorithm requires exactly 32 signing bytes.
    # If an algorithm can directly sign data such as ML-DSA,
    # it should and this function should represent the
    # internal cost of hashing + a base fee.

    minimum_word_size = (signing_data_len + 31) // 32
    return uint64(30 + (6 * minimum_word_size))

def validate_autonomous(signature: AutonomousSignature) -> None | Error:
    # ...
    # Simple cryptography here
    # ...

def validate_detached(signature: DetachedSignature) -> None | Error:
    # ...
    # Simple cryptography here
    # ...

def verify_autonomous(
    signing_data: Bytes,
    signature: AutonomousSignature
) -> PublicKey | Error:
    # ...
    # Complicated cryptography here
    # ...
    return algorithm_type || untagged_public_key

def verify_detached(
    signing_data: Bytes,
    signature: DetachedSignature,
    public_key: PublicKey
) -> None | Error:
    # ...
    # Complicated cryptography here
    # ...
```

## Rationale
Generic algorithm has a good reason to be used in the EVM, therefore it should be.

## Backwards Compatibility
No backward compatibility issues found.

## Security Considerations
Needs discussion.

## Copyright
Copyright and related rights waived via [CC0](../../LICENSE.md).
