---
title: Batched Generic Proof Dependencies
description: Enables bounded generic proof verification and sponsored batches of independent claims
author: Marc Harvey-Hill (@Marchhill)
status: Draft
type: Standards Track
category: Core
created: 2026-11-13
requires: 7805, 8141, 8288
---

## Abstract

This EIP enables generic leanSTARK dependencies in [EIP-8288](./eip-8288.md), defines bounded singleton and batch proof verification, and calibrates dependency gas charges against a common proving budget. For discounted batches, transactions pay per claim and a sponsor separately pays for each leaf used in the block. Any valid subset of a batch can be included without changing its members' signatures. Discounted transactions are submitted directly to builders and are excluded from the public mempool and inclusion-list obligations.

## Motivation

Generic proofs let accounts authenticate claims under a chosen verification key instead of executing costly verifiers on chain. One proof inside the aggregation circuit can establish claims for many transactions. Charging every claim as a separate proof ignores that amortization. Each transaction should commit to its own claim before a batch is formed, without depending on other members remaining includable.

An application supporting future post-quantum passkeys can collect assertions through its API, fund proving and submit a leaf, its payment transaction and the users' transactions directly to a builder. Each user keeps a native [EIP-8141](./eip-8141.md) transaction with its own nonce, receipt and payer. Another batcher or sponsor can serve the signed transactions without changing them. Public-mempool access and inclusion-list protection remain available through the ordinary, full-price scheme.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This EIP enables EIP-8288's reserved `LEANSTARK_SCHEME`, adds batch claims and leaf payments, and replaces its dependency digest and recursive statements. Activation requires a new `AGGREGATED_VK`; other EIP-8288 rules apply unless modified below.

### Constants

| Name | Value |
| --- | --- |
| `LEANSTARK_SCHEME` | `0x11` (enabled) |
| `BATCHED_LEANSTARK_SCHEME` | `0x12` (provisional) |
| `LEANSTARK_LEAF_PAYMENT_SCHEME` | `0x13` (provisional) |
| `MAX_CLAIMS_PER_BATCH_LEAF` | `256` (provisional) |
| `MAX_DEPS_PER_BLOCK` | `16384` (provisional) |
| `LEANSTARK_LEAF_PAYMENT_GAS` | `675000` (provisional) |
| `LEANSTARK_CLAIM_GAS` | `4200` (provisional) |
| `BATCH_HASH` | Keccak-256 (provisional) |
| `MAX_INNER_PROOFS_PER_STEP` | `16` (provisional) |

The provisional resource and gas parameters MUST be finalized through the activation benchmarks below.

### Provisional changes to EIP-8288

The dependency digest and base pricing below are included provisionally here and intended to move into EIP-8288 once benchmarks settle the parameters.

#### Dependency pricing

| Name | Value |
| --- | --- |
| `LEANSPHINCS_VERIFICATION_GAS` | `15400` (provisional) |
| `LEANSTARK_VERIFICATION_GAS` | `572000` (provisional) |
| `RECURSIVE_PROOF_SHARE_GAS` | `5100` (provisional) |

From activation, replace EIP-8288's native and generic verification charges with these values and its intrinsic proof-share multiplier with `RECURSIVE_PROOF_SHARE_GAS`.

#### Dependency digest

Replace `get_deps_hash` everywhere in EIP-8288, including block commitments, with the hash of canonical 96-byte triples, including the scheme. Lists retain EIP-8288's sorting and deduplication rules.

```python
def encode_dependency(dep):
    scheme, data_hash, verification_key_hash = dep
    return scheme.to_bytes(32, 'big') + data_hash + verification_key_hash

def get_deps_hash(deps):
    return DEPS_HASH(b''.join(encode_dependency(dep) for dep in deps))
```

### Dependency encoding

Allow `LEANSTARK_SCHEME`, `BATCHED_LEANSTARK_SCHEME` and `LEANSTARK_LEAF_PAYMENT_SCHEME` alongside `LEANSPHINCS_SCHEME` in dependency verification frames. They use EIP-8288's 96-byte triple; the 31 padding bytes before the scheme byte remain reserved and zero:

