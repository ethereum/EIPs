---
title: Variable-Size Blobs
description: Extends post-quantum PeerDAS with power-of-two blob sizes and size-aware resource accounting
author: Francesco Risitano (@frisitano)
discussions-to: https://ethereum-magicians.org/t/eip-8479-post-quantum-peerdas-and-variable-size-blobs/30167
status: Draft
type: Standards Track
category: Core
created: 2026-11-24
requires: 7688, 7732, 7805, 7892, 7918, 8070, 8136, 8141, 8288, 8408, 8479, 8512
---

## Abstract

This EIP extends [EIP-8479](./eip-8479.md) Peer Data Availability Sampling (PeerDAS) with variable-size blobs while keeping 128 columns. It introduces signed codeword lengths, length-bound commitments and versioned hashes, size-aware validation and resource accounting. EIP-8479 remains independent of this extension. Fee-transition and activation requirements remain unresolved as specified below.

## Motivation

Fixed-size blobs force a sender with less than one blob of data either to pay for unused capacity or to delay publication while batching additional data. Variable-sized blobs allow smaller publications without waiting for a full batch. Keeping the same number of columns preserves the PeerDAS column structure, while varying the bytes per cell changes the capacity per blob.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Prerequisite and Scope

This EIP requires EIP-8479. It reuses its Merkle tree, binary field, additive Reed–Solomon relation, challenge derivation, proof public inputs and successful Boolean result. The commitment formats and their length binding are defined by this EIP. Except for the changes specified here, its transaction, proof, network and consensus rules apply, including the [EIP-8141](./eip-8141.md) frame transaction and [EIP-8288](./eip-8288.md) dependency proof.

In the variable profile, the size predicate, size-dependent guest dimensions, cell type and transaction byte bound below replace the fixed-profile rules. The fixed profile remains unchanged when this extension is inactive. Shared names refer to EIP-8479 definitions; they are not a second authority for those definitions.

### Constants and Units

Blob byte lengths count rate-1/2 codeword bytes in EIP-8479's binary-field representation. A codeword of `blob_byte_length` bytes encodes `blob_byte_length // 2` nominal data bytes. A 262144-byte codeword carries 131072 nominal data bytes. Cell byte lengths vary while the number of columns remains 128.

| Name | Value | Definition |
| - | - | - |
| `MIN_BLOB_BYTES` | `2048` | Minimum permitted codeword byte length |
| `MAX_BLOB_BYTES` | `1048576` | Maximum permitted codeword byte length |
| `MAX_CELL_BYTES` | `8192` | Maximum cell byte length |
| `MAX_BLOBS_PER_TX` | `1` | Maximum number of blobs referenced by a transaction |

`NUMBER_OF_COLUMNS = 128`, `MERKLE_DEPTH = 7`, `HASH_BYTES = 32` and the cryptographic domain prefixes remain EIP-8479 values. This EIP replaces its six-blob transaction limit with one blob per transaction; the block limits are specified separately. The fixed `CODEWORD_BYTES`, `DATA_BYTES` and `CELL_BYTES` constants do not constrain the variable profile.

### Size Validation and Merkle Commitments

```python
def is_power_of_two(value: int) -> bool:
    return value > 0 and (value & (value - 1)) == 0


def is_valid_blob_byte_length(blob_byte_length: uint64) -> bool:
    return (
        MIN_BLOB_BYTES <= blob_byte_length <= MAX_BLOB_BYTES
        and is_power_of_two(blob_byte_length)
        and blob_byte_length % NUMBER_OF_COLUMNS == 0
    )
```

The permitted codeword sizes are 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288 and 1048576 bytes. Their cells have lengths 16 through 8192 bytes in powers of two. Clients MUST reject any other length before allocation, hashing or proof verification.

In the variable profile, `Blob` is a byte list bounded by `MAX_BLOB_BYTES`, not EIP-8479's fixed byte vector. Decoders MUST additionally enforce the permitted-size predicate. The Merkle helper is:

