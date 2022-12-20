---
eip: <to be assigned>
title: Functional SELFDESTRUCT
description: Changes SELFDESTRUCT to only cause a finite number of state changes
author: Pandapip1 (@Pandapip1), Alex Beregszaszi (@axic)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2022-12-20
requires: <to be assigned>
---

## Abstract

Changes `SELFDESTRUCT` to only cause a finite number of state changes.

## Motivation

The `SELFDESTRUCT` instruction has a fixed price, but is unbounded in storage/account changes (it needs to delete all keys). This has been an outstanding concern for some time.

Furthermore, *Verkle trees* might accounts will be organised differently. Account properties, including storage, would have individual keys. It would not be possible to traverse and find all used keys. This makes `SELFDESTRUCT` very challenging to support in Verkle trees. This EIP is a step towards supporting `SELFDESTRUCT` in Verkle trees.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### `SELFDESTRUCT`

Instead of destroying the contract at the end of the transaction, instead, the following will occur at the end of the transaction in which it is invoked:

1. The contract's code is set to `0x1`, and its nonce is set to `2^64-1`.
2. Starting at the contract's address plus one, while either that address's code or nonce are not equal to zero, increment it. The contract's `0`th storage slot is set to that address.
3. The contract's balance is transferred, in its entirety, to the address on the top of the stack.
4. The top of the stack is popped.

## Rationale

This EIP is a step towards supporting `SELFDESTRUCT` in Verkle trees. It is a minimal change to the current behaviour, and does not change the gas cost of `SELFDESTRUCT`.

## Backwards Compatibility

This EIP requires a protocol upgrade, since it modifies consensus rules.

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
