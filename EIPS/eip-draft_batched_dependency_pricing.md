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

This EIP extends [EIP-8288](./eip-8288.md) with proofs of multiple independent claims under one verification key and recalibrates its dependency gas charges against a common proving budget. Transactions pay per claim; a sponsor separately pays for each leaf used in the block. Any valid subset of a batch can be included without changing its members' signatures. These transactions are submitted directly to builders and are excluded from the public mempool and inclusion-list obligations.

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
| `LEANSPHINCS_VERIFICATION_GAS` | `15400` (provisional) |
| `LEANSTARK_VERIFICATION_GAS` | `572000` (provisional) |
| `RECURSIVE_PROOF_SHARE_GAS` | `4200` (provisional) |
| `LEANSTARK_CLAIM_GAS` | `4200` (provisional) |
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

From activation, replace EIP-8288's native and generic verification charges with the values above and its intrinsic proof-share multiplier with `RECURSIVE_PROOF_SHARE_GAS`. Charge each declaration as follows:

| Scheme | Dependency frame's `limits.execution` contribution | Intrinsic proof share |
| --- | --- | --- |
| `LEANSPHINCS_SCHEME` | `LEANSPHINCS_VERIFICATION_GAS` | `RECURSIVE_PROOF_SHARE_GAS` |
| `LEANSTARK_SCHEME` | `LEANSTARK_VERIFICATION_GAS` | `RECURSIVE_PROOF_SHARE_GAS` |
| `BATCHED_LEANSTARK_SCHEME` | `LEANSTARK_CLAIM_GAS` | `0` |
| `LEANSTARK_LEAF_PAYMENT_SCHEME` | `LEANSTARK_VERIFICATION_GAS + RECURSIVE_PROOF_SHARE_GAS` | `0` |

Charge each occurrence before dependency deduplication. Sum frame contributions to obtain the frame's exact `limits.execution`; add proof shares to transaction intrinsic gas as in EIP-8288. Other transaction and authorization costs still apply. Frame charges count toward block execution capacity under EIP-8141's normal gas accounting; refunds do not reduce that capacity charge.

A sponsor declares one or more leaf payments in its own frame transaction. Its payer authorizes the fees through EIP-8141; member transactions need not use that payer. A payment is effective only when its transaction is valid and included in the same block, before or after its members. If two sponsors pay for the same leaf, both declarations are charged; deduplication gives neither a refund nor additional credit. Payment in an earlier block provides no credit.

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

Each batch dependency is assigned to the payment triple of the verified leaf that established it. Recursive proofs authenticate records `(dependency, source)`, where `source` is that payment triple for a batch dependency and absent for other schemes. Records are sorted and deduplicated by dependency. Intermediate proofs may retain claims without their payment dependencies; payment presence is checked at finalization. Recursive public statements are:

```python
def get_ordinary_hash(deps_hash):
    assert len(deps_hash) == 32
    return DEPS_HASH(b'EIP8288:aggregate:v1' + b'\x00' + deps_hash)

def get_batch_state_hash(records):
    return DEPS_HASH(b'EIP8288:aggregate:v1' + b'\x01' + b''.join(
        encode_dependency(dep) + (
            encode_dependency(source) if source is not None else bytes(96)
        )
        for dep, source in records
    ))

def get_batch_final_hash(deps_hash):
    assert len(deps_hash) == 32
    return DEPS_HASH(b'EIP8288:aggregate:v1' + b'\x02' + deps_hash)
```

`encode_dependency` is EIP-8288's canonical 96-byte encoding. The circuit checks record order, widths and source types before hashing. The common prefix and distinct one-byte tags separate all three recursive statement domains independently of payload length. Under the updated `AGGREGATED_VK`, ordinary recursive proofs use `get_ordinary_hash(get_deps_hash(deps))` in wrappers, inclusion lists, blocks and recursive inputs; the ordinary-output circuit MUST reject both new schemes. Ordinary proofs can be imported with absent sources; finalized proofs MUST NOT be imported for aggregation in either domain. Direct generic leaf statements are unchanged.

