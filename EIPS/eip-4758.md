---
eip: 4758
title: Deactivate SELFDESTRUCT
description: Deactivate SELFDESTRUCT by changing it to SENDALL, which does recover all funds to the caller but does not delete any code or storage.
author: Guillaume Ballet (@gballet), Vitalik Buterin (@vbuterin), Dankrad Feist (@dankrad)
discussions-to: https://ethereum-magicians.org/t/eip-4758-deactivate-selfdestruct/8710
status: Stagnant
type: Standards Track
category: Core
created: 2022-02-03
---

## Abstract

This EIP renames the `SELFDESTRUCT` opcode to `SENDALL`, and replaces its functionality. The new functionality will be only to send all Ether in the account to the caller.

## Motivation

The `SELFDESTRUCT` opcode requires large changes to the state of an account, in particular removing all code and storage. This will not be possible in the future with Verkle trees: Each account will be stored in many different account keys, which will not be obviously connected to the root account.

This EIP implements this change. Applications that only use `SELFDESTRUCT` to retrieve funds will still work.

## Specification

 * The `SELFDESTRUCT` opcode is renamed to `SENDALL`, and now only immediately moves all ETH in the account to the target; it no longer destroys code or storage or alters the nonce
 * All refunds related to `SELFDESTRUCT` are removed

## Rationale

Getting rid of the `SELFDESTRUCT` opcode has been considered in the past, and there are currently no strong reasons to use it. Disabling it will be a requirement for statelessness.

## Backwards Compatibility

This EIP requires a hard fork, since it modifies consensus rules.

Few applications are affected by this change. The only use that breaks is where a contract is re-created at the same address using `CREATE2` (after a `SELFDESTRUCT`).

## Security Considerations

The following applications of `SELFDESTRUCT` will be broken and applications that use it in this way are not safe anymore:

1. Any use where `SELFDESTRUCT` is used to burn non-ETH token balances, such as [EIP-20](./eip-20.md)), inside a contract. We do not know of any such use (since it can easily be done by sending to a burn address this seems an unlikely way to use `SELFDESTRUCT`)
2. Where `CREATE2` is used to redeploy a contract in the same place. There are two ways in which this can fail:
    * The destruction prevents the contract from being used outside of a certain context. For example, the contract allows anyone to withdraw funds, but `SELFDESTRUCT` is used at the end of an operation to prevent others from doing this. This type of operation can easily be modified to not depend on `SELFDESTRUCT`.
    * The `SELFDESTRUCT` operation is used in order to make a contract upgradable. This is not supported anymore and delegates should be used.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
