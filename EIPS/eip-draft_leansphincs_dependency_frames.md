---
title: Dependency frames for leanSPHINCS signatures
description: Adds leanSPHINCS signatures to frame transactions, declared in a frame that accounts read and a later upgrade can aggregate
author: Ivan Litteri (@ilitteri)
status: Draft
type: Standards Track
category: Core
created: 2026-11-17
requires: 8141
---

## Abstract

This EIP adds two things to [EIP-8141](./eip-8141.md) frame transactions: leanSPHINCS, a stateless hash-based signature scheme, as a signature scheme the protocol validates, and a frame mode, the dependency verification frame. The frame executes no code. Its data is a list of `(scheme, data_hash, verification_key_hash)` triples, the transaction's dependencies. The only dependency scheme defined is leanSPHINCS: a dependency states that `data_hash` is signed under the leanSPHINCS public key `verification_key_hash`, and a zero `data_hash` stands for the transaction's own signature hash. The signature itself stays in the transaction, as an entry of its signature list, and the protocol validates it before any frame executes. A transaction is valid only if every dependency is matched by such an entry. Smart accounts read their dependencies through the existing frame introspection instructions and approve on them. A later upgrade can let a block's aggregate proof satisfy a dependency in place of the signature, as [EIP-8288](./eip-8288.md) specifies, and can add dependencies whose witnesses do not fit in a transaction, such as proofs, without changing accounts or the transaction format.

## Motivation

Post-quantum accounts need a signature scheme whose security does not rest on the hardness of discrete logarithms. leanSPHINCS is one. It is stateless, so a key can sign from several devices and be restored from a backup without tracking which one-time keys it has used, and its only primitive is Keccak-256, which every client already implements. Its cost is size: a signature is 7,740 bytes, more than a hundred times a secp256k1 signature, and a block of such transactions carries hundreds of kilobytes of signatures that every node downloads, verifies and keeps.

The lasting fix is aggregation: a block carries one recursive proof that all of its signatures are valid, and nodes verify that proof in place of each signature. The proof systems that would do this are still changing, and building every block would require running a prover. Post-quantum accounts should not wait for them, but they do need, from the start, the interface that aggregation will keep. Accounts are long-lived, and their validation code fixes where a signature is looked for. An account that looks in one place cannot use an aggregate that answers in another without changing its code.

Signatures are also not the only thing that will be verified outside the EVM. Proofs follow, and a proof's witness is hundreds of kilobytes, too large for a transaction to carry. A transaction will then declare what it depends on and leave the witness to the block's aggregate proof. The dependency verification frame is that declaration, and signatures should use it from the start, so accounts and contracts read every dependency the same way.

This EIP therefore fixes what aggregation keeps, and leaves for later only what it adds:

- A transaction declares the signatures it depends on in a dependency verification frame. The frame is covered by the transaction's signature hash, and accounts read it with `FRAMEPARAM` and `FRAMEDATACOPY`. Aggregation changes neither.
- The signature stays in the transaction, and the protocol validates it natively. A node validates a transaction on its own: a mempool node rejects a missing or invalid signature before simulating anything, and no block or network object is added.
- A dependency is satisfied by a signature in the transaction. A later upgrade adds a second way, a block's aggregate proof, and a transaction that relies on it leaves the signature out. Dependencies whose witnesses do not fit in a transaction use only the second way.
- A transaction that carries its own signature needs no prover. That stays true after aggregation, so such a transaction can still be included when no aggregator is available.
- The scheme is the leanSPHINCS definition an aggregate proof verifies, so keys created under this EIP stay usable once signatures are aggregated.

Allowing only leanSPHINCS keeps this upgrade to one scheme, with one parameter set and a fixed verification cost. Other dependency kinds, such as proofs, can arrive with aggregation: the frame format already names the scheme of each dependency.

## Specification

TBD

## Rationale

TBD

## Backwards Compatibility

TBD

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
