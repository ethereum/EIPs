---
eip: xxx
title: SchemedTransaction — Scheme-Agile Transactions
description: A new EIP-2718 transaction type allowing users to choose between ECDSA (secp256k1), P256 (secp256r1), and Falcon-512 signature schemes, with sender address derived from the public key.
author: Giulio Rebuffo (@Giulio2002) <giulio.rebuffo@gmail.com>, Ben Adams (@benaadams)
discussions-to: https://ethereum-magicians.org/t/schemed-transaction/28044
status: Draft
type: Standards Track
category: Core
created: 2026-03-22
requires: 2718, 2930, 1559, 7951
---

## Abstract

This EIP introduces a new [EIP-2718](./eip-2718.md) typed transaction (`TransactionType = 0x05`) called SchemedTransaction. A SchemedTransaction allows the sender to select a signature algorithm via an explicit `scheme_id` byte in the transaction envelope. Three schemes are defined at launch: secp256k1 (ECDSA), secp256r1 (P256), and Falcon-512 (post-quantum).

The sender address is derived deterministically by recovering (or verifying) the public key from the signature and hashing it. For `scheme_id = 0x00` (secp256k1), address derivation is exactly the same as legacy Ethereum. For other schemes, the `scheme_id` is prefixed before hashing to provide address domain separation.

Because post-quantum signatures are significantly larger than ECDSA signatures, Falcon transactions incur an additional gas surcharge proportional to the signature and public key size.

## Motivation

### The post-quantum imperative

Quantum computers will eventually break ECDSA over secp256k1. The Ethereum Foundation has declared post-quantum security a top protocol priority, but no concrete, user-facing transaction type currently lets EOAs opt in to post-quantum signing.

Many users and wallets need a simpler primitive: sign a standard transaction with a different algorithm, have the protocol verify it natively, and derive the sender address the same way it always has — from the public key embedded in the signature. SchemedTransaction provides exactly this and nothing more.

### Passkey / WebAuthn support

[EIP-7951](./eip-7951.md) defines a P256 precompile, but wallets using WebAuthn or Secure Enclave keys still cannot natively sign Ethereum transactions. SchemedTransaction extends native support to P256, enabling passkey-based wallets without smart contract wrappers.

### Minimal protocol surface

Rather than introducing new opcodes, account abstractions, or execution frame models, SchemedTransaction is a single new transaction type that reuses the existing [EIP-1559](./eip-1559.md) fields with only two changes: the legacy `v, r, s` fields are replaced by `scheme_id` and `signature_data`.

Execution frame–based approaches (e.g., composable transaction types) can be layered on top of SchemedTransaction later if needed. However, frame-based designs have unresolved issues around mempool validation — verifying nested frames before inclusion is expensive and introduces new DoS vectors. SchemedTransaction sidesteps these problems entirely: signature verification is a single, cheap, stateless check at the transaction envelope level, exactly like today's ECDSA. This gives Ethereum immediate quantum resistance and native WebAuthn/passkey support without waiting for the frame model to mature.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

| Name | Value | Description |
|------|-------|-------------|
| `SCHEMED_TX_TYPE` | `0x05` | [EIP-2718](./eip-2718.md) transaction type byte |
| `SCHEME_SECP256K1` | `0x00` | secp256k1 ECDSA |
| `SCHEME_P256` | `0x01` | secp256r1 / P256 (per [EIP-7951](./eip-7951.md)) |
| `SCHEME_FALCON` | `0x02` | Falcon-512 |
| `FALCON_SIG_MAX_LEN` | `666` | Maximum compressed Falcon-512 signature length (bytes) |
| `FALCON_PK_LEN` | `897` | Falcon-512 public key length (bytes) |
| `CALLDATA_GAS_PER_BYTE` | `16` | Gas per non-zero byte of calldata (existing schedule) |

The `scheme_id` space ranges from `0x00` to `0xFF`, allowing up to 256 registered algorithms. New schemes MUST be specified via a distinct EIP.

### Transaction Envelope

A SchemedTransaction is serialized as:

```
0x05 || rlp([
    chain_id,
    nonce,
    max_priority_fee_per_gas,
    max_fee_per_gas,
    gas_limit,
    to,
    value,
    data,
    access_list,
    scheme_id,
    signature_data
])
```

#### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `chain_id` | `uint256` | [EIP-155](./eip-155.md) chain identifier |
| `nonce` | `uint64` | Sender account nonce |
| `max_priority_fee_per_gas` | `uint256` | [EIP-1559](./eip-1559.md) priority fee |
| `max_fee_per_gas` | `uint256` | [EIP-1559](./eip-1559.md) max fee |
| `gas_limit` | `uint64` | Gas limit |
| `to` | `Address \| null` | Recipient address, or null for contract creation |
| `value` | `uint256` | Wei to transfer |
| `data` | `bytes` | Calldata |
| `access_list` | `List[AccessListEntry]` | [EIP-2930](./eip-2930.md) access list |
| `scheme_id` | `uint8` | Signature algorithm identifier (`0x00`–`0xFF`) |
| `signature_data` | `bytes` | Algorithm-specific signature bytes (see [Signature Formats](#signature-formats-and-address-derivation)) |

This is intentionally identical to an [EIP-1559](./eip-1559.md) (type 2) transaction with two changes: the legacy `v, r, s` fields are replaced by `scheme_id` and `signature_data`.

### Signing Data

The sender signs the following hash:

```python
def signing_hash(tx) -> bytes32:
    return keccak256(
        SCHEMED_TX_TYPE || rlp([
            tx.chain_id,
            tx.nonce,
            tx.max_priority_fee_per_gas,
            tx.max_fee_per_gas,
            tx.gas_limit,
            tx.to,
            tx.value,
            tx.data,
            tx.access_list,
            tx.scheme_id
        ])
    )
```

Note that `scheme_id` is included in the signed payload for **all** SchemedTransactions, including `scheme_id = 0x00`. Preserving the legacy secp256k1 address derivation does not imply preserving the legacy signing preimage. `scheme_id = 0x00` remains a distinct transaction format under `SCHEMED_TX_TYPE = 0x05`, while producing the same sender address as legacy Ethereum.

### Signature Formats and Address Derivation

For each supported scheme, the `signature_data` field has a defined format. The sender address is derived by recovering (or extracting) the public key and hashing it. `scheme_id = 0x00` intentionally preserves the current Ethereum address derivation, while non-secp256k1 schemes use `keccak256(scheme_id || pubkey)[12:]` for domain separation.

#### secp256k1 (`0x00`)

| Field | Size |
|-------|------|
| `r` | 32 bytes |
| `s` | 32 bytes |
| `v` | 1 byte (recovery id: 0 or 1) |

Total: 65 bytes.

For `scheme_id = 0x00`, `signature_data` encodes the legacy secp256k1 tuple `(r, s, v)` in 65 bytes. The transaction envelope remains SchemedTransaction-native; only address derivation preserves legacy Ethereum behaviour.

`s` MUST satisfy `s <= secp256k1n / 2` per [EIP-2](./eip-2.md).

Address derivation (unchanged from legacy Ethereum):

```python
pubkey = ecrecover(signing_hash, v, r, s)   # 64-byte uncompressed (no 0x04 prefix)
address = keccak256(pubkey)[12:]
```

Scheme gas surcharge: **0** (verification cost is included in base 21,000).

#### P256 / secp256r1 (`0x01`)

| Field | Size |
|-------|------|
| `r` | 32 bytes |
| `s` | 32 bytes |
| `v` | 1 byte (recovery id: 0 or 1) |
| `x_hint` | 32 bytes (public key x-coordinate for recovery) |

Total: 97 bytes.

P256 does not natively support public key recovery from `(r, s, v)` alone (unlike secp256k1). The `x_hint` field provides the signer's compressed public key x-coordinate, enabling deterministic recovery:

`s` MUST satisfy `s <= p256n / 2`.

```python
pubkey = p256_recover(signing_hash, v, r, s, x_hint)   # via EIP-7951 precompile
address = keccak256(SCHEME_P256 || pubkey)[12:]
```

The `SCHEME_P256` byte is prefixed to the public key before hashing to ensure address domain separation — a P256 key and a secp256k1 key cannot collide on the same address.

Scheme gas surcharge: **0** (P256 verification cost is absorbed into the base 21,000 intrinsic gas, making P256-signed transactions gas-equivalent to secp256k1).

#### Falcon-512 (`0x02`)

| Field | Size |
|-------|------|
| `signature` | 666 bytes (compressed Falcon-512 signature) |
| `pubkey` | 897 bytes (Falcon-512 public key) |

Total: 1,563 bytes.

Unlike ECDSA curves, Falcon does not support public key recovery from the signature alone. The full public key MUST be included in the transaction. `len(signature)` MUST NOT exceed 666 bytes and `len(pubkey)` MUST equal 897.

```python
# Verification:
challenge = FALCON_HASH_TO_POINT(signing_hash, signature)
valid = FALCON_CORE(signature, pubkey, challenge)
assert valid

# Address derivation:
address = keccak256(SCHEME_FALCON || pubkey)[12:]
```

The choice of hash-to-point variant (SHAKE256 vs Keccak-PRNG) is an implementation detail. This EIP does not prescribe which H2P function is used — both produce valid Falcon-512 verifications.

**Scheme gas surcharge:** Falcon transactions carry substantially more data than ECDSA transactions. To prevent under-pricing and ensure fair resource accounting, Falcon transactions MUST pay an additional gas surcharge of **25,000 gas**, proportional to the extra signature and public key size.

### Intrinsic Gas

The intrinsic gas for a SchemedTransaction is calculated as:

```
intrinsic_gas = 21000
    + calldata_gas(data)
    + access_list_gas(access_list)
    + scheme_gas_surcharge(scheme_id)
```

Where `scheme_gas_surcharge` is:

| Scheme | Surcharge | Breakdown |
|--------|-----------|-----------|
| `SCHEME_SECP256K1` | 0 | Included in base 21,000 (same as today) |
| `SCHEME_P256` | 0 | Included in base 21,000 (same cost as secp256k1) |
| `SCHEME_FALCON` | 25,000 | Proportional to extra signature and public key size |

This ensures Falcon transactions pay proportionally for the bandwidth, storage, and propagation costs imposed by their larger signatures.

### Transaction Validation

A node validating a SchemedTransaction MUST perform the following checks in order:

1. **Type check**: First byte is `0x05`.
2. **RLP decode**: Decode the payload according to the field list above.
3. **Chain ID**: `chain_id` matches the node's chain.
4. **Scheme validation**: `scheme_id` is a registered algorithm.
5. **Signature verification and address recovery**:
   - Compute `signing_hash` per [Signing Data](#signing-data).
   - Call the appropriate verification routine for `scheme_id`.
   - Recover or verify the public key and derive the sender address.
6. **Nonce check**: Sender account nonce matches `tx.nonce`.
7. **Balance check**: Sender has sufficient balance for `gas_limit * max_fee_per_gas + value`.
8. **Gas accounting**: Charge `21,000 + scheme_gas_surcharge` as the intrinsic gas cost.
9. **Execute**: Execute the transaction as a standard call to `to` with `value` and `data`.

### Receipt

The [EIP-2718](./eip-2718.md) `ReceiptPayload` for this transaction is:

```
rlp([status, cumulative_transaction_gas_used, logs_bloom, logs])
```

Identical to [EIP-1559](./eip-1559.md) receipts.

## Rationale

### Why a new transaction type?

Wrapping an existing transaction and replacing its signature (as other proposals do) creates an awkward double-envelope: the outer wrapper carries the alternative signature while the inner transaction carries nullified `v, r, s` fields. SchemedTransaction is a clean single-envelope design where the scheme is a first-class field alongside the standard [EIP-1559](./eip-1559.md) transaction fields.

### Why preserve the existing secp256k1 address?

`scheme_id = 0x00` is intended to be a drop-in replacement for today's ECDSA-backed EOAs. Reusing the existing `keccak256(pubkey)[12:]` derivation avoids creating a second address for the same secp256k1 key, preserves account continuity, and keeps SchemedTransaction backwards-compatible for users who remain on secp256k1.

### Why include pubkey for Falcon but not for ECDSA?

ECDSA over secp256k1 supports efficient public key recovery from `(hash, v, r, s)`. This is a well-known property of the secp256k1 curve and is the reason Ethereum never needed to include the sender's public key in transactions.

Falcon does not natively have this property: given a Falcon signature and a message, you cannot recover the public key. The full 897-byte public key must therefore be provided. There are potential approaches to enable Falcon key recovery (e.g., embedding key material in the signature salt or using a public key registry), but the tradeoffs involved are non-trivial and can be decided on later during ACD discussions.

P256 is intermediate: recovery is possible but requires a hint (the x-coordinate). The 32-byte `x_hint` field provides this.

### Why a size-based gas surcharge for Falcon?

Falcon-512 signatures (666 bytes) and public keys (897 bytes) are ~24× larger than secp256k1 signatures (65 bytes). This extra data must be propagated across the network, stored by archive nodes, and processed during sync. The 25,000 gas surcharge ensures that Falcon transactions pay proportionally for these costs. Without this, Falcon transactions would be systematically under-priced relative to their true resource consumption.

### Why Falcon-512 specifically?

Falcon-512 (NIST FIPS 206) offers the smallest combined signature + public key size among NIST-standardized lattice-based schemes at the 128-bit security level. CRYSTALS-Dilithium signatures are 2–3× larger. Falcon's compact signatures make it the most practical choice for on-chain transactions where every byte has a gas cost.

## Backwards Compatibility

- SchemedTransaction with `scheme_id = 0x00` (secp256k1) produces the same sender address and execution semantics as an [EIP-1559](./eip-1559.md) transaction, but uses a distinct typed envelope and signing hash.
- Existing EOAs can send SchemedTransactions without any on-chain migration. Their address is unchanged when using `scheme_id = 0x00`.
- Smart contracts calling `msg.sender` or `tx.origin` see the derived address regardless of scheme, so no contract changes are needed.
- An EOA that transitions to Falcon will have a **new address** (derived from Falcon pubkey). Asset migration from the old secp256k1 address to the new Falcon address is an explicit user action.

## Reference Implementation

TODO: Extend go-ethereum (or Reth) to:

1. Register `0x05` as a new [EIP-2718](./eip-2718.md) type.
2. Implement RLP decode/encode for the SchemedTransaction envelope.
3. Wire `scheme_id` dispatch to existing `ecrecover`, the P256 precompile, and Falcon precompiles.
4. Add the Falcon gas surcharge to intrinsic gas calculation.

## Security Considerations

### Address collision across schemes

For `scheme_id = 0x00`, this EIP deliberately preserves Ethereum's existing `keccak256(pubkey)[12:]` address derivation. For all other schemes, `keccak256(scheme_id || pubkey)[12:]` provides domain separation from secp256k1 and from each other. A collision would require a preimage attack on Keccak-256 across distinct inputs, which is computationally infeasible.

### Quantum migration timing

Users MUST migrate to Falcon addresses before a cryptographically relevant quantum computer (CRQC) is operational. Once a CRQC exists, any secp256k1 address whose public key has been revealed on-chain (i.e., has sent at least one transaction) is vulnerable. SchemedTransaction enables proactive migration.

### Large signature DoS

Falcon signatures are ~1.5 KB, roughly 24× larger than secp256k1. The 25,000 gas surcharge ensures these transactions are not under-priced.

### Scheme downgrade attacks

An attacker who compromises a quantum computer could attempt to forge secp256k1 signatures for addresses that have previously transacted with scheme `0x00`. This is not a vulnerability introduced by this EIP — it is the pre-existing quantum threat. Users concerned about this SHOULD migrate to a Falcon address preemptively.

### Keccak-256 and quantum resistance

Address derivation and signing hashes rely on Keccak-256. While Keccak is not broken by Shor's algorithm, Grover's algorithm reduces its effective security from 256 bits to 128 bits. This remains adequate for the foreseeable future, but in a fully post-quantum Ethereum it may be worth replacing Keccak-256 with a hash function offering a larger security margin (e.g., SHA-3-512 or a 256-bit hash with a 512-bit internal state) in the signing hash and address derivation paths. This EIP does not mandate such a change but notes it as a consideration for future work.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