| Scheme | `data_hash` | `verification_key_hash` |
| --- | --- | --- |
| `LEANSTARK_SCHEME` | Individual claim, with EIP-8288's zero substitution | Leaf verification-key hash |
| `BATCHED_LEANSTARK_SCHEME` | Individual claim, with EIP-8288's zero substitution | Leaf verification-key hash |
| `LEANSTARK_LEAF_PAYMENT_SCHEME` | Nonzero `get_batch_hash(claims)` | Leaf verification-key hash |

The payment triple identifies a leaf statement independently of its proof bytes. A member transaction commits to its claim and key, not the batch membership or sponsor.

### Generic proof verification

Provisionally, the leanSTARK verification key is the verifier's canonical 32-byte `program_commitment`, binding the complete program and its layout. The fork's pinned proof-system specification defines its derivation and all key-material encodings, and fixes the commitment construction, byte order, proof system, field, transcript, soundness parameters and resource bounds. Per-key parameter overrides are forbidden; proof-specific dimensions are authenticated inputs constrained by those bounds.

At the fork's soundness level, the commitment must bind at most one complete program and layout even when generated adversarially. It must bind the proof transcript and support sound openings of the program-table evaluations required by verification, with authentication work sublinear in padded program size. Verification authenticates the proven program against the commitment named by:

```python
def get_vk_hash(program_commitment):
    assert len(program_commitment) == 32
    return keccak256(b'EIP8288:vk:v1' + program_commitment)
```

### Verifier resource bounds

The fork fixes the following bounds with `AGGREGATED_VK`:

- Maximum program size, trace dimensions, committed field elements, bus interactions and proof bytes. Program size includes support code and padding; proof bytes include all openings and authentication data. Encodings must represent every permitted proof. Reject violations at direct admission and inside aggregation, including discarded inputs.
- Outer aggregation trace and proof-system size bounds. Finalize `MAX_INNER_PROOFS_PER_STEP` and leaf bounds jointly with the commitment construction. The resulting circuit must support full steps of maximum-resource leaves under distinct keys and permitted mixtures with recursive inputs within those bounds.
- Output capacity of at least `MAX_DEPS_PER_BLOCK` dependencies.

Counters and indices must represent permitted program, list, intermediate-union and derived byte lengths without overflow, including input unions larger than the retained output. Reject out-of-range lengths before narrowing conversions.

### Block dependency capacity

A block is invalid if `len(dependencies(block)) > MAX_DEPS_PER_BLOCK`. Count distinct resolved triples across all schemes, including leaf payments. The limit is independent of the block gas limit; changing it requires a fork with a matching `AGGREGATED_VK`.

### Gas accounting

Combining the base pricing above with the batch charges, charge each declaration as follows:

| Scheme | Dependency frame's `limits.execution` contribution | Intrinsic proof share |
| --- | --- | --- |
| `LEANSPHINCS_SCHEME` | `LEANSPHINCS_VERIFICATION_GAS` | `RECURSIVE_PROOF_SHARE_GAS` |
| `LEANSTARK_SCHEME` | `LEANSTARK_VERIFICATION_GAS` | `RECURSIVE_PROOF_SHARE_GAS` |
| `BATCHED_LEANSTARK_SCHEME` | `LEANSTARK_CLAIM_GAS` | `0` |
| `LEANSTARK_LEAF_PAYMENT_SCHEME` | `LEANSTARK_LEAF_PAYMENT_GAS` | `0` |

Charge each occurrence before dependency deduplication. Sum frame contributions to obtain the frame's exact `limits.execution`; add proof shares to transaction intrinsic gas as in EIP-8288. Other transaction and authorization costs still apply. Frame charges count toward block execution capacity under EIP-8141's normal gas accounting; refunds do not reduce that capacity charge.

A sponsor declares one or more leaf payments in its own frame transaction. Its payer authorizes the fees through EIP-8141; member transactions need not use that payer. A payment is effective only when its transaction is valid and included in the same block, before or after its members. If two sponsors pay for the same leaf, both declarations are charged; deduplication gives neither a refund nor additional credit. Payment in an earlier block provides no credit.

