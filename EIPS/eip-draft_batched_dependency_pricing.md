---
title: Batch Pricing for Generic Proofs
description: Discounts generic proof dependencies through complete sponsored batches with a minimum batch size signed by each transaction
author: Marc Harvey-Hill (@Marchhill)
discussions-to: https://ethereum-magicians.org/t/eip-8288-frame-type-for-pq-sig-and-stark-aggregation/28723
status: Draft
type: Standards Track
category: Core
created: 2026-11-13
requires: 8141, 8288, 8437
---

## Abstract

This EIP extends [EIP-8288](./eip-8288.md) with proofs of multiple independent claims under one verification key. A new dependency scheme splits its charge into a marginal claim cost and a share of leaf verification, determined by a minimum batch size committed by the transaction. Public mempool admission and propagation require complete, funded batches sponsored by one paymaster; block inclusion remains per transaction.

## Motivation

Verifying one generic proof inside the aggregation circuit can establish claims for many transactions. Charging every claim as a separate proof ignores that amortization. Each transaction should commit to its own claim and minimum acceptable batch size without waiting for the batch's membership to be chosen.

An application supporting future post-quantum passkeys can collect assertions through its API, fund proving and sponsor users through [EIP-8141](./eip-8141.md). The backend submits one proven batch with its member transactions. Users need neither a local prover nor raw-witness gossip; a different batcher using the same verifier can serve them without changing their signed claims.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This EIP uses EIP-8288's verification-key derivation, singleton claim digest and verifier resource bounds. It changes the aggregation circuit and therefore requires a new `AGGREGATED_VK`.

### Constants

| Name | Value |
| --- | --- |
| `BATCHED_LEANSTARK_SCHEME` | `0x12` (provisional) |
| `MAX_CLAIMS_PER_BATCH_LEAF` | `256` (provisional) |
| `LEANSTARK_LEAF_GAS` | `30000` (provisional) |
| `LEANSTARK_CLAIM_GAS` | `300` (provisional) |
| `BATCH_HASH` | EIP-8288's `CLAIM_HASH` |
| `BATCH_WRAPPER_MODE` | `2` |
| `MAX_BATCH_BYTES` | `2**21` |

The provisional resource and gas parameters MUST be finalized through the activation benchmarks below. The networking version is provisionally `eth/74`.

### Dependency encoding

A batch dependency retains EIP-8288's 96-byte triple. Its first 32 bytes are:

```text
zero[29] || uint16_be(min_batch) || BATCHED_LEANSTARK_SCHEME
```

`min_batch` MUST be between 1 and `MAX_CLAIMS_PER_BATCH_LEAF`, inclusive. Other schemes retain their zero-padding rule. No other nonzero reserved bits are valid.

For dependency parsing, sorting, deduplication, introspection and hashing, `scheme` is the entire 32-byte word interpreted as an unsigned big-endian integer. The low byte selects the scheme; the upper bytes MUST NOT be dropped. `data_hash` and `verification_key_hash` retain their EIP-8288 meanings, including zero-`data_hash` substitution. The transaction signature covers the encoded `min_batch` through the dependency frame's data.

### Gas accounting

Each declaration of the new scheme contributes the following to its dependency frame's exact `limits.execution`:

```python
def leaf_share(min_batch):
    return (LEANSTARK_LEAF_GAS + min_batch - 1) // min_batch

def batch_dependency_gas(min_batch):
    return LEANSTARK_CLAIM_GAS + leaf_share(min_batch)
```

Charge each declaration before dependency deduplication, regardless of execution reverting. Other schemes' charges, EIP-8288's transaction-level intrinsic proof-share charge and EIP-8141's other gas and fee rules continue to apply. The actual batch size or block order does not change the transaction's charge.

### Batch statements

A leaf has one verification key, a proof and a nonempty list `claims` of at most `MAX_CLAIMS_PER_BATCH_LEAF` 32-byte values. Its public statement is:

```python
def get_batch_hash(claims):
    return BATCH_HASH(b'EIP8288:batch:v1' + b''.join(claims))
```

For one claim this equals EIP-8288's `get_claim_hash`. `BATCH_HASH` remains fixed independently of `DEPS_HASH`. Existing singleton verifiers remain usable; a verifier need not accept longer lists.

The aggregation circuit MUST check claim widths, the list bound and strictly increasing byte-lexicographic order before hashing. The leaf verifier need not duplicate the order check. It must establish each claim independently of other records; a constraint spanning records belongs in one composite claim. The protocol authenticates acceptance under the selected key, not the claims' meaning or independence, which remain the responsibility of accounts selecting that key.

For each verified leaf with `N = len(claims)`, the aggregation circuit may establish:

- Ordinary `LEANSTARK_SCHEME` dependencies whose claim is in `claims` and whose key matches the leaf.
- Batch dependencies with the same membership and key checks, additionally requiring `min_batch <= N`.

A direct ordinary leanSTARK proof is a one-claim leaf. It and each multi-claim leaf count once toward `MAX_INNER_PROOFS_PER_STEP`, together with recursive proof inputs. All leaf resource bounds apply before discards. The per-leaf claim bound does not cap recursive output.

Recursive proofs carry the exact established triples, including `min_batch`, through EIP-8288's union, deduplication and discard operations. They MUST NOT increase `min_batch`, establish a new batch qualifier from the size of a recursive union, or restore discarded triples without another verified input. A subset retained from a verified leaf keeps its established qualifier: `min_batch` refers to the original leaf, not the surviving block membership. No leaf identifier, group cap or historical proof counter is added to the block statement.

`MAX_LEANSTARK_DEPS_PER_WRAPPER` limits direct proofs in mode 0; it does not limit claims in a recursive mode 1 proof. Both generic schemes count toward `MAX_STARKS_PER_TX`; other EIP-8288 transaction and wrapper limits continue to apply.

### Complete batch wrappers

A batch wrapper is a canonical RLP object:

```text
[transactions, BATCH_WRAPPER_MODE, [deps, leaf_proof]]
```

- `transactions` contains full pooled encodings as byte strings, ordered by strictly ascending consensus transaction hash. Their form, blob-data elision and cell handling follow [EIP-8437](./eip-8437.md). The complete object MUST fit `MAX_BATCH_BYTES`.
- Each member MUST declare exactly one dependency, using `BATCHED_LEANSTARK_SCHEME`. All members MUST use the same verification key and have distinct resolved claims. Conflicting `(sender, nonce)` pairs are forbidden.
- `deps` is exactly the sorted, deduplicated union of those declarations. There MUST be a one-to-one correspondence between its claims and member transactions, with no surplus claims. Derive `claims` by sorting its resolved `data_hash` values byte-lexicographically.
- Verify `leaf_proof` once against `(get_batch_hash(claims),)` and the common key. With `N = len(claims)`, every member MUST have `min_batch <= N`, and the sum of members' `leaf_share(min_batch)` MUST be at least `LEANSTARK_LEAF_GAS`.

Only complete batch wrappers may introduce batch-dependent transactions into the public mempool. Ordinary mode 0/1 wrappers and standalone transaction messages MUST NOT introduce or propagate these transactions. Ordinary generic dependencies remain eligible for EIP-8288's mode 0/1 paths.

### Admission and lifecycle

Clients MUST validate the whole batch before admitting or relaying any member:

1. Apply the byte, encoding, dependency and proof checks above.
2. Apply EIP-8141's public-mempool rules to every member against the same head, without executing another member's body. All MUST pass and approve the same canonical paymaster as payer. Existing blob-availability checks apply to every member.
3. Atomically reserve every distinct member's `max_fee` under EIP-8141's paymaster accounting. Existing pending reservations count once; another batch cannot reuse their balance as additional funding. New membership and payer reservations are committed only if all checks succeed.

