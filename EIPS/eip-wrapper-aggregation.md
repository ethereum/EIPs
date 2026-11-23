---
title: eth/76 - Proof Wrapper Aggregation
description: Adds aggregate wrapper relay, coverage hints, manifests and compact retrieval to eth/76
author: Marc Harvey-Hill (@Marchhill), Daniil Ankushin (@AnkushinDaniil), Manuel Arto (@manusw7), Csaba Kiraly (@cskiraly)
discussions-to: https://ethereum-magicians.org/t/eip-8437-eth-75-proof-wrapper-propagation/29934
status: Draft
type: Standards Track
category: Networking
created: 2026-11-23
requires: 8288, 8437
---

## Abstract

This EIP defines `eth/76`, extending [EIP-8437](./eip-8437.md) with relay of recursive proof wrappers, coverage hints, transaction manifests and compact retrieval. Peers can identify useful aggregates before fetching them and avoid retransmitting transaction encodings already exchanged.

## Motivation

Aggregators can produce overlapping proofs for the same transactions. Wrapper hashes alone do not identify equivalent coverage when proof bytes differ, and repeatedly transmitting transaction metadata and encodings wastes bandwidth. Aggregate propagation needs coverage-aware discovery and retrieval.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

`eth/76` extends `eth/75` and uses EIP-8437's notation, activation condition, wrapper byte bound, transaction and blob handling, and validation rules except as specified below. Status (`0x00`) is unchanged; the protocol version and new message IDs are provisional. Clients MUST use the message forms of the version negotiated on the connection.

### Wrapper encoding

