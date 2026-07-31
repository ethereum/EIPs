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
ALG_TYPE = 0xFA
SIZE = 128

def gas_cost(signing_data: Bytes) -> Uint64:
    return Uint64(128 + len(signing_data))

def validate(signature: Bytes) -> None | Error:
    # ...
    # Simple cryptography here
    # ...
    return None

def verify(signature: Bytes, signing_data: Bytes) -> Bytes | Error:
    # ...
    # Complicated cryptography here
    # ...
    return public_key

def merge_detached_signature(detached_signature: bytes, public_key: bytes) -> bytes:
    # ...
    # Either concatenation or a no-op here
    # ...
    return detached_signature + public_key
```

## Rationale
Generic algorithm has a good reason to be in Ethereum, therefore it should be.

## Backwards Compatibility
No backward compatibility issues found.

## Security Considerations
Needs discussion.

## Copyright
Copyright and related rights waived via [CC0](../../LICENSE.md).
