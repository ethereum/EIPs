---
eip: TBD
title: Fallback Proposers
description: Enable IL committee members to propose fallback blocks when the designated proposer is offline
author: Thomas Thiery (@soispoke) <thomas.thiery@ethereum.org>
discussions-to: https://ethereum-magicians.org/t/eip-focil-fallback-block-proposers/TBD
status: Draft
type: Standards Track
category: Core
created: 2025-01-16
requires: 7805, 7732
---

## Abstract

This EIP extends FOCIL ([EIP-7805](./eip-7805.md)) and ePBS ([EIP-7732](./eip-7732.md)) with a fallback proposer mechanism. If the designated proposer for slot `S` does not produce a beacon block by a deadline, a deterministically chosen IL committee member from slot `S-1` is additionally authorized to propose a beacon block for slot `S`.

FOCIL inclusion-list satisfaction for fallback blocks is enforced the same way as for designated blocks: payloads that fail IL satisfaction remain state-transition valid but lose fork-choice support once the payload is available, causing them to be reorged in favor of IL-satisfying alternatives.

## Motivation

FOCIL enables a committee of validators to force-include transactions via fork-choice enforced inclusion lists. However, FOCIL assumes the proposer will show up. If a proposer is offline or intentionally misses their slot, IL transactions remain unincluded despite the IL committee having done their job.

This creates a censorship vector: a proposer can be bribed to skip their slot, or coordinated proposer absence can systematically delay IL transactions. This EIP closes that gap by enabling a fallback proposer when the designated proposer is absent.

## Dependencies

This EIP requires three specifications to be active in the same fork:

| Dependency | Description |
|------------|-------------|
| [EIP-7805](./eip-7805.md) (FOCIL) | Inclusion lists, IL committee, view-freeze timing |
| [EIP-7732](./eip-7732.md) (ePBS) | Bids, payload envelopes, PTC, proposer boost |
| FOCIL×ePBS integration | Extends `ExecutionPayloadBid` with `inclusion_list_bits`; defines payload-level IL satisfaction tracking |

**Terminology**: "FOCIL×ePBS" in this document refers to the combined fork specification that merges EIP-7805 and EIP-7732.

## Specification

### Constants

| Name | Value | Description |
|------|-------|-------------|
| `FALLBACK_PROPOSER_DEADLINE` | TBD | Time after slot start when fallback blocks may be gossiped |

The deadline value must satisfy two constraints:
- **Upper bound**: Fallback block must have time to propagate before `get_attestation_due_ms()`
- **Lower bound**: Designated proposer must have priority; should exceed typical block propagation time

The concrete value should be determined once ePBS timing parameters are finalized.

### Design Summary

| Aspect | Approach |
|--------|----------|
| **Selection** | Fallback proposer computed purely from `BeaconState` (deterministic) |
| **Consensus** | Blocks valid if proposed by designated OR fallback proposer |
| **Networking** | Fallback blocks gossip-gated until `FALLBACK_PROPOSER_DEADLINE` |
| **Fork choice** | Proposer boost unchanged (fallback blocks not boosted) |
| **FOCIL** | Two-phase IL enforcement per FOCIL×ePBS (see below) |

### IL Enforcement (FOCIL×ePBS)

IL satisfaction is enforced in two phases:

**Phase 1 - IL Inclusivity Check (PTC, slot S):**
The FOCIL×ePBS integration extends `ExecutionPayloadBid` with:

```python
class ExecutionPayloadBid(Container):
    # ... base fields ...
    inclusion_list_bits: Bitvector[INCLUSION_LIST_COMMITTEE_SIZE]  # FOCIL×ePBS extension
```

Each bit corresponds to an IL committee position in slot `S-1` and signals that the builder claims to have considered that IL when constructing the payload. The **Payload Timeliness Committee (PTC)** checks this bitlist against their local IL view when voting on payload timeliness. This is a fast, local check performed within slot `S`.

**Phase 2 - Full IL Satisfaction (Attesters, slot S+1):**
Full IL satisfaction requires inspecting the actual payload contents, which is only possible after the payload is revealed. **Attesters of slot `S+1`** verify that the payload for slot `S` actually includes the required IL transactions (or that valid exemptions apply). Payloads that fail this check lose fork-choice support: attesters build on the parent block instead, causing the non-satisfying block to be reorged.

### Fallback Proposer Selection

The fallback proposer for slot `S` is the first IL committee member from slot `S-1` whose validator index differs from the designated proposer:

