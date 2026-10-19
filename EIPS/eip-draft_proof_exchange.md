---
title: eth/73 - Recursive STARK Exchange
description: Adds peer-to-peer exchange of block-level recursive STARK proofs to the eth protocol
author: Toni Wahrstätter (@nerolation), Thomas Coratger (@tcoratger), Vitalik Buterin (@vbuterin)
discussions-to: https://ethereum-magicians.org/t/TBD
status: Draft
type: Standards Track
category: Networking
created: 2026-10-19
requires: 8070, 8288
---

## Abstract

This EIP modifies the 'eth' p2p protocol to support the recursive STARK proofs of [EIP-8288](./eip-8288.md). It adds two new messages, `GetRecursiveStarks` (0x14) and `RecursiveStarks` (0x15), enabling peers to request and serve proofs for synchronization.

## Motivation

[EIP-8288](./eip-8288.md) requires every block to carry a recursive STARK that proves the validity of all dependencies declared by its transactions. The proof is not part of the block header or the block body. The header carries only a 32-byte commitment to it, `recursive_stark_hash`, and the proof itself travels in the `ExecutionPayload`.

Because the proof is in neither the header nor the body, `GetBlockBodies` cannot serve it, and the Engine API payload body methods reach only the local consensus layer. A node that validates a block by re-execution must verify its proof, so a syncing node needs a way to obtain proofs from peers. This EIP adds that wire protocol support.

## Specification

### Block Header Extension

The block header is extended with two fields appended after the last header field of the preceding fork:

```
block-header = [
    ...
    recursive-stark-hash: B_32,
    block-deps-hash: B_32,
]
```

The `recursive-stark-hash` field contains `keccak256(recursive-stark)` and the `block-deps-hash` field contains `get_deps_hash(dependencies(block))`, both as defined in [EIP-8288](./eip-8288.md). These fields MUST be present in headers after EIP-8288 activation and absent for earlier blocks.

### Recursive STARK Encoding

A recursive STARK is transmitted as the serialized proof byte string defined in [EIP-8288](./eip-8288.md):

```
recursive-stark: B
```

A block without dependencies has an empty `recursive-stark`.

### New Protocol Messages

#### GetRecursiveStarks (0x14)

```
[request-id: P, [blockhash₁: B_32, blockhash₂: B_32, ...]]
```

Request recursive STARKs for the given block hashes. The number of proofs that can be requested in a single message is subject to implementation-defined limits.

Proofs are only available for blocks after [EIP-8288](./eip-8288.md) activation and within the retention period defined therein. Requests for unavailable proofs return empty entries.

#### RecursiveStarks (0x15)

```
[request-id: P, [recursive-stark₁, recursive-stark₂, ...]]
```

Response to `GetRecursiveStarks`. Each element corresponds to a block hash from the request, in order. The RLP empty string (`0x80`) is returned for blocks where the proof is unavailable.

A block without dependencies has an empty proof, which also encodes as `0x80`. The receiver tells the two cases apart by the block header: `recursive-stark-hash` equals `keccak256` of the empty byte string only for a block without dependencies.

The recommended soft limit for `RecursiveStarks` responses is 2 MiB.

### Validation

When a recursive STARK is received, clients MUST validate it by computing `keccak256(recursive-stark)` and comparing against the `recursive-stark-hash` in the corresponding block header. Verifying the proof against `block-deps-hash` is part of block validation under [EIP-8288](./eip-8288.md) and is not required at the wire protocol level.

## Rationale

### Separate Messages vs. Block Body Extension

Proofs are transmitted via dedicated messages rather than extending block bodies because:

1. **Size**: A recursive STARK is hundreds of kilobytes, significantly increasing block propagation overhead if bundled.
2. **Optional retrieval**: A node that trusts finality for a block does not need its proof. It can sync headers and bodies for finalized blocks without downloading proofs.
3. **Retention policy**: Proofs may be pruned per [EIP-8288](./eip-8288.md), while block bodies are retained longer.

### Message IDs

Message IDs 0x14 and 0x15 follow sequentially from the existing messages. `BlockAccessLists` (0x13), defined in [EIP-8159](./eip-8159.md), is the highest message ID in eth/71 and eth/72.

### Response Size Limit

The 2 MiB soft limit is consistent with other eth protocol responses (blocks, receipts, headers) and accommodates several proofs per response. Responses containing a single proof that exceeds 2 MiB are still valid, as the soft limit governs when to stop appending additional items, not the maximum size of an individual item.

## Backwards Compatibility

This EIP changes the eth protocol and requires rolling out a new version, eth/73. Supporting multiple protocol versions is standard practice. Rolling out eth/73 does not break older clients, as they can continue using earlier versions.

This EIP requires the hard fork that activates [EIP-8288](./eip-8288.md) for the header field extension. The new messages are only meaningful for blocks after that fork.

## Security Considerations

### Validation Cost

Validating a received proof against the header requires one keccak256 over a few hundred kilobytes, which is negligible. Verifying the proof against `block-deps-hash` is more expensive and is governed by the block validity rules of [EIP-8288](./eip-8288.md), not by this protocol.

### Amplification

A `GetRecursiveStarks` request can trigger responses much larger than the request, since each requested hash can return a proof of hundreds of kilobytes. Implementations SHOULD apply rate limiting and respect the soft response size limit to prevent amplification attacks.

### Unavailable Data

Clients MUST handle empty responses gracefully. A peer returning empty entries for available blocks may be misbehaving but could also have pruned the data legitimately.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
