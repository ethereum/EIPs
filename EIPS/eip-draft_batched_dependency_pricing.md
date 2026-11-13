---
title: Batch Pricing for Generic Proofs
description: Discounts generic proof dependencies submitted directly to builders using a minimum batch size signed by each transaction
author: Marc Harvey-Hill (@Marchhill)
status: Draft
type: Standards Track
category: Core
created: 2026-11-13
requires: 7805, 8141, 8288
---

## Abstract

This EIP extends [EIP-8288](./eip-8288.md) with proofs of multiple independent claims under one verification key. A new dependency scheme splits its charge into a marginal claim cost and a share of leaf verification, determined by a minimum batch size committed by the transaction. Discounted transactions are submitted directly to builders and are excluded from the public mempool and inclusion-list obligations.

## Motivation

Verifying one generic proof inside the aggregation circuit can establish claims for many transactions. Charging every claim as a separate proof ignores that amortization. Each transaction should commit to its own claim and minimum acceptable batch size without waiting for the batch's membership to be chosen.

An application supporting future post-quantum passkeys can collect assertions through its API, fund proving and submit a batch proof with the users' transactions directly to a builder. Each user keeps a native [EIP-8141](./eip-8141.md) transaction with its own nonce, receipt and payer. A different batcher using the same verifier can serve the signed transactions. Public-mempool access and inclusion-list protection remain available through the ordinary, full-price scheme.

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

The provisional resource and gas parameters MUST be finalized through the activation benchmarks below.

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

Charge each declaration before dependency deduplication, regardless of execution reverting. Other schemes' charges, EIP-8288's intrinsic proof-share charge per declared dependency and EIP-8141's other gas and fee rules continue to apply. The actual batch size or block order does not change the transaction's charge.

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

Recursive proofs carry the exact established triples, including `min_batch`, through EIP-8288's union, deduplication and discard operations. They MUST NOT increase `min_batch`, establish a new batch qualifier from the size of a recursive union, or restore discarded triples without another verified input. A subset retained from a verified leaf keeps its established qualifier: `min_batch` refers to the original leaf, not the surviving block membership.

### Submission and inclusion

Batchers submit transactions and their leaf proofs directly to builders. The submission API and service payment are outside this specification. Builders verify the leaves and incorporate them into EIP-8288's recursive block proof; leaves are not added to the block encoding.

Transactions declaring `BATCHED_LEANSTARK_SCHEME` MUST NOT be admitted to or propagated through the public mempool, including inside proof wrappers. They impose no [EIP-7805](./eip-7805.md) inclusion obligation, even if an inclusion list supplies a covering proof. Includers MUST omit them; their presence does not remove other entries' obligations.

Builders may include any valid subset of the submitted transactions. Each transaction follows EIP-8141's validity and payment rules independently, and the block proof must retain its exact dependencies, including `min_batch`. No common payer or atomic inclusion is required. Expiry, replacement or inclusion of one transaction does not invalidate the leaf's proof of the other claims.

### Public-mempool fallback

Accounts seeking a fallback SHOULD authorize both generic schemes under the same verification key and claim semantics. A sender can replace the discounted declaration with ordinary `LEANSTARK_SCHEME`, update the gas budget, re-sign and obtain a singleton proof for the updated transaction. The ordinary transaction is subject to the existing public-mempool and inclusion-list eligibility rules. A singleton proof cannot satisfy an already-signed `min_batch > 1`.

### Activation requirements

Activation requires the new aggregation key, canonical leaf proof encoding and conformance vectors, and EIP-8288's verifier resource and counter bounds. Publish numerical time and peak-memory budgets, target hardware and bounded worker counts before finalizing gas parameters.

Benchmarks MUST cover singleton proofs under distinct keys, maximum-size leaves, and blocks retaining one discounted claim from each of many distinct maximum-resource leaves, including padded leaves. Measure leaf verification, claim hashing and output handling separately, plus total work, recursive critical path, memory and transmitted bytes. The leaf charge MUST cover the most expensive permitted proof shape, not an average application program. If the gas schedule does not meet the budgets in the partial-inclusion case, revise the charges or interface before activation.

## Rationale

### Charging for shared work

The leaf charge prices the worst permitted recursive verification under EIP-8288's resource bounds; the claim charge prices additional digest and output work. Neither depends on the signature scheme implemented by a user verifier. `min_batch` makes the charge knowable before signing and permits smaller batches at higher prices, unlike a fixed threshold. With the provisional values, the dependency-frame charge is 30,300 gas at `min_batch = 1`, and 769 at `min_batch = 64`. EIP-8288's separate 30,000-gas transaction proof share still applies: batching reduces a single declaration's combined proof charges from 60,000 to 30,418 at `min_batch = 256`, excluding other transaction costs.

This is not a payment to the batcher. An application may fund proving, charge a separate service fee or receive an authorized transaction payment. Batching amortizes proof overhead and recursive verification; application-specific claim proving, possibly using the signature scheme's own aggregation, can still dominate. Filling a batch trades latency for cost.

### Submission path

Direct submission lets builders choose and price the proving work they accept, without a public pool tracking interdependent transactions or shared fee reservations. Each user retains a native transaction. Combining users' operations into one application transaction could share more fixed costs, but would also share its nonce and receipt and require application-level replay protection.

Builder choice does not prove the discount sound: unused claims can still leave a leaf underfunded, so activation benchmarks include that case.

## Backwards Compatibility

Activation enables a new dependency scheme and changes the aggregation verifier. Existing schemes retain their encodings, charges and singleton statements. User verification keys only gain batching if their programs accept lists of independent claims; a program restricted to one claim remains usable.

Public-mempool message formats remain unchanged. Blocks contain individual transactions and the recursive proof under the activating fork's rules, without batch membership fields.

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
| Duplicate declaration in a transaction | Charge both occurrences before dependency deduplication |
| Matching claim under a different key; invalid or over-resource leaf | Reject, including inputs later discarded |
| A member expires, is replaced or included | The leaf can still establish other claims; evaluate each transaction separately |
| Transactions have different payers or only a subset is included | Apply individual validity and established qualifiers; no atomic-inclusion requirement |
| A leaf has padded claims with no corresponding included transaction | May establish a matching discount; leaf size does not prove payment |
| Discounted transaction submitted to the public pool or inside a wrapper | Do not admit or propagate, even with a valid proof |
| An inclusion list contains ordinary and discounted entries | Discounted entries impose no obligation; evaluate the others normally |
| Switch a signature-hash-bound transaction to the ordinary scheme | Recompute its budget and signature; prove the updated claim before ordinary admission |

## Security Considerations

The constants are provisional, not measured prices. The recursive proof must authenticate the original leaf size; union size, repeated claims or a sender-provided count cannot replace that check. A verifier may accept padded claims with no paying transactions, and pruning may retain one discounted claim from an expensive leaf. Consequently, leaf size proves eligibility for the discount, not shared payment. Private submission removes public relay costs, not this proving-cost mismatch.

Batchers and builders can delay, withhold or expose transactions received privately. The discounted path has no inclusion-list guarantee. A sender unable to prove needs another prover for the full-price fallback, which also requires account support and public-mempool eligibility.

Accounts remain responsible for verifier semantics and for authenticating every claim independently. Under a sound verifier, a batcher cannot forge authorization. Accounts may also retain a native key or an in-EVM validation path within the public-mempool limits.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
