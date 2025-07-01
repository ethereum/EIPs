
---
title: Granular Transaction Types
description: Extends the capacity and granularity for new transaction types.
author: Marc Harvey-Hill (@Marchhill)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-07-01
<!-- requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field. -->
---

## Abstract

This proposal extends the capacity for new transaction types with a new transaction envelope beginning with `0xFF`. The new type allows for more granular control; multiple transaction types can be combined together by being enabled in a bit field.

## Motivation

The existing transaction type envelope introduced in [EIP-2718](./eip-2718.md) supports up to 128 different transaction types. Although this may seem like enough for the forseeable future, these could be rapidly used up due to the introduction of compound types, that combine existing transaction types.

As an example, consider what would happen if a new transaction type is introduced for account abstraction (eg. [EIP-7701](./eip-7701.md)). There is now a need to introduce many more types, combining the account abstraction transaction type with blob transactions, setcode transactions, etc. This could lead to a combinatorial explosion in the number of transaction types.

The new transaction format both extends the space for new transaction types, and allows for existing transaction types to easily combined.

## Specification

The new transaction format is defined as `0xFF || TypeSelector || TransactionPayload`, and likewise for receipts `0xFF || TypeSelector || ReceiptPayload`.

The `TypeSelector` is an RLP encoded bit field, where each bit represents whether a transaction type is enabled. Each transaction type can be either a base type, or an extension type. A valid type selector consists of a single base type, and zero or more extension types.

The order of the transaction payload fields is determined by first including the fields of the base transaction type. The following fields of the extension types are then appended in order.

By convention, the `x`th bit corresponds to enabling the fields from traditional type `x` transactions. As a simplified example, imagine we have introduced a new type `0x5` transaction which is equivalent to an [EIP-1559](./eip-1559) transaction type with some new fields. The equivalent type selector would be `0b00100100`. In this case, type `0x2` EIP-1559 type is first enabled as the base type, then `0x5` is an extension type, so the new fields for this type are appended afterwards. If another extension type was enabled by setting bit 6, then these fields would be appended after.

Note that the fields from the base type are always included first, even if the base type is enabled at a later bit than an extension type.

### Existing Transaction Type definitions

todo

Since there is no need to support legacy (type `0x0`) transactions in the new format, the zero bit is repurposed. It is defined as a base type with the fields of a type `0x2` EIP-1559 transaction, with the added condition that the `to` field may not be nil. This allow it to be used as a base type for type `0x3` and `0x4` transactions.

## Rationale

### RLP Encoding

By RLP encoding the type selector, an extremely large number of transaction types can be supported without wasting space.

### Type Prefix

The byte `0xFF` is used as a prefix, as this was reserved as a sentinel type for future extensions.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