Proof validity alone is insufficient for admission or relay. If any member expires, is replaced, is included, or otherwise ceases to pass admission, clients MUST stop offering the batch and remove its membership. A member may remain pending only through another complete, currently admissible batch. Release its reservation when it has no remaining pending membership. Clients MUST NOT relay the remaining members as a partial batch. Re-entry requires a complete admissible batch; checking a cached valid proof need not be repeated.

Clients SHOULD bound batch bytes, verification work and retained variants globally and per peer and paymaster. Resource refusal or a member's state-dependent admission failure is not proof invalidity or peer misbehavior. EIP-8437's malformed-data and proof-failure rules otherwise apply.

### Propagation

`eth/74` extends EIP-8437's `eth/73` without changing Status or its three wrapper-message encodings. NewProofWrapperHashes (`0x16`) additionally accepts mode `2`, with lengths bounded by `MAX_BATCH_BYTES`; GetProofWrappers (`0x17`) and ProofWrappers (`0x18`) retrieve complete batch wrappers in the same way as ordinary wrappers. The wrapper hash is Keccak-256 of the complete RLP object; the two coverage hints use its encoded `deps` and consensus transaction hashes.

Mode 2 responses MUST carry full transaction encodings, for either value of `compact`. EIP-8437's count limits, response ordering, soft limit and validation-before-relay apply. Announce only batches that remain fully admitted; proof coverage alone does not suppress a batch announcement. An admitted batch with matching dependency and transaction hints may suppress another. Peers MUST NOT send mode 2 wrappers or their members to `eth/73` peers. Before local activation, clients MUST ignore mode 2 announcements without penalties and send none.

### Block construction and inclusion lists

Builders aggregate batch leaves into EIP-8288's recursive proof. The proof need only retain the dependencies of included transactions, with their original `min_batch` values. Blocks carry no batch wrapper and impose neither common-paymaster nor atomic-batch inclusion requirements. Existing inclusion-list rules likewise apply to transactions individually; a recursive proof can cover a selected subset of a leaf's claims.

### Activation requirements

Activation requires the new aggregation key, canonical leaf proof encoding and conformance vectors, and EIP-8288's verifier resource and counter bounds. Publish numerical time and peak-memory budgets, target hardware and bounded worker counts before finalizing gas parameters.

Benchmarks MUST cover singleton proofs under distinct keys, maximum-size leaves, complete sponsored batches, and blocks retaining one discounted claim from each of many distinct maximum-resource leaves. Measure leaf verification, claim hashing and output handling separately, plus total work, recursive critical path, memory and transmitted bytes. The leaf charge MUST cover the most expensive permitted proof shape, not an average application program. If the proposed gas schedule does not meet the budgets, revise the charges or interface before activation.

## Rationale

### Charging for shared work

The leaf charge prices the worst permitted recursive verification under EIP-8288's resource bounds; the claim charge prices additional digest and output work. Neither depends on the signature scheme implemented by a user verifier. `min_batch` makes the charge knowable before signing. With the provisional values, the dependency-frame charge is 30,300 gas at `min_batch = 1`, and 769 at `min_batch = 64`; 64 such members contribute 30,016 gas toward the leaf, excluding their marginal charges.

This is not a payment to the batcher. An application may fund proving, charge a separate service fee or receive an authorized transaction payment. Batching amortizes proof overhead and recursive verification; application-specific claim proving, possibly using the signature scheme's own aggregation, can still dominate. Filling a batch trades latency for cost.

### Complete sponsored batches

Checking only a leaf's size would let a sender pad it with unpaid claims and gossip one cheap transaction with a large proof. Complete batches require a distinct admitted transaction for every claim and enough declared leaf shares. One canonical paymaster supplies bounded, shared fee exposure using existing reservation rules. A paymaster is not a validity guarantee: sender nonces, account state, expiries and competing transactions still require revalidation.