Both [EIP-8288](./eip-8288.md) wrapper modes are supported: `0` for direct witnesses and `1` for a recursive proof. Mode `1` uses the [EIP-8437 canonical wrapper encoding](./eip-8437.md#wrapper-encoding), with `content = [deps, recursive_stark]`, where `recursive_stark` is one nonempty proof byte string. EIP-8288's applicable dependency limits and enabled schemes apply to both modes.

Hash references are transport-only: clients MUST reconstruct the complete wrapper before applying `MAX_WRAPPER_BYTES` or computing its hash.

### Modifications to existing messages

#### NewProofWrapperHashes (0x18)

`[[mode₀: P, length₀: P, hash₀: B_32, deps-hash₀: B_32, txs-hash₀: B_32, txs-meta₀], ...]`

Announce 1–64 held wrappers in strictly ascending hash order. Mode is `0` or `1`; length and hash describe the complete canonical wrapper. EIP-8437's announcement fan-out, on-connection offers, unsupported-mode handling and bounded repeat suppression apply to both modes on `eth/76` connections.

- `deps-hash`: Keccak-256 of the concatenated 96-byte entries in the canonical `deps` list.
- `txs-hash`: Keccak-256 of the concatenated, ascending consensus transaction hashes.
- `txs-meta`: EIP-8437's inline metadata for mode `0` wrappers with at most 17 transactions; otherwise the empty list.

Requesters MAY skip a fetch when both digests match a held wrapper validated under the current rules. Hints alone establish no coverage or validity; matching only `deps-hash` does not identify the transactions.

Under the same verification rules, peers SHOULD suppress wrappers whose transactions are covered by held, validated wrappers exchanged with or announced by the recipient, unless they reduce proof bytes or estimated verification work, or supply a recursive proof for an [EIP-8288 inclusion list](./eip-8288.md#extended-focil-data-structure) where the recipient has only direct witnesses. EIP-8437's bounded records and re-announcement policy apply.

The announcement tuple is fixed for `eth/76`. Extending it requires a new protocol version; canonical decoding rejects extra fields.

#### GetProofWrappers (0x19)

`[request-id: P, compact: P, [hash₀: B_32, hash₁: B_32, ...]]`

Request 1 to 32 distinct wrapper hashes previously announced by the responder under the same verification rules. `compact` is `0` or `1`: with `0`, returned wrappers MUST contain complete transaction encodings; with `1`, responders MAY use [hash-based omission](#hash-based-omission). Unannounced hashes are treated as unavailable, as in EIP-8437.

#### ProofWrappers (0x1a)

`[request-id: P, [[hash₀: B_32, wrapper₀], [hash₁: B_32, wrapper₁], ...]]`

Responses carry either mode. Requesters MUST reconstruct wrappers as specified under [Hash-based omission](#hash-based-omission) before checking their canonical hashes, modes and full lengths against the responder's announcements. EIP-8437's matching, omission, retry, serving-budget and soft-limit rules apply.

### New messages

#### GetProofWrapperManifests (0x1b)

`[request-id: P, [hash₀: B_32, hash₁: B_32, ...]]`

Request the manifests of 1 to 32 distinct wrappers, each previously announced by the responder on that connection under the same verification rules; responders treat other hashes as GetProofWrappers does. A wrapper's manifest is the metadata of all its transactions, in the `txs-meta` layout, whatever its mode and transaction count.

#### ProofWrapperManifests (0x1c)

`[request-id: P, [[hash₀: B_32, txs-meta₀], [hash₁: B_32, txs-meta₁], ...]]`

Return the manifests of available validated wrappers, paired with their hashes. ProofWrappers' response matching, omission and retry rules, soft response limit, empty responses and scoring apply, with complete manifests in place of wrappers, and served manifests count toward the serving budget. Responders SHOULD keep each validated wrapper's manifest rather than derive it per request. Requesters MUST check a manifest on arrival as specified under [Validation](#validation), and against the wrapper if they fetch it.

### Hash-based omission

Compact responses reconstruct the same canonical wrapper using encodings previously delivered on the connection.

- With `compact = 1`, responders MAY replace transaction bytes previously sent in full within a validated wrapper on that connection with `[encoding-hash: B_32]`, if smaller. The hash is Keccak-256 of the pooled transaction bytes, excluding the enclosing Recursive Length Prefix (RLP) string prefix. References are RLP lists; transactions are byte strings.
- Requesters MUST resolve references from cached, validated encodings and check their hashes. The complete wrapper determines identity and byte limits; reconstruction MUST stay within the announced length.
- On a missing encoding, requesters MUST discard the compact item and SHOULD retry with `compact = 0` and a fresh request ID. Cache misses MUST NOT incur penalties.

### Validation

EIP-8437's validation and peer-penalty rules apply to both modes, with these additional checks:

- Clients MUST validate wrappers before reaggregation, as well as before announcement, serving or transaction admission.
- Before decoding or hashing manifests, requesters SHOULD check that the response's request ID is outstanding and its connection open.
- References in a `compact = 0` response are malformed: clients MUST discard them and MAY impose penalties or disconnect.
- On arrival, clients MUST check nonempty inline metadata and manifests against EIP-8437's metadata rules, and require their hashes to concatenate to the preimage of the announced `txs-hash`. Inline metadata for mode `1` is malformed. Manifests have no 17-transaction limit, but MUST describe a nonempty list of transactions and fit the announced wrapper length under EIP-8437's size checks.
- Once the canonical wrapper is reconstructed, clients MUST check, alongside its hash and before proof verification, the announcement digests and metadata, inline or from a manifest, of the peer that served it. Metadata MUST be exactly what the wrapper's transactions give, and inline metadata empty where the rules above require it. A mismatch MUST cause discard and SHOULD cause disconnection, independently of proof validity.
- Metadata and manifests are kept per peer. One peer's claims MUST NOT cause discard of a wrapper served by another; EIP-8437's checks against held transactions and attribution of false metadata apply equally to manifests.

Wrappers validated only under previous verification rules MUST NOT be used for coverage suppression. Hints and manifests never substitute for wrapper validation.

## Rationale

Mode distinguishes direct-witness verification from recursive-proof verification; length gives the complete wrapper's encoded size. Dependency and transaction digests identify equivalent coverage despite different proof bytes, avoiding redundant downloads. Compared with a dependency hint alone, `txs-hash` adds 33 encoded bytes per announcement to distinguish different transactions sharing dependencies. The wire dependency digest uses a fixed hash of encoded triples rather than the circuit digest, allowing checks independent of fork verification rules.

Aggregates can overlap, repeating transaction metadata across wrappers. Requested manifests let peers inspect only the wrappers they consider fetching, while small mode 0 wrappers retain inline metadata. Hash omission saves repeated transaction bytes while preserving canonical identity, at the cost of cache tracking and full retries after eviction. Encoding hashes also bind blob metadata.

## Backwards Compatibility

On an `eth/75` connection, peers exchange only mode 0 wrappers using EIP-8437's four-field announcements and two-field requests, without manifests or hash omission. On `eth/76`, both modes use the six-field announcements and three-field requests defined here. Message shapes are selected by negotiated version, not wrapper mode.

An aggregate alone does not provide the direct witnesses needed to construct a mode 0 wrapper for an `eth/75` peer. Clients holding those witnesses can continue serving the mode 0 wrapper. Block-proof exchange and consensus validity are unaffected.

## Test Cases

[Announcement vectors](../assets/eip-wrapper-aggregation/announcement-vectors.json), [wrapper vectors](../assets/eip-wrapper-aggregation/wrapper-vectors.json) and [the checker](../assets/eip-wrapper-aggregation/check_vectors.py) cover encoding and matching. Synthetic envelopes and witnesses do not test transaction or proof validity.

| Checker case | Expected result |
| --- | --- |
| Maximum announcement/request; excess count | 6,851/1,072 encoded bytes for 64 announcements without metadata/32 hashes; reject excess |
| Unsupported modes, alone or mixed with supported modes | Ignore unsupported entries; still enforce encoding, count, length and ordering |
| Metadata fixture: 17 transactions per entry, maximum wire integers and three fee fields | 201,732 encoded bytes for 64 entries |
| Mode 0 inline metadata; mode 1 without inline metadata | Accept; reject metadata on mode 1 or for more than 17 transactions |
| Malformed metadata, hashes not matching `txs-hash`, or fields differing from a fetched wrapper | Reject before proof verification; attribute false metadata to its sender |
| Different proof bytes, identical dependency and transaction sets | Different wrapper hashes; equal coverage hints permit skipping the fetch |
| Equal dependency digest, different transaction sets | Dependency equality alone does not suppress fetching |
| False dependency or transaction digest, including with an invalid proof | Reject mismatch before proof verification |
| Manifest request for both modes, including a synthetic 4,097-transaction wrapper; an unannounced hash | Return all metadata in request order; omit the unannounced wrapper |
| Repeated, reordered, empty or malformed manifests; false fields in an otherwise well-formed manifest | Reject on arrival or when checked against the wrapper, as applicable |
| One peer's false metadata or manifest; another peer serves correctly | Do not transfer blame between peers |
| Manifests crossing the soft limit | Stop packing; receiver accepts overshoot |
| Full response to either compact flag | Accept without an omission cache |
| Compact response with cached references; missing reference | Reconstruct the identical wrapper; discard the incomplete item and retry in full |
| Reference with `compact = 0`, malformed reference, wrong cached encoding or false canonical hash | Reject |
| Compact form fits the cap but reconstructed wrapper exceeds it | Reject |
| Blob metadata differs while the consensus transaction hash is unchanged | Encoding hashes differ; do not substitute the other encoding |
| Announcement or request encoded for the other negotiated version | Reject the wrong message shape |
| Mode 1 or manifests selected for an `eth/75` connection | Do not send; mode 0 full retrieval remains available |

Client integration cases:

- Suppress wrappers covering already-covered transactions unless cheaper or supplying a recursive proof for an inclusion list where the recipient has only direct witnesses.
- Hints never establish coverage before validation. A correct hint remains consistent across verifier changes; an incorrect hint is penalizable independently of proof failure.
- Enforce EIP-8437's activation condition for all five wrapper messages and invalidate coverage suppression when verification rules change.
- Validate an aggregate containing a transaction rejected by the pool; EIP-8437's unchanged-relay and per-transaction admission rules still apply.
- Never omit an encoding not previously delivered in full on that connection. Retain a validated cache entry for reconstruction or retry in full after eviction.
- Exhaust verification budgets with singleton or overlapping mode 1 wrappers. Defer further work without treating budget exhaustion as invalidity or peer misbehavior.
- Apply EIP-8437's blob availability checks after aggregate validation. Multiple wrappers covering one transaction neither add providers nor reset sampling.

## Security Considerations

EIP-8437's per-peer and global bounds apply to both modes, manifests and reconstruction caches. Singleton and overlapping mode 1 wrappers consume the verification budget; clients should prefer mode 1 when it reduces verification work for the covered transactions. Manifests can list thousands of transactions, so budgets should count bytes and records, not only requests.

Validation before relay adds per-hop download and verification latency; propagation within the aggregation interval requires measurement. Coverage hints can guide fetching but cannot establish validity or justify penalties against another peer. Cached encodings must remain bound to their exact bytes, including blob metadata.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