### Batch statements

A leaf has one verification key, a proof and a nonempty list `claims` of at most `MAX_CLAIMS_PER_BATCH_LEAF` 32-byte values. Its public statement is:

```python
def get_batch_hash(claims):
    return BATCH_HASH(b'EIP8288:batch:v1' + b''.join(claims))

def get_claim_hash(data_hash):
    assert len(data_hash) == 32
    return get_batch_hash([data_hash])
```

Verify each leaf with `verify_leanSTARK((get_batch_hash(claims),), verification_key_hash, proof)`. A direct `LEANSTARK_SCHEME` witness is a proof byte string establishing `(get_claim_hash(data_hash),)`, a one-claim leaf. This applies to mode 0 admission and direct inputs to aggregation. `BATCH_HASH` remains fixed independently of `DEPS_HASH`; a verifier may accept only singleton lists.

The aggregation circuit MUST check claim widths, the list bound and strictly increasing byte-lexicographic order before hashing. The leaf verifier need not duplicate the order check. It must establish each claim independently of other records; a constraint spanning records belongs in one composite claim. The protocol authenticates acceptance under the selected key, not the claims' meaning or independence, which remain the responsibility of accounts selecting that key.

For each verified leaf, the aggregation circuit may establish:

- Ordinary `LEANSTARK_SCHEME` dependencies whose claim is in `claims` and whose key matches the leaf.
- Batch dependencies with the same membership and key checks.
- Its leaf-payment dependency, whose digest and key match the leaf.

A step is one execution of the aggregation circuit producing one recursive proof. It MUST support any combination of up to `MAX_INNER_PROOFS_PER_STEP` generic leaves and recursive proofs within the other resource bounds, and reject larger counts. Each direct singleton or batch leaf counts once, including direct proofs across folded mode 0 wrappers and discarded or redundant inputs; proofs deeper in the tree do not count. Apply all resource bounds before discards. Recursion may combine more claims and proofs than these per-step and per-leaf bounds.

### Recursive payment binding

Each batch dependency is assigned to the payment triple of the verified leaf that established it. Recursive proofs authenticate records `(dependency, source)`, where `source` is that payment triple for a batch dependency and absent for other schemes. Records are sorted and deduplicated by dependency. The resource and counter bounds apply to the 192-byte records and intermediate unions. Intermediate proofs may retain claims without their payment dependencies; payment presence is checked at finalization. Recursive public statements are:

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

The circuit checks record order, widths and source types before hashing. The common prefix and distinct one-byte tags separate all three recursive statement domains independently of payload length. Under the updated `AGGREGATED_VK`, ordinary recursive proofs use `get_ordinary_hash(get_deps_hash(deps))` in wrappers, inclusion lists, blocks and recursive inputs; the ordinary-output circuit MUST reject both new schemes. Ordinary proofs can be imported with absent sources; finalized proofs MUST NOT be imported for aggregation in either domain.

- At each step, the prover chooses among sources authenticated by its verified inputs. The output commits to that choice. A later step may change it only by supplying another verified source for the same dependency; union size cannot create a leaf statement or payment identity.
- Discarding a dependency removes its record. Discarding a payment does not remove references to it from retained claims. Discarded dependencies cannot be restored without another verified input.

Finalization verifies an intermediate proof and checks that every source payment is present in its retained dependencies, then outputs `get_batch_final_hash(get_deps_hash(deps))`. The block's `block_deps_hash` remains `get_deps_hash(dependencies(block))`. For a nonempty dependency set, validators MUST verify against `get_batch_final_hash(block_deps_hash)` if either new scheme is present, and `get_ordinary_hash(block_deps_hash)` otherwise. Empty dependency sets retain EIP-8288's empty-proof rule. Both statements also bind the fork's `AGGREGATED_VK`. Sources remain private proving inputs: validators enforce payment binding through the proof, without a new block field.

### Submission and inclusion

