---
eip: 7657
title: Sync committee slashings
description: Slashing condition for malicious sync committee messages
author: Etan Kissling (@etan-status)
discussions-to: https://ethereum-magicians.org/t/eip-7657-sync-committee-slashings/19288
status: Stagnant
type: Standards Track
category: Core
created: 2024-03-21
---

## Abstract

This EIP defines a slashing condition for malicious [sync committee messages](https://github.com/ethereum/consensus-specs/blob/b3e83f6691c61e5b35136000146015653b22ed38/specs/altair/validator.md#containers).

## Motivation

A dishonest supermajority of sync committee members is able to convince applications relying on Ethereum's [light client sync protocol](https://github.com/ethereum/consensus-specs/blob/b3e83f6691c61e5b35136000146015653b22ed38/specs/altair/light-client/sync-protocol.md) to assume a non-canonical finalized header, and to potentially take over the sync authority for future `SyncCommitteePeriod`. By signing a malicious beacon block root, a malicious (but valid!) `LightClientUpdate` message can be formed and subsequently used to, for example, exploit a trust-minimized bridge contract based on the light client sync protocol.

An additional type of slashing is introduced to deter against signing non-canonical beacon block roots as a sync committee member. As is the case with [`ProposerSlashing`](https://github.com/ethereum/consensus-specs/blob/b3e83f6691c61e5b35136000146015653b22ed38/specs/phase0/beacon-chain.md#proposerslashing) and [`AttesterSlashing`](https://github.com/ethereum/consensus-specs/blob/b3e83f6691c61e5b35136000146015653b22ed38/specs/phase0/beacon-chain.md#attesterslashing), only malicious behaviour is slashable. This includes simultaneous contradictory participation across multiple chain branches, but a validator that is simply tricked into syncing to an incorrect checkpoint should not be slashable even though it is participating on a non-canonical chain. Note that a slashing must be verifiable even without access to history, e.g., by a checkpoint synced beacon node.

Note that regardless of the slashing mechanism, a slashing can only be applied retroactively after an attack has already occurred. Use cases that secure a larger amount than `SYNC_COMMITTEE_SIZE * MAX_EFFECTIVE_BALANCE` = `512 * 32 ETH` = `16384 ETH` (on mainnet) should combine the light client sync protocol with other established methods such as a multisig, or may want to require posting additional collateral to be eligible for submitting updates. Other methods are out of scope for this EIP.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### State transition checks

Note: This still allows having contradictions between attestations/proposals and sync committee messages. This also, by design, allows a validator to not participate at all in honest sync committee messages but solely participate in dishonest sync committee messages.

| Name | Value |
| - | - |
| `BLOCK_STATE_ROOT_INDEX` | `get_generalized_index(BeaconBlock, 'state_root')` (= 11) |
| `STATE_BLOCK_ROOTS_INDEX` | `get_generalized_index(BeaconState, 'block_roots')` (= 37) |
| `STATE_HISTORICAL_ROOTS_INDEX` | `get_generalized_index(BeaconState, 'historical_roots')` (= 39) |
| `HISTORICAL_BATCH_BLOCK_ROOTS_INDEX` | `get_generalized_index(HistoricalBatch, 'block_roots')` (= 2) |

```python
class SyncCommitteeSlashingEvidence(Container):
    attested_header: BeaconBlockHeader
    next_sync_committee: SyncCommittee
    next_sync_committee_branch: Vector[Root, floorlog2(NEXT_SYNC_COMMITTEE_INDEX)]
    finalized_header: BeaconBlockHeader
    finality_branch: Vector[Root, floorlog2(FINALIZED_ROOT_INDEX)]
    sync_aggregate: SyncAggregate
    signature_slot: Slot
    sync_committee_pubkeys: Vector[BLSPubkey, SYNC_COMMITTEE_SIZE]
    actual_finalized_block_root: Root
    actual_finalized_branch: List[Root, (
        floorlog2(BLOCK_STATE_ROOT_INDEX)
        + floorlog2(STATE_HISTORICAL_ROOTS_INDEX)
        + 1 + floorlog2(HISTORICAL_ROOTS_LIMIT)
        + floorlog2(HISTORICAL_BATCH_BLOCK_ROOTS_INDEX)
        + 1 + floorlog2(SLOTS_PER_HISTORICAL_ROOT))]

class SyncCommitteeSlashing(Container):
    slashable_validators: List[ValidatorIndex, SYNC_COMMITTEE_SIZE]
    evidence_1: SyncCommitteeSlashingEvidence
    evidence_2: SyncCommitteeSlashingEvidence
    recent_finalized_block_root: Root
    recent_finalized_slot: Slot

def sync_committee_slashing_evidence_has_sync_committee(evidence: SyncCommitteeSlashingEvidence) -> bool:
    return evidence.next_sync_committee_branch != [Root() for _ in range(floorlog2(NEXT_SYNC_COMMITTEE_INDEX))]

def sync_committee_slashing_evidence_has_finality(evidence: SyncCommitteeSlashingEvidence) -> bool:
    return evidence.finality_branch != [Root() for _ in range(floorlog2(FINALIZED_ROOT_INDEX))]

def is_valid_sync_committee_slashing_evidence(evidence: SyncCommitteeSlashingEvidence,
                                              recent_finalized_block_root: Root,
                                              recent_finalized_slot: Slot,
                                              genesis_validators_root: Root) -> bool:
    # Verify sync committee has sufficient participants
    sync_aggregate = evidence.sync_aggregate
    if sum(sync_aggregate.sync_committee_bits) < MIN_SYNC_COMMITTEE_PARTICIPANTS:
        return False

    # Verify that the `finality_branch`, if present, confirms `finalized_header`
    # to match the finalized checkpoint root saved in the state of `attested_header`.
    # Note that the genesis finalized checkpoint root is represented as a zero hash.
    if not sync_committee_slashing_evidence_has_finality(evidence):
        if evidence.actual_finalized_block_root != Root():
            return False
        if evidence.finalized_header != BeaconBlockHeader():
            return False
    else:
        if evidence.finalized_header.slot == GENESIS_SLOT:
            if evidence.actual_finalized_block_root != Root():
                return False
            if evidence.finalized_header != BeaconBlockHeader():
                return False
            finalized_root = Root()
        else:
            finalized_root = hash_tree_root(evidence.finalized_header)
        if not is_valid_merkle_branch(
            leaf=finalized_root,
            branch=evidence.finality_branch,
            depth=floorlog2(FINALIZED_ROOT_INDEX),
            index=get_subtree_index(FINALIZED_ROOT_INDEX),
            root=evidence.attested_header.state_root,
        ):
            return False

    # Verify that the `next_sync_committee`, if present, actually is the next sync committee saved in the
    # state of the `attested_header`
    if not sync_committee_slashing_evidence_has_sync_committee(evidence):
        if evidence.next_sync_committee != SyncCommittee():
            return False
    else:
        if not is_valid_merkle_branch(
            leaf=hash_tree_root(evidence.next_sync_committee),
            branch=evidence.next_sync_committee_branch,
            depth=floorlog2(NEXT_SYNC_COMMITTEE_INDEX),
            index=get_subtree_index(NEXT_SYNC_COMMITTEE_INDEX),
            root=evidence.attested_header.state_root,
        ):
            return False

    # Verify that the `actual_finalized_block_root`, if present, is confirmed by `actual_finalized_branch`
    # to be the block root at slot `finalized_header.slot` relative to `recent_finalized_block_root`
    if recent_finalized_block_root == Root():
        if evidence.actual_finalized_block_root != Root():
            return False
    if evidence.actual_finalized_block_root == Root():
        if len(evidence.actual_finalized_branch) != 0:
            return False
    else:
        finalized_slot = evidence.finalized_header.slot
        if recent_finalized_slot < finalized_slot:
            return False
        distance = recent_finalized_slot - finalized_slot
        if distance == 0:
            gindex = GeneralizedIndex(1)
        else:
            gindex = BLOCK_STATE_ROOT_INDEX
            if distance <= SLOTS_PER_HISTORICAL_ROOT:
                gindex = (gindex << floorlog2(STATE_BLOCK_ROOTS_INDEX)) + STATE_BLOCK_ROOTS_INDEX
            else:
                gindex = (gindex << floorlog2(STATE_HISTORICAL_ROOTS_INDEX)) + STATE_HISTORICAL_ROOTS_INDEX
                gindex = (gindex << uint64(1)) + 0  # `mix_in_length`
                historical_batch_index = finalized_slot // SLOTS_PER_HISTORICAL_ROOT
                gindex = (gindex << floorlog2(HISTORICAL_ROOTS_LIMIT)) + historical_batch_index
                gindex = (gindex << floorlog2(HISTORICAL_BATCH_BLOCK_ROOTS_INDEX)) + HISTORICAL_BATCH_BLOCK_ROOTS_INDEX
            gindex = (gindex << uint64(1)) + 0  # `mix_in_length`
            block_root_index = finalized_slot % SLOTS_PER_HISTORICAL_ROOT
            gindex = (gindex << floorlog2(SLOTS_PER_HISTORICAL_ROOT)) + block_root_index
        if len(evidence.actual_finalized_branch) != floorlog2(gindex):
            return False
        if not is_valid_merkle_branch(
            leaf=evidence.actual_finalized_block_root,
            branch=evidence.actual_finalized_branch,
            depth=floorlog2(gindex),
            index=get_subtree_index(gindex),
            root=recent_finalized_block_root,
        ):
            return False

    # Verify sync committee aggregate signature
    sync_committee_pubkeys = evidence.sync_committee_pubkeys
    participant_pubkeys = [
        pubkey for (bit, pubkey) in zip(sync_aggregate.sync_committee_bits, sync_committee_pubkeys)
        if bit
    ]
    fork_version = compute_fork_version(compute_epoch_at_slot(evidence.signature_slot))
    domain = compute_domain(DOMAIN_SYNC_COMMITTEE, fork_version, genesis_validators_root)
    signing_root = compute_signing_root(evidence.attested_header, domain)
    return bls.FastAggregateVerify(participant_pubkeys, signing_root, sync_aggregate.sync_committee_signature)

def process_sync_committee_slashing(state: BeaconState, sync_committee_slashing: SyncCommitteeSlashing) -> None:
    is_slashable = False

    # Check that evidence is ordered descending by `attested_header.slot` and is not from the future
    evidence_1 = sync_committee_slashing.evidence_1
    evidence_2 = sync_committee_slashing.evidence_2
    assert state.slot >= evidence_1.signature_slot > evidence_1.attested_header.slot >= evidence_1.finalized_header.slot
    assert state.slot >= evidence_2.signature_slot > evidence_2.attested_header.slot >= evidence_2.finalized_header.slot
    assert evidence_1.attested_header.slot >= evidence_2.attested_header.slot

    # Only conflicting data among the current and previous sync committee period is slashable;
    # on new periods, the sync committee initially signs blocks in a previous sync committee period.
    # This allows a validator synced to a malicious checkpoint to contribute again in a future period
    evidence_1_attested_period = compute_sync_committee_period_at_slot(evidence_1.attested_header.slot)
    evidence_2_attested_period = compute_sync_committee_period_at_slot(evidence_2.attested_header.slot)
    assert evidence_1_attested_period <= evidence_2_attested_period + 1

    # It is not allowed to sign conflicting `attested_header` for a given slot
    if evidence_1.attested_header.slot == evidence_2.attested_header.slot:
        if evidence_1.attested_header != evidence_2.attested_header:
            is_slashable = True

    # It is not allowed to sign conflicting finalized `next_sync_committee`
    evidence_1_finalized_period = compute_sync_committee_period_at_slot(evidence_1.finalized_header.slot)
    evidence_2_finalized_period = compute_sync_committee_period_at_slot(evidence_2.finalized_header.slot)
    if (
        evidence_1_attested_period == evidence_2_attested_period
        and evidence_1_finalized_period == evidence_1_attested_period
        and evidence_2_finalized_period == evidence_2_attested_period
        and sync_committee_slashing_evidence_has_finality(evidence_1)
        and sync_committee_slashing_evidence_has_finality(evidence_2)
        and sync_committee_slashing_evidence_has_sync_committee(evidence_1)
        and sync_committee_slashing_evidence_has_sync_committee(evidence_2)
    ):
        if evidence_1.next_sync_committee != evidence_2.next_sync_committee:
            is_slashable = True

    # It is not allowed to sign a non-linear finalized history
    recent_finalized_slot = sync_committee_slashing.recent_finalized_slot
    recent_finalized_block_root = sync_committee_slashing.recent_finalized_block_root
    if (
        not sync_committee_slashing_evidence_has_finality(evidence_1)
        or not sync_committee_slashing_evidence_has_finality(evidence_2)
    ):
        assert recent_finalized_block_root == Root()
    if recent_finalized_block_root == Root():
        assert recent_finalized_slot == 0
    else:
        # Merkle proofs may be included to indicate that `finalized_header` does not match
        # the `actual_finalized_block_root` relative to a given `recent_finalized_block_root`.
        # The finalized history is linear. Therefore, a mismatch indicates signing on an unrelated chain.
        # Note that it is not slashable to sign solely an alternate history, as long as it is consistent.
        # This allows a validator synced to a malicious checkpoint to contribute again in a future period
        linear_1 = (evidence_1.actual_finalized_block_root == hash_tree_root(evidence_1.finalized_header))
        linear_2 = (evidence_2.actual_finalized_block_root == hash_tree_root(evidence_2.finalized_header))
        assert not linear_1 or not linear_2
        assert linear_1 or linear_2  # Do not slash on signing solely an alternate history

        # `actual_finalized_branch` may be rooted in the provided `finalized_header` with highest slot
        rooted_in_evidence_1 = (
            evidence_1.finalized_header.slot >= evidence_2.finalized_header.slot
            and recent_finalized_slot == evidence_1.finalized_header.slot
            and recent_finalized_block_root == evidence_1.actual_finalized_block_root and linear_1
        )
        rooted_in_evidence_2 = (
            evidence_2.finalized_header.slot >= evidence_1.finalized_header.slot
            and recent_finalized_slot == evidence_2.finalized_header.slot
            and recent_finalized_block_root == evidence_2.actual_finalized_block_root and linear_2
        )

        # Alternatively, if evidence about non-linearity cannot be obtained directly from an attack,
        # it can be proven that one of the `finalized_header` is part of the canonical finalized chain
        # that our beacon node is synced to, while the other `finalized_header` is unrelated.
        rooted_in_canonical = (
            recent_finalized_slot < state.slot <= recent_finalized_slot + SLOTS_PER_HISTORICAL_ROOT
            and recent_finalized_slot <= compute_start_slot_at_epoch(state.finalized_checkpoint.epoch)
            and recent_finalized_block_root == state.block_roots[recent_finalized_slot % SLOTS_PER_HISTORICAL_ROOT]
        )
        assert rooted_in_evidence_1 or rooted_in_evidence_2 or rooted_in_canonical
        is_slashable = True

    assert is_slashable

    # Check that slashable validators are sorted, known, and participated in both signatures
    will_slash_any = False
    sync_aggregate_1 = evidence_1.sync_aggregate
    sync_aggregate_2 = evidence_2.sync_aggregate
    sync_committee_pubkeys_1 = evidence_1.sync_committee_pubkeys
    sync_committee_pubkeys_2 = evidence_2.sync_committee_pubkeys
    participant_pubkeys_1 = [
        pubkey for (bit, pubkey) in zip(sync_aggregate_1.sync_committee_bits, sync_committee_pubkeys_1)
        if bit
    ]
    participant_pubkeys_2 = [
        pubkey for (bit, pubkey) in zip(sync_aggregate_2.sync_committee_bits, sync_committee_pubkeys_2)
        if bit
    ]
    slashable_validators = sync_committee_slashing.slashable_validators
    num_validators = len(state.validators)
    for i, index in enumerate(slashable_validators):
        assert (
            index < num_validators
            and (i == 0 or index > slashable_validators[i - 1])
        )
        assert state.validators[index].pubkey in participant_pubkeys_1
        assert state.validators[index].pubkey in participant_pubkeys_2
        if is_slashable_validator(state.validators[index], get_current_epoch(state)):
            will_slash_any = True
    assert will_slash_any

    # Validate evidence, including signatures
    assert is_valid_sync_committee_slashing_evidence(
        evidence_1,
        recent_finalized_block_root,
        recent_finalized_slot,
        state.genesis_validators_root,
    )
    assert is_valid_sync_committee_slashing_evidence(
        evidence_2,
        recent_finalized_block_root,
        recent_finalized_slot,
        state.genesis_validators_root,
    )

    # Perform slashing
    for index in slashable_validators:
        if is_slashable_validator(state.validators[index], get_current_epoch(state)):
            slash_validator(state, index)
```

## Rationale

### What's the use case?

Without a slashing, the light client sync protocol is somewhat limited. While wallet applications may benefit from it (the risk being, that incorrect data is displayed) and new beacon nodes may use it for accelerating chain synchronization, other interesting use cases such as bridges, token distributions or other systems requiring proofs depend on the mechanism providing higher security guarantees.

By making attacks by sync committee members slashable, a sufficiently high deterrent could be provided. A majority of the sync committee would have to be bribed to succeed in an attack even in the most simple cases, representing a sizable slashable balance.

## Backwards Compatibility

This EIP requires a hard fork as it introduces new consensus validation rules.

Supporting infrastructure may be introduced separately once the consensus validation rules are in place, including but not limited to:

- Slashing protection DB updates, to guarantee that honest validators cannot be slashed on reorgs
- Validator client / remote signer APIs, to pass along information related to slashing protection
- libp2p meshes for exchanging slashing evidence between beacon nodes
- Slasher, to monitor potential targets and construct slashing evidence
- Beacon APIs, to submit and monitor slashing evidence

## Test Cases

TBD

## Reference Implementation

TBD

## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
