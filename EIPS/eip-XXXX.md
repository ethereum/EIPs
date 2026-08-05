---
title: VOPS Profiles for FOCIL Eligibility
description: Describes VOPS profiles that a future FOCIL extension could use to determine which transactions receive inclusion enforcement.
author: Thomas Thiery (@soispoke)
discussions-to: TBD
status: Draft
type: Informational
created: 2026-08-05
requires: 1559, 2718, 2930, 3607, 4844, 7702, 7732, 7805, 7928, 8141, 8250, 8272
---

## Abstract

This EIP describes two validity-only partial statelessness (VOPS) profiles for fork-choice enforced inclusion list (FOCIL) eligibility. Profile 1 covers regular transactions, every non-frame type without blobs, and keeps [EIP-7805](./eip-7805.md)'s end-of-payload omission check. Profile 2 covers [EIP-8141](./eip-8141.md) frame transactions whose validation stays within a fixed account abstraction VOPS (AA-VOPS) state surface, including privacy transactions based on keyed nonces and recent roots. Profile 2 omission is checked at a builder-claimed transaction index in the payload, so it protects a transaction only if the transaction remains valid at every index the builder could claim. Transactions outside both profiles may still appear in inclusion lists (ILs), but FOCIL does not enforce them. Public mempool admission and FOCIL eligibility remain separate. This EIP is Informational; consensus enforcement belongs in an extension to EIP-7805.

## Motivation

FOCIL ([EIP-7805](./eip-7805.md)) requires builders to include IL transactions unless a missing transaction is invalid when appended to the payload or the payload does not have enough remaining gas to append it. That rule is cheap for regular transactions because the omission check depends mainly on gas, nonce, and balance. Frame transactions have programmable validation, so validity may also depend on keyed nonces, payer state, recent roots, or bounded account storage.

This EIP defines which transactions remain cheap enough to enforce. Profile 1 keeps EIP-7805's end-of-payload rule. Profile 2 evaluates an omitted frame transaction at a builder-claimed index against a fixed validation state surface. Because the builder chooses the index, Profile 2 is weaker when another transaction can move a validation dependency within the block; [Security Considerations](#security-considerations) defines that boundary.

FOCIL eligibility is not mempool policy. An includer may receive an eligible transaction through the public mempool, a custom mempool, or direct submission. The submission path affects whether a transaction reaches an IL, not whether its omission is enforceable.

## Specification

