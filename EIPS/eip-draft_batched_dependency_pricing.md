---
title: Batch Pricing for Generic Proofs
description: Separates sponsored leaf verification from per-claim charges for generic proofs submitted directly to builders
author: Marc Harvey-Hill (@Marchhill)
status: Draft
type: Standards Track
category: Core
created: 2026-11-13
requires: 7805, 8141, 8288
---

## Abstract

This EIP extends [EIP-8288](./eip-8288.md) with proofs of multiple independent claims under one verification key. Transactions pay per claim; a sponsor separately pays for each leaf used in the block. Any valid subset of a batch can be included without changing its members' signatures. These transactions are submitted directly to builders and are excluded from the public mempool and inclusion-list obligations.

## Motivation

Verifying one generic proof inside the aggregation circuit can establish claims for many transactions. Charging every claim as a separate proof ignores that amortization. Each transaction should commit to its own claim before a batch is formed, without depending on other members remaining includable.

An application supporting future post-quantum passkeys can collect assertions through its API, fund proving and submit a leaf, its payment transaction and the users' transactions directly to a builder. Each user keeps a native [EIP-8141](./eip-8141.md) transaction with its own nonce, receipt and payer. Another batcher or sponsor can serve the signed transactions without changing them. Public-mempool access and inclusion-list protection remain available through the ordinary, full-price scheme.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This EIP uses EIP-8288's verification-key derivation, singleton claim digest and verifier resource bounds. It changes the aggregation circuit and therefore requires a new `AGGREGATED_VK`.

### Constants

| Name | Value |
| --- | --- |
| `BATCHED_LEANSTARK_SCHEME` | `0x12` (provisional) |
| `LEANSTARK_LEAF_PAYMENT_SCHEME` | `0x13` (provisional) |
| `MAX_CLAIMS_PER_BATCH_LEAF` | `256` (provisional) |
| `LEANSTARK_LEAF_GAS` | `30000` (provisional) |
| `LEANSTARK_CLAIM_GAS` | `300` (provisional) |
| `BATCH_HASH` | EIP-8288's `CLAIM_HASH` |

The provisional resource and gas parameters MUST be finalized through the activation benchmarks below.

### Dependency encoding

Both new schemes are valid in dependency verification frames and use EIP-8288's 96-byte triple with 31 zero padding bytes before the scheme byte:

| Scheme | `data_hash` | `verification_key_hash` |
| --- | --- | --- |
| `BATCHED_LEANSTARK_SCHEME` | Individual claim, with EIP-8288's zero substitution | Leaf verification-key hash |
| `LEANSTARK_LEAF_PAYMENT_SCHEME` | Nonzero `get_batch_hash(claims)` | Leaf verification-key hash |

The payment triple identifies a leaf statement independently of its proof bytes. A member transaction commits to its claim and key, not the batch membership or sponsor.

### Gas accounting

Each declaration contributes to its dependency frame's exact `limits.execution`:

- `BATCHED_LEANSTARK_SCHEME`: `LEANSTARK_CLAIM_GAS`.
- `LEANSTARK_LEAF_PAYMENT_SCHEME`: `LEANSTARK_LEAF_GAS`.

Charge each occurrence before dependency deduplication. EIP-8288's intrinsic proof-share charge applies to claim declarations, including the new claim scheme, but excludes leaf-payment declarations. Other transaction and authorization costs still apply. Frame charges count toward block execution capacity under EIP-8141's normal gas accounting; refunds do not reduce that capacity charge.

A sponsor declares one or more leaf payments in its own frame transaction. Its payer authorizes the fees through EIP-8141; member transactions need not use that payer. A payment is effective only when its transaction is valid and included in the same block, before or after its members. Repeated declarations are charged repeatedly but identify the same leaf. Payment in an earlier block provides no credit.

### Batch statements

A leaf has one verification key, a proof and a nonempty list `claims` of at most `MAX_CLAIMS_PER_BATCH_LEAF` 32-byte values. Its public statement is:

```python
def get_batch_hash(claims):
    return BATCH_HASH(b'EIP8288:batch:v1' + b''.join(claims))
```

For one claim this equals EIP-8288's `get_claim_hash`. `BATCH_HASH` remains fixed independently of `DEPS_HASH`. Existing singleton verifiers remain usable; a verifier need not accept longer lists.

The aggregation circuit MUST check claim widths, the list bound and strictly increasing byte-lexicographic order before hashing. The leaf verifier need not duplicate the order check. It must establish each claim independently of other records; a constraint spanning records belongs in one composite claim. The protocol authenticates acceptance under the selected key, not the claims' meaning or independence, which remain the responsibility of accounts selecting that key.

