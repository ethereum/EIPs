---
title: Proof Object Transport over devp2p
description: Defines request-driven proof transfer over devp2p using authenticated chunks, bounded reassembly, and recovery.
author: Marchhill (@Marchhill)
discussions-to: https://ethereum-magicians.org/t/eip-8288-frame-type-for-pq-sig-and-stark-aggregation/28723
status: Draft
type: Standards Track
category: Networking
created: 2026-10-05
requires: 2718, 8288
---

## Abstract

This EIP defines the `lean/1` devp2p capability for discovering and retrieving [EIP-8288](./eip-8288.md) proof objects. Receivers request bounded sets of independently verifiable chunks and can resume retrieval from multiple peers. The protocol distinguishes transport integrity from proof validity and consensus authentication. It supports mempool wrappers, retrieval of existing block proofs, and existing inclusion-list packages without changing their consensus rules.

## Motivation

Dependency witnesses and aggregated proofs can be much larger than ordinary transactions. Sending an entire object as one message occupies the shared connection until that message has been written, repeats bytes the receiver already has, and makes interrupted retrieval expensive. Unsolicited objects also force receivers to allocate memory and schedule cryptographic work before deciding whether they need the object.

Small requested chunks permit bounded storage, selective recovery and scheduling between proof traffic and other devp2p messages. A canonical commitment allows chunks from different peers to be combined without accepting inconsistent bytes. Proof validity remains a separate check after reconstruction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Scope and constants

This EIP specifies transport. [EIP-8288](./eip-8288.md) and the activated frame-transaction, block and inclusion-list specifications determine dependency commitments, proof statements, proof profiles, transaction admission, block validity, gas and inclusion obligations. Successful transfer does not establish any of those conditions.

| Name | Value | Meaning |
| --- | --- | --- |
| `CAPABILITY` | `lean/1` | Capability name and version |
| `MESSAGE_COUNT` | `10` | Relative message IDs `0x00` through `0x09` |
| `CHUNK_BYTES` | `65536` | Fixed object chunk size |
| `MAX_OBJECT_BYTES` | `67108864` | Transport object ceiling, 64 MiB |
| `MAX_MESSAGE_BYTES` | `131072` | Uncompressed capability message-data ceiling |
| `MAX_RLP_DEPTH` | `8` | Maximum nesting of decoded transport lists |
| `MAX_PROFILES` | `16` | Profile IDs in Status |
| `MAX_ANNOUNCEMENTS` | `64` | Descriptors in one announcement |
| `MAX_LOOKUPS` | `16` | Metadata selectors in one request |
| `MAX_CHUNKS_PER_REQUEST` | `32` | Distinct indices requested at once |
| `MAX_REQUESTS_PER_PEER` | `4` | Live outgoing or incoming requests, per direction |
| `MAX_TXS_PER_OBJECT` | `4096` | Transaction entries in a transport package |
| `MAX_TXS_PER_REQUEST` | `16` | Transaction hashes requested at once |
| `MAX_TRANSACTION_BYTES` | `1048576` | One transaction envelope in transaction recovery |
| `MAX_TX_RESPONSE_BYTES` | `65536` | Transaction recovery response-data ceiling |
| `MAX_METADATA_RESPONSE_BYTES` | `65536` | Objects response-data ceiling |
| `MAX_HEADER_SKELETON_BYTES` | `16384` | Encoded transport header skeleton ceiling |
| `MAX_HEADER_FIELDS` | `64` | Fields in a transport header skeleton |
| `MAX_REQUEST_IDLE_SECONDS` | `30` | Request expiry without useful progress |
| `MAX_REQUEST_AGE_SECONDS` | `120` | Absolute request lifetime |
| `MAX_ASSEMBLY_IDLE_SECONDS` | `30` | Assembly expiry without a newly verified chunk |
| `MAX_ASSEMBLY_AGE_SECONDS` | `300` | Absolute assembly lifetime |

These are wire limits, not block-validity or proof-verification limits. An activated proof profile can impose smaller consensus bounds. A client MAY advertise or enforce lower local capacity and refuse work without penalizing a healthy peer. A transport refusal MUST NOT be treated as an invalid transaction or block.

### Capability and profiles

Peers negotiate `lean/1` through the existing RLPx Hello exchange. All ten message IDs MUST be reserved even if an optional object kind is unsupported. Only Status may be sent until the peer's Status has been accepted.

A **profile ID** is a 32-byte immutable identifier assigned by the chain's [EIP-8288](./eip-8288.md) activation specification. Its definition MUST identify the cryptographic statement, supported schemes, canonical witness and aggregate-proof encodings, aggregation verification key, public-input encoding, and consensus acceptance bounds. The network transport encodings in this EIP are fixed; a profile MUST NOT silently replace them. Changes to a profile definition require a new profile ID.

Each profile MUST define a canonical aggregate-proof encoding and verification rule for the empty dependency set. An empty-set encoding MUST be accepted only for the commitment to the empty canonical dependency list and MUST NOT cover any nonempty dependency statement. It does not permit omission of the recursive STARK header entry or its dependency commitment.

