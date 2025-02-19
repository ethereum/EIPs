---
eip: 7642
title: eth/69 - Drop pre-merge fields
description: Drop unnecessary fields after the merge
author: Marius van der Wijden (@MariusVanDerWijden), Felix Lange <fjl@ethereum.org>
discussions-to: https://ethereum-magicians.org/t/eth-70-drop-pre-merge-fields-from-eth-protocol/19005
status: Stagnant
type: Standards Track
category: Networking
created: 2024-02-29
requires: 5793
---

## Abstract

After the merge the `td` field in the networking protocol became obsolete.
This EIP modifies the networking messages such that this field is not sent anymore.
Additionally we propose to remove the `Bloom` field from the receipts networking messages.

## Motivation

We recently discovered that none of the clients store the `Bloom` field of the receipts as it can be recomputed on demand.
However the networking spec requires the `Bloom` field to be sent over the network.
Thus a syncing node will ask for the Bloom filters for all receipts.
The serving node will regenerate roughly 530GB of bloom filters (2.3B txs * 256 byte).
These 530GBs are send over the network to the syncing peer, the syncing peer will verify them and not store them either.
This adds an additional 530GB of unnecessary bandwidth to every sync.

Additionally we propose to remove the field that was deprecated by the merge, namely
the `TD` field in the `Status` message. 

## Specification

Modify the `Status (0x00)` message as follows:

- (eth/68): `[version: P, networkid: P, td: P, blockhash: B_32, genesis: B_32, forkid]`

- (eth/69): `[version: P, networkid: P, blockhash: B_32, genesis: B_32, forkid]`

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

- (eth/69): `receipt = {legacy-receipt, typed-receipt}` with `typed-receipt = tx-type || receipt-data` and

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

After the merge, the `TD` field of the `Status` message became meaningless since the difficulty of post-merge blocks are 0.
It could in theory be used to distinguish synced with unsynced nodes, 
but the same thing can be accomplished with the forkid as well. 
It is not used in the go-ethereum codebase in any way.

Removing the bloom filters from the `Receipt` message reduces the cpu load of serving nodes as well as the bandwidth significantly. The receiving nodes will need to recompute the bloom filter. The recomputation is not very CPU intensive. 
The bandwidth gains amount to roughly 530GiB per syncing node or (at least) 95GiB snappy compressed. 

## Backwards Compatibility

This EIP changes the eth protocol and requires rolling out a new version, `eth/69`. Supporting multiple versions of a wire protocol is possible. Rolling out a new version does not break older clients immediately, since they can keep using protocol version `eth/68`.

This EIP does not change consensus rules of the EVM and does not require a hard fork.

## Security Considerations

None

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
