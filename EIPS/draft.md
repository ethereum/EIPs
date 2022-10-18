

---
eip: tbd
title: "eth/68: Add transaction type to tx announcement "
description: "Adds the transaction type to tx announcement messages in the wire protocol"
author: Marius van der Wijden (@MariusVanDerWijden)
discussions-to: tbd
status: Draft
type: Standards Track
category: Networking
created: tbd
requires: 2464, 2481, 4938
---

## Abstract

The [Ethereum Wire Protocol](https://github.com/ethereum/devp2p/tree/master/caps/eth.md) defines request and response messages for exchanging data between clients. The `NewPooledTransactionHashesPacket` response announces transactions available in the node. We propose to extend the `NewPooledTransactionHashesPacket` such that the node sends both the transaction hashes as well as the transaction types as define in EIP-2718.

## Motivation

`NewPooledTransactionHashesPacket` was introduced to provide a fallback mechanism if transaction broadcast broke. The idea is for a node to announce which transactions it has locally to peers and let request the transactions. 

With the upcoming EIP-4844 a new transaction type is introduced for blob transactions. Since they are large, broadcasting them will increase bandwidth requirements. Adding the transaction type to the `NewPooledTransactionHashesPacket` will allow nodes to select which types of transactions they want to fetch.

An additional benefit is that clients now know which transaction type to expect before fetching them.

## Specification

Modify the following message type from the `eth` protocol:

* `NewPooledTransactionHashesPacket (0x08)`
* * **(eth/67)**: `[hash_0: B_32, hash_1: B_32, ...]`
* * **(eth/68)**: `[type_0: B_1, type_1: B_1, ...], [hash_0: B_32, hash_1: B_32, ...]`

## Rationale
This change will make the eth protocol future proof for new transaction type that might not be relevant for all nodes. It gives the receiving node better control over the data it fetches from the peer as well as allow throttling the download of specific types.

## Backwards Compatibility

This EIP changes the `eth` protocol and requires rolling out a new version, `eth/68`. Supporting multiple versions of a wire protocol is possible. Rolling out a new version does not break older clients immediately, since they can keep using protocol version `eth/67`.

This EIP does not change consensus rules of the EVM and does not require a hard fork.

## Security Considerations

None

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).


