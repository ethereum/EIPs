---
title: Align Checkpoint with Epoch Boundary Block
description: Resolve FFG checkpoints to the last block before the epoch instead of the first block of the epoch
author: Cayman (@wemeetagain), Nico Flaig (@nflaig), Lodekeeper (@lodekeeper)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2026-07-06
---

## Abstract

Anchor the Casper FFG checkpoint for epoch `N` to the epoch boundary block, the last block before epoch `N`, rather than the first block of epoch `N`. A new accessor `get_checkpoint_root` replaces `get_block_root` wherever targets and checkpoints are resolved. Checkpoint epochs are unchanged; only the block root a checkpoint maps to moves.

## Motivation

Every attestation carries an FFG target vote naming a checkpoint `(epoch, root)`. Today the root for epoch `N` is the block at the epoch's first slot, and every attestation in epoch `N` names this same target. Committees in later slots know the target by the time they vote, but the first slot's committee must vote one third of a slot after the target block itself is proposed. If the block arrives late, some of those attesters vote for it while others vote for the previous block. Only one of the two matches the checkpoint the chain settles on; the other votes are lost to justification, and their attesters forfeit target rewards. The effect is systematic and measurable: on the live network, target-vote misses concentrate in the first slot of each epoch, with roughly `1/SLOTS_PER_EPOCH` of FFG weight exposed every epoch.

This EIP instead anchors the checkpoint for epoch `N` to the boundary block, the last block before epoch `N`. The target is then fixed before the epoch begins, so no block produced during epoch `N` can change it. The earliest committee gains more than a full slot of propagation margin, up from a third of a slot.

The current anchoring is also a long-standing off-by-one rather than a deliberate design decision (ethereum/consensus-specs issues 2174 and 652), and it makes finalization semantics misleading. "Epoch `N` finalized" today means only that the first block of epoch `N` is finalized; the rest of the epoch's blocks can still be reorged. Under this proposal a checkpoint for epoch `N` names the chain through the end of epoch `N - 1`, so finalizing it finalizes whole epochs, nothing more and nothing less. Explorers and tooling that report finality per epoch become accurate.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Execution layer

This requires no changes to the execution layer.

### Consensus layer

#### New `get_checkpoint_root`

`get_checkpoint_root(state, epoch)` returns the root of the boundary block anchoring the checkpoint for `epoch`: the last block before the epoch begins. In a healthy network this is the last block of the previous epoch; if the previous epoch's trailing slots are empty, it is an earlier block. The genesis epoch, which has no previous epoch, resolves to the genesis block.

```python
def get_checkpoint_root(state: BeaconState, epoch: Epoch) -> Root:
    """
    Return the block root anchoring the checkpoint for ``epoch`` -- the last
    block before ``epoch`` (the epoch boundary).
    """
    if epoch == GENESIS_EPOCH:
        return get_block_root_at_slot(state, GENESIS_SLOT)
    return get_block_root_at_slot(state, Slot(compute_start_slot_at_epoch(epoch) - 1))
```

#### Modified functions

The following functions resolve checkpoint roots via `get_checkpoint_root(state, epoch)` instead of `get_block_root(state, epoch)`:

- `get_attestation_participation_flag_indices`: the matching-target check compares `data.target.root` against `get_checkpoint_root(state, data.target.epoch)`. Source and head matching and the timeliness conditions are unchanged.
- `weigh_justification_and_finalization`: newly recorded justified checkpoints take their `root` from `get_checkpoint_root`. The justification bits and finalization rules are unchanged.

#### Fork choice

`get_checkpoint_block(store, root, epoch)` resolves the checkpoint to the ancestor at slot `compute_start_slot_at_epoch(epoch) - 1`, or at the genesis slot for the genesis epoch. Its consumers (`on_attestation` validation, `filter_block_tree`, and the gossip conditions on the target block) need no further changes.

#### Honest validator

The FFG target is set to `Checkpoint(epoch=get_current_epoch(head_state), root=get_checkpoint_root(head_state, get_current_epoch(head_state)))`. The source vote is unchanged. The validator guide's special case for the first slot of the epoch, where the head block itself is the target, is removed.

#### Fork transition

`get_checkpoint_root` and `get_checkpoint_block` MUST resolve epochs before the activation epoch via `compute_start_slot_at_epoch(epoch)`, i.e. under the previous anchoring. This is required for correctness:

- Checkpoints recorded before activation use the previous anchoring. `filter_block_tree` requires the finalized checkpoint root to match `get_checkpoint_block` on every viable branch. Re-resolving the finalized epoch under the new rule breaks this match, and with it head computation, until a post-activation checkpoint is finalized.
- Attestations with pre-activation target epochs remain includable for an epoch after activation. Evaluating them under the previous anchoring preserves their validity and rewards.

## Rationale

The boundary block, run through the state transition function, deterministically yields the chain state at the start of the epoch, since no blocks follow it before the epoch begins. It is also fixed before the epoch begins; any later choice would depend on the epoch's own block production.

Keeping the checkpoint epoch and moving only the root confines the change to a single question, which block anchors an epoch. Slashing conditions, justification bits, and finalization rules are untouched, and no containers change, so serialization, gossip formats, and slashing-protection databases are unaffected.

`get_block_root(state, epoch)` already returns the boundary block when the epoch's first slot is empty. This proposal makes that resolution the rule rather than the fallback; behavior changes only when a block occupies the epoch's first slot. The genesis epoch, which has no block before it, resolves to the genesis block, as today.

## Backwards Compatibility

This EIP introduces backwards-incompatible changes to the consensus layer and must be accompanied by a hard fork. The fork transition rule in the Specification handles attestations that cross the fork boundary.

Tooling that assumes a checkpoint root names a block at an epoch's first slot, such as checkpoint sync providers and consumers, must be updated.

## Test Cases

- With blocks at both the last slot of epoch `N - 1` and the first slot of epoch `N`, `get_checkpoint_root(state, N)` returns the boundary block and differs from `get_block_root(state, N)`.
- With the first slot of epoch `N` empty, `get_checkpoint_root(state, N)` equals `get_block_root(state, N)`.
- With the last slot of epoch `N - 1` empty, or epoch `N - 1` entirely empty, `get_checkpoint_root(state, N)` returns the most recent earlier block.
- `get_checkpoint_root(state, GENESIS_EPOCH)` returns the genesis block root.
- An attestation targeting the boundary block receives the target participation flag; one targeting the epoch's first block does not.
- Justification and finalization vectors where boundary-anchored target votes justify and finalize epochs, recording checkpoint roots equal to `get_checkpoint_root` output.
- `on_attestation` accepts targets naming the boundary block and rejects targets naming the epoch's first block.
- With branches diverging at the epoch boundary, `get_checkpoint_block` resolves a different boundary block on each branch, and an attestation validates only against the target of its own branch.
- Fork transition vectors: attestations with pre-activation target epochs keep their validity and rewards after activation, and `filter_block_tree` continues to find viable branches while the finalized checkpoint predates activation.

## Security Considerations

FFG safety is unaffected: justification, finalization, and slashing operate on checkpoint epochs, which do not change.

The remaining attack surface is a maliciously late boundary block, which can still split the next epoch's first-slot target votes. This is the same attack that late first-slot blocks enable today, made strictly harder: the propagation margin grows from a third of a slot to over a full slot. Withholding the boundary block outright achieves nothing, since the target falls back to an earlier, already-propagated block.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
