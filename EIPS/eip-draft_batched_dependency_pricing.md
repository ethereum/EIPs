---
title: Batched Generic Proof Dependencies
description: Enables multi-claim generic proofs with bounded recursive aggregation
author: Marc Harvey-Hill (@Marchhill)
status: Draft
type: Standards Track
category: Core
created: 2026-11-13
requires: 7805, 8141, 8288
---

## Abstract

This EIP enables generic leanSTARK dependencies in [EIP-8288](./eip-8288.md) and lets one leaf proof establish independent claims for multiple transactions. Transactions use the same dependency scheme whether proved individually or in a batch, and follow ordinary public-mempool and inclusion-list rules. Recursive aggregation can retain any verified subset without changing transaction signatures. The EIP defines verifier resource bounds, a block dependency limit and provisional charges for shared validation costs.

## Motivation

Generic proofs let accounts authenticate claims under a chosen verification key instead of executing costly verifiers on chain. Proving many claims in one leaf amortizes proof overhead, transmission and recursive verification. Each transaction should commit to its own claim before the batch is formed, without depending on other members remaining includable.

An application supporting future post-quantum passkeys can collect assertions through its API, fund proving, and submit the users' transactions in an ordinary recursive wrapper. Each user keeps an [EIP-8141](./eip-8141.md) transaction with its own nonce, receipt and payer. The application can sponsor transaction gas through payer frames. A sender can instead obtain a singleton proof from another prover without changing the signed transaction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This EIP enables EIP-8288's reserved `LEANSTARK_SCHEME`, defines its singleton and batch statements, and replaces the dependency digest. Activation requires a new `AGGREGATED_VK`; other EIP-8288 rules apply unless modified below.

### Constants

| Name | Value |
| --- | --- |
| `LEANSTARK_SCHEME` | `0x11` (enabled) |
| `MAX_CLAIMS_PER_BATCH_LEAF` | `256` (provisional) |
| `MAX_DEPS_PER_BLOCK` | `16384` (provisional) |
| `MAX_INNER_PROOFS_PER_STEP` | `16` (provisional) |
| `BATCH_HASH` | Keccak-256 (provisional) |

The provisional resource and gas parameters MUST be finalized through the activation requirements below.

### Provisional changes to EIP-8288

The dependency digest and pricing below are included provisionally here and intended to move into EIP-8288 once benchmarks settle the parameters.

#### Dependency pricing

| Name | Value |
| --- | --- |
| `LEANSPHINCS_VERIFICATION_GAS` | `3000` (provisional) |
| `LEANSTARK_VERIFICATION_GAS` | `30000` (provisional) |
| `RECURSIVE_PROOF_SHARE_GAS` | `2700` (provisional) |

Use these verification charges in dependency frames and replace EIP-8288's intrinsic proof-share multiplier with `RECURSIVE_PROOF_SHARE_GAS`. Charge each declaration before deduplication, independently of how its proof was produced. Other transaction costs and EIP-8141 gas accounting apply normally.

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

Allow `LEANSTARK_SCHEME` alongside `LEANSPHINCS_SCHEME` in dependency verification frames. For a generic dependency, `data_hash` is the individual claim and `verification_key_hash` identifies its leaf verifier. EIP-8288's zero substitution and reserved zero padding apply. Neither the batch membership nor the prover's identity appears in the transaction.

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

A block is invalid if `len(dependencies(block)) > MAX_DEPS_PER_BLOCK`. Count distinct resolved triples across both schemes. The limit is independent of the block gas limit; changing it requires a fork with a matching `AGGREGATED_VK`.

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

### Recursive aggregation

In addition to direct dependencies and recursive proofs, the aggregation circuit accepts batch leaves `(claims, verification_key_hash, proof)`. Each verified leaf establishes `(LEANSTARK_SCHEME, claim, verification_key_hash)` for every claim in its list. Union these dependencies with those established by the other verified inputs, then apply EIP-8288's deduplication and discard rules. Outputs may retain any subset; neither discards nor overlapping inputs can establish a claim under a different key or restore a claim absent from all verified inputs.

A step is one execution of the aggregation circuit producing one recursive proof. It MUST support any combination of up to `MAX_INNER_PROOFS_PER_STEP` generic leaves and recursive proofs within the other resource bounds, and reject larger counts. Each direct singleton or batch leaf counts once, including direct proofs across folded mode 0 wrappers and discarded or redundant inputs; proofs deeper in the tree do not count. Apply all resource bounds before discards. Recursion may combine more claims and proofs than these per-step and per-leaf bounds.