```python
def get_fallback_proposer(state: BeaconState, slot: Slot) -> Optional[ValidatorIndex]:
    """
    Returns the fallback proposer for the given slot, or None if no fallback exists.
    Selection is purely state-derived (no dependency on observed equivocations).
    """
    previous_slot = Slot(slot - 1)
    il_committee = get_inclusion_list_committee(state, previous_slot)
    designated = get_beacon_proposer_index(state, slot)

    for validator_index in il_committee:
        if validator_index != designated:
            return validator_index

    return None  # Possible in very small validator sets
```

### Consensus Validity Change

A block for slot `S` is proposer-valid if proposed by either the designated or fallback proposer:

```python
def is_valid_block_proposer(state: BeaconState, block: BeaconBlock) -> bool:
    """
    Returns True if block.proposer_index is authorized to propose for block.slot.
    """
    designated = get_beacon_proposer_index(state, block.slot)
    if block.proposer_index == designated:
        return True

    fallback = get_fallback_proposer(state, block.slot)
    return fallback is not None and block.proposer_index == fallback
```

### Actual Block Proposer Helper

After `process_block_header`, the actual block proposer is available via:

```python
def get_current_block_proposer_index(state: BeaconState) -> ValidatorIndex:
    """
    Returns the proposer of the block currently being processed.
    Only valid after process_block_header has executed.
    """
    return state.latest_block_header.proposer_index
```

### Modifications to Existing Functions

#### `process_block_header`

**Replace:**
```python
assert block.proposer_index == get_beacon_proposer_index(state)
```

**With:**
```python
assert is_valid_block_proposer(state, block)
```

#### `process_randao`

**Replace:**
```python
proposer = state.validators[get_beacon_proposer_index(state)]
```

**With:**
```python
proposer = state.validators[get_current_block_proposer_index(state)]
```

#### `process_attestation` (reward attribution)

**Replace:**
```python
increase_balance(state, get_beacon_proposer_index(state), proposer_reward)
```

**With:**
```python
increase_balance(state, get_current_block_proposer_index(state), proposer_reward)
```

#### Other Proposer-Dependent Functions

The same pattern applies to:
- `process_sync_aggregate`: proposer reward for sync committee inclusion
- `process_attester_slashing`: proposer reward for slashing inclusion
- `process_proposer_slashing`: proposer reward for slashing inclusion

### Fallback Block Constraints

Fallback blocks are ordinary beacon blocks, distinguished only by `proposer_index`.

| Requirement | Level | Description |
|-------------|-------|-------------|
| FOCIL satisfaction | SHOULD | Select payloads satisfying IL constraints for slot `S-1` |
| Additional transactions | MAY | Include non-IL transactions |
| Consensus contents | MUST | Include attestations, slashings, etc. as required |

### Builder Market Constraints

Under ePBS p2p validation:
- `SignedProposerPreferences` are accepted only for validators in `state.proposer_lookahead` (designated proposers)
- `SignedExecutionPayloadBid` requires a matching previously-seen preference for that slot

**Consequence**: Fallback proposers cannot participate in the gossip-based builder market. They will typically **self-build**.

### Self-Build Bid Construction

```python
def create_self_build_bid(
    state: BeaconState,
    block: BeaconBlock,
    payload: ExecutionPayload,
    blob_kzg_commitments: List[KZGCommitment],
    il_bits: Bitvector[INCLUSION_LIST_COMMITTEE_SIZE],
    fee_recipient: ExecutionAddress,
) -> SignedExecutionPayloadBid:
    """
    Create a self-build bid per ePBS conventions.

    Note: process_execution_payload_bid checks bid.parent_block_hash == state.latest_block_hash
    and bid.prev_randao == get_randao_mix(state, get_current_epoch(state)).
    """
    bid = ExecutionPayloadBid(
        slot=block.slot,
        parent_block_hash=state.latest_block_hash,
        parent_block_root=block.parent_root,
        block_hash=payload.block_hash,
        builder_index=BUILDER_INDEX_SELF_BUILD,
        value=Gwei(0),
        execution_payment=Gwei(0),
        prev_randao=get_randao_mix(state, get_current_epoch(state)),
        fee_recipient=fee_recipient,
        gas_limit=payload.gas_limit,
        blob_kzg_commitments_root=hash_tree_root(blob_kzg_commitments),
        inclusion_list_bits=il_bits,
    )
    return SignedExecutionPayloadBid(message=bid, signature=bls.G2_POINT_AT_INFINITY)
```

### Timeline

Let `t0 = slot_start_time(S)`.

**Slot S-1:**
- IL committee gossips inclusion lists
- Validators freeze IL view at `t0 - SECONDS_PER_SLOT + VIEW_FREEZE_DEADLINE`

**Slot S:**
| Time | Event |
|------|-------|
| `t0` | Designated proposer may broadcast beacon block |
| `t0 + FALLBACK_PROPOSER_DEADLINE` | Fallback proposer may broadcast beacon block |
| `t0 + get_attestation_due_ms()` | Attesters vote on beacon block |
| `t0 + get_payload_attestation_due_ms()` | PTC votes on payload (checks IL bitlist inclusivity) |