```python
def compute_blob_merkle_root(data: Blob) -> Bytes32:
    assert is_valid_blob_byte_length(len(data))
    cell_bytes = len(data) // NUMBER_OF_COLUMNS
    nodes = [
        keccak256(data[i * cell_bytes:(i + 1) * cell_bytes])
        for i in range(NUMBER_OF_COLUMNS)
    ]
    while len(nodes) > 1:
        nodes = [
            keccak256(nodes[i] + nodes[i + 1])
            for i in range(0, len(nodes), 2)
        ]
    return nodes[0]
```

The remaining leaf ordering, `keccak256` leaf hashes, binary tree construction and depth are unchanged. Every blob still has 128 leaves and every authentication path still has seven ordered sibling hashes.

### Length-Bound Commitments and Versioned Hashes

EIP-8479's root-only commitment is replaced with the following value in the variable profile:

```python
class BlobCommitment:
    blob_merkle_root: Bytes32
    blob_byte_length: Uint64
```

`blob_merkle_root` is exactly 32 bytes and `blob_byte_length` is an unsigned 64-bit codeword byte length. Each transaction commitment is encoded as the RLP list `[blob_merkle_root, blob_byte_length]`, with the length encoded as a canonical RLP integer. The consensus SSZ commitment is a `Container` with the same `Bytes32` and `Uint64` fields in that order. The transaction signature MUST bind both fields.

The canonical commitment-list encoding replaces EIP-8479's root-list encoding:

```python
def encode_blob_commitments(
    blob_commitments: list[BlobCommitment],
) -> Bytes:
    return (
        uint64_le(len(blob_commitments))
        + b"".join(
            commitment.blob_merkle_root
            + uint64_le(commitment.blob_byte_length)
            for commitment in blob_commitments
        )
    )
```

EIP-8479's binding-commitment and challenge-seed functions use this encoding, retaining their separate domain prefixes and the ordered list's count. Receivers MUST validate the signed length and MUST NOT reinterpret a root under another length.

The proposed variable-profile version byte is `VARIABLE_PQ_VERSION = 0x03`, distinct from EIP-8479's `PQ_VERSION = 0x02`. Its final allocation requires protocol coordination before activation. The versioned hash replaces EIP-8479's root-only construction with:

```python
def blob_commitment_to_versioned_hash(
    commitment: BlobCommitment,
) -> Bytes32:
    digest = keccak256(
        commitment.blob_merkle_root
        + uint64_le(commitment.blob_byte_length)
    )
    return Bytes32(bytes([VARIABLE_PQ_VERSION]) + digest[1:])
```

`BLOBHASH` (`0x49`) and Engine API `versionedHashes` use this length-bound hash in the variable profile. Fixed-profile versioned hashes retain their original root-only meaning.

### Guest and Proof Binding

The variable profile uses the same binary symbol field, 16-byte symbol encoding, additive evaluation domain, membership-vector recurrence and two ordered challenges as EIP-8479. In `verify_reed_solomon_relation`, input decoding enforces the valid-size predicate above and the fixed `k` is replaced with:

```python
symbols = [
    decode_field_element(data[i:i+16])
    for i in range(0, len(data), 16)
]
k = len(symbols) // 2
log_k = k.bit_length() - 1
```

The recurrence and inner-product checks are otherwise unchanged. Both membership checks MUST pass independently for every blob; residuals MUST NOT be combined across challenges or blobs. The same ordered challenge pair is used for every blob in a proof batch. A transaction has only one blob; a batch combining transactions may contain different blob sizes, subject to the final proof-batching integration. The binding commitment and challenge seed remain distinct hashes with distinct domain prefixes. The host derives both challenges from the signed ordered commitments; the guest recomputes the binding commitment from private blobs and uses the supplied public challenges. Proof verification MUST bind both public input values and the successful `True` result to the expected domain-separated public-input digest.