Recursive proofs retain EIP-8288's statement `(get_deps_hash(deps), AGGREGATED_VK)` in wrappers, inclusion lists, blocks and recursive inputs. The block's `block_deps_hash` is `get_deps_hash(dependencies(block))`; empty dependency sets retain EIP-8288's empty-proof rule.

### Mempool and inclusion lists

A multi-claim leaf is folded into a mode 1 wrapper before public propagation. The wrapper covers exactly its listed transactions' dependencies; surplus leaf claims are discarded during aggregation. `MAX_LEANSTARK_DEPS_PER_WRAPPER` applies to mode 0 only; mode 1 generic dependency lists are bounded by the aggregation circuit's output capacity. Transaction validity and pool admission are evaluated individually. Omitting a member does not require new signatures or a new leaf proof, although the covering aggregate must be updated.

A dependency-bearing inclusion-list transaction imposes an obligation only when the list supplies a valid recursive proof covering all its dependencies under the block's fork. Missing or invalid coverage does not remove dependency-free entries' obligations. Builders reuse these covering proofs as recursive inputs; no original witnesses or new leaf proofs are required.

An otherwise applicable inclusion-list transaction `T` may be omitted for dependency capacity only if `len(set(dependencies(block)) | set(dependencies(T))) > MAX_DEPS_PER_BLOCK`. Transactions adding no distinct dependencies cannot be excused on this ground. Local proving capacity MUST NOT excuse an otherwise required inclusion.

### Fork transition

Proof-validation caches MUST distinguish verifier keys and public statements, including `AGGREGATED_VK` for recursive proofs. When the applicable mempool fork changes, wrappers validated only under previous rules MUST NOT be admitted, served, announced or used to suppress announcements. Direct witnesses MUST be validated under the new rules before reuse: a generic proof of the bare `(data_hash,)` statement cannot satisfy the claim-digest statement. Recursive coverage must be rebuilt under the new key for admission, inclusion lists and blocks.

### Activation requirements

Before activation:

- Pin the complete proof-system specification and soundness analysis covering adversarial keys, canonical key/proof encodings, resource bounds, `DEPS_HASH`, `BATCH_HASH`, `AGGREGATED_VK` and conformance vectors.
- Calibrate verification charges against native checks on node-class hardware and the proof share against shared proof verification and relay costs. Include invalid inputs, transaction gas limits and validator execution/proof-verification budgets.
- Demonstrate permitted aggregation steps, output capacity and inclusion-list construction and integration within their timing and memory budgets, including maximum committee load, latest permitted arrivals, overlaps and pruning. Publish hardware, worker counts, gas limits, schedules and safety margins before finalizing the bounds.

Use the [benchmark methodology](../assets/eip-draft_batched_dependency_pricing/benchmarks.md). Per-step bounds and dependency counts alone do not establish latency; modelled parallel speedups do not satisfy the timing requirements.

## Rationale

### Batch statements

Single-claim proofs repeat proof overhead and recursive verification. A batch leaf amortizes that work while preserving each transaction's independent claim. Users sign before the batch is formed; accounts pin the verifier key rather than a batch root. Recursion can prune and combine coverage without the original witnesses.

User verifiers compute the claim digest in-circuit, so fixing `BATCH_HASH` independently of `DEPS_HASH` preserves pinned keys when the aggregation hash changes. The generic interface also supports signature schemes with their own aggregation, provided each output claim is independently valid.

### Verifier identity and capacity

Sound evaluation openings authenticate the committed program without hashing its entire table inside recursion. Binding must hold for adversarial keys; the pinned proof-system specification defines the construction. The block dependency limit bounds output size independently of gas-limit changes. Per-leaf and per-step limits bound individual operations, not total proving time or redundant input histories.

### Pricing and prover incentives

Verification charges price public validation work; the proof share is an allowance for shared block-proof verification and relay costs. Transaction data uses normal gas accounting. These charges do not price worst-case leaf proving or guarantee that every gas-admissible selection can be proved within a slot. Builders select optional work according to their capacity and fees; inclusion-list obligations instead arrive with covering proofs and require a measured integration budget.

Batching reduces prover work and proof traffic without changing the per-declaration charge. Priority fees reward the block producer, not an independent leaf prover; applications may fund proving or arrange service fees off chain. Inclusion lists do not guarantee proof production for an unproven claim. A sender needs prover access for either a singleton or a batch, while accounts may retain a native-key or in-EVM fallback. Filling a batch trades latency for amortization.

## Backwards Compatibility

