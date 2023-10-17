---
eip: 6780
title: SELFDESTRUCT only in same transaction
description: SELFDESTRUCT will recover all funds to the caller but not delete the account, except when called in the same transaction as creation
author: Guillaume Ballet (@gballet), Vitalik Buterin (@vbuterin), Dankrad Feist (@dankrad)
discussions-to: https://ethereum-magicians.org/t/deactivate-selfdestruct-except-where-it-occurs-in-the-same-transaction-in-which-a-contract-was-created/13539
status: Draft
type: Standards Track
category: Core
created: 2023-03-25
requires: 2681, 2929, 3529
---

## Abstract

This EIP changes the functionality of the `SELFDESTRUCT` opcode. The new functionality will be only to send all Ether in the account to the caller, except that the current behaviour is preserved when `SELFDESTRUCT` is called in the same transaction a contract was created.

## Motivation

The `SELFDESTRUCT` opcode requires large changes to the state of an account, in particular removing all code and storage. This will not be possible in the future with Verkle trees: Each account will be stored in many different account keys, which will not be obviously connected to the root account.

This EIP implements this change. Applications that only use `SELFDESTRUCT` to retrieve funds will still work. Applications that only use `SELFDESTRUCT` in the same transaction as they created a contract will also continue to work without any changes.

## Specification

The behaviour of `SELFDESTRUCT` is changed in the following way:

1. When `SELFDESTRUCT` is executed in a transaction that is not the same as the contract calling `SELFDESTRUCT` was created:

 - `SELFDESTRUCT` does not delete any storage keys or code
 - `SELFDESTRUCT` transfers the entire account balance to the target.
 - No refund is given, as per [EIP-3529](./eip-3529.md).
 - [EIP-2929](./eip-2929.md)'s rules regarding `SELFDESTRUCT` remain unchanged.
  
2. When `SELFDESTRUCT` is executed in the same transaction as the contract was created:

 - `SELFDESTRUCT` continues to behave as originally, i.e. deletes all storage keys and the account itself.
 - Subsequently, the account will behave like exactly like an empty account, both in the same transaction and in all later ones
 - Transfer the account balance to the target **and** set account balance to `0.`
 - Note that no refund is given since [EIP-3529](./eip-3529.md).
 - Note that the rules of [EIP-2929](./eip-2929.md) regarding `SELFDESTRUCT` remain unchanged.
 - Note that when verkle tries are implemented on Ethereum, the cleared storage will be marked as having been written before but empty. This leads to no observable differences in EVM execution, but a contract having been created and deleted will lead to different state roots compared to the action not happening.

The `SELFDESTRUCT` opcode remains deprecated as specified in [EIP-6049](./eip-6049.md). Any use in newly deployed contracts is strongly discouraged even if this new behaviour is taken into account, and future changes to the EVM might further reduce the functionality of the opcode.

## Rationale

Getting rid of the `SELFDESTRUCT` opcode has been considered in the past, and there are currently no strong reasons to use it. This EIP implements a behavior that will attempt to leave some common uses of `SELFDESTRUCT` working, while reducing the complexity of the change on EVM implementations that would come from contract versioning. A further option that was considered was to just remove storage clearing from `SELFDESTRUCT` in [EIP-6046](./eip-6046.md) while preserving removal of contracts, however this is not safe because existing contracts rely on storage being empty when they are deployed.

## Backwards Compatibility

This EIP requires a hard fork, since it modifies consensus rules.

The only breaking change occurs when a contract is re-created at the same address using `CREATE2` (after a `SELFDESTRUCT`), where the `SELFDESTRUCT` is executed in a transaction that's different from the one that originally creates the contract.

## Security Considerations

The following applications of `SELFDESTRUCT` will be broken and applications that use it in this way are not safe anymore:

2. Where `CREATE2` is used to redeploy a contract in the same place in order to make a contract upgradable. This is not supported anymore and [ERC-2535](./eip-2535.md) or other types of proxy contracts should be used instead.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
