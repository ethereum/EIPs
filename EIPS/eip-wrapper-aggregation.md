---
title: eth/76 - Aggregated Proof Propagation
description: Adds aggregate wrapper relay, coverage hints, manifests and compact retrieval to eth/76
author: Marc Harvey-Hill (@Marchhill), Daniil Ankushin (@AnkushinDaniil), Manuel Arto (@manusw7), Csaba Kiraly (@cskiraly)
discussions-to: https://ethereum-magicians.org/t/eip-eth-76-aggregated-proof-propagation/30502
status: Draft
type: Standards Track
category: Networking
created: 2026-11-23
requires: 8288, 8437
---

## Abstract

This EIP defines `eth/76`, extending [EIP-8437](./eip-8437.md) with relay of recursive proof wrappers, coverage hints, transaction-hash manifests and compact retrieval. Peers can identify useful aggregates before fetching them and avoid retransmitting transaction encodings already exchanged.

## Motivation

Relaying reusable aggregates can replace many individual witnesses with one proof and reduce the proving work left to builders during block construction. Aggregators can produce overlapping proofs for the same transactions. Wrapper hashes alone do not identify equivalent coverage when proof bytes differ, and repeatedly transmitting transaction encodings wastes bandwidth. Aggregate propagation needs coverage-aware discovery and retrieval.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

`eth/76` extends `eth/75` and uses EIP-8437's notation, activation condition, wrapper byte bound, transaction and blob handling, and validation rules except as specified below. Status (`0x00`) is unchanged; the protocol version and new message IDs are provisional. Clients MUST use the message forms of the version negotiated on the connection.

### Wrapper encoding

