---
eip: 7862
title: Delayed State Root
description: Separate state root computation from block validation
author: Charlie Noyes <charlie@paradigm.xyz>, Dan Robinson <dan@paradigm.xyz>, Justin Drake <justin@ethereum.org>, Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/eip-7862-delayed-execution-layer-state-root/22559
status: Draft
type: Standards Track
category: Core
created: 2024-12-23
---

## Abstract

This proposal decouples state root computation from block validation by deferring the execution layer's state root reference by one block. Each block's header contains the post-state root of the previous block rather than its own. Validators can attest to block validity without waiting for state root computation.

## Motivation

State root computation is a significant bottleneck in block production. With [EIP-7732](./eip-7732.md) (ePBS), builders have tighter timing constraints. [EIP-7928](./eip-7928.md) (Block-Level Access Lists) enables parallel state access but doesn't help with state root computation for builders.

With delayed state roots:

1. **Builders compute one state root per slot** (for the previous block) instead of thousands during the MEV auction window
2. **State root computation can use BAL data** from the previous block to parallelize proof generation
3. **The critical path shifts**: state root computation is frontloaded to the beginning of the slot rather than blocking attestations

The state root in block `n` represents the post-state of block `n-1` (equivalently: the pre-state of block `n`). Light clients experience one slot of additional latency for state proofs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Header

The `state_root` field semantics change. No new fields are added.

```python
class Header:
    parent_hash: Hash32
    ommers_hash: Hash32
    coinbase: Address
    state_root: Root  # Post-state of block (n-1), i.e., pre-state of this block
    transactions_root: Root
    receipt_root: Root
    bloom: Bloom
    difficulty: Uint
    number: Uint
    gas_limit: Uint
    gas_used: Uint
    timestamp: U256
    extra_data: Bytes
    prev_randao: Bytes32
    nonce: Bytes8
    base_fee_per_gas: Uint
    withdrawals_root: Root
    blob_gas_used: U64
    excess_blob_gas: U64
    parent_beacon_block_root: Root
    requests_hash: Hash32
    block_access_list_hash: Hash32
```

### BlockChain

The `BlockChain` object tracks the last computed state root:

```python
class BlockChain:
    blocks: List[Block]
    state: State
    chain_id: U64
    last_computed_state_root: Root
```

### Header Validation

```python
def validate_header(chain: BlockChain, header: Header) -> None:
    if header.number < 1:
        raise InvalidBlock

    parent_header = chain.blocks[-1].header

    # Verify delayed state root matches the last computed state root
    if header.state_root != chain.last_computed_state_root:
        raise InvalidBlock

    # ... remaining validation unchanged
```

### State Transition

```python
def state_transition(chain: BlockChain, block: Block) -> None:
    validate_header(chain, block.header)

    block_env = vm.BlockEnvironment(...)

    block_output = apply_body(
        block_env=block_env,
        transactions=block.transactions,
        withdrawals=block.withdrawals,
    )

    # Validate all roots except state_root (already validated in header)
    if block_output.block_gas_used != block.header.gas_used:
        raise InvalidBlock
    # ... other validations

    # Compute and store state root for the NEXT block
    chain.last_computed_state_root = state_root(block_env.state)

    chain.blocks.append(block)
    if len(chain.blocks) > 255:
        chain.blocks = chain.blocks[-255:]
```

### Fork Activation

At activation block `F`:

```python
def apply_fork(old: BlockChain) -> BlockChain:
    # Initialize last_computed_state_root to current state root
    # (post-state of block F-1)
    old.last_computed_state_root = state_root(old.state)
    return old
```

Block `F` MUST contain the post-state root of block `F-1`. From `F+1` onwards, each block contains its parent's post-state root.

## Rationale

### ePBS Compatibility

With [EIP-7732](./eip-7732.md), the `ExecutionPayloadEnvelope` contains a CL `state_root` verified at the end of `process_execution_payload`. This EIP changes only the EL header's `state_root` semantics. The CL state root verification is unaffected.

### BAL Synergy

[EIP-7928](./eip-7928.md) provides the block access list, which identifies all storage slots touched during execution. With delayed state roots, clients can:

1. Receive block `n` with BAL
2. Use the BAL to parallelize state root computation for block `n`
3. Include that root in block `n+1`

Without this EIP, BALs don’t help with state root computation: the root is only known after execution finishes, which is too late to use within the same slot. With this proposal, builders can start constructing a block without fully executing the previous one, by applying the BAL state diff to the slot’s pre-state.

### Light Client Impact

State proofs for block `n` require waiting for block `n+1`. Most light client protocols already tolerate multi-block delays for proof generation. The security model is unchanged; only timing shifts by one slot.

## Backwards Compatibility

Requires a hard fork. Clients that do not implement this change will reject blocks with delayed state roots.

## Security Considerations

### Reorganization Handling

During reorgs, clients MUST recompute `last_computed_state_root` for each block in the new canonical chain. The delayed nature does not affect reorg logic.

### Pre-state Availability

Clients MUST retain the pre-state (post-state of parent block) until the current block's state root is included in the next block. This is already standard practice for reorg handling.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