Activation enables the reserved `LEANSTARK_SCHEME` and replaces its proposed bare `(data_hash,)` statement with `(get_claim_hash(data_hash),)`. Verifiers written for the former must adopt the new statement. The scheme-bearing dependency digest requires a new aggregation key.

Frame and wrapper encodings remain unchanged. Transactions must budget the activating fork's gas charges. Mode 0 carries singleton witnesses; mode 1 carries recursive coverage for individual or batched claims, with public-mempool and inclusion-list eligibility independent of batch membership.

## Test Cases

| Case | Expected result |
| --- | --- |
| Nonzero scheme padding or an unsupported scheme | Reject |
| One-claim digest | `get_batch_hash([claim]) == get_claim_hash(claim)`; reject a proof of the bare claim |
| Same claim and key under different schemes | Distinct canonical 96-byte encodings and dependency digests |
| Wrong key, key-hash tag or commitment width | Reject |
| Program substitution, unauthenticated dimensions or parameter overrides | Reject |
| Opening for another commitment, point or value; unbound transcript | Reject, including inconsistent key-bound evaluations even if the key hash is recomputed |
| Each resource bound and one above it | Accept the bound; reject overflow even for discarded inputs; count support code, padding and authentication data |
| Full step at finalized arity and maximum resource bounds | Fits outer proof bounds; reject oversized steps even within the arity limit |
| `MAX_INNER_PROOFS_PER_STEP` immediate generic/recursive inputs, then one more | Accept then reject; include direct inputs across wrappers and discarded or redundant proofs |
| `MAX_DEPS_PER_BLOCK` distinct block dependencies, then one more | Accept at the limit if otherwise valid; reject one above even if gas fits |
| Repeated triples or a changed gas limit | Count distinct triples once; the block dependency limit does not change |
| 65,535- and 65,536-entry intermediate unions pruned to a supported output | Preserve lengths and retained entries without truncation; reject out-of-range lengths before narrowing |
| Change `DEPS_HASH` | Does not change `get_claim_hash` or the user verification key |
| Empty, repeated, unsorted or 257-claim leaf | Reject before hashing or verification |
| 256-claim leaf folded into a wrapper covering 64 claims, then pruned to one | Retain exactly the selected dependencies with the same leaf and transaction signatures |
| Overlapping leaves and recursive inputs under the same or different keys | Deduplicate identical triples; keep different keys distinct; reject unsupported output claims |
| A member expires or fails pool admission | Other members remain independently admissible; reaggregation can omit its exclusive dependencies |
| Multiple generic claims in mode 0 versus mode 1 | Enforce the direct-wrapper limit in mode 0; accept valid recursive coverage within output bounds in mode 1 |
| Batched transaction in a public wrapper or inclusion list | Apply ordinary eligibility and coverage rules, with no batch-membership condition |
| Inclusion list with missing or invalid covering proof | No dependency-bearing obligation without coverage; dependency-free entries retain theirs |
| An inclusion-list transaction adds dependencies beyond the block limit | Excuse that entry for capacity; shared or empty dependencies do not excuse omission |
| One native or generic declaration | 5,700 or 32,700 gas respectively, excluding other transaction costs |
| Duplicate declarations or 64 separately signed claims proved in one leaf | Charge every declaration; generic charges are 64 times 32,700 = 2,092,800 gas |
| Rebatch or obtain a singleton proof for the same claim and key | The signed transaction and its charges do not change |
| Activation with old verdicts cached | Revalidate direct witnesses and rebuild recursive coverage under the new key |

## Security Considerations

The gas charges are provisional pending native-verifier and shared proof-cost measurements. Fee floors do not prevent unpaid mempool verification, and repeated invalid or redundant inputs can consume work without inclusion. Clients should bound local verification, storage and reaggregation work.

A small step arity does not bound the number of steps or guarantee a timely block proof. Inclusion lists constrain the builder's choice, so their covering-proof availability and worst-case integration path must meet the fork's deadlines even when optional work is declined. Builder-local slowness is not an omission excuse. The final aggregate must cover every included dependency, irrespective of the proving schedule.

Lower protocol charges do not remove prover-availability or builder-concentration risks. Reusable public proofs and access to independent provers can reduce dependence on a particular builder, but inclusion lists protect only transactions that already have valid coverage.

Accounts remain responsible for verifier semantics and independent claim validity. Authorization claims must bind the signer, message and required policy. A batcher cannot forge a claim under a sound selected verifier, but can withhold proving or observe transactions before propagation. Changing batcher requires no change to a transaction whose claim and verifier key are unchanged.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
