---
eip: 8237
title: Independent CL/EL Sync
description: Enables independent consensus and execution layer synchronization by replacing execution_requests_root with an accumulator hash.
author: M. Kalinin <noblesse.knight@gmail.com>, Potuz (@potuz), Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/eip-8237-independent-cl-el-sync/28331
status: Draft
type: Standards Track
category: Core
created: 2026-04-22
requires: 7732
---

## Abstract

This EIP modifies the `ExecutionPayloadBid` container introduced in [EIP-7732](./eip-7732.md) by replacing the `execution_requests_root` field with `partial_header_hash` included in the `BeaconBlockBody` a SHA256 accumulator that chains together all the fields that need independent validation by the consensus layer. This same field is added to the `ExecutionPayload` container for independent validation in the execution layer. Together, these changes allow consensus layer clients to perform range sync without downloading execution payloads, as the accumulator provides a single commitment that can be verified against the beacon block bid without requiring the full payload or interaction with the execution engine.

## Motivation

Before the Glamsterdam fork, beacon blocks contain embedded execution payloads. When consensus layer clients perform range sync, they request large ranges of blocks, execute the consensus state transition function, and send each payload to the execution engine for validation. The only objects that need to be consistent between both layers are the block hash of the payload and the execution requests that originate in the execution layer but are used as input for the consensus state transition function.

[EIP-7732](./eip-7732.md) separates execution payloads from beacon blocks. Execution payloads are broadcast independently in `ExecutionPayloadEnvelope` objects. This separation allows, in principle, the consensus layer to request only beacon blocks during range sync, significantly reducing bandwidth and CPU latency since no block hash verification and no interaction with the execution layer would be needed.

However, without downloading the execution payload envelopes, the consensus layer cannot verify that the block hash of the payload matches the committed `block_hash` in the bid, nor that other fields like execution requests in the payload match the committed `execution_requests_root` in the beacon block bid.

This EIP solves this synchronization problem by modifying `execution_requests_root` in `ExecutionPayloadBid` by instead including a SHA256 accumulator of all the fields that need verification on the consensus layer. Since the accumulator chains across blocks, a consensus layer client performing range sync can verify the entire chain of commitments once the execution layer catches up, without needing the individual payloads at sync time.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Consensus Layer

#### Modified Containers

##### `ExecutionPayloadBid`

The `execution_requests_root` field is removed. 

```python
class ExecutionPayloadBid(Container):
    parent_block_hash: Hash32
    parent_block_root: Root
    block_hash: Hash32
    prev_randao: Bytes32
    fee_recipient: ExecutionAddress
    gas_limit: uint64
    builder_index: BuilderIndex
    slot: Slot
    value: Gwei
    execution_payment: Gwei
    blob_kzg_commitments: List[KZGCommitment, MAX_BLOB_COMMITMENTS_PER_BLOCK]
    # [Modified in Gloas:EIP-8237]
    # Removed execution_requests_root
```

##### `BeaconBlockBody`

The field `partial_header_hash` is added. It consists of a SHA256 accumulator. This avoids requiring SSZ `hash_tree_root` infrastructure, which the execution layer does not implement.

```python
class BeaconBlockBody(Container):
    randao_reveal: BLSSignature
    eth1_data: Eth1Data
    graffiti: Bytes32
    proposer_slashings: List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
    attester_slashings: List[AttesterSlashing, MAX_ATTESTER_SLASHINGS_ELECTRA]
    attestations: List[Attestation, MAX_ATTESTATIONS_ELECTRA]
    deposits: List[Deposit, MAX_DEPOSITS]
    voluntary_exits: List[SignedVoluntaryExit, MAX_VOLUNTARY_EXITS]
    sync_aggregate: SyncAggregate
    # [Modified in Gloas:EIP7732]
    # Removed `execution_payload`
    bls_to_execution_changes: List[SignedBLSToExecutionChange, MAX_BLS_TO_EXECUTION_CHANGES]
    # [Modified in Gloas:EIP7732]
    # Removed `blob_kzg_commitments`
    # [Modified in Gloas:EIP7732]
    # Removed `execution_requests`
    # [New in Gloas:EIP7732]
    signed_execution_payload_bid: SignedExecutionPayloadBid
    # [New in Gloas:EIP7732]
    payload_attestations: List[PayloadAttestation, MAX_PAYLOAD_ATTESTATIONS]
    # [New in Gloas:EIP7732]
    parent_execution_requests: ExecutionRequests
    # [New in Gloas:EIP-8237]
    partial_header_hash: Hash32
```

#### Accumulator Definition

The `partial_header_hash` is computed as:

```python
def compute_partial_header_hash(
    parent_hash: Hash32,
    prev_randao: Bytes32,
    gas_limit: uint64,
    timestamp: uint64,
    withdrawals: List[Withdrawal, MAX_WITHDRAWALS_PER_PAYLOAD],
    slot_number: uint64,
    execution_requests: ExecutionRequests,
) -> Hash32:
    return SHA256(parent_hash + prev_randao + serialize(gas_limit) + serialize(timestamp) + serialize(withdrawals) + serialize(slot_number) + serialize(execution_requests))
```

