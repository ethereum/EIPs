---
eip: XXXX
title: CATX Transaction Format
description: Cryptographically Agile Transaction format separating signature from transaction body
author: Danno Ferrin (@shemnon) <danno@tectonic.xyz>, Ron Kahat <ron@tectonic.xyz>
discussions-to: TODO
status: Draft
type: Standards Track
category: Core
created: 2025-03-04
requires: 1559, 2718, 2930, 4844
---

## Abstract

CATX (Cryptographically Agile Transactions) is an EIP-2718 transaction format that separates the transaction body from its signatures using a flat structure: `[payload_type, payload_body, (sig_type, sig_body)+]`. This enables future migration to post-quantum cryptography without modifying transaction semantics, supports multi-signature payloads where each signature commits to its position index, and facilitates future support of zk signature aggregation.

## Motivation

Current Ethereum transactions tightly couple body and signature by embedding algorithm-specific fields in the transaction, requiring new transaction types for each signature algorithm. CATX addresses three key concerns:

1. **Post-quantum cryptography adoption**: Signature types are independent of payload types, enabling migration to PQC algorithms without modifying transaction semantics
2. **Position-committed signatures**: Each signature commits to its index position, preventing key substitution attacks (Fujita et al., 2024) in multi-signature payloads
3. **ZK signature aggregation**: Trailing signatures can be easily stripped for aggregation schemes, with the payload body remaining intact for proof generation

## Specification

### Parameters

| Name             | Description                | Value  |
|------------------|----------------------------|--------|
| `CA_TX_TYPE`     | EIP-2718 transaction type  | TBD    |
| `ECDSA_SIG_TYPE` | ECDSA signature identifier | `0x00` |

### Transaction Encoding

```
CA_TX_TYPE || rlp([payload_type, payload_body, (sig_type, sig_body)+])
```

Signatures are appended as flat alternating `sig_type, sig_body` pairs. The number of signature pairs required is controlled by the payload (either fixed per `payload_type` or determined by fields within `payload_body`). If a transaction does not contain exactly the required number of signatures, the transaction is invalid.

### Payload Types and Data

| Type   | Name     | Sig Count | payload_body                                                                                                                                         |
|--------|----------|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `0x01` | EIP-2930 | 1         | `[chain_id, nonce, gas_price, gas_limit, to, value, data, access_list]`                                                                              |
| `0x02` | EIP-1559 | 1         | `[chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, to, value, data, access_list]`                                              |
| `0x03` | EIP-4844 | 1         | `[chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, to, value, data, access_list, max_fee_per_blob_gas, blob_versioned_hashes]` |

Legacy (type 0) transactions are not supported because payload information is encoded in the signature.

`payload_body` corresponds to the signing form of the related transaction types. Transactions will be processed in the manner specified in their respective EIPs.

Type 4 payloads (EIP-7702 SetCode) are not defined in this EIP. EIP-7702 authorization signatures commit to a sub-structure (the delegation tuple) rather than the entire transaction, requiring special handling. A CATX-compatible EIP-7702 payload type would keep authorization signatures embedded within the `payload_body`, not in the trailing signature table.

Some future transaction types, like Frame transactions ([EIP-8141](./eip-8141)), will require multiple signatures committing to the whole transaction. The payload body controls how many signatures are required.

### Signatures

Each signature consists of a `sig_type, sig_body` pair. `sig_type` is encoded as an RLP number. `sig_body` is encoded as an RLP byte string (using either short or long string encoding as appropriate for the signature length).

When a signature is transmitted with both public key or verification key and signature data, the public key or verification key should be first in the `sig_body`. This does not apply to algorithms that support key extraction such as ECDSA.

### Signature Hash

Each signature commits to both the payload and its position index within the transaction. The hash is computed in two layers:

```
payload_hash = payload_type || rlp(payload_body)
signature_hash(index) = keccak256(CA_TX_TYPE || payload_hash || rlp(index))
```

Where `payload_type` is the inner type byte and `index` is RLP-encoded, permitting an unlimited number of signatures.


### Position-Indexed Signatures

Including the signature index in the hash prevents key substitution attacks in multi-signature payloads. Each signature cryptographically commits to its position, ensuring:

- Signature at index 0 signs `hash(CA_TX_TYPE || payload_hash || rlp(0))`
- Signature at index 1 signs `hash(CA_TX_TYPE || payload_hash || rlp(1))`
- Signatures cannot be reordered or substituted between positions

