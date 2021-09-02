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
across different chains. With th


## Specification

As of the fork block `N`, consider blocks with a `gas_limit` greater than
`30,000,000` invalid.

## Rationale

### Why Cap the Gas Limit

The gas limit is currently under the control of block proposers. They have the
ability to increase the gas limit to whatever value they desire. This allows
them to bypass the EIP and All Core Devs processes in protocol decisions that
may negatively affect the security and/or decentralization of the network.

### No Fixed Gas Limit

A valuable property of proposers choosing the gas limit is they can scale it
down quickly if the network becomes unstable or is undergoing certain types of
attacks. For this reason, we maintain their ability to lower the gas limit
_below_ 30,000,000.

## Backwards Compatibility
No backwards compatibility issues.

## Test Cases
TBD

## Security Considerations
No security considerations.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