Both [EIP-8288](./eip-8288.md) wrapper modes are supported: `0` for direct witnesses and `1` for a recursive proof. Mode `1` uses the [EIP-8437 canonical wrapper encoding](./eip-8437.md#wrapper-encoding), with `content = [deps, recursive_stark]`, where `recursive_stark` is one nonempty proof byte string. EIP-8288's applicable dependency limits and enabled schemes apply to both modes.

Hash references are transport-only: clients MUST reconstruct the complete wrapper before applying `MAX_WRAPPER_BYTES` or computing its hash.

### Modifications to existing messages

#### NewProofWrapperHashes (0x18)

`[[mode₀: P, length₀: P, hash₀: B_32, deps-hash₀: B_32, txs-hash₀: B_32, txs-meta₀], ...]`

Announce 1–64 held wrappers in strictly ascending hash order. Mode is `0` or `1`; length and hash describe the complete canonical wrapper. EIP-8437's announcement byte bound, fan-out, on-connection offers, unsupported-mode handling and bounded repeat suppression apply to both modes on `eth/76` connections.

- `deps-hash`: Keccak-256 of the concatenated 96-byte entries in the canonical `deps` list.
- `txs-hash`: Keccak-256 of the concatenated, ascending consensus transaction hashes.
- `txs-meta`: EIP-8437's inline metadata for mode `0` wrappers with at most 17 transactions; otherwise the empty list.

Requesters MAY skip a fetch when both digests match a held wrapper validated under the current rules, subject to [Mixed-version peers](#mixed-version-peers). Hints alone establish no coverage or validity; matching only `deps-hash` does not identify the transactions.

Peers SHOULD announce a wrapper only if it adds transaction coverage, reduces proof bytes or estimated verification work for the recipient, or supplies a recursive proof for an [EIP-8288 inclusion list](./eip-8288.md#extended-focil-data-structure) where the recipient has only direct witnesses. Compare against the union of held, validated wrappers exchanged with or announced by the recipient under the same verification rules; different proof bytes alone do not justify another announcement. For mode 0 offers, compare only against mode 0 coverage. EIP-8437's bounded records and re-announcement policy apply.

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

Request the manifests of 1 to 32 distinct wrappers, each previously announced by the responder on that connection under the same verification rules; responders treat other hashes as GetProofWrappers does. A wrapper's manifest is the strictly ascending list of all its consensus transaction hashes, whatever its mode and transaction count. Requesters SHOULD fetch a manifest only when comparing its hashes with held coverage may avoid a wrapper fetch; otherwise they SHOULD request the wrapper directly.

#### ProofWrapperManifests (0x1c)

`[request-id: P, [[hash₀: B_32, [txhash₀: B_32, ...]], ...]]`

Return the manifests of available validated wrappers, paired with their hashes. ProofWrappers' response matching, omission and retry rules, soft response limit, empty responses and scoring apply, with complete manifests in place of wrappers, and served manifests count toward the serving budget. Responders SHOULD keep each validated wrapper's manifest rather than derive it per request. Requesters MUST check a manifest on arrival as specified under [Validation](#validation), and against the wrapper if they fetch it.

### Hash-based omission

Compact responses reconstruct the same canonical wrapper using locally cached transaction encodings.

- With `compact = 1`, responders MAY replace transaction bytes with `[encoding-hash: B_32]`, if smaller. They SHOULD do so when prior wrapper exchanges or announcements indicate the requester holds the encoding. The hash is Keccak-256 of the pooled transaction bytes, excluding the enclosing Recursive Length Prefix (RLP) string prefix. References are RLP lists; transactions are byte strings.
- Requesters MUST resolve references by encoding hash from any locally cached, validated encoding, regardless of which peer supplied it, and check their hashes. The complete wrapper determines identity and byte limits; reconstruction MUST stay within the announced length.
- On a missing encoding, requesters MUST discard the compact item and SHOULD retry with `compact = 0` and a fresh request ID. Cache misses MUST NOT incur penalties.

### Mixed-version peers

While connected to `eth/75` peers, clients SHOULD fetch offered mode 0 wrappers not already covered by retained mode 0 wrappers, even when aggregates cover the same transactions. Clients SHOULD retain validated mode 0 wrappers covering pending transactions and announce them under EIP-8437's rules. Fetching and retention remain subject to local budgets and current verification rules; an aggregate cannot reconstruct missing direct witnesses.

### Validation

EIP-8437's validation and peer-penalty rules apply to both modes, with these additional checks:

- Clients MUST validate wrappers before reaggregation, as well as before announcement, serving or transaction admission.
- Before decoding or hashing manifests, requesters SHOULD check that the response's request ID is outstanding and its connection open.
- References in a `compact = 0` response are malformed: clients MUST discard them and MAY impose penalties or disconnect.
- On arrival, clients MUST check nonempty inline metadata against EIP-8437's metadata rules. A manifest MUST contain a nonempty, strictly ascending list of 32-byte hashes and its RLP encoding MUST be smaller than the announced wrapper length. In either form, the concatenated hashes MUST hash to the sender's announced `txs-hash`. Inline metadata for mode `1` is malformed; manifests have no 17-transaction limit.
- Once the canonical wrapper is reconstructed, clients MUST check, alongside its hash and before proof verification, the announcement digests, inline metadata and any manifest supplied by the serving peer. Metadata and manifest hashes MUST match the wrapper's transactions exactly, and inline metadata MUST be empty where required above. A mismatch MUST cause discard and SHOULD cause disconnection, independently of proof validity.
- Metadata and manifests are kept per peer. Fetch decisions based only on unverified hints or manifests MUST remain scoped to their sender: they MUST NOT suppress fetching the same wrapper from another announcer or mark its coverage as validated. One peer's claims MUST NOT cause discard of a wrapper served by another; mismatches are attributed only to their sender.

Wrappers validated only under previous verification rules MUST NOT be used for coverage suppression. Hints and manifests never substitute for wrapper validation.

## Rationale

Mode distinguishes direct-witness verification from recursive-proof verification; length gives the complete wrapper's encoded size. Dependency and transaction digests identify equivalent coverage despite different proof bytes, avoiding redundant downloads. Compared with a dependency hint alone, `txs-hash` adds 33 encoded bytes per announcement to distinguish different transactions sharing dependencies. Keeping `txs-hash` in every announcement gives both modes the same coverage lookup, even when inline hashes make it derivable. The wire dependency digest uses a fixed hash of encoded triples rather than the circuit digest, allowing checks independent of fork verification rules.

Aggregates can overlap. Hashes-only manifests identify partial overlap without repeating per-transaction fee and source metadata; small mode 0 wrappers retain inline metadata. When the hash list would not change the fetch decision, requesting the wrapper directly avoids a round trip. Compact retrieval can reuse encodings obtained from any peer. A full-wrapper retry after a cache miss avoids a separate missing-transaction request protocol. Encoding hashes also bind blob metadata.

## Backwards Compatibility

On an `eth/75` connection, peers exchange only mode 0 wrappers using EIP-8437's four-field announcements and two-field requests, without manifests or hash omission. On `eth/76`, both modes use the six-field announcements and three-field requests defined here. Message shapes are selected by negotiated version, not wrapper mode.

An aggregate alone does not provide the direct witnesses needed to construct a mode 0 wrapper for an `eth/75` peer. Block-proof exchange and consensus validity are unaffected.

## Test Cases

[Announcement vectors](../assets/eip-wrapper-aggregation/announcement-vectors.json), [wrapper vectors](../assets/eip-wrapper-aggregation/wrapper-vectors.json) and [the checker](../assets/eip-wrapper-aggregation/check_vectors.py) cover encoding and matching. Synthetic envelopes and witnesses do not test transaction or proof validity.

| Checker case | Expected result |
| --- | --- |
| Maximum announcement/request; excess count | 6,851/1,072 encoded bytes for 64 announcements without metadata/32 hashes; reject excess |
| Unsupported modes, alone or mixed with supported modes | Ignore unsupported entries; still enforce encoding, count, length and ordering |
| Announcement payload exactly 2 MiB; one byte larger, including metadata for an unsupported mode | Accept the size boundary; reject the oversized payload |
| Unknown scheme identifiers in structurally valid wrappers | Decode; dependency validation determines support |
| Metadata fixture: 17 transactions per entry, maximum wire integers and three fee fields | 190,660 encoded bytes for 64 entries |
| Mode 0 inline metadata; mode 1 without inline metadata | Accept; reject metadata on mode 1 or for more than 17 transactions |
| Malformed metadata, hashes not matching `txs-hash`, or fields differing from a fetched wrapper | Reject before proof verification; attribute false metadata to its sender |
| Different proof bytes, identical dependency and transaction sets | Different wrapper hashes; equal coverage hints permit skipping the fetch |
| Equal dependency digest, different transaction sets | Dependency equality alone does not suppress fetching |
| False dependency or transaction digest, including with an invalid proof | Reject mismatch before proof verification |
| Manifest request for both modes, including a synthetic 4,097-transaction wrapper; an unannounced hash | Return all transaction hashes in request order; omit the unannounced wrapper |
| Repeated, reordered, empty or malformed manifests; hashes differing from a fetched wrapper | Reject on arrival or when checked against the wrapper, as applicable |
| One peer's false metadata or manifest; another peer serves correctly | Do not transfer blame between peers |
| Manifests crossing the soft limit | Stop packing; receiver accepts overshoot |
| Full response to either compact flag | Accept without an omission cache |
| Compact response with references cached from another peer; missing reference | Reconstruct the identical wrapper; discard the incomplete item and retry in full |
| Reference with `compact = 0`, malformed reference, wrong cached encoding or false canonical hash | Reject |
| Compact form fits the cap but reconstructed wrapper exceeds it | Reject |
| Blob metadata differs while the consensus transaction hash is unchanged | Encoding hashes differ; do not substitute the other encoding |
| Announcement or request encoded for the other negotiated version | Reject the wrong message shape |
| Mode 1 or manifests selected for an `eth/75` connection | Do not send; mode 0 full retrieval remains available |

Client integration cases require peer and fork state not modeled by the checker:

- Hold an aggregate without its direct witnesses while connected to an `eth/75` peer. A mode 0 offer is not suppressed by aggregate coverage: fetch it within local budgets, validate, retain and serve it in full to the older peer. Peers continue announcing mode 0 coverage even when the recipient holds an aggregate.
- Two validated aggregates have different hashes but the same coverage and no reduction in proof bytes or estimated verification work: suppress the second announcement. Retain the exception for a recursive inclusion-list proof where the recipient has only direct witnesses.
- Peer A supplies a manifest suggesting no useful coverage; peer B announces the same wrapper with different hints. A fetch decision based only on A's manifest does not suppress fetching from B; validate B's response against B's hints and manifest.
- Without held coverage to compare, fetch the wrapper directly rather than requesting its manifest.
- Hints never establish coverage before validation. A correct hint remains consistent across verifier changes; an incorrect hint is penalizable independently of proof failure.
- Enforce EIP-8437's activation condition for all five wrapper messages and invalidate coverage suppression when verification rules change.
- A valid wrapper covers A with dependencies `{a, shared}` and B with `{b, shared}`. Admit A and reject B: the original wrapper remains valid and relayable unchanged. Reaggregate A alone with `{a, shared}`; discard only `b`, not `shared`.
- Resolve a compact reference using a validated encoding received from a different peer; if absent or evicted, retry in full. An equal consensus hash with different blob metadata does not resolve the reference.
- Exhaust verification budgets with singleton or overlapping mode 1 wrappers. Defer further work without treating budget exhaustion as invalidity or peer misbehavior.
- Apply EIP-8437's blob availability checks after aggregate validation. Multiple wrappers covering one transaction neither add providers nor reset sampling.

## Security Considerations

EIP-8437's per-peer and global bounds apply to both modes, manifests and reconstruction caches. Singleton and overlapping mode 1 wrappers consume the verification budget; clients should prefer mode 1 when it reduces verification work for the covered transactions. Manifests can list thousands of transactions, so budgets should count bytes and records, not only requests.

Validation before relay adds per-hop download and verification latency; propagation within the aggregation interval requires measurement. Coverage hints can guide fetching but cannot establish validity or justify penalties against another peer. Cached encodings must remain bound to their exact bytes, including blob metadata.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
