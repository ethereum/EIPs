---
eip: 7668
title: Remove bloom filters
description: Remove bloom filters from the execution block
author: Vitalik Buterin (@vbuterin)
discussions-to: https://ethereum-magicians.org/t/eip-7653-remove-bloom-filters/19447
status: Stagnant
type: Standards Track
category: Core
created: 2024-03-31
---

## Abstract

Require the bloom filters in an execution block, including at the top level and in the receipt object, to be empty.

## Motivation

Logs were originally introduced to give applications a way to record information about onchain events, which decentralized applications (dapps) would be able to easily query. Using bloom filters, dapps would be able to quickly go through the history, identify the few blocks that contained logs relative to their application, and then quickly identify which individual transactions have the logs that they need.

In practice, this mechanism is far too slow. Almost all dapps that access history end up doing so not through RPC calls to an Ethereum node (even a remote-hosted one), but through centralized extra-protocol services.

This EIP proposes recognizing that reality, and removing bloom filters from the protocol. Applications that need history querying would be encouraged to develop and use decentralized protocols that create provable log indexes using eg. ZK-SNARKs and incrementally-verifiable computation.

## Specification

The logs bloom of an execution block is now required to be empty (ie. 0 bytes long). The logs bloom of a transaction receipt is now required to be empty (ie. 0 bytes long).

## Rationale

This is a minimally disruptive way to remove the need to handle blooms from clients. A future EIP can later clean up by removing this field entirely, along with other fields that have been deprecated.

Gas costs of LOG are not reduced, because while the externality of polluting the bloom filter no longer needs to be accounted for, the costs of hashing have increased due to the needs of ZK-SNARK EVM implementations.

## Backwards Compatibility

Applications that depend on bloom filters to read events will cease to work. Very few applications depend on this feature today, because at current gas limits the false positive rate is so high and processing the logs in a long history query is so slow, especially for light clients (whom this feature was primarily intended to benefit).

## Security Considerations

As no new features are introduced or made cheaper, no security concerns are raised.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
