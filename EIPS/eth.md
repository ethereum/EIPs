---
title: eth/70: Drop pre-merge fields from eth protocol
description: Drop unnecessary fields after the merge
author: Marius van der Wijden (@MariusVanDerWijden)
status: Draft
type: Standards Track
category: Networking
created: 2024-02-29
requires: EIP-5793
---


## Abstract

After the merge a few fields and messages in the networking protocol became obsolete.
This EIP modifies the networking messages such that these fields are not send anymore.
Additionally we propose to remove the `Bloom` field from the receipts networking messages.

## Motivation

We recently discovered that none of the clients store the `Bloom` field of the receipts as it can be recomputed on demand.
However the networking spec requires the `Bloom` field to be send over the network.
Thus a syncing node will ask for the Bloom filters for all receipts.
The serving node will regenerate roughly 530GB of bloom filters (2.3B txs * 256 byte).
These 530GBs are send over the network to the syncing peer, the syncing peer will verify them and not store them either.
This adds an additional 530GB of unnecessary bandwith to every sync.

Additionally we propose to remove fields and messages that were deprecated by the merge, such as 
- Removing the `TD` field in the `Status` message. 
- Removing the `NewBlockHashes` message.
- Removing the `NewBlock` message.

## Specification

Remove the `NewBlockHashes (0x01)` message.

Remove the `NewBlock (0x07)` message.

Modify the `Status (0x00)` message as follows:
- (eth/68): `[version: P, networkid: P, td: P, blockhash: B_32, genesis: B_32, forkid]`
- (eth/70): `[version: P, networkid: P, blockhash: B_32, genesis: B_32, forkid]`

Modify the encoding for receipts in the `Receipts (0x10)` message as follows:
- (eth/68): `receipt = {legacy-receipt, typed-receipt}` with `typed-receipt = tx-type || receipt-data` and
```
legacy-receipt = [
    post-state-or-status: {B_32, {0, 1}},
    cumulative-gas: P,
    bloom: B_256,
    logs: [log₁, log₂, ...]
]
```
- (eth/70): `receipt = {legacy-receipt, typed-receipt}` with `typed-receipt = tx-type || receipt-data` and
```
legacy-receipt = [
    post-state-or-status: {B_32, {0, 1}},
    cumulative-gas: P,
    logs: [log₁, log₂, ...]
]
```
We omit the bloom filter from both the legacy and typed receipts.
Receiving nodes will be able to recompute the bloom filter based on the logs.

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

Since this EIP removes the `NewBlock` and `NewBlockHashes

This EIP changes the eth protocol and requires rolling out a new version, `eth/70`. Supporting multiple versions of a wire protocol is possible. Rolling out a new version does not break older clients immediately, since they can keep using protocol version `eth/68`.

This EIP does not change consensus rules of the EVM and does not require a hard fork.

## Security Considerations

None

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