An aggregate proof MUST prove the complete dependency statement required by [EIP-8288](./eip-8288.md), covering every declared dependency within the recursive proof. A profile MUST preserve that statement for all supported dependency schemes. Profile negotiation does not change the aggregation requirement.

Clients MUST obtain acceptable profile IDs and their activation contexts from local chain configuration, not from peer-provided verification keys, manifests or download locations. Negotiation selects a locally known verifier; it does not authorize new cryptography. An object may be requested only under a common profile which applies to its transaction, block or inclusion-list context. Historical block proofs MAY use a common historical profile. Mempool packages use a profile active for the receiving node's candidate execution context.

Status is sent exactly once in each direction:

```text
Status (0x00) = [1, chain_id, genesis_hash, profiles, kinds, max_object_bytes]
```

- `chain_id` is an unsigned integer less than `2**256`.
- `genesis_hash` is exactly 32 bytes.
- `profiles` is a nonempty, strictly ascending list of at most `MAX_PROFILES` distinct 32-byte profile IDs.
- `kinds` is a nonzero three-bit mask: bit `kind - 1` advertises support for that kind. Bit zero MUST be set; bits above two MUST be zero.
- `max_object_bytes` is an integer in `[1, MAX_OBJECT_BYTES]` and declares a local receive ceiling, not a promise to admit every object below it.

The chain ID and genesis hash MUST match local configuration. There MUST be at least one common acceptable profile. A well-formed incompatible Status disables this capability; clients SHOULD preserve other negotiated protocols on the connection. Data before accepted Status, a second Status, malformed fields, or an unnegotiated capability is a protocol violation. A peer MUST NOT infer a profile's activation or consensus validity from a successful handshake alone.

### Encoding

Message data uses canonical RLP with the exact field counts specified below. Integers use shortest unsigned RLP encoding; zero is the empty byte string. Integer widths given below are range bounds, not fixed-width RLP fields. Leading zeros, trailing fields, trailing bytes, nonminimal length prefixes and wrong list/string types are invalid. All hashes are byte strings of exactly 32 bytes. Lists MUST be checked against their count bounds before allocating elements. Transport RLP nesting MUST NOT exceed `MAX_RLP_DEPTH`. Transaction envelopes and proof bytes are opaque byte strings at this layer; their dedicated, bounded parsers apply afterward rather than recursively interpreting their contents as transport RLP.

`H` denotes Ethereum Keccak-256, not standardized SHA3-256. `RLP(x)` denotes canonical RLP. `U8`, `U32` and `U64` used in commitment formulas denote fixed-width **big-endian** unsigned encodings. Those formulas do not use RLP for their integers. `||` denotes byte concatenation. Domain labels below are their exact ASCII bytes followed by one zero byte.