This admission rule does not ensure that every leaf is fully paid in a block. Builders may include subsets and bear the resulting proving cost; private submissions and inclusion obligations can also produce partial batches. Requiring full payment at consensus would need additional leaf accounting or atomic inclusion. The activation workload therefore includes partial batches rather than assuming profitable builder selection removes that case.

### Statements and transport

Transactions commit to individual claims and `min_batch`, not the later batch membership. Existing one-claim statements remain valid, while multi-claim verifiers must support the extended list. Keeping the claim hash independent of the aggregation hash avoids changing pinned user keys when recursion changes.

A new wrapper mode reuses announcement and retrieval instead of adding parallel bundle messages. Full delivery avoids partial admission and keeps this version independent of omission caches. Ordinary singleton proofs remain available at the full EIP-8288 price.

## Backwards Compatibility

Activation enables a new dependency scheme and changes the aggregation verifier. Existing schemes retain their encodings, charges and singleton statements. User verification keys only gain batching if their programs accept lists of independent claims; a program restricted to one claim remains usable.

Older peers do not receive batch wrappers or their members. Blocks and inclusion lists contain ordinary transactions and recursive proofs under the activating fork's rules, without a bundle field.

## Test Cases

| Case | Expected result |
| --- | --- |
| `min_batch` is 0, 1, 256, 257; nonzero reserved bit | Reject, accept, accept, reject; reject |
| Change `min_batch` in a signed transaction | Signature hash changes; the dependency digest also binds the full scheme word |
| One-claim digest | Equals EIP-8288's singleton statement |
| Empty, repeated, unsorted or 257-claim leaf | Reject before hashing or leaf verification |
| Leaf of 64 distinct claims; declared minima 64 and 65 | Accept 64; reject 65 |
| Merge 64 independently proved singleton claims | May establish their existing qualifiers; cannot establish `min_batch = 64` |
| Prune a 64-claim leaf to one established triple | Accept its original qualifier; reject increasing it or resurrecting a discarded triple without verified coverage |
| 64 members at minimum 64 | Each pays 769 dependency gas; leaf shares total 30,016 |
| Duplicate declaration in a transaction | Charge both occurrences; it cannot count as two members for bundle admission |
| Missing member, surplus claim, mixed keys or conflicting sender/nonces | Reject bundle admission |
| One member fails admission, or paymaster cannot fund summed maximum fees | Admit none; create no partial reservations |
| Two batches share a pending member | Count its payer reservation once; releasing one batch does not release an otherwise pending member |
| A member expires, is replaced or included | Stop offering the batch; retain other members only through another complete admitted batch |
| Mode 2 sent with an omission reference | Reject; complete encodings are required even with `compact = 1` |
| Complete batch exactly at `MAX_BATCH_BYTES`; one byte larger | Accept size boundary; reject oversized batch |
| A block includes one member of a valid batch | Check its individual validity and established qualifier; no atomic-inclusion requirement |

## Security Considerations

The constants are provisional, not measured prices. A list-sized discount is safe only if the recursive proof authenticates the original leaf size; union size, repeated claims or a sender-provided count cannot replace that check. Retaining qualifiers through pruning deliberately permits underfunded block subsets, so public-mempool admission alone does not bound worst-case block proving work.

Complete batches can still consume unpaid network work and can be invalidated after admission. Shared sponsorship concentrates this risk and does not remove it. Local work limits, canonical-paymaster reservations, expiry and whole-batch revalidation bound exposure; alternative proof bytes or repeated submissions must not duplicate reservations.

Accounts remain responsible for verifier semantics and for authenticating every claim independently. With `MAX_STARKS_PER_TX = 1`, signature authorization plus an application proof needs one composite claim. Keeping the application witness private from a batcher requires a user-generated zero-knowledge proof checked by that composite verifier. A batcher can delay or censor but cannot forge a sound claim. Accounts needing a path without a batcher can retain singleton proving, a native key or an in-EVM validation path within the public-mempool limits.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
