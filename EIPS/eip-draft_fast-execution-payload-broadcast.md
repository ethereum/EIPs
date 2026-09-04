---
eip: xxxx
title: Fast Execution Payload Broadcast
description: Faster execution payload propagation via chunked gossip
author: Kamil Salakhiev (@kamilsa), Csaba Kiraly (@cskiraly), Potuz (@potuz)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Networking
created: 2026-09-05
requires: 7732
---

## Abstract

[EIP-7732](./eip-7732.md) propagates the execution payload as a single message on the `execution_payload` gossipsub topic. This EIP replaces that topic with `execution_payload_chunks`, which carries the payload envelope split into `TOTAL_EXECUTION_PAYLOAD_CHUNKS` chunks. The builder commits to the chunk set with a Merkle root carried in the execution bid, so each chunk is independently verifiable from a single bid signature check plus an inclusion proof.

## Motivation

The gas-limit growth that [EIP-7732](./eip-7732.md) enables implies larger payloads leading to increased latency. If PTC members do not receive the payload within the attestation deadline, an otherwise valid payload considered as missed.

Existing `execution_payload` gossipsub topic scales poorly as payloads grow. Two effects dominate:

1. Once a peer received a large message, it is hard to cancel in-flight duplicates, so the same bytes arrive several times and consume bandwidth that could carry new data.
2. A peer must download the full message before it can forward any of it, so each hop adds a full transfer leading to increased latency propotional to message size multiplied by hop count.

Both effects are mitigated when the message is chunked. Large duplicates are impossible with chunk granularity, and a peer can forward each chunk as soon as it arrives, so hops overlap instead of serializing.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

#### Parameters

| Constant | Value |
| --- | --- |
| `TOTAL_EXECUTION_PAYLOAD_CHUNKS` | `64` |
| `CHUNK_INCLUSION_PROOF_DEPTH` | `6` |

#### Commitment

The execution bid commits to the chunked envelope:

```python
class ExecutionPayloadBid(ProgressiveContainer):
    ...
    payload_chunks_root: Root  # [New in this EIP]
    ...
```

`payload_chunks_root` is the root of a Merkle tree whose leaves are the `TOTAL_EXECUTION_PAYLOAD_CHUNKS` chunks of the serialized `ExecutionPayloadEnvelope`, in index order. A receiver therefore verifies one bid signature and, per chunk, one Merkle inclusion proof. Once the envelope is reconstructed, it MUST be checked against the payload hash committed in the beacon block.

#### Envelope

Chunking is applied to the envelope:

```python
class ExecutionPayloadEnvelope():
    payload: ExecutionPayload
    execution_requests: ExecutionRequests
    parent_beacon_block_root: Root
    builder_index: BuilderIndex
    # [Modified in this EIP] removed `beacon_block_root`
```

`beacon_block_root` is removed because it is not known at the time of envelope construction: 

Under EIP-7732 the builder constructs the envelope after observing that its bid was included, and can therefore embed the beacon block root. Under this EIP the builder must commit to the chunks when it produces the bid — before the block exists — so the root cannot be part of the committed bytes. It is instead carried per chunk in the `PayloadChunk` message:

```python
class PayloadChunk():
    index: ChunkIndex
    chunk: Chunk
    chunk_inclusion_proof: Vector[Bytes32, CHUNK_INCLUSION_PROOF_DEPTH]
    slot: Slot
    beacon_block_root: Root
```

Chunks are constructed by serializing the envelope and splitting it into `TOTAL_EXECUTION_PAYLOAD_CHUNKS`.

Receivers reconstruct the envelope by concatenating chunks `0..TOTAL_EXECUTION_PAYLOAD_CHUNKS` in index order.

#### Networking

This EIP introduces the `execution_payload_chunks` gossip topic and deprecates `execution_payload`. The topic carries `PayloadChunk` messages.

Once the builder observes a beacon block containing its bid, it is able to construct the `TOTAL_EXECUTION_PAYLOAD_CHUNKS` `PayloadChunk` messages and publishes them to the topic.

#### Open questions and future considerations

- The networking scheme could be extended by erasure coding the chunks, so that a receiver can reconstruct the envelope from a subset of chunks. This introduces additional complexity and may lead to higher bandwidth usage. However, it may mitigate "coupon collector" problems where a receiver is missing a small number of chunks may wait a long time to receive them
- In future it might be considered to introduce `bal_chunks` topic following the same broadcasting scheme for Block Access List (BAL) messages, which are currently part of the execution payload. This would allow start BAL messages propagation sooner than the rest of the payload.

## Rationale

**Why a Merkle commitment.** Alternatives such as KZG place proof generation on the builder's critical path. A Merkle tree over chunks is cheap enough to build at bid time, and a single root in the bid makes each chunk self-verifying against one already-verified signature.

**Why `TOTAL_EXECUTION_PAYLOAD_CHUNKS = 64`.** The value is not derived from measurement; smaller chunk counts already show benefit compared to single large messages. 64 is chosen for forward compatibility in case we decide to extend protocol erasure coding via `c-kzg`, which segments data into 64 chunks and extends them to 128.

## Backwards Compatibility

The `execution_payload` topic is removed, so this change is not backwards compatible and requires a fork.

## Reference Implementation

`TBD`

## Security Considerations

`beacon_block_root` moves from the signed envelope to the `PayloadChunk` message, so it is no longer covered by the builder's bid signature. Validation MUST therefore bind a chunk to a block by checking `beacon_block_root` against a known block whose bid carries the matching `payload_chunks_root`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
