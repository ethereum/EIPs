
---
title: Granular Transaction Types
description: Extends the capacity and granularity for new transaction types.
author: Marc Harvey-Hill (@Marchhill)
discussions-to: https://ethereum-magicians.org/t/eip-granular-transaction-types/24715
status: Draft
type: Standards Track
category: Core
created: 2025-07-01
---

## Abstract

This proposal extends the capacity for new transaction types with a new transaction envelope beginning with `0xFF`. The new type allows for more granular control; multiple transaction types can be combined together by being enabled in a bit field.

## Motivation

The existing transaction type envelope introduced in [EIP-2718](./eip-2718.md) supports up to 128 different transaction types. Although this may seem like enough for the forseeable future, these could be rapidly used up due to the introduction of compound types, that combine existing transaction types.

As an example, consider what would happen if a new transaction type is introduced for account abstraction (eg. [EIP-7701](./eip-7701.md)). If smart accounts become widely adopted, there is a need to introduce many more types, combining the account abstraction transaction type with blob transactions, setcode transactions, etc. Account abstraction is one example, but the same argument could apply to any new transaction type added in future. This could lead to a combinatorial explosion in the number of transaction types.

The new transaction format both extends the space for new transaction types, and allows for existing transaction types to easily combined.

## Specification

The new transaction format is defined as `0xFF || TypeSelector || TransactionPayload`, and likewise for receipts in order to match their corresponding transaction type `0xFF || TypeSelector || ReceiptPayload`.

The `TypeSelector` is a bit field, where each bit represents whether a transaction type is enabled. This bit field is a byte string which is RLP encoded to allow for variable length. Each transaction type can be either a base type, or an extension type. A valid type selector consists of a single base type, and zero or more extension types.

The order of the transaction payload fields is determined by first including the fields of the base transaction type. The following fields of the extension types are then appended in order.

By convention, the `x`th bit corresponds to enabling the fields from traditional type `x` transactions. As a simplified example, imagine we have introduced a new type `0x5` transaction which is equivalent to an [EIP-1559](./eip-1559) transaction type with some new fields. The equivalent type selector would be `0b0010_0100`. In this case, type `0x2` EIP-1559 type is first enabled as the base type, then `0x5` is an extension type, so the new fields for this type are appended afterwards. If another extension type was enabled by setting bit 6, then these fields would be appended after.

Note that the fields from the base type are always included first, even if the base type is enabled at a later bit than an extension type.

### Existing Transaction Type definitions

| Bit | Type      | Fields                |
|-----|-----------|-----------------------|
| 0   | Base      | Type 0x2 EIP-1559*    |
| 1   | Base      | Type 0x1 Access List  |
| 2   | Base      | Type 0x2 EIP-1559     |
| 3   | Extension | Type 0x3 Blob†        |
| 4   | Extension | Type 0x4 Setcode†     |

* Since there is no need to support legacy (type `0x0`) transactions in the new format, the zero bit is repurposed. It is defined as a base type with the fields of a type `0x2` EIP-1559 transaction, with the added condition that the `to` field MUST NOT be `nil`. This allow it to be used as a base type for type `0x3` and `0x4` transactions.

† As these are extension types, only the additional fields are included; the rest are covered by the base type.

As an example for how the new transaction format can be used, the following table shows how old transaction types can be reimplemented with the new format.

| Old type         | Unencoded Transaction selector | Equivalent New Type |
|------------------|--------------------------------|---------------------|
| 0x0 Legacy       | *Unsupported*                  | *Unsupported*       |
| 0x1 Access Lists | 0b0100_0000 = 0x40             | 0xFF40              |
| 0x2 EIP-1559     | 0b0010_0000 = 0x20             | 0xFF20              |
| 0x3 Blob         | 0b1001_0000 = 0x90             | 0xFF8190            |
| 0x4 Setcode      | 0b1000_1000 = 0x88             | 0xFF8188            |

Note that these equivalent types have the same fields, but not necessarily in the same order.

## Rationale

### RLP Encoding

RLP encoding the type selector allows it to have variable length, meaning that a very large number of transaction types can be supported without wasting space.

### Type Prefix

The byte `0xFF` is used as a prefix, as this was reserved as a sentinel type for future extensions in EIP-2718.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