This is critical for payload types like EIP-8141 Frame transactions where multiple parties (sender, sponsor) sign the same transaction body but for different purposes.

### Signature Type 0: ECDSA

This EIP only specifies ECDSA_SIG_TYPE. Other EIPs will define other signature types.

```
sig_body = v[1] || r[32] || s[32]
```

Where `v` uses 0/1 parity (not legacy 27/28); any other value is invalid. Total: 65 bytes. Existing rules regarding ECDSA signatures, such as `s` being in the lower half of the curve order, MUST be observed.

### Address Derivation

Address derivation depends on the signature type to prevent cross-scheme collisions.

**ECDSA (0x00)**: Uses the legacy Ethereum address derivation for backwards compatibility:

```
address = keccak256(uncompressed_pubkey)[12:32]
```

Where `uncompressed_pubkey` is the 64-byte public key (without the `0x04` prefix).

**Future signature types**: Include the signature type in the hash to ensure distinct address spaces:

```python
def derive_address(sig_type: uint8, public_key: bytes) -> ExecutionAddress:
    if sig_type == 0x00:
        # ECDSA: legacy derivation
        return keccak256(public_key)[12:32]
    elif len(public_key) == 63:
        # Pad 63-byte keys with 0x00 between sig_type and key
        return keccak256(sig_type || 0x00 || public_key)[12:32]
    else:
        return keccak256(sig_type || public_key)[12:32]
```

The 63-byte special case inserts a `0x00` padding byte. Without it, `keccak256(sig_type || 63_byte_key)` would be 64 bytes—the same length as ECDSA's `keccak256(64_byte_key)`—creating potential collision risk. This approach is consistent with [EIP-7932](./eip-7932.md).

### Receipts

The common receipt formatting is used

```
CA_TX_TYPE || rlp([status, cumulative_gas_used, logs_bloom, logs])
```

### Transaction Hash

The transaction hash is computed as:

```
tx_hash = keccak256(CA_TX_TYPE || rlp([payload_type, payload_body, sig_type, sig_body, ...]))
```

This is the keccak256 hash over the entire encoded transaction.

### Gas Costs

Single ECDSA-signed CATX transactions have a base intrinsic gas cost of 21000, consistent with existing transaction types. Future signature types or payloads requiring multiple signatures may require different gas costs due to longer signatures or more computationally intensive verification algorithms; these costs will be specified in the EIPs proposing those signature types.

## Rationale

**Flat structure**: Enables independent extension of payload types and signature algorithms without unneeded RLP nesting structures.

**Payload-controlled signature count**: The payload controls how many signatures are required: either as a fixed count per `payload_type` or determined by fields within the `payload_body`. This allows payload types to define their own multi-signature semantics (e.g., variable frame counts in EIP-8141) while ensuring all required signatures are present.

**Trailing vs embedded signatures**: The trailing signature table is for signatures that commit to the entire transaction. Signatures that commit to sub-structures within the payload (such as EIP-7702 authorization tuples) remain embedded in the `payload_body`. This distinction is important: trailing signatures can be stripped for ZK aggregation while embedded signatures are part of the payload semantics.

**Position-indexed hashes**: Including the signature index in the hash prevents key substitution attacks. Without this, in a multi-signature transaction where parties A and B both sign the same payload, A's signature could be copied to B's position (or vice versa), potentially changing the authorization semantics. Position indexing ensures each signature is bound to its specific role.

**Reduced Signature Manipulation**: The signature hash uses a byte-slice of the payload instead of a re-written container, simplifying memory management.

## Backwards Compatibility

This is a new transaction type and does not affect existing types. EIP-2930/1559/4844 transactions can be converted to CATX format. Note that the position-indexed signature hash means existing signatures are not directly compatible—transactions must be re-signed for CATX format (avoiding a signature malleability concerns).

## Security Considerations

- `sig_type` binds transaction to specific algorithm; implementations must verify correct algorithm is used
- Future signature types use distinct address derivation to prevent cross-scheme collisions
- Fork-based algorithm management enables deprecation of vulnerable schemes while keeping existing structures.
- Implementations MUST reject transactions where the signature count does not exactly match the count required by the payload
- Position-indexed signature hashes prevent key substitution attacks (see Fujita, Sakai, Yamashita, & Hanaoka, "On Key Substitution Attacks against Aggregate Signatures and Multi-Signatures", IACR ePrint 2024/1728) where one signer's signature is copied to another position

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