- At each step, the prover chooses among sources authenticated by its verified inputs. The output commits to that choice. A later step may change it only by supplying another verified source for the same dependency; union size cannot create a leaf statement or payment identity.
- Discarding a dependency removes its record. Discarding a payment does not remove references to it from retained claims. Discarded dependencies cannot be restored without another verified input.

Finalization verifies an intermediate proof and checks that every source payment is present in its retained dependencies, then outputs `get_batch_final_hash(get_deps_hash(deps))`. The block's `block_deps_hash` remains `get_deps_hash(dependencies(block))`. For a nonempty dependency set, validators MUST verify against `get_batch_final_hash(block_deps_hash)` if either new scheme is present, and `get_ordinary_hash(block_deps_hash)` otherwise. Empty dependency sets retain EIP-8288's empty-proof rule. Both statements also bind the fork's `AGGREGATED_VK`. Sources remain private proving inputs: validators enforce payment binding through the proof, without a new block field.

### Submission and inclusion

Batchers submit member transactions, leaf proofs and sponsorship transactions directly to builders. The submission API and any payment for the batcher's service are outside this specification. Builders verify the leaves and incorporate them into EIP-8288's recursive block proof; leaves are not added to the block encoding.

Transactions declaring either new scheme MUST NOT be admitted to or propagated through the public mempool, including inside proof wrappers. They impose no [EIP-7805](./eip-7805.md) inclusion obligation, even if an inclusion list supplies a covering proof. Includers MUST omit them; evaluate remaining entries under EIP-7805 and EIP-8288.

An inclusion-list proof establishes coverage only in the ordinary recursive domain. A proof dependency list containing either new scheme, or an intermediate or finalized proof, provides no coverage for any entry. Dependency-free entries retain their obligations regardless of that proof; other lists are unaffected.

Builders may include any valid subset of member transactions, including a single survivor. They MUST include payments matching the selected sources before producing a block with batch claims. If a selected payment is unavailable, the builder must obtain a valid payment, reaggregate with another authenticated source, or omit the affected claim. Each transaction follows EIP-8141's validity and payment rules independently. Expiry, replacement or inclusion of another member does not change the surviving member's charge or require its signature or leaf proof to be replaced; the aggregate is updated for the retained dependencies.

If all members are omitted, the builder may omit their leaf and its payment. A payment included without any surviving members, including when all have expired, still requires a valid leaf proof and is charged normally at the sponsor's risk.

A proof does not establish sponsorship-transaction validity. If that transaction becomes invalid after proving, the builder MUST replace it or update the aggregate before publishing the block. The proof may be reused with a valid replacement only if the final dependency set is unchanged; otherwise reaggregate from intermediate proofs or leaves. Member signatures need not change.

### Public-mempool fallback

Accounts seeking a fallback SHOULD authorize both generic schemes under the same verification key and claim semantics. A sender can replace the discounted declaration with ordinary `LEANSTARK_SCHEME`, update the gas budget, re-sign and obtain a singleton proof for the updated transaction. The ordinary transaction is subject to the existing public-mempool and inclusion-list eligibility rules.

### Fork transition

Proof-validation caches MUST distinguish `AGGREGATED_VK` and statement domain. When the applicable mempool fork changes, wrappers validated only under the previous rules MUST NOT be admitted, served, announced or used to suppress announcements. Direct-witness wrappers may be revalidated under the new rules; recursive coverage must be rebuilt under the new key. Transactions require current-fork coverage for admission. Old-key proofs provide no coverage for post-activation inclusion lists or blocks.

### Activation requirements

Activation requires the new aggregation key, leaf and intermediate-proof encodings, payment-binding and statement-domain conformance vectors, and EIP-8288's verifier resource and counter bounds, including the 192-byte intermediate records. Calibrate native, ordinary generic, proof-share and batch-claim charges together against EIP-8288's published block-capacity budgets, using its reference hardware, worker and thread counts, and complete transaction gas accounting. The calibration applies only to the benchmarked gas limits.

A maximum-resource leaf is a valid leaf maximizing recursive verification cost within the permitted program size (including support code and padding), trace dimensions, committed values, bus interactions, proof bytes and claim count. Include program-commitment authentication and opening verification; benchmark jointly valid combinations of resource bounds.