This EIP is Informational. It describes a nonbinding reference model for the eligibility boundary, state surface, and budget. A future Standards Track extension to [EIP-7805](./eip-7805.md) must restate every binding rule, constant, encoding, and test vector; see [EIP-7805 extension requirements](#eip-7805-extension-requirements). Must, should, and may are used in their ordinary English sense.

### VOPS profiles

This EIP defines two VOPS profiles. A transaction that satisfies neither may still be included by builders, but FOCIL does not enforce it and omission is excused. A transaction is eligible if it fits a profile. An eligible IL transaction is enforceable when the EIP-7805 extension makes unjustified omission grounds for attesters to withhold their vote. For Profile 2, the transaction must also fit the per-IL VERIFY budget (see [Includers](#includers)).

| Profile | Purpose | Transaction shape | Adds to validation state surface |
|---|---|---|---|
| 1: Base VOPS | regular transactions | legacy, [EIP-2930](./eip-2930.md), [EIP-1559](./eip-1559.md), and [EIP-7702](./eip-7702.md) transactions without blobs | none |
| 2: FOCIL AA-VOPS | frame transaction validation | [EIP-8141](./eip-8141.md) frame transactions without blobs | code and `codeHash`; first `AA_VOPS_SLOT_COUNT` storage slots; keyed nonces; recent roots |

The base VOPS proposal on ethresear.ch keeps `(address, nonce, balance, codeFlag)` for every account. Profile 2 defines a FOCIL-specific AA-VOPS extension: VOPS nodes also keep the code corpus, the first `AA_VOPS_SLOT_COUNT` storage slots of every account, keyed nonce state, and recent root state. Code is authenticated by `codeHash`; delegated accounts also require the delegated target's code. The surface has a fixed shape, not a fixed total size.

Shape decides the candidate profile: non-frame transactions with no blobs, including all [EIP-7702](./eip-7702.md) transactions, are Profile 1 candidates; [EIP-8141](./eip-8141.md) frame transactions with empty `blob_versioned_hashes` are Profile 2 candidates. Candidates that fail their profile's conditions, and any transaction carrying blobs, fall outside FOCIL enforcement.

Includers should simulate a frame transaction's validation prefix before IL inclusion. This is local admission policy; enforceability is decided by the profile and by attester replay against reconstructed state.

For a given transaction, validation may read VOPS account fields and the first `AA_VOPS_SLOT_COUNT` slots of `sender` and `payer`, [EIP-8250](./eip-8250.md) keyed nonce state, and [EIP-8272](./eip-8272.md) recent root entries. Ordinary privacy contract storage, nullifier mappings, commitment trees, and arbitrary external storage are outside the profile. Witness-based external reads are deferred; see [Reserved for future work](#reserved-for-future-work).

### Fee validity

For both profiles, `fee_valid(tx, block)` requires `max_fee_per_gas >= block.base_fee_per_gas` and `max_priority_fee_per_gas <= max_fee_per_gas`. For legacy and [EIP-2930](./eip-2930.md) transactions, `gas_price` stands in for both fields.

### Constants

| Name | Value |
|---|---:|
| `MAX_VERIFY_GAS_PER_IL` | `2**20` |
| `MAX_VERIFY_GAS_PER_TX` | `2**20` |
| `AA_VOPS_SLOT_COUNT` | Chosen by the enforcing Standards Track EIP; candidate range 2 to 4, pending benchmarks |

`AA_VOPS_SLOT_COUNT` is a parameter of this reference model, not a fixed consensus constant. No implementation can classify Profile 2 for enforcement until the enforcing Standards Track EIP selects a value.

For Profile 2, VERIFY budget cost is static: the signature verification gas counted by [EIP-8141](./eip-8141.md) plus the declared gas limits of every frame in the validation prefix. An expiry verifier frame is ignored only when matching the four allowed prefix shapes; its gas limit still counts. Whether validation succeeds is decided by replay, not by budget fit.

Both caps are `2**20`, about 1.05M gas. One heavy transaction can therefore consume a whole IL's budget. Across [EIP-7805](./eip-7805.md)'s 16 includers, the maximum metered Profile 2 budget is about 16.8M gas per slot. This is not a bound on total attester work: transaction decoding, state reconstruction, code loading, and pre-execution keyed nonce and recent root checks sit outside it. The cap is deliberately higher than [EIP-8141](./eip-8141.md)'s `MAX_VERIFY_GAS = 100_000` public mempool cap because FOCIL eligibility and public mempool admission are separate policies.

### Profile 1: Base VOPS

Base VOPS covers regular transactions, including [EIP-7702](./eip-7702.md) transactions. Eligibility checking classifies sender code but does not execute it.

A transaction is Profile 1 if all of the following hold:

1. It is a structurally valid legacy, [EIP-2930](./eip-2930.md), [EIP-1559](./eip-1559.md), or [EIP-7702](./eip-7702.md) transaction that is not a frame transaction and does not carry blobs.
2. Its signature validates against the recovered sender.
3. `tx.chain_id`, when present, matches the chain.

Omission of a Profile 1 transaction is justified if it does not fit the remaining payload gas, or if `sender.nonce` or `sender.balance` makes it invalid at the end of the payload under [EIP-7805](./eip-7805.md).

Fee validity is defined by `fee_valid(tx, block)`. Sender validity requires the sender to satisfy [EIP-3607](./eip-3607.md), with [EIP-7702](./eip-7702.md) delegation indicators treated as the valid delegated-EOA case. Omission is justified if either check fails at the end of the payload.

Profile 1 needs the sender's nonce, balance, and code classification. Externally owned accounts (EOAs) with empty code and valid delegated EOAs can originate transactions; contract accounts cannot. Profile 1 does not execute code or consume the IL VERIFY budget.

### Profile 2: FOCIL AA-VOPS

Profile 2 covers [EIP-8141](./eip-8141.md) frame transactions whose validation stays within the FOCIL AA-VOPS surface. VOPS nodes hold code reached during validation, authenticated by `codeHash`, so transactions can use shared verifier contracts without opening arbitrary storage. The motivating example is a privacy spend that checks recent roots and consumes each nullifier as a single-use [EIP-8250](./eip-8250.md) keyed nonce with `nonce_seq == 0`.

A transaction is a Profile 2 candidate if all of the following are true from the transaction alone:

1. It is a statically valid EIP-8141 frame transaction, all protocol signatures are valid, its `chain_id` matches the chain, `max_priority_fee_per_gas <= max_fee_per_gas`, and `blob_versioned_hashes` is empty.
2. Ignoring the optional EIP-8141 expiry verifier frame for shape matching, its modes, flags, and targets match one of four EIP-8141 prefixes: `self_verify`, `deploy | self_verify`, `only_verify | pay`, or `deploy | only_verify | pay`. The expiry verifier frame must be unique and first, as required by EIP-8141.
3. Its VERIFY budget cost is no more than `MAX_VERIFY_GAS_PER_TX`.

A candidate is Profile 2 eligible at an evaluation state if all of the following also hold:

1. Its [EIP-8250](./eip-8250.md) keyed nonce checks and [EIP-8272](./eip-8272.md) recent root checks pass.
2. Its validation prefix follows the EIP-8141 validation trace rules as modified below and reads state only from the surface below.
3. If present, the first non-expiry frame is a valid deploy frame. It installs code or an [EIP-7702](./eip-7702.md) delegation indicator at `sender`, and all storage it touches stays within the Profile 2 surface.
4. The prefix executes successfully and sets `payer` through `APPROVE_PAYMENT` (`0x1`) or `APPROVE_EXECUTION_AND_PAYMENT` (`0x3`). `payer` is `sender` for the `self_verify` shapes and the `pay` frame's EIP-8141 `resolved_target` otherwise. A null `pay` target resolves to `sender`.

The Profile 2 validation surface is:

- VOPS account fields (`address`, `nonce`, `balance`) for `sender` and `payer`;
- storage slots `0` through `AA_VOPS_SLOT_COUNT - 1` of `sender` and `payer`;
- the recent root references in the signed envelope and the matching `RECENT_ROOT_ADDRESS` entries checked by EIP-8272;
- keyed nonce state at `(tx.sender, nonce_key)` for every nonzero key in `tx.nonce_keys`;
- code and `codeHash` for every account reached during validation, including delegated target code.

EIP-8141 restricts public mempool storage reads to `sender`. Profile 2 also permits reads from the same low-slot range of `payer`, so such transactions may need a custom mempool or direct submission. The EIP-8141 canonical paymaster exception does not widen this storage surface. A mapping value at a `keccak256`-derived slot is outside Profile 2.

### Transactions outside FOCIL enforcement

Transactions that are neither Profile 1 nor Profile 2 are not eligible for FOCIL enforcement. This set includes:

- Any transaction with non-empty `blob_versioned_hashes`, including [EIP-4844](./eip-4844.md) blob transactions and frame transactions carrying blobs: blob gas has its own target and maximum, and this EIP defines no omission check over that second budget.
- Frame transactions whose prefix reads storage outside the Profile 2 surface.
- Frame transactions whose prefix does not match an admitted shape, including `VERIFY`-mode frames beyond what the shapes allow. The admitted `only_verify | pay` shapes themselves contain two `VERIFY`-mode frames; the shape decides, not the frame count.
- Frame transactions whose prefix violates [EIP-8141](./eip-8141.md) validation trace rules, regardless of submission path.
- Frame transactions whose VERIFY budget cost exceeds `MAX_VERIFY_GAS_PER_TX`, or whose validation cannot be reproduced deterministically by attesters against reconstructed VOPS state.

### Reserved for future work

A future Profile 3 could admit declared external storage reads backed by a witness or validity proof. It would need an envelope commitment, byte limits, anchor and freshness rules, retained [EIP-7928](./eip-7928.md) write history, and an omission proof. External state writable by others also lets a builder stale a witness before the claimed index. Until those rules are specified, external storage reads are not eligible.

### Mempool admission and FOCIL eligibility

Public mempool admission is local node policy: whether a node keeps and gossips a transaction. FOCIL eligibility decides whether an IL transaction qualifies for enforcement. The sets differ in both directions, and public mempool admission is not a prerequisite for eligibility.

### Roles and duties

Includers include eligible transactions in ILs, builders include them in blocks or, for Profile 2 omissions, provide a claimed insertion index, and attesters check whether omission is justified.

#### Includers

An includer may source Profile 1 or Profile 2 transactions from the public mempool, a custom mempool, or direct submission. Transaction identity for block inclusion is based on the exact [EIP-2718](./eip-2718.md) envelope bytes across all ILs from non-equivocating includers. Profile 1 transactions do not use the IL VERIFY budget.

Profile 2 budget fill is static and evaluated per IL occurrence before deduplication. Starting with `MAX_VERIFY_GAS_PER_IL`, process occurrences in IL order. First perform only the decoding and structural shape checks needed to compute the VERIFY budget cost. If the cost cannot be computed, exceeds `MAX_VERIFY_GAS_PER_TX`, or does not fit the remaining budget, ignore the occurrence and consume nothing. Otherwise, deduct the cost before verifying any cryptographic signature. The occurrence is admitted only if it then passes every Profile 2 candidate check. A failed candidate keeps the budget debit but is not admitted. This bounds signature-verification work from structurally valid transactions with invalid signatures. Stateful eligibility is not part of fill because it depends on the evaluation index. A Profile 2 transaction is enforceable only if it is eligible at that index and at least one occurrence was admitted by this fill rule.

#### Builders

For each omitted Profile 2 candidate, a builder may commit an index in `[0, len(block.transactions)]`, where `0` is before the first block transaction. A missing, malformed, or out-of-range index defaults to `len(block.transactions)`, the end of the payload. This avoids making private receipt of an IL transaction part of consensus.

#### Attesters

For Profile 1, attesters apply the [EIP-7805](./eip-7805.md) end-of-payload check plus the sender and fee validity conditions from [Profile 1](#profile-1-base-vops).

For Profile 2, attesters use the committed index or the default end-of-payload index.

Attesters start from the parent VOPS state, apply pre-execution system updates, and apply the [EIP-7928](./eip-7928.md) block-level access list (BAL) changes for transactions before the evaluation index. This reconstructs balances, nonces, storage, code, delegation indicators, keyed nonces, and recent roots. Eligibility replay uses full EIP-8141 and EIP-8250 `APPROVE` semantics, including maximum-cost collection. The gas remaining is the block gas limit minus cumulative gas used before the index. Omission is unjustified if and only if all of the following hold:

1. the transaction is a Profile 2 candidate, satisfies `fee_valid(tx, block)`, and has an occurrence admitted by the static budget fill;
2. the transaction is Profile 2 eligible against that state, with `current_slot` equal to the block's consensus slot;
3. the EIP-8141 transaction gas limit fits the gas remaining.

Local data availability is not an omission excuse. An attester that lacks a required state value or a code body matching the reconstructed `codeHash` must synchronize or obtain authenticated data before evaluating the omission.

### EIP-7805 extension requirements

This EIP defines the eligibility profiles, not the consensus integration. The index mechanism extends [EIP-7805](./eip-7805.md)'s builder and attester duties and should be specified there. Profile 2 enforcement can activate only after EIP-8141, EIP-8250, and EIP-8272 are live.

The extension must encode claimed indices, define their lookup and deduplication rules, and commit the result in or alongside the block. Its encoding must realize the default behavior above for missing, malformed, and out-of-range indices. Out-of-band claims could differ across attesters. It must also expose a canonical diff validated by consensus for every Profile 2 state update, including keyed nonces and recent roots. EIP-7928 BAL correctness is currently established by payload execution. If a required update is absent from the BAL, an equivalent diff is an activation prerequisite.

The framework assumes attesters can execute the payload before checking omissions. Under enshrined proposer-builder separation (ePBS) ([EIP-7732](./eip-7732.md)), payloads are revealed after beacon attestations and the payload timeliness committee does not validate execution. The extension must therefore move omission checks to a post-reveal duty or leave Profile 2 disabled under ePBS.

The extension must also define:

- transaction identity and deduplication based on the exact envelope bytes;
- the static and stateful Profile 2 checks as named predicates;
- an executable access matrix for held data, permitted reads and writes, deployment, delegation, and protocol-managed state;
- state reconstruction at an index, including index-zero system updates;
- isolated replay semantics, including fork rules, timestamp, base fee, `current_slot`, warm-state initialization, and the source of cumulative gas used at each index;
- a bound on the number and total bytes of distinct code bodies loaded during a validation prefix, accounted within the replay budget;
- the total procedure attesters run to decide whether an omission is justified;
- final values for `AA_VOPS_SLOT_COUNT` and the VERIFY caps, benchmarked against the attestation deadline over the full pipeline, reconstruction and replay included;
- conformance test vectors.

A single composed payload encoding and signature hash for EIP-8141, EIP-8250, and EIP-8272 must also be defined before activation. Once zkEVM proofs are mandatory, builder omission proofs could replace attester replay; that belongs in a later revision of the enforcement rules.

## Rationale

A single eligibility boundary prevents nodes from agreeing on an IL while disagreeing on which omissions are enforceable. Separating mempool admission from eligibility lets the public mempool stay conservative while custom paths carry transactions that still fit the FOCIL budget.

Profile 1 keeps the end-of-payload rule because regular transaction validity can be checked there. Frame validation may depend on state that changed earlier in the payload, so Profile 2 checks the state at a claimed insertion index. This removes an earlier iterative append loop that could require quadratic builder work. The tradeoff is the weaker guarantee described below.

Base VOPS globally holds the account fields needed for regular transaction validity. Some AA-VOPS designs instead use account-local caches and transaction witnesses. Profile 2 chooses a different point for FOCIL: it globally holds a fixed validation surface and the code corpus so any includer can classify any candidate without first obtaining a witness. A read outside the surface makes the transaction ineligible. This trades more local storage for witness-free FOCIL eligibility.

## Backwards Compatibility

This Informational EIP changes no consensus rules by itself. Enforcing Profile 2 requires a fork that updates EIP-7805 and activates the required frame transaction, keyed nonce, recent root, and state-diff support.

## Security Considerations

Profile 2 trades guarantee strength for replay cost. Because the builder chooses the index, a transaction is protected only if it is valid at every claimable index. This EIP accepts that property and does not treat the index as evidence that insertion was attempted.

For position-stable transactions, this is equivalent to EIP-7805's end-of-payload rule. A dependency is position-stable if it is constant within the payload or changes monotonically, so invalidity at any index persists to the end. Single-use keyed nonces and recent roots have this property. Validation slots qualify only if no other authorized transaction can change them, and payment capacity qualifies only if it is reserved for the transaction. Shared payers without such a reservation receive the weaker guarantee: another sponsored transaction may reduce the payer balance before the claimed index.

The maximum metered Profile 2 budget is about 16.8M gas per slot, but total attester work is higher. In particular, EVM gas does not directly bound the bytes loaded when validation touches many distinct maximum-size code bodies. Omitted transactions pay no fees, so the full reconstruction and replay path must be benchmarked against the attestation deadline, and code-body count and byte limits must be fixed, before the caps are adopted by a Standards Track EIP.

Static budget fill lets all nodes compute the same budget from the IL alone, but it is griefable. A transaction can consume an IL's full budget while valid, then be invalidated by a cheaper conflicting transaction included first. Simulation does not prevent this case. The EIP-7805 extension must either accept this limit, reduce the per-transaction share, or change budget fill and deduplication.

Replay is sound only if attesters reconstruct the same state, including keyed nonce and recent root writes, code and delegation changes, balances, nonces, and low slots. A BAL commitment binds the published bytes but does not prove that they are correct; until execution proofs provide that evidence, attesters must validate the payload before using the BAL for omission checks.

Privacy protocols remain responsible for binding their proof to the transaction. For single-use nullifiers, validation must authenticate `sender`, the full `nonce_keys` set or its canonical hash, `nonce_seq == 0`, the exact recent root references, the chain and contract domain, and the authorized execution and payment intent.

Transaction identity is the exact EIP-2718 envelope bytes for IL presence, deduplication, budget fill, and omission checks. A byte-distinct variant does not satisfy the listed transaction. Its actual effects are part of the reconstructed state and justify omission only if replay shows that the listed transaction became invalid.

The globally held surface is bounded by field type, not by total size. Code, keyed nonce entries, recent root sources, and low slots can all grow. Parameter selection must account for storage growth as well as replay time.

Enforcement through custom mempools or direct submission depends on committee visibility: if no includer receives a transaction, FOCIL cannot enforce it. Direct endpoints also create denial-of-service, private access market, and metadata risks, so implementations need bounded admission policies.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