[RLPx](https://github.com/ethereum/devp2p/blob/76cf0a141e8aa8616e3305738d51101945387d3c/rlpx.md) compression, encryption, message-ID multiplexing and connection authentication remain unchanged. Implementations MUST check the advertised uncompressed size before decompression and reject data exceeding `MAX_MESSAGE_BYTES`. Each Chunk is a separate capability message. Body bytes MUST be transferred only in requested Chunk messages; there is no whole-object message codec and implementations MUST NOT rely on RLPx frame fragmentation to transfer an object. An object with `N == 1` is valid and uses one requested Chunk message.

### Object kinds and canonical bodies

An **object** consists of a descriptor and its canonical body bytes. All bodies MUST have length in `[1, MAX_OBJECT_BYTES]`. Parsing a body never bypasses the activated profile's bounds or [EIP-8288](./eip-8288.md) validation.

#### Kind 1: mempool wrapper

The context is the empty list. The body is:

```text
RLP([transactions, mode, [dependencies, proof_content]])
transactions = [entry, ...]
entry = [0, transaction_envelope] | [1, transaction_hash]
dependencies = [dependency_bytes96, ...]
proof_content = [witness_bytes, ...]     if mode == 0
proof_content = aggregate_proof_bytes   if mode == 1
```

`transaction_envelope` is the exact [EIP-2718](./eip-2718.md) transaction encoding, including the type byte for typed transactions and the complete canonical RLP for a legacy transaction. It is carried as an RLP byte string, never embedded as an RLP list. Its transaction hash is `H(transaction_envelope)`. A hash entry carries exactly 32 bytes. Tags disambiguate transaction envelopes from hashes, irrespective of their lengths.

The transaction list contains between one and `MAX_TXS_PER_OBJECT` entries and is strictly ascending by transaction hash, with no duplicate hash. Replacing a full entry with a hash entry creates a different object. The dependency list contains fixed-width 96-byte triples in the canonical order required by [EIP-8288](./eip-8288.md), with no duplicates or unsupported schemes. For mode zero there is exactly one witness byte string per dependency, in the same order. For mode one the content is exactly one proof byte string. No other mode or field arrangement is permitted.

Every hash entry MUST be resolved to its exact transaction envelope before the dependency union and transaction validity can be established. Hash-only receipt, a chunk proof, or a proof over a caller-supplied dependency list does not establish transaction coverage. An unresolved wrapper MAY be retained within a bounded recovery budget, but MUST NOT be admitted, reaggregated or announced as verified. Full entries exceeding `MAX_TRANSACTION_BYTES` may be transported inside a requested object, subject to its object limit; they cannot be recovered through the small transaction-recovery messages below. Senders SHOULD use full entries unless the receiving peer has demonstrated it can resolve their hashes.

The transport wrapper maps directly to the abstract [EIP-8288](./eip-8288.md) wrapper. Its tagged entries and byte-string representation specify the wire encoding; they do not change transaction or dependency semantics. Empty dependency sets and their proof encodings are governed by the activated profile. Dependency-free wrappers still require normal transaction validation.

#### Kind 2: block-proof sidecar

The context and body are:

```text
context = [block_hash, block_number, transactions_root, block_deps_hash, raw_proof_hash, skeleton_hash]
body = RLP([raw_proof_bytes])
raw_proof_hash = H(raw_proof_bytes)
```

`block_number` is an unsigned 64-bit integer. The other fields are 32-byte hashes. The raw proof is precisely the proof byte string in that block's [EIP-8288](./eip-8288.md) header entry, excluding the dependency hash and any surrounding RLP encoding. The enclosing one-element RLP list represents an empty raw proof unambiguously if an activated profile permits it.

The descriptor is accompanied in an Objects response by a bounded **transport header skeleton**:

```text
skeleton = [proof_field_index, field_encodings]
skeleton_hash = H("lean/1/skeleton\0" || RLP(skeleton))
```

`field_encodings` is a list of at most `MAX_HEADER_FIELDS` byte strings, in the exact top-level order of the original fork-specific canonical header. Each non-proof entry contains the complete canonical RLP encoding of exactly one header field, including its RLP prefix; it is not the decoded field value. At `proof_field_index` the entry is the empty byte string as a transport placeholder, with no RLP-encoded field inside it. Every other entry MUST contain a nonempty canonical single RLP item. `proof_field_index` MUST be less than the field count and match the [EIP-8288](./eip-8288.md) proof-field position for that block's activated header format. The complete encoded skeleton is at most `MAX_HEADER_SKELETON_BYTES` bytes.

The receiver checks the skeleton hash and bounded field encodings before requesting proof chunks. Before proof work, it MUST preflight the field count, order, types, widths and permitted values against the activated fork-specific header schema. Nested non-proof field encodings MUST be parsed with explicit depth and allocation bounds, no larger than `MAX_RLP_DEPTH`; a generic recursive parser with an unbounded stack is insufficient. Wrong proof-field index, unexpected fields or noncanonical fork encodings MUST be rejected at this stage. It reconstructs the original header by replacing the placeholder with `RLP([raw_proof_bytes, block_deps_hash])`, concatenating all encoded items, and prepending the canonical RLP **list** prefix for that concatenation's byte length. It MUST NOT RLP-encode the field-encoding byte strings as header fields. The Keccak-256 hash of the reconstructed canonical header MUST equal the requested `block_hash`. The reconstructed header's block number, transaction root and dependency hash MUST equal the descriptor context, and all activated header rules MUST be applied. The skeleton MUST NOT be hashed, validated or inserted into a header store as if it were the canonical header.

The body must subsequently be obtained and validated through the existing block protocol. Its transaction root must match the reconstructed header; the transaction dependency union must match `block_deps_hash`; `H(raw_proof_bytes)` must equal `raw_proof_hash`; and the proof statement must verify under the applicable profile. Only then may the sidecar be used as a valid block proof. A reconstructed hash matching an untrusted peer's requested identifier does not establish canonical-chain membership or a trusted fork-choice anchor.

The skeleton, raw proof hash and Merkle root are untrusted hints until reconstruction and the relevant independent header/body checks complete. A known consensus block hash commits to the eventual **full** header, but does not authenticate the peer's independently chosen chunk root. This permits bounded retrieval before obtaining the multi-MiB inline header without allowing early relay of unanchored chunks.

This kind retrieves the **same** proof committed by the existing full header. The compact skeleton is only a transport representation: it does not remove the inline proof from canonical headers, change block/header hashing, replace normal body availability, or permit processing a block with a missing proof. Ordinary ETH header responses remain unchanged and may still be large. A client using this object family can instead obtain the skeleton and proof in bounded messages and reconstruct those original bytes. A future consensus format which commits only to a proof hash requires a separate specification.

#### Kind 3: inclusion-list package

The context is `[package_hash]`, where `package_hash = H(body)`. The body is:

```text
RLP([transactions, aggregate_proof_bytes, deps_hash, proven_dependencies])
transactions = [transaction_envelope, ...]
proven_dependencies = [dependency_bytes96, ...]
```

Transactions are full byte-string envelopes in their inclusion-list order, with at most `MAX_TXS_PER_OBJECT` entries. They MUST NOT be sorted by the transport or replaced by hashes. `proven_dependencies` is the explicit canonical set required by the activated [EIP-8288](./eip-8288.md) inclusion-list extension; `deps_hash` is its [EIP-8288](./eip-8288.md) commitment. This transports the existing package content and does not create a new signature, author, slot or inclusion obligation. Any enclosing consensus-layer authentication and inclusion-list identifiers travel through the existing inclusion-list protocol.

Clients MUST apply the existing package applicability, transaction eligibility and omission rules after reconstruction. Missing or invalid dependency coverage has the effect specified by [EIP-8288](./eip-8288.md) and the activated inclusion-list rules; this EIP neither discards independent obligations nor converts arbitrary packages into authenticated inclusion lists. A package hash supplied by a peer is only a lookup key.

### Descriptors and identity

```text
descriptor = [kind, profile_id, context, byte_length, content_hash, chunk_root]
content_hash = H(body)
context_hash = H("lean/1/context\0" || RLP(context))
object_id = H("lean/1/object\0" || RLP(descriptor))
```

`kind` is 1, 2 or 3. The profile and context have the forms defined above. `byte_length` is an unsigned 64-bit integer within the object bounds. A descriptor is at most 512 encoded bytes. All descriptor hashes and geometry MUST be checked before accepting chunks. The descriptor binds kind, profile, context, exact length, content and Merkle root. Different context, profile, transaction representation or proof bytes produce different identities.

An object is keyed locally by `object_id`; a transfer is keyed by `(connection, request_id)`. Announcements with an already known descriptor MUST NOT create another assembly. Distinct peer claims of identity do not merge assemblies unless the complete canonical descriptors are identical.

### Chunk commitments

Split the body at fixed `CHUNK_BYTES` offsets, without padding body bytes. Let:

```text
N = ceil(byte_length / CHUNK_BYTES)
W = smallest power of two >= N
depth = log2(W)
S = U8(kind) || profile_id || context_hash || content_hash || U64(byte_length) || U32(N)
chunk[i] = body[i * CHUNK_BYTES : min((i + 1) * CHUNK_BYTES, byte_length)]
```

Thus `1 <= N <= 1024` and `0 <= depth <= 10`. All real chunks except the last have exactly `CHUNK_BYTES` bytes; the last has `byte_length - (N - 1) * CHUNK_BYTES` bytes, including a full-sized final chunk when the length is divisible by `CHUNK_BYTES`.

Build a perfect binary tree of `W` leaves:

```text
leaf[i] = H("lean/1/leaf\0" || S || U32(i) || U32(len(chunk[i])) || chunk[i])  for i < N
leaf[i] = H("lean/1/empty\0" || S || U32(i))                               for N <= i < W
parent = H("lean/1/node\0" || U8(level) || left || right)
chunk_root = H("lean/1/root\0" || S || tree_root)
```

`level` is zero for parents of leaves and increases by one toward the root. For `W == 1`, `tree_root` is the single real leaf and no parent hash is used. Padding leaves are indexed empty commitments, not duplicates of the last real leaf or hashes of a zero-filled chunk.

A chunk branch lists exactly `depth` sibling hashes, starting at leaf level. At branch position `level`, use the corresponding bit of `index`: a zero bit hashes `(current, sibling)`, a one bit hashes `(sibling, current)`. Apply the root domain afterward and compare with the descriptor's `chunk_root`. `index` MUST be less than `N`; verifying only its low bits is insufficient. A sibling subtree which consists entirely of padding MUST equal the canonical empty subtree computed by the construction above. Full reconstruction MUST independently recompute the complete canonical root and `content_hash`.

Branch verification authenticates bytes to the **descriptor's root**. It does not authenticate that descriptor to consensus or establish proof validity. A peer-announced root, including one accompanied by a block hash or a matching claimed content hash, is untrusted until its relation to the complete valid object has been established.

### Messages and request lifecycle

The following IDs are relative to the capability's negotiated message offset:

| ID | Message | Direction |
| --- | --- | --- |
| `0x00` | Status | Both |
| `0x01` | AnnounceObjects | Both |
| `0x02` | GetObjects | Request |
| `0x03` | Objects | Response |
| `0x04` | GetChunks | Request |
| `0x05` | Chunk | Response |
| `0x06` | Complete | Terminal chunk-response status |
| `0x07` | Cancel | Requester to serving peer |
| `0x08` | GetTransactions | Request |
| `0x09` | Transactions | Response |

Request IDs are unsigned 64-bit integers beginning at one and increasing by **exactly one** for each locally originated request on a connection, with no gaps. All three request types share that counter. IDs MUST NOT wrap or be reused on a connection. Simultaneous requests in opposite directions have independent namespaces. A responder echoes the ID; it does not allocate a new one. A receiver MUST require the first new incoming request ID to be one and every subsequent new incoming request ID to equal the previous ID plus one, across all three request types, including requests refused with Busy, Unsupported or Unavailable. Gaps, reuse or regression are protocol violations. A requester MUST NOT exceed `MAX_REQUESTS_PER_PEER` outstanding requests; a responder MAY accept fewer and return Busy for the remainder.

Useful progress means a requested, previously absent, valid result. Duplicate or malformed responses do not refresh timers. A client MUST expire a request after either the idle or absolute lifetime, and MUST stop its own serving work when its request deadline expires. Disconnect releases all request state. Expiry and cancellation do not reset the absolute age of an existing object assembly.

#### AnnounceObjects (0x01)

```text
[descriptor, ...]
```

The list contains between one and `MAX_ANNOUNCEMENTS` descriptors, in strictly ascending `object_id` order. Senders MUST announce only objects they possess in full and have validated for their kind and profile. Block sidecars additionally require validated block attachment context; inclusion-list packages require the applicable package validation, without claiming any external authorization they do not have.

An announcement is an availability hint. Receivers need not trust or store it, automatically request it, allocate its declared size, or consider it a valid proof. Repeated announcements do not create credit or extend retention deadlines. Peers SHOULD suppress unchanged announcements and rotate bounded selections fairly across useful objects. No fixed proving or broadcast interval is required by this transport.

#### GetObjects (0x02) and Objects (0x03)

```text
GetObjects = [request_id, selectors]
selector = [kind, profile_id, lookup_kind, lookup_key]
Objects = [request_id, results]
result = [status, descriptor_or_empty, auxiliary]
```

Selectors contain between one and `MAX_LOOKUPS` entries and are strictly ascending by `(kind, profile_id, lookup_kind, lookup_key)` without duplicates. `lookup_key` is 32 bytes. `lookup_kind = 0` means the primary identity: an object ID for kind one, a block hash for kind two, or a package hash for kind three. `lookup_kind = 1` is permitted only for kind one and means a transaction hash whose **full envelope** is wanted. No other lookup kind is permitted.

For the transaction-hash selector a server returns any already possessed, validated wrapper under that profile containing the requested hash as a full entry. It need not construct a new wrapper or proof. The receiver validates that full entry and its hash after retrieval; metadata alone does not establish that the selector was satisfied. Once the returned body passes complete transport integrity and structural encoding checks, that exact full entry MAY be extracted by matching the requested transaction hash to resolve the **original** wrapper. This extraction does not require resolving unrelated hash entries or verifying the returned wrapper as a package; it does not admit or relay that returned wrapper. The original wrapper still requires its own complete dependency-union, proof and transaction checks. A client MUST NOT create recursive hash-recovery chains merely to obtain this one envelope. The receiver MAY choose a different returned wrapper object and recover its dependencies normally, subject to the same request, unresolved-wrapper and verification budgets. An unavailable full-entry wrapper returns Unavailable. This lookup also provides the recovery route for transaction envelopes too large for Transactions messages.

Results correspond one-for-one in selector order. A non-OK result contains an empty byte string in both remaining fields. For OK, `descriptor_or_empty` is the descriptor; `auxiliary` is the header skeleton for kind two and the empty byte string for other kinds. A kind-two server MUST provide the canonical skeleton and sidecar for the requested profile and block. All descriptor and auxiliary hashes MUST be checked before retaining metadata. An announcement of a block-sidecar descriptor does not carry a skeleton; the receiver retrieves it with GetObjects before requesting chunks, unless already locally known.

The complete uncompressed Objects response is at most `MAX_METADATA_RESPONSE_BYTES`, including outer RLP and result fields. If OK results would exceed the ceiling, the responder returns Busy for the remaining entries. It MUST NOT omit entries, split the response or exceed `MAX_MESSAGE_BYTES`. A client reserves metadata capacity before accepting it; it need not retain every valid result.

Statuses are `0 = OK`, `1 = Unavailable`, `2 = Busy`, `3 = Unsupported`, `4 = TooLarge`. An OK descriptor MUST match the selector, apply to the requested common profile, and be no larger than the requester's advertised ceiling. Unavailable includes unknown or no-longer-retained objects. Busy means local resource pressure, with no promise of a later response. Unsupported includes a well-formed noncommon profile or unimplemented optional kind. TooLarge permits identifying an object outside the advertised receive ceiling without sending it.

The response is terminal for this request. A request does not require the peer to run a prover, fetch from another peer, serve historical objects indefinitely, or allocate an object it does not already possess.

#### GetChunks (0x04), Chunk (0x05), and Complete (0x06)

```text
GetChunks = [request_id, object_id, indices]
Chunk = [request_id, object_id, index, chunk_bytes, branch]
Complete = [request_id, object_id, status]
```

The requester MUST already have accepted a well-formed descriptor for `object_id`, from an announcement, an Objects response, or locally derived metadata. Indices are a strictly ascending list of between one and `MAX_CHUNKS_PER_REQUEST` unsigned 32-bit integers less than `N`. The request grants credit for precisely those indices: at most 2 MiB of body data plus bounded branch/message overhead. A new request is required for further indices.

The server sends at most one Chunk per requested index, in request order, and MUST NOT send unsolicited indices or merge several chunks into one message. The object ID, exact chunk length and branch depth MUST match the retained descriptor. A server MAY stop early due to unavailability or pressure, but MUST send Complete if the connection is live. Complete statuses are `0 = Served`, `1 = Unavailable`, `2 = Busy`, `3 = Unsupported`, `4 = Cancelled`, `5 = TooLarge`. Served means that all requested chunks were written before Complete; it does not mean that the receiver reconstructed, verified or admitted the object.

A Chunk can arrive only for an outstanding GetChunks request and a requested index. Clients MUST verify its geometry and branch before retaining chunk bytes. An identical duplicate MUST NOT allocate again or refresh progress. A conflicting chunk is invalid even if another peer supplied a valid chunk for the same index. The receiving client SHOULD retain valid chunks from other peers when one peer fails.

Complete is terminal and frees unused credit. A Served status with missing chunks is a protocol violation unless those chunks were deliberately discarded by local policy. Bytes discarded locally may be requested again. No request is automatically expanded to fetch the remaining object.

#### Cancel (0x07)

```text
[request_id]
```

Cancel refers to a request originated by the cancelling peer. The responder MUST stop scheduling new work for it. For a live GetChunks request it MUST return Complete with Cancelled unless a terminal Complete has already been written. A currently writing Chunk may finish first. Metadata and transaction requests produce at most one response; if it has already been written, Cancel has no effect.

Until a terminal response or local expiry, the requester retains the bounded live request record and may discard its credited in-flight responses without copying them. On retirement it removes that record. A response for an already issued but no longer live ID MUST be discarded before object allocation or proof work, including after terminal response or expiry. A response ID greater than the highest locally issued ID, or zero, is unsolicited and invalid. This distinction requires only the monotonically increasing highest-issued counter and the bounded live map, not an unbounded tombstone set; retired responses grant zero credit. Clients MUST still enforce framing, size and local incoming-rate bounds when discarding late messages. An unknown or already completed Cancel is ignored. Cancellation is local transfer control, not a withdrawal of transaction, block or inclusion-list validity. Cancelling one peer's transfer MUST NOT discard chunks retained from other peers.

#### GetTransactions (0x08) and Transactions (0x09)

```text
GetTransactions = [request_id, transaction_hashes]
Transactions = [request_id, results]
result = [status, transaction_envelope_or_empty]
```

Hashes are a strictly ascending list of one to `MAX_TXS_PER_REQUEST` distinct hashes and MUST be referenced by a retained wrapper being recovered. The request grants no authorization to insert transactions into a pool. A client MUST bound concurrent unresolved wrappers and requested hashes, and MUST NOT recursively request arbitrary hashes supplied outside these wrappers.

Results correspond one-for-one in request order and use the same statuses as Objects. An OK value is a canonical transaction envelope whose hash matches the requested hash. Other statuses contain the empty byte string. The complete uncompressed Transactions RLP message, including request ID, lists, statuses and prefixes, is limited to `MAX_TX_RESPONSE_BYTES`; the responder MUST report Busy for remaining entries which would exceed that limit and TooLarge for an individual envelope which cannot fit with its result and whole-response overhead, even if all other entries carry empty non-OK results. It MUST NOT split a transaction across these messages. Recovery of a large envelope uses GetObjects with the kind-one transaction-hash selector to discover an existing wrapper containing its full entry, followed by ordinary bounded chunk retrieval, not an unbounded transaction response. A requester MAY reuse the negotiated ETH transaction-recovery protocol instead, under its existing bounds.

After recovery the receiver recomputes the exact wrapper dependency union, verifies every required proof and applies normal transaction admission. Pool rejection, nonce changes or fee policy are not chunk-transfer protocol violations. Absence of an entry is not evidence of malicious behavior.

### Reassembly, resume, and multiple peers

Clients MUST track one retained assembly per object ID, with verified chunks indexed by their canonical indices. Received indices MAY be out of order across different requests and peers. A receiver resumes by requesting only missing indices; no additional resume token is needed. Existing chunks MUST NOT be attributed to a new peer merely because that peer announces the same object.

Before allocating or copying a chunk, clients MUST account for its actual bytes, branch metadata, assembly bookkeeping and pending verification work against finite per-peer and global budgets. A declared object length MUST NOT trigger allocation of that total length. Implementations MAY stream completed objects into an appropriately bounded store rather than concatenate in memory. If a completion copy is used, its additional storage MUST be reserved before the copy and remain charged through validation and admission.

Assemblies expire on both idle and absolute deadlines using a timer that runs without further incoming messages. Only a newly verified, previously absent chunk refreshes idle time. Repeated duplicates, new sources, new requests or descriptor replay MUST NOT renew absolute lifetime. Expiry releases incomplete bytes and metadata. A completed object waiting for validation remains subject to separate finite bytes/count/work budgets; moving it between queues MUST NOT release accounting while the bytes remain retained.

Receivers SHOULD distribute disjoint missing ranges across useful peers, limiting duplicate requests and total outstanding credit. They MAY retry a stalled range on another peer within the assembly's lifetime. Authentication failures affect the responsible source, not a healthy source's retained bytes. A disconnected or unavailable peer does not invalidate the object. Clients MUST bound source lists, announcements, completed-object caches, cancellation records, duplicate caches and retry schedules, including under many peers or many identities.

No peer is required to retain all requested indices after local eviction. A later Unavailable or Busy response is legitimate. Progress is not guaranteed under adversarial withholding or insufficient local capacity.

### Validation and relay

After all chunks are present, the receiver MUST check exact length, full content hash, canonical Merkle root and canonical object encoding. It MUST then apply the kind's full proof and context validation. Cryptographic verification uses the locally configured activated profile, including its byte and work bounds. Transaction or package metadata provided by the sender MUST NOT substitute for authenticated proof claims.

A receiver MUST NOT announce, supply to other peers, admit, or reaggregate chunks from an unverified object merely because they verify against a peer-announced root. The same restriction applies when a peer claims that the content belongs to a known block: knowing a block hash or raw proof hash does not authenticate that peer's independently chosen Merkle root.

Early chunk relay is permitted only if an independent, activated authentication mechanism authenticates the **exact descriptor root and all fields in `S`**, or if the receiver has already reconstructed and fully validated that exact object and independently derived its root. This EIP defines no additional producer signature or consensus Merkle-root commitment. In its base operation, new objects therefore require full validation before relay. RLPx authenticates a connection's peer; it does not make its announced proofs trustworthy.

Full proof validity and transaction admission are distinct. A valid wrapper whose transaction fails local pool policy MAY be retained as a verified proof object under local policy, but MUST NOT be represented as an admitted transaction. No Complete status is an admission acknowledgement. Senders MUST NOT treat a completed write as proof that a peer will retain or admit the object indefinitely.

### Scheduling and error behavior

Senders MUST apply backpressure before serializing queued chunks and MUST yield scheduling opportunities between complete Chunk messages. Proof traffic MUST NOT prevent already queued base-protocol control traffic from being serviced at the next message boundary. A sender MUST NOT queue the complete object as an unbounded series of serialized messages. Request credit bounds queued responses; implementations SHOULD use smaller writable-channel windows and fair scheduling across objects, peers and other negotiated capabilities. Bytes already being written cannot be preempted.

Malformed canonical encodings, bad branches, inconsistent geometry, mismatched recovered transaction hashes, unsupported field values, unsolicited credit violations and invalid full proof statements are invalid peer data. Clients MUST discard the invalid contribution and stop its associated transfer. They MAY disable lean, disconnect or penalize the responsible peer under bounded local policy. Structural size violations MUST be rejected before large allocation or decompression; framing errors use the existing RLPx error behavior.

Ordinary incompatibility, Unavailable, Busy, TooLarge, local queue exhaustion, healthy cancellation, expiry and valid-proof pool rejection MUST NOT by themselves be classified as malicious proof data. Unsupported requests receive the defined status rather than being reinterpreted as another codec. Unknown message IDs are protocol violations. Late data for an already issued, retired request is ignored before payload copying and receives zero credit; unrequested future IDs receive no memory or work allocation and are invalid.

Verification and proving queues MUST have finite concurrency and backlog limits. Repeated Busy results MUST NOT create an unbounded retry queue. Clients SHOULD reduce or stop requests from sources repeatedly sending invalid data or consuming credit without useful progress. Local policy MAY use rate and abandonment limits, but SHOULD tolerate isolated stalls and MUST count only actual new progress when refreshing timers.

## Rationale

Fixed chunks and exact domains give one tree per descriptor and avoid geometry negotiation, ambiguous padding and high-bit index aliases. A small request window limits retained data and permits recovery without inviting an entire unsolicited object. Metadata queries also permit asking for a known block proof without scanning announcements.

Profile IDs separate transport compatibility from verifier compatibility. Keys and consensus bounds belong to the chain's activated proof specification; a networking handshake cannot safely select arbitrary peer-supplied verifiers.

[EIP-8411](./eip-8411.md) authenticates its chunk root through a validated builder bid. This proposal uses that commitment distinction, but new proof objects have no equivalent signed root in the base protocol. Consequently, branch verification supports integrity and multi-source retrieval, while full verification precedes relay. Merkle authentication is not a claim that unsigned announcements are consensus trusted.

Request-driven transfer replaces indiscriminate rebroadcast with explicit demand. Fair announcement rotation and bounded selection complement [EIP-8288](./eip-8288.md)'s aggregation cadence without requiring every active transaction to fit into one wrapper or assigning a fixed proving-time deadline.

Block sidecars provide a common transfer mechanism for existing proof bytes. The header skeleton permits reconstruction of the original canonical header without a single large header write, while consensus attachment and inline header contents remain intact. Changing that canonical header format would be a separate Core change.

## Backwards Compatibility

Peers exchange proof objects only after negotiating `lean/1` and accepting the Status defined in this specification. Clients must use the specified encodings; they must not auto-detect another codec or silently downgrade. Well-formed incompatible Status disables this capability while preserving other negotiated protocols where possible.

Clients without this capability continue using their existing protocols. This EIP does not change RLPx, transaction/block validity, the block hash, Engine API encodings or inclusion-list obligations. Transport availability is not a new consensus prerequisite.

## Test Cases

The commitment vectors below use `kind = 1`, a 32-byte zero profile ID, empty context, and `body[i] = i % 251`. They test the commitment codec only; the synthetic bodies and zero profile are not valid mempool objects. Hex strings omit `0x`. The branch is for the final real chunk, listed from leaf upward.

```json
[
  {
    "size": 1,
    "chunk_count": 1,
    "content_hash": "bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a",
    "context_hash": "c0f2b9dd6c5fa856eedea5db76f1e33f1c263f5ebf391755b7d6cb2216100f3f",
    "last_leaf": "21738102e26669e761d6e6828f6e7642b560948e39e89efd18a05cf1ac9f9788",
    "padding_leaf": null,
    "chunk_root": "1deb89d1898605e8b1bbf8af186a1efeaa5d828f3587a30cf015ac684e692484",
    "object_id": "d39b2e3efc881ed2746601367bd3985a6707d29426ea14ed339ca992e8eb94e6",
    "last_index": 0,
    "branch": []
  },
  {
    "size": 65537,
    "chunk_count": 2,
    "content_hash": "4faa2deae4c869a3cddf91ae8646575699f5d568e57df4914b0536d59bf6a4c9",
    "context_hash": "c0f2b9dd6c5fa856eedea5db76f1e33f1c263f5ebf391755b7d6cb2216100f3f",
    "last_leaf": "c650f7216ac9af040a4d7186f70cd12d0e7c8183e72a42dbcb9af09a9f7451ec",
    "padding_leaf": null,
    "chunk_root": "ff33e4b630c69ecd67518e1213f5a648df50fc1b5c7a8592439e2f4c5ca21e7e",
    "object_id": "ee5cedb6e340e576b1d4b7d6be2002bbac911e1ee26db7a18587b7f8ee616028",
    "last_index": 1,
    "branch": [
      "b17ef669920b42856d351293191ee28da75c15de4d483c535d333d86b05adaea"
    ]
  },
  {
    "size": 131073,
    "chunk_count": 3,
    "content_hash": "35ae5a437a69fef01f453512998f4e90f1ba613a1d10962f80ebefcc836dbd09",
    "context_hash": "c0f2b9dd6c5fa856eedea5db76f1e33f1c263f5ebf391755b7d6cb2216100f3f",
    "last_leaf": "c733e3dfb0db3dd59d8b5e30b1a8efda92b67ac886c0835c47ccc7d5a169b0c3",
    "padding_leaf": "95da608e046232746cce65132a6525b04d1104a68ef4eb2cdb6787d2493baf7b",
    "chunk_root": "c648bf887bb5c49d3eba6a968f6e21507ea3ca0a61120aa16e7c980baf7434cd",
    "object_id": "f0d141fc8ee27459e661bd8459f51199967afdcb76b0155459b660954be94fe2",
    "last_index": 2,
    "branch": [
      "95da608e046232746cce65132a6525b04d1104a68ef4eb2cdb6787d2493baf7b",
      "0d2a51ca27b23b2e78b66c81dd790fccc2fb1fe65e01a41c867f62798ee4d181"
    ]
  }
]
```

The following message-data vectors exclude the capability message ID and RLPx framing:

| Message | Decoded value | Canonical hex |
| --- | --- | --- |
| GetChunks | request 7, the three-chunk object above, indices `[0, 2]` | `e507a0f0d141fc8ee27459e661bd8459f51199967afdcb76b0155459b660954be94fe2c28002` |
| Cancel | request 7 | `c107` |
| Wrapper body, codec-only | one full entry with envelope `7f00`, mode zero, empty dependencies/proofs | `cac5c480827f0080c2c0c0` |

The final row demonstrates tagged byte-string encoding only; its synthetic transaction is invalid and is rejected by transaction validation.

Rejection cases also include zero-length bodies, objects above the negotiated ceiling, nonminimal RLP integers, duplicate or unsorted transaction hashes, ambiguous untagged entries, wrong dependency widths, oversized announcement/request lists, duplicate requested indices, indices equal to `N`, wrong final-chunk lengths, wrong branch depth, noncanonical padding, changed profile/context/content hash, and chunks without outstanding credit.

Lifecycle cases cover interrupted resume, disjoint ranges from two peers, corrupt bytes from one peer while preserving a healthy peer's chunks, cancelling during a write, duplicate chunks not extending idle time, absolute expiry despite new sources, expiry without incoming packets, completion-copy pressure, bounded verification Busy, unknown hash recovery, pool rejection after a valid proof, and control traffic between chunk writes. Block-sidecar cases cover correct full-header reconstruction and hash, incorrect double-RLP encoding of already encoded fields, a misplaced or nonempty proof placeholder, wrong fork field count or index, wrong skeleton hash, a correct proof with a changed non-proof header field, and oversized or excessively nested auxiliary metadata rejected before proof allocation. A sidecar is also rejected when a peer's self-consistent descriptor does not match the independently established header/body context.

## Security Considerations

Announcements are untrusted offers. Peer identity, an object hash and a valid branch do not make proof claims true. Credit and finite memory/work budgets are required even for structurally correct chunks; many identities can otherwise fill storage with objects which never become useful. Commitment formulas bind length, index, kind, profile and context, while full profile verification binds the actual EIP dependency claims.

Merkle collision resistance does not authenticate an arbitrary root. Forwarding chunks against an unanchored root amplifies spam and is forbidden. The canonical full-object hash and Merkle root must both be checked; inconsistent padding or alternative chunk trees are not alternate encodings of an accepted object.

Reassembly must remain charged through cryptographic verification and admission, including replacement queues and disconnect races. Absolute deadlines prevent slow streams from retaining memory indefinitely. Integer arithmetic for counts, offsets, remaining lengths and credit must be checked before allocation. Proof decoders require profile-specific work and allocation preflight in addition to transport byte bounds.

Chunking allows messages to interleave on a connection; it does not remove TCP loss head-of-line blocking, reduce cryptographic proving work, ensure block availability, or guarantee completion within a slot. Proof validity cannot be inferred from delivery timing. An unavailable sidecar or unsupported local profile must not become a new consensus-invalidity rule.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
