---
eip: TBD
title: Encrypted Transaction Envelope (ETE) Typed Transaction
description: Introduces a typed transaction carrying an encrypted payload and a zero-knowledge proof to enable mempool privacy and policy enforcement without altering L1 execution semantics.
author: Tyler (@lengyeltyler), lengyeltyler@proton.me
discussions-to: https://ethereum-magicians.org/t/eip-encrypted-transaction-envelope/0000
status: Draft
type: Standards Track
category: Core
created: 2025-08-13
requires: [2718, 1559]
---

## Abstract

This EIP defines a new EIP-2718 typed transaction that encapsulates an Encrypted Transaction Envelope (ETE): a public header, an AEAD-encrypted body, and a zero-knowledge validity proof that binds them. Nodes gossip the opaque, mempool-private payload without exposing calldata. Builders or proposers who opt in decrypt and verify before inclusion, then transform the ETE into a standard EIP-1559 transaction for execution. Consensus rules and EVM semantics remain unchanged. This provides pre-inclusion confidentiality and a standard envelope format that can also be adopted by L2s for end-to-end private execution.

## Motivation

Ethereum provides authenticity and integrity for transactions, but no confidentiality — calldata is broadcast in plaintext, enabling:

- MEV extraction through front-running and sandwich attacks
- Leakage of trading strategies and private business logic
- Targeting or harassment of addresses

Private mempools exist, but they are proprietary and incompatible. Standardizing an encrypted envelope:

- Gives wallets and dApps a single, interoperable privacy format
- Enables zero-knowledge policy proofs (e.g., spending limits, one-per-person) without revealing sensitive details
- Allows immediate adoption by L2s for full privacy, while keeping L1 backwards-compatible

## Specification

### Transaction Type

Allocates a new EIP-2718 type `0x4f`.

RLP payload:

```text
ETETransaction ::= [
    chainId: uint256,
    nonce: uint256,
    maxPriorityFeePerGas: uint256,
    maxFeePerGas: uint256,
    gasLimit: uint256,
    toCommitment: bytes32,
    header: bytes,
    ciphertext: bytes,
    proof: bytes,
    accessList?: [ … ], // EIP-2930 optional
    v: uint256, r: bytes32, s: bytes32
]

### Header (RECOMMENDED encoding: CBOR)

- `version: uint8`
- `networkId: uint64`
- `policyTag: bytes32` — commitment to the policy proven in proof
- `nonceCommitment: bytes32` — commitment to a private nonce
- `vkLocator: bytes` — locator to retrieve the Viewing Public Key (e.g., VKReg address + key ID)  
  - **Viewing Public Key**: A public key used solely for decrypting transaction contents. May be published in VKReg or another registry. It is distinct from the sender’s signing key to avoid cross-use compromises.
- `feeHint: uint32` — OPTIONAL

### Ciphertext

- AEAD-encrypted (e.g., HPKE) to the Viewing Public Key of the target.
- Plaintext SHOULD contain: `methodId`, arguments, deadline, maxFee, optional accessList.

### Proof

- A zero-knowledge proof binding (`header`, `ciphertext`) that MUST prove points 1–3; MAY also prove optional constraints such as 4:

  1. Ciphertext is well-formed for the given version.
  2. `policyTag` is satisfied according to app-defined policy logic.
  3. `nonceCommitment` corresponds to a valid unused nonce.
  4. OPTIONAL: `userTag = PRF(secret, epoch)` for anti-spam.

### Gossip & Validation

Nodes MUST:

- Validate RLP structure, fee fields, and that `header.networkId` matches.
- Reject if `len(ciphertext) > MAX_CIPHERTEXT_BYTES` or `len(proof) > MAX_PROOF_BYTES`.
- Perform cheap structural checks on proof before gossip.
- Use `(sender, nonce)` from the outer signature for replacement rules.

Non-supporting nodes ignore type `0x4f` in mempool but remain consensus-compatible.

Mempool gossip and validation rules are identical to EIP-1559 transactions except where specified herein.

### Inclusion & Execution

Opt-in builders/proposers:

1. Resolve `vkLocator` (e.g., via VKReg) to obtain Viewing Public Key.
2. Decrypt ciphertext.
3. Verify proof.
4. Construct a standard EIP-1559 transaction and include in block.

EVM execution is unchanged; the chain never processes ciphertext.

EVM execution is unchanged; the chain never processes ciphertext.

**Flow Diagram:**

```text
[Wallet] --encrypt+proof--> [ETE Tx] --gossip (opaque)--> [Builder]
           --> decrypt & verify --> [Standard Tx] --> [Block Inclusion] --> [Execution]

**Signing**
```markdown
###Signing

Signing root: 'keccak256( 0x4f || rlp([fields before v]) )'.
'toCommitment' SHOULD be 'keccak256(targetAddress || domainSeparator)'.

### Fees

Outer sender pays gas as in standard EIP-1559.

- Gas fee fields (`maxPriorityFeePerGas`, `maxFeePerGas`, `gasLimit`) are in the unencrypted outer envelope, so nodes can apply replacement rules without decrypting.

### Access Lists

If included, follows EIP-2930 encoding.

## Rationale

- Uses EIP-2718 typed tx for opt-in compatibility.
- Proofs included in transaction allow for early structural validation.
- Viewing key indirection supports rotation and algorithm agility.
- The `vkLocator` indirection is compatible with a future VKReg standard but does not require it; implementers may point to ENS, off-chain resolvers, or other registries.

## Backwards Compatibility

No impact on existing transaction types. Non-supporting clients simply won’t propagate type 0x4f.

## Security Considerations

	-	DoS: enforce size caps, cheap checks, peer scoring.
	-	Key compromise: rotate viewing keys; use per-tx ephemeral keys.
	-	Replay: nonceCommitment + domain-separated toCommitment. These commitments MUST be bound to chainId to prevent cross-chain replay.
	-	Censorship: multiple builders/relayers; does not solve consensus-layer censorship.
	-	Privacy limit on L1: calldata visible after inclusion — full privacy requires L2 execution.

Reference Implementation

TBD.

Copyright

CC0