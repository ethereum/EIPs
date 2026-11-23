---
title: Variable-Size Post-Quantum Blobs
description: Extends post-quantum PeerDAS with power-of-two blob sizes and size-aware resource accounting
author: Francesco Risitano (@frisitano), Thomas Coratger (@tcoratger), Tom Wambsgans (@TomWambsgans), Benedikt Wagner (@benedikt-wagner)
discussions-to: https://ethereum-magicians.org/t/eip-8479-post-quantum-peerdas-and-variable-size-blobs/30167
status: Draft
type: Standards Track
category: Core
created: 2026-11-24
requires: 4844, 7594, 7688, 7732, 7805, 7892, 7918, 8070, 8136, 8141, 8288, 8408, 8479, 8512
---

## Abstract

This draft extends [EIP-8479](./eip-8479.md) post-quantum Peer Data Availability Sampling (PeerDAS) with power-of-two codeword lengths while keeping 128 columns. It extracts the variable-size rules from the combined proposal, including signed lengths, size-aware validation and resource accounting. EIP-8479 remains usable at its fixed size and unchanged baseline blob pricing without this extension. The extracted fee proposal and unresolved activation requirements are distinguished below; this draft is not an activation-ready consensus specification.

## Motivation

Fixed-size blobs force a sender with less than one blob of data either to pay for unused capacity or to delay publication while batching additional data. Variable-sized blobs allow smaller publications without waiting for a full batch. Keeping the same number of columns preserves the PeerDAS column structure, while varying the bytes per cell changes the capacity per blob.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Prerequisite and Scope

This draft requires EIP-8479. It does not define variable-size KZG blobs or a separate data-availability construction. The Merkle tree, binary field, additive Reed–Solomon relation, commitment encodings, challenge derivation, proof public inputs and successful Boolean result are owned by EIP-8479. Except for the changes specified here, its transaction, proof, network and consensus rules apply, including the [EIP-8141](./eip-8141.md) frame transaction and [EIP-8288](./eip-8288.md) dependency proof.

In the variable profile, the size predicate, size-dependent guest dimensions, cell type and transaction byte bound below replace the fixed-profile rules. The fixed profile remains unchanged when this extension is inactive. Shared names refer to EIP-8479 definitions; they are not a second authority for those definitions.

### Constants and Units

Blob byte lengths count rate-1/2 codeword bytes. A codeword of `blob_byte_length` bytes encodes `blob_byte_length // 2` nominal data bytes. This uses EIP-8479's binary-field representation, not [EIP-4844](./eip-4844.md) field serialization or application packing. A 262144-byte codeword carries 131072 nominal data bytes. Cell byte lengths vary while the number of columns remains 128.

| Name | Value | Definition |
| - | - | - |
| `MIN_BLOB_BYTES` | `2048` | Minimum permitted codeword byte length |
| `MAX_BLOB_BYTES` | `524288` | Maximum permitted codeword byte length |
| `MAX_CELL_BYTES` | `4096` | Maximum cell byte length |
| `MAX_BLOB_BYTES_PER_TX` | `1572864` | Combined codeword-byte limit per transaction; 786432 nominal data bytes |

`NUMBER_OF_COLUMNS = 128`, `MAX_BLOBS_PER_TX = 6`, `MERKLE_DEPTH = 7`, `HASH_BYTES = 32` and the cryptographic domain prefixes remain EIP-8479 values. The six-blob transaction limit originates in [EIP-7594](./eip-7594.md); it is independent of the block schedule. The fixed `CODEWORD_BYTES`, `DATA_BYTES` and `CELL_BYTES` constants do not constrain the variable profile.

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

The permitted codeword sizes are 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144 and 524288 bytes. Their cells have lengths 16 through 4096 bytes in powers of two. Clients MUST reject any other length before allocation, hashing or proof verification.

EIP-8479's `compute_blob_merkle_root` uses the following variable-profile cell length in place of its fixed `CELL_BYTES`:

```python
assert is_valid_blob_byte_length(len(data))
cell_bytes = len(data) // NUMBER_OF_COLUMNS
```

The remaining leaf ordering, `keccak256` leaf hashes, binary tree construction and depth are unchanged. Every blob still has 128 leaves and every authentication path still has seven ordered sibling hashes.

