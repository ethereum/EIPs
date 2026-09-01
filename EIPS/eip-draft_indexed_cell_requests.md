---
title: eth/73 - Indexed Cell Requests
description: Add an indexed mask encoding for heterogeneous blob cell requests.
author: Vikram Bhattacharjee (@vbhattaccmu)
discussions-to: https://ethereum-magicians.org/t/eip-8070-sparse-blobpool/26023
status: Draft
type: Standards Track
category: Networking
created: 2026-09-01
requires: 8070
---

## Abstract

This EIP introduces `eth/73`, extending the cell retrieval protocol defined by [EIP-8070](./eip-8070.md). It adds indexed forms of `GetCells` and `Cells` in which each transaction hash references a mask in a deduplicated mask table. The existing shared-mask forms remain available for uniform requests, avoiding additional overhead in the common case.

## Motivation

The `eth/72` `GetCells` message applies one cell mask to every transaction hash in a request. When transactions require different cell sets, a client must partition one scheduling batch into multiple requests by exact mask equality. Partial responses and differing peer availability can produce these heterogeneous missing-cell sets.

Using one mask per transaction would avoid partitioning but would repeat a 16-byte mask for every hash and increase the size of uniform requests. An indexed table represents each unique mask once and lets a sender retain the shared form when it is more efficient.

Synthetic request traces show substantial reductions in request frames for highly fragmented batches. A sparse devnet observation, however, recorded no fragmented batches in the measured window. This EIP is therefore a draft for evaluating a conditional optimization, not a claim that current network traffic requires a new protocol version.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Protocol version

`eth/73` extends `eth/72`. All `eth/72` messages and semantics remain unchanged except for the additions to `GetCells` and `Cells` specified below.

The following notation is used:

- `P` is an RLP-encoded positive integer.
- `B` is an RLP byte string.
- `B_16` is a 16-byte cell mask.
- `B_32` is a 32-byte transaction hash.

### Mask table

An indexed message contains `masks`, a list of unique `B_16` values, and `mask_ids`, a byte string containing one unsigned byte for each transaction hash. Each byte in `mask_ids` is the zero-based index of the mask applying to the hash at the same position.

An indexed message MUST satisfy all of the following requirements:

1. It contains between 1 and 64 transaction hashes.
2. `len(mask_ids)` equals the number of transaction hashes.
3. It contains between 1 and 64 masks.
4. Every mask identifier is less than `len(masks)`.
5. Every mask is referenced by at least one mask identifier.
6. No two masks are equal.
7. Masks appear in order of their first reference in `mask_ids`.
8. Transaction hashes are unique within the message.

A peer receiving an indexed message that violates any of these requirements MUST treat the message as invalid.

### `GetCells` (`0x14`)

`eth/73` accepts two request forms:

- Shared: `[request_id: P, [hash_0: B_32, hash_1: B_32, ...], cell_mask: B_16]`
- Indexed: `[request_id: P, [hash_0: B_32, hash_1: B_32, ...], [mask_0: B_16, mask_1: B_16, ...], mask_ids: B]`

The RLP list length distinguishes the two forms. The shared form has the same encoding and semantics as `eth/72`.

For an indexed request, the mask selected by `mask_ids[i]` specifies the cell indices requested from every blob of the transaction identified by `hashes[i]`.

A sender MUST use the shared form when all transaction hashes require the same mask. When a scheduling batch contains multiple masks, a sender MAY either partition it into shared requests or send an indexed request. A sender SHOULD use the indexed form only when it reduces the number of requests or the total encoded request size.

### `Cells` (`0x15`)

`eth/73` accepts two response forms:

- Shared: `[request_id: P, [hash_0: B_32, hash_1: B_32, ...], [[cell_0_0: B_2048, ...], [cell_1_0: B_2048, ...], ...], cell_mask: B_16]`
- Indexed: `[request_id: P, [hash_0: B_32, hash_1: B_32, ...], [[cell_0_0: B_2048, ...], [cell_1_0: B_2048, ...], ...], [mask_0: B_16, mask_1: B_16, ...], mask_ids: B]`

A response MUST use the same form as its corresponding request. An indexed response MAY omit requested transaction hashes or cells according to the existing `eth/72` response-size and serving-capacity rules. Its `masks` and `mask_ids` fields describe only the hashes and cells actually present in that response and MUST satisfy the mask-table requirements above.

For each returned transaction, its response mask MUST be a subset of the mask requested for that transaction. Cells for each transaction MUST be ordered first by blob order in the transaction and then by increasing cell index among the set bits of its response mask.

A requester MUST reject a response containing an unrequested transaction hash, a cell outside the corresponding requested mask, an invalid cell or proof, or a cell ordering inconsistent with the response mask.

### Resource limits

Implementations MUST validate the transaction count, mask count, identifiers, and canonical mask-table ordering before allocating cell-response storage.

Indexed and shared requests MUST be charged against the same peer request and response quotas. The `eth/72` response soft limit continues to apply. A responder MAY truncate an indexed response independently for each transaction, provided that every returned response mask remains a subset of the corresponding requested mask.

## Rationale

### Indexed masks

A parallel mask array has simple semantics but adds 16 bytes for every transaction. The indexed table is equivalent when every mask is unique and is smaller when masks repeat. Requiring first-reference order, unique entries, and no unused entries gives each mapping one canonical encoding.

### Adaptive encoding

Custody-aligned sampling normally produces one shared mask across many transactions. Keeping the `eth/72` form prevents a regression for this case. Indexed encoding targets recovery and partial-delivery states where missing-cell sets diverge.

### Indexed responses

The `eth/72` `Cells` response contains one shared mask. It cannot describe different returned cell sets for different transaction hashes. An indexed request therefore requires a corresponding indexed response; changing only `GetCells` would leave partial and heterogeneous responses ambiguous.

### Observed workload

Controlled traces demonstrate the mechanism but do not establish its frequency. In one corrected sparse-node observation, 92 scheduling batches contained zero fragmented batches. Implementers should collect mask-group cardinality, hashes per group, request frames, response frames, and end-to-end latency before recommending deployment of `eth/73`.

## Backwards Compatibility

This EIP introduces a new negotiated `eth` capability. An `eth/73` implementation can continue negotiating `eth/72` with peers that do not support indexed cell requests. Such peers receive only the shared `GetCells` and `Cells` forms defined by EIP-8070.

## Security Considerations

Indexed messages add parser and memory-amplification surface. Implementations must enforce the 64-hash and 64-mask bounds before allocating response buffers. They must also validate identifiers and canonical table structure before performing transaction or blob lookups.

A small indexed request can imply a large response. Implementations must retain response-size, serving-time, and peer-rate limits and must account for the total cells implied by all selected masks. Indexed requests must not receive a larger quota than equivalent shared requests.

Transaction-specific masks reveal more detailed information about a requester's missing data than a shared custody mask. Implementations should prefer shared requests for routine custody sampling and use indexed requests only when heterogeneous recovery state makes them beneficial.

As with `eth/72`, every returned cell and proof must be cryptographically validated against the transaction's commitments. A response that maps valid cells to the wrong transaction or cell index is invalid.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