Batchers submit member transactions, leaf proofs and sponsorship transactions directly to builders. The submission API and any payment for the batcher's service are outside this specification. Builders verify the leaves and incorporate them into EIP-8288's recursive block proof; leaves are not added to the block encoding.

Transactions declaring either new scheme MUST NOT be admitted to or propagated through the public mempool, including inside proof wrappers. They impose no [EIP-7805](./eip-7805.md) inclusion obligation, even if an inclusion list supplies a covering proof. Includers MUST omit them; evaluate remaining entries under EIP-7805 and EIP-8288.

An inclusion-list proof establishes coverage only in the ordinary recursive domain. A proof dependency list containing either new scheme, or an intermediate or finalized proof, provides no coverage for any entry. Dependency-free entries retain their obligations regardless of that proof; other lists are unaffected.

An otherwise applicable inclusion-list transaction `T` may be omitted for dependency capacity only if `len(set(dependencies(block)) | set(dependencies(T))) > MAX_DEPS_PER_BLOCK`. Transactions adding no distinct dependencies cannot be excused on this ground.

Builders may include any valid subset of member transactions, including a single survivor. They MUST include payments matching the selected sources before producing a block with batch claims. If a selected payment is unavailable, the builder must obtain a valid payment, reaggregate with another authenticated source, or omit the affected claim. Each transaction follows EIP-8141's validity and payment rules independently. Expiry, replacement or inclusion of another member does not change the surviving member's charge or require its signature or leaf proof to be replaced; the aggregate is updated for the retained dependencies.

If all members are omitted, the builder may omit their leaf and its payment. A payment included without any surviving members, including when all have expired, still requires a valid leaf proof and is charged normally at the sponsor's risk.

A proof does not establish sponsorship-transaction validity. If that transaction becomes invalid after proving, the builder MUST replace it or update the aggregate before publishing the block. The proof may be reused with a valid replacement only if the final dependency set is unchanged; otherwise reaggregate from intermediate proofs or leaves and produce a new finalization proof. Member signatures need not change.

### Public-mempool fallback

Accounts seeking a fallback SHOULD authorize both generic schemes under the same verification key and claim semantics. A sender can replace the discounted declaration with ordinary `LEANSTARK_SCHEME`, update the gas budget, re-sign and obtain a singleton proof for the updated transaction. The ordinary transaction is subject to the existing public-mempool and inclusion-list eligibility rules.

### Fork transition

Proof-validation caches MUST distinguish verifier keys, statement domains and public inputs, including `AGGREGATED_VK` for recursive proofs. When the applicable mempool fork changes, wrappers validated only under the previous rules MUST NOT be admitted, served, announced or used to suppress announcements. Direct witnesses MUST be validated under the new rules before reuse: a generic proof of the bare `(data_hash,)` statement cannot satisfy the new claim-digest statement, while native witnesses may remain valid. Recursive coverage must be rebuilt under the new key. Transactions require current-fork coverage for admission. Old-key proofs provide no coverage for post-activation inclusion lists or blocks.

### Activation requirements

Before activation:

- Pin the complete proof-system specification and soundness analysis covering adversarial keys, canonical key/proof encodings, `DEPS_HASH`, `BATCH_HASH`, `AGGREGATED_VK`, and key, digest, payment-binding and statement-domain conformance vectors.
- Publish the reference prover/verifier configuration, hardware and worker count, block gas limit, numerical builder and validator time/memory budgets, and safety margins.
- Demonstrate maximum-resource steps and valid blocks meeting those budgets: EVM execution, native signatures, distinct-key singleton proofs, full batch leaves, one surviving claim per paid leaf, and adversarial mixtures. Measure cumulative carry and payment binding through overlaps, pruning and finalization. Finalize all bounds and charges together; an ordinary singleton proof or leaf payment, including required transaction overhead, must fit within the applicable per-transaction gas limit.

Use the [benchmark methodology](../assets/eip-draft_batched_dependency_pricing/benchmarks.md) for workload construction and reporting. Models and extrapolations do not satisfy the gate; higher gas limits require recalibration.

## Rationale

### Verifier identity and statements