Benchmarks MUST cover:

- Singleton proofs under distinct keys, full 256-claim leaves, and blocks retaining one claim per maximum-resource leaf with its payment; include mixtures with native signatures and EVM execution. Charges assume unpacked leaves: one generic leaf per initial aggregation step, without shared-key preprocessing savings.
- Claim hashing, payment lookup and binding, overlapping leaves, pruning and finalization throughout the block's aggregation tree. Report tree depth, cumulative per-claim work, total work, critical-path latency, scheduled completion time at the stated worker count, peak memory and transmitted bytes.

The leaf charge MUST account for maximum permitted verification work; the claim charge MUST account for cumulative claim and payment-binding work through finalization, not just a single hashing pass. Calibrate ordinary dependency carry and batch-claim carry at the same tree depths, separating per-record work from amortized leaf and recursive-node overhead; charge each component once. Their rates MUST keep gas-admissible blocks within the shared time and memory budgets, including recursive critical-path latency and inter-worker transfers. Total work divided by worker count is not a completion-time measurement. Measure the selected commitment construction, maximum-resource leaves and payment binding before finalizing the charges; modelled timings do not satisfy this requirement. If the gas schedule does not meet the budgets, revise the charges or interface before activation.

## Rationale

### Charging for shared work

The charges allocate EIP-8288's block proving capacity under the reference hardware and worker budget. Work-proportional pricing approximates additive work but does not alone bound peak memory or recursive critical-path latency. Program size, trace dimensions, committed values and bus interactions affect the worst case; proof size or an assumed small average-to-worst-case ratio cannot establish a safe rate.

Generic verification includes its recursive child-slot cost; the separate proof share prices dependency carry, so native signatures do not pay for a generic proof's child slot. A leaf payment charges both once; member claims pay their own carry and payment binding. Neither new scheme adds another intrinsic share. Losing members cannot reduce the leaf charge.

The provisional claim charge equals the proof share pending comparable carry and payment-binding measurements. This is a conservative placeholder, not a measured equality: a native-path share estimate that includes amortized node overhead is not a pure per-record baseline.

The payment declaration uses ordinary transaction fee authorization and settlement; it does not compensate the batcher directly. An application may fund proving or charge a separate service fee. Batching amortizes proof overhead and recursive verification; application-specific claim proving, possibly using the signature scheme's own aggregation, can still dominate. Filling a batch trades latency for cost.

A separate payment transaction keeps the fixed charge independent of members' validity. A shared member paymaster alone would not achieve this. Identifying the payment by the key and claim-list digest lets a sponsor authorize it after proving and lets the same statement use different proof bytes. Authenticated sources and the finalization check prevent unpaid claims in a block without repeating payment-presence checks at each step. A separate finalization domain prevents importing a proof after its sources have been erased.

### Submission path

Direct submission avoids a public pool tracking sponsorship dependencies or reserving fees for a batch. Each user retains a native transaction. Combining users' operations into one application transaction could share more fixed costs, but would also share its nonce and receipt and require application-level replay protection.

## Backwards Compatibility

Activation enables two dependency schemes and changes the aggregation verifier. The applicable fork's `AGGREGATED_VK` fixes the accepted schemes and statement forms; pre-activation generic verification remains singleton-only. Existing schemes retain their encodings and singleton leaf statements, but use the revised gas schedule; all recursive proofs adopt the tagged statements above. Transactions signed with old dependency-frame execution limits require updated budgets and signatures. User verification keys only gain batching if their programs accept lists of independent claims; a program restricted to one claim remains usable and can produce a sponsored singleton.

Public-mempool message formats remain unchanged. Blocks contain individual transactions and the recursive proof under the activating fork's rules, without batch membership fields.

## Test Cases

