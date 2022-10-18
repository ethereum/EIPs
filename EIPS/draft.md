
---
eip: tbd
title: "eth/69: Add withdrawals to block"
description: "Adds the withdrawals to the block bodies and the withdrawal root to the block header in the eth protocol"
author: Marius van der Wijden (@MariusVanDerWijden)
discussions-to: tbd
status: Draft
type: Standards Track
category: Networking
created: tbd
requires: 2464, 2481, 4938, tbd
---

## Abstract

The [Ethereum Wire Protocol](https://github.com/ethereum/devp2p/tree/master/caps/eth.md) defines request and response messages for exchanging data between clients. The `block-bodies` definition contains the transactions and uncles of a block. We propose to extend the `block-bodies` with a list of withdrawals. The `header` definition contains the fields of a block header. We propose to extend the `header` with the `withdrawal-root`. The `block` definition contains the headers, transactions and uncles of a block. We propose to extend the `block` with a list of withdrawals.

## Motivation
With the introduction of withdrawals, the header and the block body format is changed. In order to allow nodes to respond with a valid block, the block bodies need to be extended with the withdrawal list and the block header with the withdrawal root.

The `block-body` definition is used in the `BlockBodies` message. The `block` definition is used by the `NewBlock` message. The `header` definition is used in the `block` definition and the `BlockHeaders` message.

## Specification

Modify the following message type from the `eth` protocol:

* `block-body`:
* * **(eth/67)**: We defined `block-body = [transactions, ommers]`
* * **(eth/68)**: We define `block-body = [transactions, ommers, withdrawals]`
* * **(eth/68)**: We define `withdrawals` as `[withdrawal_0, withdrawal_1, ...]`
* * **(eth/68)**: We define `withdrawal` as ` [index: B_8, address: B_20, amount: B_32]
* `header`:
* * **(eth/67)**: We defined `header = [
    parent-hash: B_32,
    ommers-hash: B_32,
    coinbase: B_20,
    state-root: B_32,
    txs-root: B_32,
    receipts-root: B_32,
    bloom: B_256,
    difficulty: P,
    number: P,
    gas-limit: P,
    gas-used: P,
    time: P,
    extradata: B,
    mix-digest: B_32,
    block-nonce: B_8,
    basefee-per-gas: P,
]`
* * **(eth/68)**: We define `header` as `header = [
    parent-hash: B_32,
    ommers-hash: B_32,
    coinbase: B_20,
    state-root: B_32,
    txs-root: B_32,
    receipts-root: B_32,
    bloom: B_256,
    difficulty: P,
    number: P,
    gas-limit: P,
    gas-used: P,
    time: P,
    extradata: B,
    mix-digest: B_32,
    block-nonce: B_8,
    basefee-per-gas: P,
    withdrawal-root: B_32,
]` for all messages using `header`
* * **(eth/67)**: We defined `block = [header transactions, ommers]`
* * **(eth/68)**: We define `block = [header, transactions, ommers, withdrawals]`


## Rationale
This change will extend the eth protocol to enable withdrawals since they change the header and body format.

## Backwards Compatibility

This EIP changes the `eth` protocol and requires rolling out a new version, `eth/69`. Supporting multiple versions of a wire protocol is possible. Rolling out a new version does not break older clients immediately, since they can keep using protocol version `eth/68`.

This EIP does not change consensus rules of the EVM and does not require a hard fork.

## Security Considerations

None

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).


