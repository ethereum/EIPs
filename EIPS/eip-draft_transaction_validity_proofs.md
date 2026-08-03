---
title: Transaction Validity Proofs
description: Mempool policy admitting frame transactions by verifying a STARK over their validation prefix instead of simulating it
author: Marc Harvey-Hill (@Marchhill)
discussions-to: https://ethereum-magicians.org/
status: Draft
type: Standards Track
category: Networking
created: 2026-07-30
requires: 8141, 8288
---

## Abstract

This EIP defines a mempool-layer admission class for [EIP-8141](./eip-8141.md) frame transactions. A transaction MAY be gossiped together with a succinct STARK — an *admission proof* — that proves its validation prefix, executed against a recent state root `S`, satisfies the EIP-8141 trace rules and terminates with `APPROVE` and payer `P`. A node MAY admit such a transaction by verifying the proof instead of simulating the prefix, and proof-carrying transactions are relaxed from the `MAX_VERIFY_GAS` prefix bound. The proof is in the [EIP-8288](./eip-8288.md) enshrined proof format and is verified with the same ingress machinery. This is pure networking policy: no consensus change, no new transaction type, no change to the EIP-8288 enshrined circuit. The proof is transport metadata only — it never appears in a block, receipt, or on-chain state, and is discarded after inclusion.

Like the EIP-8141 mempool rules and [ERC-7562](./eip-7562.md), the rules in this document govern public-mempool propagation, **not** block validity. A block containing a transaction admitted under this policy is valid or invalid on ordinary protocol rules alone.

## Motivation

Today's mempool admits only what it can cheaply check. `MAX_VERIFY_GAS` and the EIP-8141 trace rules bound the *cost* of the admission decision, and in doing so exile authorization logic that is expensive to evaluate but perfectly legitimate. A succinct proof makes "expensive to decide, cheap to check" possible for the admission decision itself — the same move EIP-8288 makes for signature verification.

The usual workaround — moving expensive authorization into the execution phase — breaks the failure-cost symmetry a signature check has. A bad signature is rejected in the mempool: the sender pays no gas and nothing is ever recorded on-chain. Move that check into execution and every failed authorization instead becomes an included, gas-paid, publicly visible reverted transaction — griefable and privacy-leaking. It also pushes complex accounts toward private builders, who will simulate anything for a fee, so those accounts give up public-gossip transport and FOCIL coverage. This EIP restores the signature-like property that a rejected transaction costs the sender nothing and leaves no trace, and brings the public mempool to parity with private order flow on validation expressiveness.

This targets applications whose validation prefix carries a high verification-gas cost — for example those checking many signatures, verifying non-standard signature schemes, or running gas-heavy zero-knowledge-proof checks — which `MAX_VERIFY_GAS` today forces either into the execution phase or out of the public mempool entirely.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This document uses, without restating, terms from its dependencies: from EIP-8141 — frame transactions, the validation prefix and its trace rules, `MAX_VERIFY_GAS`, `sig_hash(T)`, and the expiry-frame mechanism; from EIP-8288 — the enshrined proof format, the dependency-triple model `(scheme, data_hash, verification_key)`, and the convention that dependency verification happens in the block-level pipeline, not in account code.

### Parameters

| Parameter | Description | Suggested value |
| --- | --- | --- |
| `PREFIX_VK` | Verification key of the prefix-semantics circuit | A defined constant of the enshrined-system release; versioned per fork |
| `MAX_PROOF_STATE_AGE` | Maximum age, in blocks, of the state root `S` a proof may target | `~32` |
| `MAX_ADMISSION_PROOF_SIZE` | Per-proof transport size cap | Order 256 KiB; expected to fall as proof systems improve |

Values are RECOMMENDED defaults; clients SHOULD ship identical defaults (see Security Considerations, *denial of service*).

### Statement

The admission proof is a proof in the EIP-8288 enshrined proof format, under the verification key `PREFIX_VK`, of the statement:

> Executing the validation prefix of transaction `T` (identified by `sig_hash(T)`) against state root `S`, under the EIP-8141 trace rules, and assuming the transaction's declared dependency/signature list `D` is valid, terminates with `APPROVE` and payer `P`, subject to the declared validity conditions `C`.

Public inputs are `(sig_hash(T), S, H(D), P, C)`. The prover MUST also commit — as a public input or committed access list — to the sender-local state the prefix reads (nonce, code hash, listed storage keys); nodes delta-check that commitment on revalidation.

### Dependencies are assumptions, not sub-proofs

The circuit reads the *contents* of `D` as a private witness — needed to evaluate a prefix that branches on dependency metadata (which keys signed, under which schemes) and to compute `H(D)` — but MUST NOT perform the cryptographic verification of those signatures or leanSPHINCS/leanSTARK dependencies; it assumes each verifies, exactly as the on-chain prefix does. The node discharges that assumption separately (Admission rule, step 3).

### Admission rule

On receiving a proof-carrying frame transaction, a node MUST, in order:

1. Run stateless checks first — intrinsic validity and signature-list well-formedness. If any fail, reject.
2. Verify the admission proof against `PREFIX_VK`. If verification fails, reject and attribute the failure to the forwarding peer.
3. Verify the declared list `D` (which MUST match `H(D)`) through the EIP-8288 ingress pipeline — discharging the proof's assumption that `D` is valid.
4. Check that `S` is canonical and no older than `MAX_PROOF_STATE_AGE`.
5. Check that every declared condition in `C` currently holds.
6. Check that the sender-local state committed by the proof (step *Statement*) is unchanged since `S`.

If all pass, the node MAY admit the transaction **without simulating the prefix**, and MUST otherwise treat it as an ordinary frame transaction for propagation and pool management.

A proof relaxes only the *cost* of admission: all other EIP-8141 rules are unchanged — in particular, prefix reads MUST remain sender-local and MUST NOT depend on shared mutable state — so a proof never alters what a transaction's validity depends on, only how cheaply it can be checked.

### Relaxations granted to proof-carrying transactions

- `MAX_VERIFY_GAS` does not apply to the prefix: admission cost is the near-constant proof verification, and at inclusion the prefix is bounded by ordinary block and transaction gas limits, so no separate prefix-gas ceiling is needed.
- The declared conditions `C` generalize the single EIP-8141 expiry frame: `C` MAY express deadline ranges, slot/epoch windows, and nonce-equality conditions. Nodes enforce `C` natively as envelope metadata; the prefix itself need not re-encode it.

### Revalidation and staleness

On each new block, for a pooled proof-carrying transaction a node MUST re-check only:

- the declared conditions `C`, and
- the committed sender-local reads against the new head state — a cheap delta check, with no EVM execution.

A pooled proof does not go stale merely because the global state root advances each block: prefix reads are sender-local, so only a change to the account's *own* declared reads invalidates it — which, as for an ordinary transaction today, happens only when that account itself sends another transaction. `MAX_PROOF_STATE_AGE` therefore bounds proving latency, not per-block staleness: the proof must target a root recent enough to still be inside the window when it arrives.

If either check fails, the node MUST evict the transaction. The submitter may then re-prove against a fresh root, or fall back to simulated admission if the prefix fits within `MAX_VERIFY_GAS`. Simulated admission remains the default class; this policy is strictly additive.

### Transport

A devp2p extension carries the admission proof alongside the transaction envelope. Clients:

- MUST reject a proof larger than `MAX_ADMISSION_PROOF_SIZE`.
- MUST verify the proof before forwarding, and SHOULD apply per-peer rate limits to proof-carrying transactions.
- MUST NOT persist the proof, include it in a block, or reference it in any receipt. The proof is discarded once the transaction is included or dropped.

## Rationale

**On EIP-8288.** EIP-8288 is not a strict dependency; the mechanism is logically independent of signature aggregation, and reuses 8288's proof format and ingress-verification machinery by design. Verification is the binding cost — every node runs it on every proof, against one cryptographic stack to audit and version — whereas proving runs once, off-chain, for an opt-in transaction; a purpose-built system would prove the prefix's heavier workload (EVM execution, keccak/MPT state access) more cheaply, but only by adding a second network-wide verifier, the wrong trade for a networking-layer feature. Deployment is thus expected alongside or after EIP-8288, though earlier client-level implementation is possible.

**Mempool-only; the proof never lands on-chain.** At inclusion the chain executes the prefix authoritatively, so an on-chain proof would be calldata spent predicting something the block does anyway. The statement is deliberately scoped as conditional on `S`, so an attested claim can never contradict actual execution — it asserts a fact about state `S`, not about the block.

**The enshrined 8288 circuit is untouched.** `PREFIX_VK` is a distinct circuit that only targets the shared proving backend; admission proofs are mempool-only and need no consensus support, so the EIP adds nothing to the scarce budget of consensus-circuit complexity.

**Dependencies are assumed, not proven.** Verifying them inside the prefix circuit would duplicate what the 8288 ingress pipeline already does and risk divergence between the two verifiers.

## Backwards Compatibility

Fully additive. This EIP introduces no new transaction type, no new opcodes, and no gas-schedule or other consensus changes. Non-participating nodes simply treat a proof-carrying transaction as an ordinary EIP-8141 frame transaction: they ignore the attached proof and either simulate the prefix as usual or decline to admit it when the prefix exceeds `MAX_VERIFY_GAS`. Simulated admission is unchanged and remains the default.

## Security Considerations

**Inherited proof-system assumptions.** Admission soundness rests entirely on the EIP-8288 proof system and on `PREFIX_VK`. Both MUST track enshrined-system upgrades across forks, and `PREFIX_VK` MUST be versioned so nodes reject proofs made for a superseded circuit.

**Denial of service.** Proof verification is cheap but nonzero and runs before forwarding. Nodes MUST run stateless checks first, MUST enforce `MAX_ADMISSION_PROOF_SIZE` to reject oversized proofs before parsing, and SHOULD rate-limit proof-carrying transactions per peer; an invalid proof is attributable to the peer that forwarded it. Because these are advisory rules, clients SHOULD ship identical parameter defaults; if client policies diverge, gossip for proof-carrying transactions will fragment.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