For each verified leaf, the aggregation circuit may establish:

- Ordinary `LEANSTARK_SCHEME` dependencies whose claim is in `claims` and whose key matches the leaf.
- Batch dependencies with the same membership and key checks.
- Its leaf-payment dependency, whose digest and key match the leaf.

A direct ordinary leanSTARK proof is a one-claim leaf. It and each multi-claim leaf count once toward `MAX_INNER_PROOFS_PER_STEP`, together with recursive proof inputs. All leaf resource bounds apply before discards. The per-leaf claim bound does not cap recursive output.

### Recursive payment binding

Each batch dependency is assigned to the payment triple of the verified leaf that established it. Recursive proofs authenticate records `(dependency, source)`, where `source` is that payment triple for a batch dependency and absent for other schemes. Every source payment MUST also be a retained dependency. Records are sorted and deduplicated by dependency. An intermediate proof's public statement is:

```python
def get_batch_state_hash(records):
    return DEPS_HASH(b'EIP8288:batch-state:v1' + b''.join(
        encode_dependency(dep) + (
            encode_dependency(source) if source is not None else bytes(96)
        )
        for dep, source in records
    ))
```

`encode_dependency` is EIP-8288's canonical 96-byte encoding. The circuit checks record order, widths and source types before hashing. The tag separates intermediate statements from ordinary dependency digests. The updated `AGGREGATED_VK` supports intermediate aggregation and finalization; a dependency-only statement containing batch claims can be produced only by finalization.

- Merging retains authenticated assignments. For duplicate dependencies it may select either verified source; union size cannot create a new leaf statement or payment identity.
- Discarding a dependency removes its assignment. A payment may be discarded only when no retained dependency refers to it. Discarded dependencies cannot be restored without another verified input.
- An ordinary recursive proof of `get_deps_hash(deps)` may be imported with absent sources only if `deps` contains no `BATCHED_LEANSTARK_SCHEME` dependency. Finalization cannot erase payment bindings for subsequent pruning.

Finalization verifies an intermediate proof and checks that every source payment is present in its retained dependencies. It outputs the usual `get_deps_hash(deps)`, which block validation MUST match against `dependencies(block)`. Thus each retained batch claim requires a matching included payment declaration. Intermediate records are proving inputs; no batch membership field is added to the block.

### Submission and inclusion

Batchers submit member transactions, leaf proofs and sponsorship transactions directly to builders. The submission API and any payment for the batcher's service are outside this specification. Builders verify the leaves and incorporate them into EIP-8288's recursive block proof; leaves are not added to the block encoding.

Transactions declaring either new scheme MUST NOT be admitted to or propagated through the public mempool, including inside proof wrappers. They impose no [EIP-7805](./eip-7805.md) inclusion obligation, even if an inclusion list supplies a covering proof. Includers MUST omit them; their presence does not remove other entries' obligations.

Builders may include any valid subset of member transactions, including a single survivor, provided the corresponding leaf payments are included. Each transaction follows EIP-8141's validity and payment rules independently. Expiry, replacement or inclusion of another member does not change the surviving member's charge or require its signature or leaf proof to be replaced; the aggregate is updated for the retained dependencies.

If all members are omitted, the builder may omit their leaf and its payment. A payment included without any surviving members still requires a valid leaf proof and is charged normally. A missing or invalid sponsorship transaction requires another valid payment transaction, not new member signatures.

### Public-mempool fallback

Accounts seeking a fallback SHOULD authorize both generic schemes under the same verification key and claim semantics. A sender can replace the discounted declaration with ordinary `LEANSTARK_SCHEME`, update the gas budget, re-sign and obtain a singleton proof for the updated transaction. The ordinary transaction is subject to the existing public-mempool and inclusion-list eligibility rules.

### Activation requirements

Activation requires the new aggregation key, leaf and intermediate-proof encodings, payment-binding conformance vectors, and EIP-8288's verifier resource and counter bounds, including the 192-byte intermediate records. Publish numerical time and peak-memory budgets, target hardware and bounded worker counts before finalizing gas parameters.

Benchmarks MUST cover singleton proofs under distinct keys, maximum-size leaves, and blocks retaining one claim per maximum-resource leaf with its payment. Include padded leaves, overlapping leaves, pruning and finalization. Measure leaf verification, claim hashing and payment-binding work separately, plus total work, recursive critical path, memory and transmitted bytes. The leaf charge MUST cover the most expensive permitted proof shape, not an average application program. If the gas schedule does not meet the budgets, revise the charges or interface before activation.

## Rationale

### Charging for shared work