The existing `BlobCommitment` remains `(blob_merkle_root, blob_byte_length)`. The signed RLP integer length, consensus-layer `Uint64` length, canonical eight-byte little-endian commitment-list encoding and versioned hash are unchanged. The canonical list includes its count and preserves order. Receivers MUST validate the signed length with the variable predicate and MUST NOT reinterpret a root under another length.

### Guest and Proof Binding

The variable profile uses the same binary symbol field, 16-byte symbol encoding, additive evaluation domain, membership-vector recurrence and two ordered challenges as EIP-8479. In `verify_reed_solomon_relation`, the valid-size predicate is the one above and the fixed `k` is replaced with:

```python
symbols = [
    decode_field_element(data[i:i+16])
    for i in range(0, len(data), 16)
]
k = len(symbols) // 2
log_k = k.bit_length() - 1
```

The recurrence and inner-product checks are otherwise unchanged. Both membership checks MUST pass independently for every blob; residuals MUST NOT be combined across challenges or blobs. The same ordered challenge pair is used across a batch, including mixed-size batches. The binding commitment and challenge seed remain distinct hashes with distinct domain prefixes. The host derives both challenges from the signed ordered commitments; the guest recomputes the binding commitment from private blobs and uses the supplied public challenges. Proof verification MUST bind both public input values and the successful `True` result to the expected domain-separated public-input digest.

A fixed-profile proof cannot establish validity of a differently sized blob. The variable guest accepts a different input language and therefore requires its own reviewed program and verification-key binding. The variable-profile key, EIP-8288 registration/dispatch and scheme compatibility are unresolved; this draft does not allocate a scheme identifier, reuse the fixed key for a new program or claim that moving pseudocode establishes a working verifier. These choices MUST be resolved before activation. EIP-8288 integration and proof-budget questions deferred by EIP-8479 remain unresolved here.

### Frame Transaction and EVM Rules