The guest derives a length-bound commitment from each private blob:

```python
def derive_blob_commitment(blob: Blob) -> BlobCommitment:
    assert is_valid_blob_byte_length(len(blob))
    return BlobCommitment(compute_blob_merkle_root(blob), len(blob))
```

A fixed-profile proof cannot establish validity of a differently sized blob. The variable guest accepts a different input language and therefore requires its own reviewed program and verification-key binding. The variable-profile key, EIP-8288 registration/dispatch and scheme compatibility are unresolved; this draft does not allocate a scheme identifier, reuse the fixed key for a new program or claim a working verifier. These choices MUST be resolved before activation. EIP-8288 integration and proof-budget questions deferred by EIP-8479 remain unresolved here.

### Frame Transaction and EVM Rules

The [EIP-8141](./eip-8141.md) frame transaction and mandatory dependency-frame structure are inherited. Its signed `blob_commitments` field uses the RLP pairs defined above; `TXPARAM_BLOB_COUNT` counts these commitments and [BLOBHASH](./eip-8479.md#blobhash-opcode) uses their variable-profile versioned hashes. In the variable profile, a blob-carrying frame transaction is valid only if:

```python
assert len(tx.blob_commitments) == MAX_BLOBS_PER_TX
assert is_valid_blob_byte_length(tx.blob_commitments[0].blob_byte_length)
```

An empty list continues to denote a frame transaction without blobs. A blob-carrying transaction contains exactly one commitment, whose signed length is at most `MAX_BLOB_BYTES`. `TXPARAM_BLOB_COUNT` therefore returns zero or one; `BLOBHASH` returns zero for every index greater than zero. The valid-size bound already enforces the per-transaction byte ceiling, so no separate aggregate-byte limit is needed.

### Cell Transport and Reconstruction

EIP-8479 owns the provisional `eth/76` sparse blobpool transport and its inheritance of [EIP-8070](./eip-8070.md), [EIP-8408](./eip-8408.md) indexed requests and [EIP-8512](./eip-8512.md) dependency-proof exchange. This draft does not allocate another protocol version or change message identifiers. The final profile negotiation/version allocation remains an activation requirement; a fixed-profile peer MUST NOT receive an unsupported variable-length cell merely because it negotiated the provisional PQ transport.

Shared/indexed masks, request IDs, canonical mask tables, transaction/blob/cell ordering, empty responses, subset checks, wrapper validation and proof-wrapper-only propagation remain EIP-8479 rules. Each returned cell MUST have exactly `commitment.blob_byte_length // NUMBER_OF_COLUMNS` bytes; the signed length MUST first pass the variable-size predicate. Transactions in one indexed response may have different blob sizes and cell lengths; each blob-carrying transaction has exactly one blob.

Path omission remains per blob: fewer than 64 returned cells requires one path per cell; 64 through 127 requires no paths and reconstruction; 128 requires no paths and direct full-tree verification. Reconstruction MUST use that blob's signed length, binary-field encoding, cell layout and returned column indices. Failed reconstruction, inconsistent returned cells or a reconstructed Merkle root differing from the signed root MUST cause rejection. No new sparse reconstruction helper or recovery threshold is introduced.

EIP-8479's `engine_getBlobsV5` response shape, request parameters, one-second timeout, `null` ordering and authentication-path rules remain unchanged. Each returned cell is validated against the variable signed length. The Engine API profile/version negotiation for the widened accepted sizes MUST be resolved before activation; this draft does not silently redefine the fixed profile for existing callers.

### Consensus Containers and Limits

The progressive commitment/path lists, [Heze execution payload bid](https://github.com/ethereum/consensus-specs/blob/d2021d2719235f0df4726a1d330502cb15aa8ea3/specs/heze/beacon-chain.md#executionpayloadbid), full sidecar and [EIP-8136](./eip-8136.md) partial-column message structures remain EIP-8479 definitions, incorporating [EIP-7732](./eip-7732.md), [EIP-7805](./eip-7805.md) and [EIP-7688](./eip-7688.md). In the variable profile, its fixed `Cell` type is replaced by:

```python
class Cell(ByteList):
    LIMIT = MAX_CELL_BYTES
```

`ByteList` bounds allocation but does not establish the correct length. The full and partial sidecar verifiers MUST validate the signed length and each selected cell's length before authentication:

```python
if not is_valid_blob_byte_length(commitment.blob_byte_length):
    return False
if len(cell) * NUMBER_OF_COLUMNS != commitment.blob_byte_length:
    return False
```

Their Merkle-root comparison uses `commitment.blob_merkle_root` in place of EIP-8479's root-only `commitment`. Every retained index, count, bitmap, path length, root and ordering check still applies. A partial column contains one cell per selected blob, not all cells of a blob, so authentication paths remain required even when every bitmap bit is set. Commitment ordering in bids and Engine API `versionedHashes` remains unchanged. Custody assignments, subnets, sampling counts, retention and recovery threshold remain the inherited PeerDAS rules; varying sizes does not prove their performance or security at the new workload.

The baseline block commitment count cannot simply be retained when a gas budget admits many small blobs. Variable-profile consensus and execution limits MUST agree on both the active block bound and the serialization/network capacity required across the complete supported schedule. Selecting those bounds, including the pre-schedule fallback, is unresolved as described below.

### Proposed Fees and Schedules

The proposed charge is one gas unit per nominal data byte plus an internal-node allowance. The following arithmetic changes EIP-8479's baseline pricing; fee-transition rules remain unresolved below.

| Name | Value | Definition |
| - | - | - |
| `NUMBER_OF_INTERNAL_NODES` | `127` | Internal nodes in the 128-leaf tree |
| `FIXED_MERKLE_BYTES_SIZE` | `4064` | `127 * 32` accounted bytes per blob |
| `FULL_BLOB_GAS` | `135136` | Candidate charge for a 262144-byte codeword |

```python
def blob_gas(commitment: BlobCommitment) -> uint64:
    assert is_valid_blob_byte_length(commitment.blob_byte_length)
    return (
        commitment.blob_byte_length // 2
        + NUMBER_OF_INTERNAL_NODES * HASH_BYTES
    )


def transaction_blob_gas(tx: FrameTransaction) -> uint64:
    return sum(blob_gas(c) for c in tx.blob_commitments)


def ceil_div(numerator: uint64, denominator: uint64) -> uint64:
    return (numerator + denominator - 1) // denominator
```

The allowance accounts for unique internal nodes in a complete Merkle tree, not actual per-peer path bytes. It is a proposed pricing choice, not an unavoidable cryptographic cost. A nominal fixed-capacity blob would cost `131072 + 4064 = 135136` gas in this candidate, whereas EIP-8479 alone charges exactly `131072` gas.

The proposed schedule conversion is:

```python
target_blob_gas = blob_schedule.target * FULL_BLOB_GAS
max_blob_gas = blob_schedule.max * FULL_BLOB_GAS
base_fee_update_fraction = ceil_div(
    blob_schedule.base_fee_update_fraction * FULL_BLOB_GAS,
    GAS_PER_BLOB,
)
```

Here `GAS_PER_BLOB = 131072` is the EIP-8479 baseline unit and `blob_schedule` is the current block's baseline [EIP-7892](./eip-7892.md) schedule. This candidate rescales schedule budgets and the update fraction; rounding does not establish exact fee-path equivalence. Its intended block accounting sums `transaction_blob_gas(tx)`, checks the active gas maximum and matches header `blob_gas_used`; frame-transaction fee reservation/payment would use that sum. Header field types and `MIN_BASE_FEE_PER_BLOB_GAS` remain unchanged.

A candidate serialization/network commitment bound uses the cheapest blob:

```python
maximum_scheduled_blob_gas = max(
    entry["MAX_BLOBS_PER_BLOCK"] * FULL_BLOB_GAS
    for entry in BLOB_SCHEDULE
)
max_blob_commitments_per_block = (
    maximum_scheduled_blob_gas
    // (MIN_BLOB_BYTES // 2 + FIXED_MERKLE_BYTES_SIZE)
)
```

`BLOB_SCHEDULE` here denotes the consensus configuration sequence of scheduled blob-limit entries. This expression is not a sufficient definition of a complete schedule: it omits the baseline maximum before its first entry and is undefined for an empty sequence. A per-transaction one-blob cap does not bound total commitments across a block. The correct complete-schedule maximum, active count/resource bounds and matching EL/CL limits require a decision.

### Unresolved Activation Requirements

This draft MUST NOT be treated as an activation-ready specification until the following choices have been resolved:

- Accept or replace the proposed Merkle allowance and size-based charge, with justified resource limits for minimum-size blobs.
- Define all schedule units and later schedule entries, active and complete-schedule maxima, and EL/CL capacity agreement, including empty schedules and the pre-first-entry baseline.
- Define the first variable-profile block's handling of parent `excess_blob_gas` and `blob_gas_used`, update-fraction rounding and later schedule changes. No reset or conversion is specified by this formula.
- Reconcile the variable charge and schedule conversion with the applicable [EIP-7918](./eip-7918.md) reserve-price rule. Its fixed per-blob price comparison cannot be assumed to generalize to arbitrary sizes. The conversion above alone is insufficient.
- Complete variable guest verification-key/profile registration, EIP-8288 proof limits and recursive integration, and the network/Engine API negotiation and fork-specific SSZ decoding for the changed `Cell` type.

Until resolved, the fee formulas above support review and arithmetic vectors only. They do not define a valid activation, fee transition or interoperability test.

### Composition and Fork Boundaries

| PQ PeerDAS | Variable-size extension | Behavior |
| - | - | - |
| Inactive | Inactive | Applicable pre-PQ data availability and fees |
| Active | Inactive | EIP-8479 fixed codewords and unchanged baseline blob fees |
| Inactive | Active | Invalid composition; prerequisite absent |
| Active | Active | Variable profile; activation blocked by the unresolved requirements above |

The extension requires prior or coordinated EIP-8479 activation, with every unresolved integration choice completed. This draft assigns no activation timestamp. EIP-8479 does not reference or require this extension. Historical fixed-profile data retain their original fork-selected decoding and fees. Variable sizes MUST NOT be accepted before variable-profile activation; transport negotiation alone does not enable transaction validity. EIP-8479's transaction-pool, dependency and fork-decoding rules continue to apply. The treatment of pending fixed-profile proofs/transactions at variable activation requires the final key/profile transition design.

## Rationale

Keeping 128 columns preserves the existing PeerDAS column layout while allowing cell byte lengths to vary. One blob per transaction gives each transaction one size and one commitment. The 1 MiB codeword ceiling permits at most 8 KiB per cell and 512 KiB of nominal data per transaction. This is one third less than the six fixed blobs permitted by EIP-8479, which together encode 768 KiB of nominal data. The lower transaction ceiling is an initial limit, not a claim that larger cells are unsafe. Signing the codeword length prevents a root from being interpreted at another size. The one-way dependency on EIP-8479 reuses its proof construction while keeping size-specific changes in this EIP. Codeword sizes are powers of two because the additive evaluation domain is a binary linear subspace: it has `2*k` points for a power-of-two `k`, and the membership recurrence uses `log2(k)` basis polynomials. Non-power-of-two sizes need a different encoding or padding rule.

The candidate fee convention accounts for nominal data bytes and one set of internal Merkle nodes. Its resource-pricing tradeoff, fee transition and schedule maxima remain open rather than being silently incorporated into the fixed-size PQ proposal.

## Backwards Compatibility

This is a consensus-breaking extension of post-quantum PeerDAS. The fixed profile remains a complete predecessor with unchanged pricing. Applications previously using multiple blobs in one transaction need to package their data into one supported-size blob or use multiple transactions; this EIP does not preserve the previous maximum data capacity per transaction. Variable-length cells change SSZ encoding from a fixed byte vector to a bounded byte list, and the widened guest input language needs a separately bound program. The signed length, pair encoding and variable version byte distinguish this profile from EIP-8479's root-only commitments; fixed-profile verifiers and peers do not automatically accept it. The unresolved profile, fee and activation requirements prevent claiming a complete rollout path.

## Test Cases

The following size and candidate-fee vectors are deterministic arithmetic cases. Their fees are conditional on adoption of the proposed fee rule; they do not certify activation.

| Codeword bytes | Nominal data bytes | Cell bytes | Candidate blob gas |
| - | - | - | - |
| 2048 | 1024 | 16 | 5088 |
| 4096 | 2048 | 32 | 6112 |
| 8192 | 4096 | 64 | 8160 |
| 16384 | 8192 | 128 | 12256 |
| 32768 | 16384 | 256 | 20448 |
| 65536 | 32768 | 512 | 36832 |
| 131072 | 65536 | 1024 | 69600 |
| 262144 | 131072 | 2048 | 135136 |
| 524288 | 262144 | 4096 | 266208 |
| 1048576 | 524288 | 8192 | 528352 |

Lengths `0`, `2047`, `2049`, `3072`, `1048575`, `1048577`, `1572864` and `2097152` are invalid. A transaction containing one 1048576-byte codeword is valid under the size/count rules; two blobs are invalid even when their combined size is below the byte ceiling. A transaction without blobs has an empty commitment list. Non-power-of-two sizes are not admitted to recover the old six-blob capacity.

Composition vectors cover all four activation combinations above. At fixed-profile-only activation, every size except 262144 remains invalid and the per-blob charge remains 131072. For identical 262144-byte inputs, Merkle roots match between profiles. Commitment encodings, binding commitments, seed halves, public-input digests and versioned hashes deliberately differ because the variable profile binds a length; its proposed gas charge also differs by 4064. Altering root, signed size, list count/order, either challenge, public-input domain/order or successful guest result is rejected under the corresponding inherited binding checks.

Cell tests cover every permitted cell size, mixed-size responses across transactions, shared/indexed responses and 63, 64, 65, 127 and 128 returned cells with non-contiguous indices. They retain EIP-8479's malformed-mask, request-ID, empty-response, subset, ordering, unavailable-cell, wrong-path, inconsistent-reconstruction and wrong-root negatives. Full/partial sidecars retain bitmap/list/path checks and reject cells whose lengths disagree with their selected commitment. Actual field reconstruction, guest/proof integration, network interoperability and fee-transition vectors remain required after the unresolved designs are specified; arithmetic and reference models are not substitutes for them.

## Security Considerations

EIP-8479's hash/random-oracle heuristic, two-challenge assumptions, proof binding and separation between encoding validity and data availability remain unchanged. No QROM, post-quantum security or interoperability proof is established here.

Small blobs increase commitment counts, paths and fixed work per nominal data byte; large cells change bandwidth and reconstruction work. Clients need size and list limits before allocation and verification, and per-blob resource bounds when reconstructing unauthenticated responses. The candidate Merkle allowance alone does not establish a sufficient denial-of-service budget. In particular, the retained 16-byte minimum cell is smaller than its 32-byte leaf digest and has a 224-byte Merkle path. This is not a cryptographic invalidity, but its overhead and minimum-cell choice require resource analysis. Mixed-size availability and fee incentives require analysis before activation. The guest-key, profile-negotiation and fork-decoding decisions are security boundaries; accepting a proof or cell under the wrong profile can bypass the intended size constraints.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