The leaf charge prices the worst permitted recursive verification under EIP-8288's resource bounds; the claim charge prices additional digest and output work. Neither depends on the signature scheme implemented by a user verifier. With the provisional values, each included claim pays 300 dependency-frame gas plus EIP-8288's 30,000-gas intrinsic proof share; a separate payment declaration contributes 30,000 gas per leaf, plus its transaction's other costs. Losing members cannot reduce the leaf charge.

The payment declaration uses ordinary transaction fee authorization and settlement; it does not compensate the batcher directly. An application may fund proving or charge a separate service fee. Batching amortizes proof overhead and recursive verification; application-specific claim proving, possibly using the signature scheme's own aggregation, can still dominate. Filling a batch trades latency for cost.

A separate payment transaction keeps the fixed charge independent of members' validity. A shared member paymaster alone would not achieve this. Identifying the payment by the key and claim-list digest lets a sponsor authorize it after proving and lets the same statement use different proof bytes. Authenticated source assignments prevent pruning from removing the payment while retaining its discounted claims.

### Submission path

Direct submission avoids a public pool tracking sponsorship dependencies or reserving fees for a batch. Each user retains a native transaction. Combining users' operations into one application transaction could share more fixed costs, but would also share its nonce and receipt and require application-level replay protection.

## Backwards Compatibility

Activation enables two dependency schemes and changes the aggregation verifier. Existing schemes retain their encodings, charges and singleton statements. User verification keys only gain batching if their programs accept lists of independent claims; a program restricted to one claim remains usable and can produce a sponsored singleton.

Public-mempool message formats remain unchanged. Blocks contain individual transactions and the recursive proof under the activating fork's rules, without batch membership fields.

## Test Cases

| Case | Expected result |
| --- | --- |
| Nonzero scheme padding; zero payment digest | Reject |
| One-claim digest | Equals EIP-8288's singleton statement |
| Empty, repeated, unsorted or 257-claim leaf | Reject before hashing or leaf verification |
| 64 members and their leaf payment; prune to one member | Accept with the same leaf and member signature; retain the payment |
| Remove the payment while retaining one assigned claim | Reject |
| Remove every member and the payment | Accept; the block owes no charge for that omitted leaf |
| Include an unused payment | Verify its leaf and charge the declaration normally |
| Padding in a leaf or different proof bytes for the same statement | Fixed payment remains required; statement identity is unchanged |
| 64 singleton leaves under one key | Require their 64 distinct payments; cannot replace them with payment for an unproved union |
| Overlapping leaves establish the same dependency | Select an authenticated source; each distinct source retained by any claim needs its own payment |
| Finalized batch proof imported without its authenticated assignments | Reject |
| Restore a discarded claim or change its source without verified coverage | Reject |
| Payment for another key, claim list or earlier block | Does not satisfy the retained claim's source |
| 64 included claims and one payment | 64 times 30,300 gas plus 30,000 leaf gas, excluding other transaction costs |
| Duplicate declaration in a transaction | Charge both occurrences before dependency deduplication |
| Matching claim under a different key; invalid or over-resource leaf | Reject, including inputs later discarded |
| A member expires, is replaced or included; member and sponsor have different payers | Evaluate each transaction separately; other claims remain provable |
| Sponsor transaction invalid or absent | Reject until a valid payment is included; members need no new signatures |
| A later ordinary execution frame reverts in a valid sponsorship transaction | Payment declaration remains effective and charged |
| Either new scheme submitted to the public pool or inside a wrapper | Do not admit or propagate, even with a valid proof |
| An inclusion list contains ordinary and discounted entries | Discounted entries impose no obligation; evaluate the others normally |
| Switch a signature-hash-bound transaction to the ordinary scheme | Recompute its budget and signature; prove the updated claim before ordinary admission |

## Security Considerations

The constants are provisional, not measured prices. Every retained discounted claim must be linked to a verified leaf and its included payment. Payment identities cannot be invented by union or changed by pruning; payment without leaf verification cannot establish a claim. All leaf resource bounds apply even to inputs later discarded. Padding cannot reduce the fixed charge.

Sponsorship remains an availability dependency: the sponsor may withhold payment or its transaction may become invalid. Another sponsor can pay for the same leaf without changing member transactions. If every member disappears, omitting the leaf prevents a block charge but does not reimburse proving already performed; that risk belongs to the batcher's service arrangement.

Batchers and builders can delay, withhold or expose transactions received privately. The discounted path has no inclusion-list guarantee. A sender unable to prove needs another prover for the full-price fallback, which also requires account support and public-mempool eligibility.

Accounts remain responsible for verifier semantics and for authenticating every claim independently. Under a sound verifier, a batcher cannot forge authorization. Accounts may also retain a native key or an in-EVM validation path within the public-mempool limits.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