The [EIP-8141](./eip-8141.md) signed frame transaction, RLP commitment pairs, [EIP-8479 BLOBHASH](./eip-8479.md#blobhash-opcode) opcode (`0x49`), `TXPARAM_BLOB_COUNT` and mandatory dependency frames remain unchanged in structure. In the variable profile, a blob-carrying frame transaction is valid only if:

```python
tx_blob_bytes = 0

assert 0 < len(tx.blob_commitments) <= MAX_BLOBS_PER_TX
for commitment in tx.blob_commitments:
    assert is_valid_blob_byte_length(commitment.blob_byte_length)
    tx_blob_bytes += commitment.blob_byte_length

assert tx_blob_bytes <= MAX_BLOB_BYTES_PER_TX
```

An empty list continues to denote a frame transaction without blobs. The aggregate byte cap and the six-commitment cap are both enforced; six maximum-size blobs exceed the byte cap, whereas three maximum-size blobs exactly fill it.

### Cell Transport and Reconstruction

EIP-8479 owns the provisional `eth/76` sparse blobpool transport and its inheritance of [EIP-8070](./eip-8070.md), [EIP-8408](./eip-8408.md) indexed requests and [EIP-8512](./eip-8512.md) dependency-proof exchange. This draft does not allocate another protocol version or change message identifiers. The final profile negotiation/version allocation remains an activation requirement; a fixed-profile peer MUST NOT receive an unsupported variable-length cell merely because it negotiated the provisional PQ transport.

Shared/indexed masks, request IDs, canonical mask tables, transaction/blob/cell ordering, empty responses, subset checks, wrapper validation and proof-wrapper-only propagation remain EIP-8479 rules. Each returned cell MUST have exactly `commitment.blob_byte_length // NUMBER_OF_COLUMNS` bytes; the signed length MUST first pass the variable-size predicate. Different blobs in one transaction or indexed response may have different cell lengths.

Path omission remains per blob: fewer than 64 returned cells requires one path per cell; 64 through 127 requires no paths and reconstruction; 128 requires no paths and direct full-tree verification. Reconstruction MUST use that blob's signed length, binary-field encoding, cell layout and returned column indices. Failed reconstruction, inconsistent returned cells or a reconstructed Merkle root differing from the signed root MUST cause rejection. No new sparse reconstruction helper or recovery threshold is introduced.

EIP-8479's `engine_getBlobsV5` response shape, request parameters, one-second timeout, `null` ordering and authentication-path rules remain unchanged. Each returned cell is validated against the variable signed length. The Engine API profile/version negotiation for the widened accepted sizes MUST be resolved before activation; this draft does not silently redefine the fixed profile for existing callers.

### Consensus Containers and Limits

The `BlobCommitment`, progressive commitment/path lists, [Heze execution payload bid](https://github.com/ethereum/consensus-specs/blob/d2021d2719235f0df4726a1d330502cb15aa8ea3/specs/heze/beacon-chain.md#executionpayloadbid), full sidecar and [EIP-8136](./eip-8136.md) partial-column message structures remain EIP-8479 definitions, incorporating [EIP-7732](./eip-7732.md), [EIP-7805](./eip-7805.md) and [EIP-7688](./eip-7688.md). In the variable profile, its fixed `Cell` type is replaced by:

```python
class Cell(ByteList):
    LIMIT = MAX_CELL_BYTES
```

`ByteList` bounds allocation but does not establish the correct length. The full and partial sidecar verifiers MUST use the variable-size predicate and replace the fixed `CELL_BYTES` check with:

```python
if len(cell) * NUMBER_OF_COLUMNS != commitment.blob_byte_length:
    return False
```

Every retained index, count, bitmap, path length, root and ordering check still applies. A partial column contains one cell per selected blob, not all cells of a blob, so authentication paths remain required even when every bitmap bit is set. Commitment ordering in bids and Engine API `versionedHashes` remains unchanged. Custody assignments, subnets, sampling counts, retention and recovery threshold remain the inherited PeerDAS rules; varying sizes does not prove their performance or security at the new workload.

The baseline block commitment count cannot simply be retained when a gas budget admits many small blobs. Variable-profile consensus and execution limits MUST agree on both the active block bound and the serialization/network capacity required across the complete supported schedule. Selecting those bounds, including the pre-schedule fallback, is unresolved as described below.

### Extracted Fee and Schedule Proposal

The combined proposal charged one gas unit per nominal data byte plus an internal-node allowance. The following constants and arithmetic preserve that extracted candidate; they are not EIP-8479's unchanged baseline pricing and are not a complete fork-transition design.

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

The extracted schedule conversion is:

```python
target_blob_gas = blob_schedule.target * FULL_BLOB_GAS
max_blob_gas = blob_schedule.max * FULL_BLOB_GAS
base_fee_update_fraction = ceil_div(
    blob_schedule.base_fee_update_fraction * FULL_BLOB_GAS,
    GAS_PER_BLOB,
)
```

Here `GAS_PER_BLOB = 131072` is the EIP-4844 unit and `blob_schedule` is the current block's baseline [EIP-7892](./eip-7892.md) schedule. This candidate rescales schedule budgets and the update fraction; rounding does not establish exact fee-path equivalence. Its intended block accounting sums `transaction_blob_gas(tx)`, checks the active gas maximum and matches header `blob_gas_used`; frame-transaction fee reservation/payment would use that sum. Header field types and `MIN_BASE_FEE_PER_BLOB_GAS` were unchanged in the combined proposal.

The combined proposal also derived serialization/network commitment capacity from the cheapest blob:

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

`BLOB_SCHEDULE` here denotes the consensus configuration sequence of scheduled blob-limit entries. This expression is preserved as the extracted candidate, not a sufficient definition of a complete schedule: it omits the baseline maximum before its first entry and is undefined for an empty sequence. A per-transaction six-blob cap does not bound total commitments across a block. The correct complete-schedule maximum, active count/resource bounds and matching EL/CL limits require a decision.

### Unresolved Activation Requirements

This draft MUST NOT be treated as an activation-ready specification until the following choices have been resolved:

- Accept or replace the extracted Merkle allowance and size-based charge, with justified resource limits for minimum-size blobs.
- Define all schedule units and later schedule entries, active and complete-schedule maxima, and EL/CL capacity agreement, including empty schedules and the pre-first-entry baseline.
- Define the first variable-profile block's handling of parent `excess_blob_gas` and `blob_gas_used`, update-fraction rounding and later schedule changes. No reset or conversion is specified by the extracted formula.
- Reconcile the variable charge and schedule conversion with the applicable [EIP-7918](./eip-7918.md) reserve-price rule. Its fixed per-blob price comparison cannot be assumed to generalize to arbitrary sizes. The old conversion alone is insufficient.
- Complete variable guest verification-key/profile registration, EIP-8288 proof limits and recursive integration, and the network/Engine API negotiation and fork-specific SSZ decoding for the changed `Cell` type.

Until resolved, the fee formulas above support review and arithmetic vectors only. They do not define a valid activation, fee transition or interoperability test.

### Composition and Fork Boundaries

| PQ PeerDAS | Variable-size extension | Behavior |
| - | - | - |
| Inactive | Inactive | Applicable baseline KZG DA and fees |
| Active | Inactive | EIP-8479 fixed codewords and unchanged baseline blob fees |
| Inactive | Active | Invalid composition; prerequisite absent |
| Active | Active | Variable profile; activation blocked by the unresolved requirements above |

The extension requires prior or coordinated EIP-8479 activation, with every unresolved integration choice completed. This draft assigns no activation timestamp. EIP-8479 does not reference or require this extension. Historical KZG and fixed-PQ data retain their original fork-selected decoding and fees. Variable sizes MUST NOT be accepted before variable-profile activation; transport negotiation alone does not enable transaction validity. EIP-8479's post-PQ KZG exclusion, transaction-pool rules, dependency requirements and no-KZG-fallback rules continue to apply. The treatment of pending fixed-profile proofs/transactions at variable activation requires the final key/profile transition design.

## Rationale

Keeping 128 columns preserves the existing PeerDAS column layout while allowing cell byte lengths to vary. Signing the codeword length prevents a root from being interpreted at another size. Depending on EIP-8479 reuses one commitment/proof construction and avoids a circular dependency or a second variable-size KZG design.

The candidate fee convention accounts for nominal data bytes and one set of internal Merkle nodes. Its resource-pricing tradeoff, fee transition and schedule maxima remain open rather than being silently incorporated into the fixed-size PQ proposal.

## Backwards Compatibility

This is a consensus-breaking extension of post-quantum PeerDAS. The fixed profile remains a complete predecessor with unchanged pricing. Variable-length cells change SSZ encoding from a fixed byte vector to a bounded byte list, and the widened guest input language needs a separately bound program. Existing signed-length fields and canonical hash encodings can be reused, but that does not make fixed-profile verifiers or peers compatible with the extension. The unresolved profile, fee and activation requirements prevent claiming a complete rollout path.

## Test Cases

The following size and candidate-fee vectors are deterministic arithmetic cases. Their fees are conditional on adoption of the extracted candidate; they do not certify activation.

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

Lengths `0`, `2047`, `2049`, `3072`, `524289` and `1048576` are invalid. Six 262144-byte codewords and three 524288-byte codewords each exactly fill the 1572864-byte transaction cap; a seventh commitment or an additional minimum-size blob beyond a full byte cap is invalid. Mixed-size transactions remain subject to both caps.

Composition vectors cover all four activation combinations above. At fixed-profile-only activation, every size except 262144 remains invalid and the per-blob charge remains 131072. For identical 262144-byte inputs, Merkle roots, commitment encodings, binding commitments, seed halves and public-input digests match between profiles; the candidate gas deliberately differs by 4064. Altering root, signed size, list count/order, either challenge, public-input domain/order or successful guest result is rejected under the corresponding inherited binding checks.

Cell tests cover every permitted cell size, mixed-size batches, shared/indexed responses and 63, 64, 65, 127 and 128 returned cells with non-contiguous indices. They retain EIP-8479's malformed-mask, request-ID, empty-response, subset, ordering, unavailable-cell, wrong-path, inconsistent-reconstruction and wrong-root negatives. Full/partial sidecars retain bitmap/list/path checks and reject cells whose lengths disagree with their selected commitment. Actual field reconstruction, guest/proof integration, network interoperability and fee-transition vectors remain required after the unresolved designs are specified; arithmetic and reference models are not substitutes for them.

## Security Considerations

EIP-8479's hash/random-oracle heuristic, two-challenge assumptions, proof binding and separation between encoding validity and data availability remain unchanged. This extraction establishes no QROM, post-quantum security or interoperability proof.

Small blobs increase commitment counts, paths and fixed work per nominal data byte; large cells change bandwidth and reconstruction work. Clients need size and list limits before allocation and verification, and per-blob resource bounds when reconstructing unauthenticated responses. The candidate Merkle allowance alone does not establish a sufficient denial-of-service budget. Mixed-size availability and fee incentives require analysis before activation. The guest-key, profile-negotiation and fork-decoding decisions are security boundaries; accepting a proof or cell under the wrong profile can bypass the intended size constraints.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
