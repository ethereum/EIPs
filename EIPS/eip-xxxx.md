---
eip: xxxx
title: RAF - Reduced Attestation Format
description: <Description is one full (short) sentence>
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/reduced-attestation-format-for-gossiping-attestations/19458
status: Draft
type: Standards Track
category: Core
created: 2024-03-31
---

## Abstract

This EIP introduces a reduced version of the `Attestation`sformat to reduce the size of attestations transmitted on the Consensus Layer's gossip network. This is achieved by replacing Checkpoint objects in gossiped `AttestationData`s with their respective 8-byte digests.

## Motivation

Attestations currently dominate the bandwidth usage of the Consensus Layer's gossip network (approx. 90% of the traffic). By optimizing the size of `AttestationData`, the aim is to reduce network load to improve node performance, and, most importantly, allow for greater throughput of other significant consensus data, such as Blobs. As a matter of fact, the current `Attestation` structure is not optimized for network transmission, leading to unnecessarily high bandwidth consumption. As a matter of fact, the application of Snappy block compression only reduces the size of an attestation by less than 10%.


## Specification

### Constants

```
CHECKPOINT_DIGEST_LENGTH = 8
```

### Containers

```python
class ReducedSignedAggregateAndProof(Container):
    message: ReducedAggregateAndProof
    signature: BLSSignature
```

```python
class ReducedAggregateAndProof(Container):
    aggregator_index: ValidatorIndex
    aggregate: ReducedAttestation
    selection_proof: BLSSignature
```

```python
class ReducedAttestation(Container):
    aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    data: ReducedAttestationData
    signature: BLSSignature
```

```python
class ReducedAttestationData(Container):
    class AttestationData(Container):
    slot: Slot
    index: CommitteeIndex
    # LMD GHOST vote
    beacon_block_root: Root
    # FFG vote
    source_digest: ByteVector[CHECKPOINT_DIGEST_LENGTH]
    target_digest: ByteVector[CHECKPOINT_DIGEST_LENGTH]
```

### Gossipsub

Change the message format exchanged by the topics `beacon_attestation_{subnet_id}` and `beacon_aggregate_and_proof` in the following ways:
1) `beacon_attestation_{subnet_id}` now gossips `ReducedAttestation`s
2) Make the `beacon_aggregate_and_proof` now gossips `ReducedAggregateAndProof`s

Whenever an `Attestation` or `AggregateAndProof` needs to be published to gossipsub, Consensus Clients MUST  create the equivalent `Reduced` version by replacing the `source` and `target` with their correspondent digests:

```python
reduced_attestation_data.source_digest = attestation_data.source.hash_tree_root()[0:CHECKPOINT_DIGEST_LENGTH]
reduced_attestation_data.source_target = attestation_data.target.hash_tree_root()[0:CHECKPOINT_DIGEST_LENGTH]
```

Subsequently, Consensus Clients, as they sync up, MUST keep track of a cache, `Dict[ByteVector[CHECKPOINT_DIGEST_LENGTH], Checkpoint]` containing all checkpoints seen so far, in order to deduce `Attestation`s from `ReducedAttestation`s. Consensus Clients MAY also evict checkpoints older than the `FinalizedCheckpoint`. If the checkpoint digest has not been seen yet, then the `Attestation` MUST be ignored as a gossip rule.

Consensus Clients SHOULD insert checkpoints into the cache during epoch transitions, as that is where new checkpoints are generated.


## Rationale

The decision of introducing a cache stems from the fact that many consensus clients already maintain caches of checkpoints, implying that adapting to a system where checkpoints are referenced through digests would not significantly increase the protocol's complexity.

The choice to use 8 or 16 bytes for `CHECKPOINT_DIGEST_LENGTH` balances data efficiency with security. Considering Ethereum's slot timing, attackers have limited time to generate collisions. This constraint makes shorter digests practical, as the risk of collision within the short slot intervals is minimal. Hence, using the first few bytes of the hash as digests is efficient for network propagation without significantly increasing collision risk.

## Backwards Compatibility

Backward incompatible.

## Security Considerations

`CHECKPOINT_DIGEST_LENGTH` must not be too short, otherwise there are risks an attacker can feasably create a collision.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
