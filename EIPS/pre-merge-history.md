---
title: Cease serving history before PoS
description: Execution layer clients will no longer serve block data before Paris over p2p.
author: lightclient (@lightclient)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Network
created: 2024-02-13
---

## Abstract

Execution layer clients will no longer request or respond to p2p queries about
block data before the Paris upgrade.

## Motivation

As of 2024, historical data in clients has grown to around 500 GB. Nearly 400 GB
of that is from block data before PoS was activated in the Paris upgrade. Long
term, Ethereum plans to bound the amount of data nodes must store. This EIP
proposes the first steps to achieve such goal.

## Specification

Clients must not make or respond to p2p queries about blocks before block 15537393.

### Header Accumulator

The header accumulator commits to the set of pre-merge headers and their
associated total difficulty. The format for this data is defined as:

```python
EPOCH_SIZE = 8192 # blocks
MAX_HISTORICAL_EPOCHS = 131072  # 2**17

# An individual record for a historical header.
HeaderRecord = Container[block_hash: bytes32, total_difficulty: uint256]

# The records of the headers from within a single epoch
EpochRecord = List[HeaderRecord, max_length=EPOCH_SIZE]

Accumulator = Container[
    historical_epochs: List[bytes32, max_length=MAX_HISTORICAL_EPOCHS],
    current_epoch: EpochRecord,
]
```

The hash tree root of `Accumulator` for data before block 15537393 is
`0xec8e040fd6c557b41ca8ddd38f7e9d58a9281918dc92bdb72342a38fb085e701`.

## Rationale

### Only Pre-PoS data

One might ask why the distinction between pre and post PoS data is made in this
EIP. The simple answer is that the at the moment of the merge, the block
structure changed substantially. Although execution layer client software today
continues on with block data on disk which remains similar to per-PoS data, the
beacon chain is now the canoncial chain definition. Therefore, a beacon block
can be used to both record historical data for execution layer and beacon layer.
Additionally, the beacon chain already has the concept of a history accumulator
via the `historical_roots` field in the state.

Over the long term, the distinctions of "execution layer" and "consensus layer"
may matter less. This EIP tries to be agnostic to client architecture and
instead focuses on the shape of the data.

## Backwards Compatibility

After this EIP is activated, nodes will no longer be able to full sync from the
devp2p network. To continue doing so, they must retrieve the data out-of-band.

## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