Where `+` denotes byte concatenation, `serialize` is the raw bytes serialization of the corresponding field. For `uint64` it's the raw 8 bytes in little Endian encoding and for the lists its the raw bytes concatenation of each field in the list.

#### Modified Verification

In `verify_execution_payload_envelope`, the verification of the execution requests against the bid commitment changes from:

```python
assert hash_tree_root(envelope.execution_requests) == bid.execution_requests_root  # old
```

to:

```python
bid = state.latest_execution_payload_bid
assert compute_partial_header_hash(
    bid.parent_block_hash,
    bid.prev_randao,
    bid.gas_limit,
    compute_timestamp_at_slot(state, bid.slot),
    state.payload_expected_withdrawals,
    bid.slot,
    requests,
) == envelope.payload.partial_header_hash
```

Similarly, in `process_parent_execution_payload`, the verification:

```python
assert hash_tree_root(requests) == parent_bid.execution_requests_root  # old
```

is replaced with the corresponding accumulator check:

```python
bid = state.latest_execution_payload_bid
assert compute_partial_header_hash(
    bid.parent_block_hash,
    bid.prev_randao,
    bid.gas_limit,
    compute_timestamp_at_slot(state, bid.slot),
    state.payload_expected_withdrawals,
    bid.slot,
    requests,
) == block.body.partial_header_hash
```

For blocks that are built on full.


### Execution Layer

#### Modified Containers

##### `ExecutionPayload`

A new field `partial_header_hash` is added to the `ExecutionPayload` container:

```python
class ExecutionPayload(Container):
    parent_hash: Hash32
    fee_recipient: ExecutionAddress
    state_root: Bytes32
    receipts_root: Bytes32
    logs_bloom: ByteVector[BYTES_PER_LOGS_BLOOM]
    prev_randao: Bytes32
    block_number: uint64
    gas_limit: uint64
    gas_used: uint64
    timestamp: uint64
    extra_data: ByteList[MAX_EXTRA_DATA_BYTES]
    base_fee_per_gas: uint256
    block_hash: Hash32
    transactions: List[Transaction, MAX_TRANSACTIONS_PER_PAYLOAD]
    withdrawals: List[Withdrawal, MAX_WITHDRAWALS_PER_PAYLOAD]
    blob_gas_used: uint64
    excess_blob_gas: uint64
    block_access_list: BlockAccessList  # [New in Gloas:EIP-7928]
    slot_number: uint64  # [New in Gloas:EIP-7843]
    partial_header_hash: Hash32  # [New in Gloas:EIP-8237]
```

##### `Header`

The `partial_header_hash` field is added to the execution layer block header, so that it is covered by `block_hash`:

```python
class Header:
    ...
    # [New in Gloas:EIP-8237]
    partial_header_hash: Hash32
```

#### Execution Layer Verification

The execution layer MUST independently compute the `partial_header_hash` using the same accumulator function and verify it matches the value in the `ExecutionPayload`.

```python
expected = compute_partial_header_hash(
    block.parent_hash,
    block.prev_randao,
    block.gas_limit,
    block.timestamp,
    block.withdrawals,
    block.slot_number,
    execution_requests,
)
assert block.partial_header_hash == expected
```

This allows the execution layer to validate the accumulator independently of the consensus layer.

### Execution Engine API 

The Execution Engine requires a new method to retrieve the accumulator value for the block with a given `block_hash`. After a long range sync, when the consensus layer sends the first gossipped payload, the execution layer and the consensus layer may find that their accumulators diverged, showing that the chain is invalid, but not where the divergence happened. The CL can find this point by requesting the accumulator value per block hash.

## Rationale

### SHA256 Instead of Hash Tree Root

SHA256 is chosen over `hash_tree_root` because the execution layer does not currently implement SSZ hashing infrastructure. Using plain SHA256 over the concatenation of serialized request data allows both layers to compute the accumulator using only primitives they already have. The accumulator does not need to be Merkle-provable; it only needs to provide a binding commitment to the chain of values.

### Accumulator Pattern

An accumulator that chains across blocks (rather than a per-block hash) is essential for the independent sync use case. During range sync, the consensus layer processes blocks sequentially. By chaining the hash, the CL can defer all execution payload verification: once the execution layer has caught up and verified its side of the accumulator, the CL can confirm that the entire chain of block hashes and execution requests was consistent, without having needed the individual payloads at each step.

### Adding the Field to ExecutionPayload

Adding `partial_header_hash` to the `ExecutionPayload` allows the execution layer to independently verify the accumulator in its own state transition function. This ensures that both layers maintain and verify the same commitment chain, providing defense in depth and enabling each layer to detect inconsistencies without relying on cross-layer communication during sync.

## Backwards Compatibility

This EIP modifies the `ExecutionPayloadBid`, `BeaconBlockBody` and `ExecutionPayload` containers, which is a consensus-breaking change. It requires activation as part of a hard fork.

## Security Considerations

This EIP does not introduce new trust assumptions. The consensus layer still eventually verifies all execution payloads; it simply defers this verification during range sync. The accumulator provides a cryptographic guarantee that the deferred verification will detect any inconsistency.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
