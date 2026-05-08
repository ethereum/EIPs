---
eip: 7658
title: Light client data backfill
description: Mechanism for beacon nodes for syncing historical light client data
author: Etan Kissling (@etan-status)
discussions-to: https://ethereum-magicians.org/t/eip-7658-light-client-data-backfill/19290
status: Stagnant
type: Standards Track
category: Core
created: 2024-03-21
---

## Abstract

This EIP defines a mechanism for syncing [light client data](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/full-node.md) between beacon nodes.

## Motivation

[Light client data](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/full-node.md) is collected by beacon nodes to assist [light clients](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/light-client.md) to sync with the network. The [sync protocol](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/sync-protocol.md) defines a mechanism to sync forward in time. However, it cannot be used to sync backward.

Collecting light client data is challenging because beacon nodes need to have access to the corresponding [`BeaconState`](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/phase0/beacon-chain.md#beaconstate) and [`SignedBeaconBlock`](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/phase0/beacon-chain.md#signedbeaconblock). `BeaconState` objects are not available before the initially synced checkpoint state, and `SignedBeaconBlock` objects have a limited retention period on libp2p.

Furthermore, each [sync committee period](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/beacon-chain.md#get_next_sync_committee) consists of `EPOCHS_PER_SYNC_COMMITTEE_PERIOD * SLOTS_PER_EPOCH` slots. To support archive services such as Portal network to provide a consistent view regardless of backend, it is necessary to choose a single canonical slot for which to derive the representative light client data for that period. Such data should be verifiable to be canonical and optimal in a decentralized and independent manner.

To support light client data backfill, this EIP proposes to track the canonical and optimal [`SyncAggregate`](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/beacon-chain.md#syncaggregate) in the `BeaconState`. This minimal addition allows proving that derived [`LightClientUpdate`](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/sync-protocol.md#lightclientupdate) and [`LightClientBootstrap`](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/sync-protocol.md#lightclientbootstrap) are also canonical and optimal.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Containers

#### New containers

##### `SyncData`

```python
class SyncData(Container):
    # Sync committee aggregate signature
    sync_aggregate: SyncAggregate
    # Slot at which the aggregate signature was created
    signature_slot: Slot
```

#### Extended containers

##### `BeaconState`

New fields are added to the end of `BeaconState` from the activating fork onward to track the current and previous sync committee period's best sync data.

```python
class BeaconState(Container):
    ...
    # Sync history
    previous_best_sync_data: SyncData
    current_best_sync_data: SyncData
    parent_block_has_sync_committee_finality: bool
```

### Helper functions

#### `default_sync_data`

```python
def default_sync_data() -> SyncData:
    return SyncData(
        sync_aggregate=SyncAggregate(
            sync_committee_bits=Bitvector[SYNC_COMMITTEE_SIZE](),
            sync_committee_signature=G2_POINT_AT_INFINITY,
        ),
        signature_slot=GENESIS_SLOT,
    )
```

### Beacon chain state transition function

#### Epoch processing

##### Modified `process_sync_committee_updates`

On sync committee boundaries, current period data is moved to previous period. This allows proving that light client data for the previous period is canonical.

```python
def process_sync_committee_updates(state: BeaconState) -> None:
    next_epoch = get_current_epoch(state) + Epoch(1)
    if next_epoch % EPOCHS_PER_SYNC_COMMITTEE_PERIOD == 0:
        ...
        state.previous_best_sync_data = state.current_best_sync_data
        state.current_best_sync_data = default_sync_data()
        state.parent_block_has_sync_committee_finality = False
```

#### Block processing

Block processing is extended to track the optimal light client data for the current period. Due to the possibility for empty slots this must be tracked before the block header is overwritten; this allows tracking the exact block after which `next_sync_committee` becomes finalized.

```python
def process_block(state: BeaconState, block: BeaconBlock) -> None:
    process_best_sync_data(state, block)
    process_block_header(state, block)
    ...
```

##### New `process_best_sync_data`

```python
def process_best_sync_data(state: BeaconState, block: BeaconBlock) -> None:
    signature_period = compute_sync_committee_period_at_slot(block.slot)
    attested_period = compute_sync_committee_period_at_slot(state.latest_block_header.slot)

    # Track sync committee finality
    old_has_sync_committee_finality = state.parent_block_has_sync_committee_finality
    if state.parent_block_has_sync_committee_finality:
        new_has_sync_committee_finality = True
    elif state.finalized_checkpoint.epoch < ALTAIR_FORK_EPOCH:
        new_has_sync_committee_finality = False
    else:
        finalized_period = compute_sync_committee_period(state.finalized_checkpoint.epoch)
        new_has_sync_committee_finality = (finalized_period == attested_period)
    state.parent_block_has_sync_committee_finality = new_has_sync_committee_finality

    # Track best sync data
    if attested_period == signature_period:
        max_active_participants = len(block.body.sync_aggregate.sync_committee_bits)
        new_num_active_participants = sum(block.body.sync_aggregate.sync_committee_bits)
        old_num_active_participants = sum(state.current_best_sync_data.sync_aggregate.sync_committee_bits)
        new_has_supermajority = new_num_active_participants * 3 >= max_active_participants * 2
        old_has_supermajority = old_num_active_participants * 3 >= max_active_participants * 2
        if new_has_supermajority != old_has_supermajority:
            is_better_sync_data = new_has_supermajority
        elif not new_has_supermajority and new_num_active_participants != old_num_active_participants:
            is_better_sync_data = new_num_active_participants > old_num_active_participants
        elif new_has_sync_committee_finality != old_has_sync_committee_finality:
            is_better_sync_data = new_has_sync_committee_finality
        elif new_num_active_participants != old_num_active_participants:
            is_better_sync_data = new_num_active_participants > old_num_active_participants
        else:
            is_better_sync_data = block.slot < state.current_best_sync_data.signature_slot
        if is_better_sync_data:
            state.current_best_sync_data = SyncData(
                sync_aggregate=block.body.sync_aggregate,
                signature_slot=block.slot,
            )
```

## Rationale

### How to rank `SyncAggregate`?

The EIP reuses the [`is_better_update`](https://github.com/ethereum/consensus-specs/blob/4afe39822c9ad9747e0f5635cca117c18441ec1b/specs/altair/light-client/sync-protocol.md#is_better_update) function from existing specs.

To ensure deterministic selection when participation and finality are equal, implementations MUST break ties by preferring the lower `signature_slot`; if equal, the existing selection SHOULD be retained.

### How could a backfill protocol use this?

Once the data is available in the `BeaconState`, a light client data backfill protocol could be defined that serves, for past periods:

1. A `LightClientUpdate` from requested `period` + 1 that proves that the entirety of `period` is finalized.
2. `BeaconState.historical_summaries[period].block_summary_root` at (1)'s `attested_header.beacon.state_root` + Merkle proof.
3. For each epoch's slot 0 block within requested `period`, the corresponding `LightClientHeader` + Merkle multi-proof for the block's inclusion into (2)'s `block_summary_root`.
4. For each of the entries from (3) with `beacon.slot` within `period`, the `current_sync_committee_branch` + Merkle proof for constructing `LightClientBootstrap`.
5. If (4) is not empty, the requested `period`'s `current_sync_committee`.
6. The best `LightClientUpdate` from `period`, if one exists, + Merkle proof that its `sync_aggregate` + `signature_slot` is selected as the canonical best one in (1)'s `attested_header.beacon.state_root`.

Only the proof in (6) depends on `BeaconState` tracking the best light client data. This modification would enshrine the logic of a subset of `is_better_update`, but does not require adding any `LightClientXyz` data structures to the `BeaconState`.

## Backwards Compatibility

This EIP requires a hard fork as it introduces new consensus validation rules.

Only light client data following the hard fork can be proven to be canonical and optimal. However, after finalization of the fork transition block, earlier light client data can no longer change and could be locked in using a hash.

## Security Considerations

None

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