Sound evaluation openings authenticate the committed program without hashing its entire table inside recursion. Binding must hold for adversarial keys; the pinned proof-system specification defines the construction. User verifiers compute the claim digest in-circuit, so fixing `BATCH_HASH` independently of `DEPS_HASH` preserves pinned keys when the aggregation hash changes. Singletons and batches use one statement, allowing batch membership to change without changing transaction claims.

### Output capacity

A fixed dependency limit bounds the circuit's output without imposing a gas-limit ceiling. At 60 million gas and the provisional minimum charge of 4,200, at most 14,285 declarations fit even before other transaction costs, below the proposed 16,384 limit. Higher gas limits or lower charges may make the dependency limit binding.

### Charging for shared work

The charges allocate EIP-8288's block proving capacity under the reference hardware and worker budget. Work-proportional pricing approximates additive work but does not alone bound peak memory or recursive critical-path latency. Program size, trace dimensions, committed values and bus interactions affect the worst case; proof size or an assumed small average-to-worst-case ratio cannot establish a safe rate.

Generic verification includes its recursive child-slot cost; the separate proof share prices dependency carry. A leaf payment additionally covers fixed payment-binding work, so it is calibrated separately from ordinary verification. Member claims pay marginal carry and binding through finalization. Neither new scheme adds another intrinsic share, and losing members cannot reduce the leaf charge. Carry charges must cover the depths of the calibrated block schedules; their provisional calibration is documented in the benchmark methodology.

The payment declaration uses ordinary transaction fee authorization and settlement; it does not compensate the batcher directly. An application may fund proving or charge a separate service fee. Batching amortizes proof overhead and recursive verification; application-specific claim proving, possibly using the signature scheme's own aggregation, can still dominate. Filling a batch trades latency for cost.

A separate payment transaction keeps the fixed charge independent of members' validity. Identifying the payment by the key and claim-list digest lets a sponsor authorize it after proving and lets the same statement use different proof bytes. Authenticated sources and the finalization check prevent unpaid claims in a block. A separate finalization domain prevents importing a proof after its sources have been erased.

### Submission path

Direct submission avoids a public pool tracking sponsorship dependencies or reserving fees for a batch. Each user retains a native transaction. Combining users' operations and payment into one transaction would remove cross-transaction payment dependence, but would also share its nonce and receipt and require application-level replay protection. Separate payments preserve individual transactions and partial inclusion at the cost of builder-side sponsorship risk.

## Backwards Compatibility

Activation enables the reserved `LEANSTARK_SCHEME` and two additional schemes. It replaces EIP-8288's proposed bare `(data_hash,)` generic statement with `(get_claim_hash(data_hash),)`; verifiers written for the former must adopt the new statement.

Native signature verification and dependency-frame encoding remain unchanged, but the dependency digest now includes scheme bytes and all recursive proofs use the new key and tagged statements. The revised gas schedule requires updated budgets and signatures for transactions signed with old dependency-frame execution limits.

Public-mempool message formats remain unchanged. Blocks contain individual transactions and the recursive proof under the activating fork's rules, without batch membership fields.

## Test Cases