**Slot S+1:**
| Time | Event |
|------|-------|
| `t1` | Attesters verify full IL satisfaction for slot S payload |

### Gossip Validation

Gossip validation MUST accept blocks from either authorized proposer and MUST reject fallback blocks received before the deadline.

```python
def validate_beacon_block_gossip(block: SignedBeaconBlock) -> bool:
    # Derive state for validation
    parent_state = get_post_state(block.message.parent_root)
    state = process_slots(copy(parent_state), block.message.slot)

    # Check proposer authorization
    if not is_valid_block_proposer(state, block.message):
        return False

    designated = get_beacon_proposer_index(state, block.message.slot)
    if block.message.proposer_index == designated:
        return validate_remaining_gossip_conditions(block)

    # Fallback proposer: deadline gating
    slot_start = slot_start_time(block.message.slot)
    if current_time() < slot_start + FALLBACK_PROPOSER_DEADLINE:
        return False

    return validate_remaining_gossip_conditions(block)
```

**Important**: Deadline gating is gossip-only. Historical sync MUST accept fallback blocks regardless of original broadcast time.

### Fork Choice

This EIP does not modify proposer boost:
- Only designated proposer blocks set `store.proposer_boost_root`
- Fallback blocks do not receive proposer boost
- Fallback blocks compete via LMD-GHOST attestation weight

A fallback block arriving first does NOT prevent a later designated block from receiving boost.

### Slashing

This EIP introduces no new slashing conditions. Fallback proposers are slashable only under existing proposer-slashing rules (signing two blocks for the same slot).

## Rationale

### Why IL Committee Member as Fallback?

IL committee members have the IL data and are invested in inclusion. Selection by committee position is deterministic and requires no new infrastructure.

### Why State-Derived Selection?

Consensus validity must be deterministic and computable from `BeaconState` alone. Using fork-choice store data (e.g., equivocation tracking) would make validity depend on gossip observations.

### Why Gossip-Level Deadline Gating?

Block validity cannot depend on receipt time (subjective). Deadline gating at the gossip layer prevents early fallback propagation while allowing historical sync.

### Why No Proposer Boost for Fallback?

`update_proposer_boost_root` checks `block.proposer_index == get_beacon_proposer_index(head_state)`. Modifying it for fallback would require subjective "no timely designated block" checks. Fallback blocks work without boost because they're typically the only candidate when the designated proposer is absent.

### Why Self-Build?

Fallback proposers cannot broadcast `SignedProposerPreferences` (validated against designated schedule), so builders cannot submit bids via gossip. Self-build avoids modifying ePBS p2p validation.

## Backwards Compatibility

This EIP requires FOCIL, ePBS, and the FOCIL×ePBS integration to be implemented.

**Changes:**
- **Consensus**: Modified proposer validity; proposer-dependent processing uses actual block proposer
- **Fork choice**: Unchanged (fallback blocks not boosted)
- **P2P**: Modified proposer check; deadline gating for fallback blocks

No new fields are added to beacon blocks.

## Security Considerations

### Consensus Safety

- **Deterministic selection**: All nodes compute the same fallback proposer from `BeaconState`
- **Objective validity**: Block validity depends only on state-derivable properties
- **Correct processing**: RANDAO verification and rewards use actual block proposer

### Liveness

- **Single fallback**: If both designated and fallback are offline, slot is skipped (probability ≈ 10⁻⁴ at 1% offline rate)
- **EMPTY slot risk**: Fallback proposers who fail to reveal envelopes convert skips into EMPTY slots, deferring withdrawals

**Mitigation**: Fallback proposers SHOULD only broadcast if they can ensure envelope revelation (i.e., self-build).

### RANDAO

With fallback, the designated proposer can choose between "propose late" or "let fallback win," allowing the chain to choose between two RANDAO reveals. This is analogous to existing "propose vs skip" optionality and does not meaningfully worsen RANDAO grinding.

### Slot-Stealing Incentives

| Disincentive | Strength |
|--------------|----------|
| Deadline gating (fewer attestations) | Medium |
| No proposer boost | Strong |
| Must self-build (no MEV infrastructure) | Strong |
| Compressed MEV window | Medium |

Under normal conditions, slot-stealing is disincentivized.

### DoS

A malicious fallback proposer can broadcast after the deadline even if a designated block exists. Impact is bounded: at most one extra block per slot from a known validator, and fork-choice prefers the boosted designated block.

## Reference Implementation

A reference implementation will extend the consensus-specs repository with the modifications listed above plus a validator guide for fallback proposer duties.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