| Case | Expected result |
| --- | --- |
| Nonzero scheme padding; zero payment digest | Reject |
| One-claim digest | Equals EIP-8288's singleton statement |
| Empty, repeated, unsorted or 257-claim leaf | Reject before hashing or leaf verification |
| 64 members and their leaf payment; prune to one member | Accept with the same leaf and member signature; retain the payment |
| Remove the payment while retaining one assigned claim | Accept as an intermediate state; reject finalization until the matching payment is restored from verified input |
| Remove every member and the payment | Accept; the block owes no charge for that omitted leaf |
| Include a payment after all its members expire | Verify its leaf and charge the sponsor normally |
| Padding in a leaf or different proof bytes for the same statement | Fixed payment remains required; statement identity is unchanged |
| 64 singleton leaves under one key | Require their 64 distinct payments; cannot replace them with payment for an unproved union |
| Overlapping leaves establish the same dependency but only one source is paid | The prover selects that source; another selection fails finalization unless its payment is supplied |
| Change a source after an earlier step selected it | Require another verified input authenticating the alternative source |
| Same payload under ordinary, intermediate and finalized tags | Distinct hash preimages regardless of payload length |
| Finalized proof imported as ordinary or intermediate input | Reject by statement-domain mismatch, including payment-only outputs |
| Ordinary-output circuit asked to emit either new scheme | Reject |
| Block with either new scheme supplies a plain dependency-digest proof | Reject; require the finalized statement and the usual block dependency commitment |
| Restore a discarded claim or change its source without verified coverage | Reject |
| Payment for another key, claim list or earlier block | Does not satisfy the retained claim's source |
| One native or ordinary generic declaration | 19,600 or 576,200 gas respectively, including the revised intrinsic share; charge duplicate declarations separately |
| 64 included claims and one payment | 64 times 4,200 gas plus 576,200 leaf gas: 845,000 gas, excluding other transaction costs |
| Two sponsors pay for the same leaf in one block | Charge both payments; deduplicate the dependency without refund or extra credit |
| Duplicate declaration in a transaction | Charge both occurrences before dependency deduplication |
| Matching claim under a different key; invalid or over-resource leaf | Reject, including inputs later discarded |
| A member expires, is replaced or included; member and sponsor have different payers | Evaluate each transaction separately; other claims remain provable |
| Sponsor transaction invalid or absent | Reject until a valid payment is included; members need no new signatures |
| Sponsor invalidated after proving; replacement preserves or changes final dependencies | Reuse the proof only for a valid replacement preserving the dependency set; otherwise reaggregate |
| A later ordinary execution frame reverts in a valid sponsorship transaction | Payment declaration remains effective and charged |
| Either new scheme submitted to the public pool or inside a wrapper | Do not admit or propagate, even with a valid proof |
| An inclusion list contains ordinary and discounted entries with an ordinary proof | Discounted entries impose no obligation; covered ordinary and dependency-free entries retain theirs |
| Inclusion-list proof names a new scheme or uses the intermediate/finalized domain | Provides no coverage; dependency-free entries and other lists are unaffected |
| Activation changes `AGGREGATED_VK` with old wrappers cached | Do not reuse old validation or suppression; rebuild coverage under the new key, retaining only direct witnesses that still verify |
| Switch a signature-hash-bound transaction to the ordinary scheme | Recompute its budget and signature; prove the updated claim before ordinary admission |

## Security Considerations

The gas parameters are provisional; payment-binding cost and complete block schedules require measurement. Every discounted claim included in a block must be linked to a verified leaf and its included payment. Payment identities cannot be invented by union or changed by pruning; payment without leaf verification cannot establish a claim. All leaf resource bounds apply even to inputs later discarded. Padding cannot reduce the fixed charge.

Sponsorship remains an availability dependency: the sponsor may withhold payment or its transaction may become invalid. Another sponsor can pay for the same leaf without changing member transactions. If every member disappears, omitting the leaf prevents a block charge but does not reimburse proving already performed; that risk belongs to the batcher's service arrangement.

Batchers and builders can delay, withhold or expose transactions received privately. The discounted path has no inclusion-list guarantee. A sender unable to prove needs another prover for the full-price fallback, which also requires account support and public-mempool eligibility.

Accounts remain responsible for verifier semantics and for authenticating every claim independently. Under a sound verifier, a batcher cannot forge authorization. Accounts may also retain a native key or an in-EVM validation path within the public-mempool limits.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