| Case | Expected result |
| --- | --- |
| Nonzero scheme padding; zero payment digest | Reject |
| One-claim digest | `get_batch_hash([claim]) == get_claim_hash(claim)`; reject a proof of the bare claim |
| Same claim and key under different schemes | Distinct canonical 96-byte encodings and dependency digests |
| Wrong key, key-hash tag or commitment width | Reject |
| Program substitution, unauthenticated dimensions or parameter overrides | Reject |
| Opening for another commitment, point or value; unbound transcript | Reject, including inconsistent key-bound evaluations even if the key hash is recomputed |
| Each resource bound and one above it | Accept the bound; reject overflow even for discarded inputs; count support code, padding and all authentication data |
| Full step at finalized arity and maximum resource bounds | Fits outer proof bounds; reject oversized steps even within the arity limit |
| `MAX_INNER_PROOFS_PER_STEP` immediate generic/recursive inputs, then one more | Accept then reject; include direct inputs across wrappers and discarded or redundant proofs |
| `MAX_DEPS_PER_BLOCK` distinct block dependencies, then one more | Accept at the limit if otherwise valid; reject one above even if gas fits |
| Repeated triples, mixed schemes and leaf payments | Count each distinct resolved triple once, including payments |
| Reduce a declaration charge or increase the gas limit | The block dependency limit remains unchanged |
| An otherwise applicable inclusion-list transaction adds dependencies beyond the block limit | Omission is excused for that entry; adding only existing dependencies or none does not excuse omission |
| 65,535- and 65,536-entry intermediate unions pruned to a supported output | Preserve lengths and retained entries without truncation; reject out-of-range program, list and derived byte lengths before narrowing |
| Noncanonical key or proof encoding | Reject before proof verification |
| Change `DEPS_HASH` | Does not change `get_claim_hash` or the user verification key |
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
| One native or ordinary generic declaration | 20,500 or 577,100 gas respectively, including the intrinsic share; charge duplicate declarations separately |
| 64 included claims and one payment | 64 times 4,200 gas plus 675,000 leaf gas: 943,800 gas, excluding other transaction costs |
| Two sponsors pay for the same leaf in one block | Charge both payments; deduplicate the dependency without refund or extra credit |
| Duplicate declaration in a transaction | Charge both occurrences before dependency deduplication |
| Matching claim under a different key; invalid or over-resource leaf | Reject, including inputs later discarded |
| A member expires, is replaced or included; member and sponsor have different payers | Evaluate each transaction separately; other claims remain provable |
| Sponsor transaction invalid or absent | Reject until a valid payment is included; members need no new signatures |
| Sponsor invalidated after proving; replacement preserves or changes final dependencies | Reuse the proof only for a valid replacement preserving the dependency set; otherwise reaggregate and finalize again |
| A later ordinary execution frame reverts in a valid sponsorship transaction | Payment declaration remains effective and charged |
| Either new scheme submitted to the public pool or inside a wrapper | Do not admit or propagate, even with a valid proof |
| An inclusion list contains ordinary and discounted entries with an ordinary proof | Discounted entries impose no obligation; covered ordinary and dependency-free entries retain theirs |
| Inclusion-list proof names a new scheme or uses the intermediate/finalized domain | Provides no coverage; dependency-free entries and other lists are unaffected |
| Activation changes verification rules with old verdicts cached | Revalidate direct witnesses; reject bare-claim generic proofs; distinguish keys, domains and public inputs in the cache; rebuild recursive coverage under the new key |
| Switch a signature-hash-bound transaction to the ordinary scheme | Recompute its budget and signature; prove the updated claim before ordinary admission |

## Security Considerations

The gas parameters are provisional; payment-binding cost and complete block schedules require measurement. Every discounted claim included in a block must be linked to a verified leaf and its included payment. Payment identities cannot be invented by union or changed by pruning; payment without leaf verification cannot establish a claim. All leaf resource bounds apply even to inputs later discarded. Padding cannot reduce the fixed charge.

Sponsorship remains an availability dependency: the sponsor may withhold payment or invalidate its transaction after proving, wasting builder work without paying on chain. Another sponsor can pay for the same leaf without changing member transactions. If every member disappears, the builder may omit the leaf. Inclusion gas does not reimburse discarded or repeated proving; builders must manage this risk through submission policy or service arrangements.

Batchers and builders can delay, withhold or expose transactions received privately. The discounted path has no inclusion-list guarantee. A sender unable to prove needs another prover for the full-price fallback, which also requires account support and public-mempool eligibility.

Generic claims can prove arbitrary computations, so worst-case benchmarks must cover the most expensive permitted singleton proofs, not only signature programs. Gas bounds included declarations; step arity and resource bounds limit individual operations, not redundant or discarded proving histories. Clients should bound that local work.

Accounts remain responsible for verifier semantics and for authenticating every claim independently. Authorization claims must bind the signer, message and required policy. Under a sound verifier, a batcher cannot forge authorization. Accounts may also retain a native key or an in-EVM validation path within the public-mempool limits.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
