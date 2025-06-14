---
title: Warm Account Write Metering
description: Introduce warm account writes, decreasing the cost of writing to an account after the first write.
author:
discussions-to: <URL>
status: Draft
type: <Standards Track, Meta, or Informational>
category: Core
created: 2025-06-14
requires: 2200
---

## Abstract

This EIP introduces warm metering for account writes. Namely, if one of the account fields (nonce, value, codehash) are changed more than once in a transaction, the later writes are cheaper, since the state root update only needs to be paid for once.

## Motivation

This EIP recognizes that updating the state root is one of the most expensive parts of block construction. Currently, multiple writes to storage are subject net gas metering, which reduces the cost of a storage write after the first write. However, updates to the account are subject to the same cost every time. This means that, for example, making multiple WETH transfers to an account in a single transaction is cheaper than making multiple native ETH transfers(!). This discourages people from using native ETH transfers, and unfairly penalizes potential future opcodes which involve value transfer, like `PAY` and `GAS2ETH`.

This EIP brings the gas cost of the account update more in line with the actual implementation cost. Multiple writes within a transaction can be batched, meaning that, after the first write, the cost of updating the state root does not need to be charged again.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The following constants are defined:

```
COLD_ACCOUNT_WRITE_COST = 10000
WARM_ACCOUNT_WRITE_COST = 100
```

On any account-updating opcode (CREATE, CREATE2, CALL), if the account fields are equal to the transaction start values (have not been updated), then `COLD_ACCOUNT_WRITE_COST` is charged. If the account fields are not equal to the transaction start values (i.e., they have been updated), then `WARM_ACCOUNT_WRITE_COST` is charged.

## Rationale

An account is represented within Ethereum as a tuple `(nonce, balance, storage_root, codehash)`. The account is a leaf of a Merkle Patricia Tree (MPT), while the `storage_root` is itself the root of the account's MPT key-value store. An update to the account's storage requires updating two MPTs (the account's `storage_root`, as well as the global state root). Meanwhile, updating the other fields in an account requires updating only one MPT.

Net metering (i.e., issuing a refund if the final value at the end of the transaction is equal to the transaction start, a la `SSTORE`) was considered, but not added for simplicity.

## Backwards Compatibility

TBD

## Test Cases

TBD

## Reference Implementation

TBD

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
