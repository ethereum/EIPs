---
eip: xxxx
title: Strict enforcement of chainId
description: Strictly enforce the chainId on transactions based on the chain.
author: Gregory Markou (@GregTheGreek)
discussions-to: 
status: Draft
type: Standards Track
category: Core
created: 2021-09-2
requires: 155
---

## Abstract

Reject transactions that do not explicitly have the same chainId as the node's configuration.

## Motivation

Per [EIP-155](./eip-155.md) a transaction with a `chainId = 0` is considered to be a valid 
transaction. This was a feature to offer developers the ability to sumbit replayable transactions 
across different chains. With the rise of evm combatible chains that use forks, or packages
from popular Ethereum clients, we are putting user funds at risk as we see users leveraging
Ethereum alternatives. This EIP aims to eliminate any potential developer or user error that 
could result in a replayable transaction griefing, or stealing funds from a user.


## Specification

As of the fork block `N`, consider transactions with a `chaindId = 0` to be invalid. Such that 
transactions are verified based on the nodes configuration. Eg:
```
if (node.cfg.chainId != tx.chainId) {
    // Reject transaction
}
```

## Rationale

The configuration set by the node is the main source of truth, and thus should be explicitly used
when deciding how to filter out a transaction. This check should exist in two places, as a filter
on the JSON-RPC (eg: `eth_sendTransaction`), and stricly enforced on the EVM during transaction 
validation.

This ensures that users will not have transactions pending that will be guaranteed to fail, and
prevents the transaction from being included in a block.

## Backwards Compatibility
This breaks all applications or tooling that submit transactions with a `chainId == 0`.

## Test Cases
TBD

## Security Considerations
No security considerations.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
