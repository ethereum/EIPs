---
title: Dependency frames for leanSPHINCS signatures
description: A frame mode that declares the leanSPHINCS signatures a transaction depends on, verified outside the EVM and carried beside it
author: Ivan Litteri (@ilitteri)
status: Draft
type: Standards Track
category: Core
created: 2026-11-17
requires: 8141
---

## Abstract

This EIP adds a frame mode to [EIP-8141](./eip-8141.md) frame transactions: the dependency verification frame. It executes no code. Its data is a list of `(scheme, data_hash, verification_key_hash)` triples, the transaction's dependencies. The only scheme defined is leanSPHINCS, a stateless hash-based signature scheme: a dependency states that `data_hash` is signed under the leanSPHINCS public key `verification_key_hash`, and a zero `data_hash` stands for the transaction's own signature hash. Signatures are not part of the transaction. They travel beside it in the mempool and in the block, which carries one signature per distinct dependency of its transactions, and every node verifies them. The block header commits to the signatures the block carries. Smart accounts read their dependencies through the existing frame introspection instructions and approve on them. A later upgrade can replace the per-signature witnesses with a single aggregate proof of all dependencies, as [EIP-8288](./eip-8288.md) does, and can add dependencies of other kinds, such as proofs, without changing transactions or accounts.

## Motivation

Post-quantum accounts need a signature scheme whose security does not rest on the hardness of discrete logarithms. leanSPHINCS is one. It is stateless, so a key can sign from several devices and be restored from a backup without tracking which one-time keys it has used, and its only primitive is Keccak-256, which every client already implements. Its cost is size: a signature is 7,740 bytes, more than a hundred times a secp256k1 signature, and a block of such transactions carries hundreds of kilobytes of signatures that every node downloads, verifies and keeps.

The lasting fix is aggregation: a block carries one recursive proof that all of its signatures are valid, and nodes verify that proof in place of each signature. The proof systems that would do this are still changing, and building every block would require running a prover. Post-quantum accounts should not wait for them, but they do need, from the start, the interface that aggregation will keep. Accounts are long-lived, and their validation code fixes where a signature is looked for. An account that looks in one place cannot use an aggregate that answers in another without changing its code.

Signatures are also not the only thing that will be verified outside the EVM. Proofs follow, and a proof's witness is hundreds of kilobytes, too large for a transaction to carry. A transaction will then declare what it depends on, and the witness will travel beside it until a block's aggregate proof answers for it. This EIP puts signatures on that model from the start: a transaction declares, the witness travels beside it, and the block answers for it.

This EIP therefore fixes what aggregation keeps, and leaves for later only what it replaces:

- A transaction declares the signatures it depends on in a dependency verification frame. The frame is covered by the transaction's signature hash, and accounts read it with `FRAMEPARAM` and `FRAMEDATACOPY`. Aggregation changes neither.
- The frame is the only declaration. A signature carried inside the transaction would need an entry of its own, naming the same scheme, key and message a second time, and a rule to keep the two consistent.
- Signatures travel beside the transaction, in the mempool and in the block. Nodes, wallets and tools handle a transaction together with its witnesses from the start, so when an aggregate proof takes the place of the signatures, only what accompanies the block changes.
- The block header commits only to the signatures a block carries. A block's dependencies are derived from its transactions, so an aggregate proof can later commit to them in whatever form it needs.
- The scheme is the leanSPHINCS definition an aggregate proof verifies, so keys created under this EIP stay usable once signatures are aggregated.
- Signatures are checked outside the EVM and before execution. A node verifies a block's signatures in parallel with executing it, and a mempool node rejects a transaction with a missing or invalid signature before simulating it.

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
