---
title: Builder Deposit Contract
description: Predeploy BLS-verifying builder deposit and top-up contracts as EIP-7685 requests, using EIP-2537 precompiles, for EIP-7732 builders
author: Cayman (@wemeetagain)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2026-05-22
requires: 2537, 7685, 7732
---

## Abstract

Predeploy two [EIP-7685](./eip-7685.md) request contracts for the [EIP-7732](./eip-7732.md) builder population, modelled on the request bus that [EIP-7002](./eip-7002.md) (withdrawals) and [EIP-7251](./eip-7251.md) (consolidations) use:

- a builder deposit contract whose `deposit(...)` verifies a BLS proof-of-possession over the `pubkey` and `withdrawal_credentials` using the [EIP-2537](./eip-2537.md) precompiles, then appends a deposit request to its queue; and
- a builder top-up contract whose `top_up(...)` appends an additional-stake request for an existing builder without on-chain signature verification.

Each contract maintains an in-state request queue drained by an end-of-block `SYSTEM_ADDRESS` system call; the dequeued records become the contract's [EIP-7685](./eip-7685.md) `request_data`, committed in the block `requests_hash`. Neither contract emits logs. Both are independent of the existing validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa`.

## Motivation

The deployed validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa` does not verify BLS signatures on chain. The consensus layer instead verifies the proof-of-possession of a `pubkey` on its **first** appearance — subsequent top-ups to the same `pubkey` are accepted without any further signature check, and in practice top-ups are submitted with all-zero signatures. Two consequences follow:

1. The existing contract is an immutable two-mode API: a "first deposit" must carry a valid signature, while every "top-up" intentionally omits one. Replacing its runtime with a signature-checking variant would break the top-up path and reject all-zero signatures that are in use today.
2. The signature-verification cost for new validators is borne entirely by the consensus layer. An adversary that can submit arbitrarily many invalid deposits forces every beacon node to pay the verification cost for each one. Mainnet absorbs this today only because the 32-ETH minimum validator deposit makes the per-attempt cost expensive.

[EIP-7732](./eip-7732.md) introduces builders as a separate consensus-layer class with a substantially lower deposit threshold (as little as 1 ETH per builder). Naively reusing the existing deposit contract for builders would amplify the consensus-side DoS surface in proportion to how much cheaper a builder deposit is, while preserving the existing top-up loophole.

This EIP introduces a **separate** deposit contract dedicated to the EIP-7732 builder population. It:

- Verifies the BLS proof-of-possession on chain using the [EIP-2537](./eip-2537.md) precompiles, so the consensus layer can skip the per-deposit pairing cost; and
- Gas-meters the verification, so the cost of presenting a candidate (valid or invalid) is charged to the depositor's transaction. DoS resistance falls out of the existing gas-pricing rules instead of needing dedicated consensus-side throttling.

The existing validator deposit contract is untouched, preserving its first-deposit-plus-unsigned-top-up semantics for the existing 32-ETH validator population.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

All address and request-type values below are placeholders pending allocation in consensus-specs and the execution-layer client configuration; the `0x03`/`0x04` request types in particular MUST be distinct from the existing deposit (`0x00`), withdrawal (`0x01`), and consolidation (`0x02`) types.

| Name | Value | Comment |
| --- | --- | --- |
| `BUILDER_DEPOSIT_CONTRACT_ADDRESS` | `0x0000000000000000000000000000000000007732` | Predeploy address of the builder deposit contract (placeholder) |
| `BUILDER_TOPUP_CONTRACT_ADDRESS` | `0x0000000000000000000000000000000000007733` | Predeploy address of the builder top-up contract (placeholder) |
| `BUILDER_DEPOSIT_REQUEST_TYPE` | `0x03` | [EIP-7685](./eip-7685.md) request-type byte for builder deposits (placeholder) |
| `BUILDER_TOPUP_REQUEST_TYPE` | `0x04` | [EIP-7685](./eip-7685.md) request-type byte for builder top-ups (placeholder) |
| `SYSTEM_ADDRESS` | `0xfffffffffffffffffffffffffffffffffffffffe` | Address that invokes the end-of-block system call (as in [EIP-7002](./eip-7002.md)) |
| `MAX_REQUESTS_PER_BLOCK` | `16` | Maximum records each contract drains into one block |
| `TARGET_REQUESTS_PER_BLOCK` | `2` | Per-block request count above which the fee rises |
| `MIN_REQUEST_FEE` | `1` | Minimum request fee, in wei |
| `REQUEST_FEE_UPDATE_FRACTION` | `17` | Controls the fee's rate of change |
| `DOMAIN_BUILDER_DEPOSIT` | `0x0b000000f5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a9` | Signing domain for builder deposit messages. The `0x0b000000` domain type is a placeholder pending consensus-specs allocation; it MUST differ from the validator `DOMAIN_DEPOSIT` (`0x03000000…`) so signatures are not interchangeable between the two contracts |
| `BLS12_G2ADD` | `0x0d` | [EIP-2537](./eip-2537.md) precompile address |
| `BLS12_PAIRING_CHECK` | `0x0f` | [EIP-2537](./eip-2537.md) precompile address |
| `BLS12_MAP_FP2_TO_G2` | `0x11` | [EIP-2537](./eip-2537.md) precompile address |
| `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` | _see [Reference Implementation](#reference-implementation)_ | Runtime bytecode of the builder deposit contract |
| `BUILDER_TOPUP_CONTRACT_RUNTIME_CODE` | _see [Reference Implementation](#reference-implementation)_ | Runtime bytecode of the builder top-up contract |

### Fork transition

At the start of processing the first block where this EIP is active, before processing transactions, execution clients MUST install each predeploy — `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` at `BUILDER_DEPOSIT_CONTRACT_ADDRESS` and `BUILDER_TOPUP_CONTRACT_RUNTIME_CODE` at `BUILDER_TOPUP_CONTRACT_ADDRESS` — if the account at the respective address is empty (zero `nonce`, empty `code`, empty `storage`, zero `balance`). Each installation MUST set `code` to the runtime code, `nonce = 1`, `balance = 0`, and leave `storage` empty.

If either account is not empty at fork time, clients MUST abort initialisation. This matches the predeploy pattern used by [EIP-2935](./eip-2935.md), [EIP-4788](./eip-4788.md), [EIP-7002](./eip-7002.md), and [EIP-7251](./eip-7251.md).

### Request queue and system call

Both predeploys follow the [EIP-7002](./eip-7002.md) / [EIP-7251](./eip-7251.md) request-bus pattern. Each maintains a FIFO queue of request records in its own storage and an EIP-1559-style `excess` counter. A user-facing entrypoint validates a request, charges the current fee, and appends one record.

A call with empty calldata dispatches on the caller:

- From `SYSTEM_ADDRESS` (the end-of-block system call): the predeploy MUST dequeue up to `MAX_REQUESTS_PER_BLOCK` records (oldest first), return their concatenation as that contract's `request_data`, advance its queue head past the returned records, then update `excess` from the number of requests added in the block (`excess = max(0, excess + count - TARGET_REQUESTS_PER_BLOCK)`) and reset that count. Records beyond the per-block cap remain queued for subsequent blocks.
- From any other caller: the predeploy MUST return the current fee (the fee getter), without modifying state.

The execution layer prepends the contract's request-type byte and includes `request_type ++ request_data` in the block requests list, committed via the `requests_hash` ([EIP-7685](./eip-7685.md)). Neither contract emits logs.

### Request fee

Each request carries a fee, computed exactly as in [EIP-7002](./eip-7002.md):

```
fee = fake_exponential(MIN_REQUEST_FEE, excess, REQUEST_FEE_UPDATE_FRACTION)
```

where `fake_exponential` is the integer approximation of `MIN_REQUEST_FEE · e^(excess / REQUEST_FEE_UPDATE_FRACTION)` used by [EIP-1559](./eip-1559.md). Because `excess` grows whenever a block contains more than `TARGET_REQUESTS_PER_BLOCK` requests and decays otherwise, the fee rises super-linearly under sustained demand and returns to `MIN_REQUEST_FEE` when demand subsides. The fee is charged on top of any staked value (see the entrypoints below) and is left locked in the contract.

Unlike EIP-7002/7251, these predeploys carry no `EXCESS_INHIBITOR`: those contracts are deployed before their activating fork and use the inhibitor to reject requests until the first system call, whereas these are installed at the fork with empty storage (`excess = 0`, the minimum fee), so there are no pre-activation requests to inhibit.

### Verified deposit entrypoint

```
deposit(
    bytes pubkey,                    // 48-byte compressed G1 (X with sign+infinity flags)
    bytes32 withdrawal_credentials,  // 32-byte commitment
    uint64 amount_gwei,              // stake to credit, in gwei (NOT signed)
    bytes signature,                 // 96-byte compressed G2 (X with sign+infinity flags)
    Fp    pubkey_y,                  // affine Y of pubkey, in EIP-2537 encoding
    Fp2   signature_y                // affine Y of signature, in EIP-2537 encoding
) payable
```

`amount_gwei` is the stake to credit. It is an explicit parameter — and is **not** part of the signed message — because `msg.value` must cover both the stake and the dynamic fee, so the credited stake cannot be derived from `msg.value` alone. The signature commits only to `(pubkey, withdrawal_credentials)`; see [Rationale](#rationale) for why the amount is not signed.

`deposit(...)` MUST perform the following, in order, before appending any record:

1. Validate input lengths, and that `amount_gwei * 1 gwei` is at least the minimum stake.
2. Require `msg.value >= amount_gwei * 1 gwei + fee`, where `fee` is the current request fee. Any value beyond `amount_gwei * 1 gwei` is retained by the contract (the fee, plus any overpayment, is not credited to the builder).
3. Reject `pubkey` or `signature` whose infinity flag is set.
4. Verify that the supplied `pubkey_y` and `signature_y` agree with the sign flag of the corresponding compressed encoding (i.e. `sign(pubkey_y)` equals the sign bit of `pubkey`, and likewise for the signature). This binds the point used in the pairing check to the encoding the consensus layer will register; without it the verified point could be the negation of the registered point.
5. Compute the signing root over the 2-field builder message:
   `signing_root = sha256(hash_tree_root(pubkey, withdrawal_credentials) || DOMAIN_BUILDER_DEPOSIT)`.
6. Verify the BLS proof-of-possession via the [EIP-2537](./eip-2537.md) `BLS12_PAIRING_CHECK` precompile, using the supplied affine `Y` coordinates to construct the G1 and G2 points.
7. Revert the entire call if the pairing check fails.

On success, `deposit(...)` MUST append a `BUILDER_DEPOSIT_REQUEST_TYPE` record of `pubkey (48) ++ withdrawal_credentials (32) ++ amount_gwei (8, little-endian)` to its queue. The signature is intentionally absent: it was verified at submission, so the consensus layer trusts the dequeued record without re-pairing.

### Unverified top-up entrypoint

```
top_up(
    bytes pubkey,                    // 48-byte compressed G1 of an existing builder
    uint64 amount_gwei               // stake to add, in gwei
) payable
```

`top_up(...)` MUST validate the pubkey length, require `amount_gwei * 1 gwei` to be at least the minimum stake, and require `msg.value >= amount_gwei * 1 gwei + fee` (same fee as `deposit`), but MUST NOT perform any signature verification. On success it MUST append a `BUILDER_TOPUP_REQUEST_TYPE` record of `pubkey (48) ++ amount_gwei (8, little-endian)` to its queue.

`top_up(...)` deliberately takes no `withdrawal_credentials`. A top-up only adds stake to an already-registered builder; the credentials are fixed by that builder's verified deposit. Omitting the field denies an unauthenticated caller any influence over a builder's withdrawal target. The consensus layer is responsible for rejecting top-up records that target a `pubkey` not already registered as an EIP-7732 builder.

The deposited ETH for both entrypoints is locked in the respective contract; the consensus layer credits the builder from the dequeued request.

### Consensus layer request objects

The consensus layer decodes each dequeued record into one of two SSZ containers, selected by request type:

```python
class BuilderDepositRequest(object):
    pubkey: Bytes48
    withdrawal_credentials: Bytes32
    amount: uint64  # Gwei

class BuilderTopUpRequest(object):
    pubkey: Bytes48
    amount: uint64  # Gwei
```

A type's `request_data` is the concatenation of the fixed-size SSZ serializations of its records — 88 bytes per `BuilderDepositRequest` (`pubkey ++ withdrawal_credentials ++ amount`) and 56 bytes per `BuilderTopUpRequest` (`pubkey ++ amount`), with `amount` little-endian — in the FIFO order the system call returns them. This matches the bytes the contract appends to its queue. Unlike the validator [EIP-6110](./eip-6110.md) `DepositRequest`, `BuilderDepositRequest` carries no `signature` (the execution layer has already verified it) and no `index`.

### Consensus-layer processing of records

The consensus layer processes the two request types as follows:

- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **not** yet in the builder set is a first deposit: it registers the builder with the record's `withdrawal_credentials` and credits its `amount`. The execution layer has already verified the proof-of-possession, so the consensus layer does not re-verify.
- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **already** in the builder set MUST be treated as a top-up: it credits `amount` and MUST NOT change the existing `withdrawal_credentials` or re-register the builder. This mirrors the validator deposit contract, where the proof-of-possession is checked only on a pubkey's first appearance and later deposits are stake additions.
- A `BuilderTopUpRequest` (type `0x04`) MUST be rejected if its `pubkey` is not already a registered builder, and otherwise credits `amount` without touching the withdrawal credentials.

## Rationale

- **A separate contract, not a replacement.** The deployed validator contract has an immutable two-mode API. Replacing its runtime would either break the all-zero-signature top-up flow that mainnet uses today, or would require keeping an unverified entrypoint in the spec — bringing the same DoS surface forward. A separate contract lets the existing validator semantics stay fixed.

- **Reuse the EIP-7685 request bus.** Builder deposits and top-ups are delivered through the same execution-to-consensus request mechanism as [EIP-7002](./eip-7002.md) withdrawals and [EIP-7251](./eip-7251.md) consolidations: an in-state queue drained by an end-of-block `SYSTEM_ADDRESS` system call, committed in `requests_hash`. This is preferred over the log-scraping path that [EIP-6110](./eip-6110.md) uses for validator deposits, which was a backwards-compatibility accommodation for the immutable validator contract. A fresh contract has no such constraint, so it uses the modern request bus and the consensus layer needs no log-parsing for builders.

- **Two predeploys, two request types.** Mirroring withdrawals (`0x01`) and consolidations (`0x02`) — each a single-type request predeploy — builder deposits (`0x03`) and top-ups (`0x04`) are two separate predeploys sharing a common queue implementation. Each is a standard single-type request contract: an empty-calldata `SYSTEM_ADDRESS` call returns a flat `request_data`. The execution layer therefore needs no new read semantics, and the consensus layer distinguishes a first-sighting deposit (with an execution-layer-verified signature) from a stake-only top-up by request type rather than by inspecting record contents.

- **EIP-1559-style request fee.** Each request carries the same dynamic, demand-responsive fee as EIP-7002/7251, rather than relying on the staked value alone as the anti-spam gate. This keeps the builder predeploys uniform with the existing request bus and smooths bursts: when a block exceeds `TARGET_REQUESTS_PER_BLOCK`, the `excess` counter grows and the fee rises super-linearly, throttling demand independently of the deposit minimum; it decays back to `MIN_REQUEST_FEE` when demand subsides. Because a deposit also carries stake, the fee is charged on top of the staked value; the fee is retained by the contract (effectively burned), and the per-block cap plus the queue still bound how many records enter a single block.

- **The amount is not signed.** The builder deposit signature commits only to `(pubkey, withdrawal_credentials)`, not the amount. Signing the amount would add no security here: the unverified `top_up` already lets anyone add stake to a `pubkey` with no signature, so the staked amount is not a signature-bound quantity by design, and even on the first deposit the depositor controls both the signature and `msg.value`, so a mismatch benefits no one. Leaving the amount unsigned also removes a circularity: with the fee drawn from `msg.value`, a *signed* amount could not be derived from `msg.value` (the fee is unknown at signing time), so it would otherwise have to be both signed and passed explicitly. `amount_gwei` is therefore an explicit but unsigned parameter — the credited stake — which keeps it symmetric with `top_up`'s amount and makes the credited value deterministic regardless of the fee at inclusion time.

- **Y coordinates supplied by the caller.** On-chain decompression of a compressed G1 or G2 point requires an Fp or Fp2 square root, which in turn requires several thousand bytes of runtime code and an order-of-magnitude more gas than the pairing check itself. Because builders already work with affine BLS points in their off-chain infrastructure, requiring the Y coordinates as call data shrinks the canonical bytecode considerably and removes the Fp-arithmetic and Sarkar/Adj sqrt code from the audit surface.

- **Caller-supplied Y is bound to the compressed sign bit.** The contract requires `sign(pubkey_y)` to equal the sign flag of the compressed `pubkey` (and likewise for the signature). The pairing check alone does NOT make this redundant: because a depositor jointly chooses the key, the queued sign bit, and the signature, they can verify a point `(X, +Y)` while the record's `pubkey` bytes decompress to `(X, −Y)`, keeping the pairing self-consistent but causing the consensus layer to register a point whose proof-of-possession was never actually verified. Binding the sign bit closes this gap with a single field comparison and short-circuits before any pairing work.

- **Gas-metered verification as the DoS gate.** Verification cost (`BLS12_PAIRING_CHECK` + `BLS12_MAP_FP2_TO_G2` + supporting work) is paid by the depositor's transaction. Submitting an invalid signature therefore costs the same as submitting a valid one; there is no asymmetric drain on the consensus layer.

- **Distinct signing domain (`DOMAIN_BUILDER_DEPOSIT`).** Builder deposit signatures use a domain type distinct from the validator deposit domain. Were the builder message identical to the validator `DepositMessage` and signed under the same domain, a public validator-deposit signature could be replayed here to force-enrol a validator pubkey as a builder (and vice versa). Two independent differences now prevent that: the builder message is a 2-field `(pubkey, withdrawal_credentials)` container (the validator message is 3-field, with the amount, so the message roots differ for the same key), and the signing domain differs. The distinct domain is retained as the explicit guarantee rather than relying on the structural difference alone — an explicit domain tag is more robust than the assumption that no other scheme ever signs a 2-field `(pubkey, withdrawal_credentials)` message under the validator domain.

## Backwards Compatibility

This EIP is additive at the execution layer: it introduces a new contract at a previously empty address. It does not modify the validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa`, does not change the `DepositEvent` layout that contract emits, and does not affect any existing validator's ability to make first deposits or top-ups.

At the consensus layer, EIP-7732 builders MUST be sourced from the builder deposit (`BUILDER_DEPOSIT_REQUEST_TYPE`) and top-up (`BUILDER_TOPUP_REQUEST_TYPE`) requests committed in the block `requests_hash`; the validator deposit contract continues to be the sole source of validator deposits. The new request types are additive — blocks that contain no builder requests produce empty `request_data` for these types, which [EIP-7685](./eip-7685.md) excludes from the `requests_hash`.

## Test Cases

A Foundry test suite under `../assets/eip-draft_builder_deposit/test/` cross-verifies the contracts against `py_ecc` (the canonical Eth2 Python reference). Coverage includes the SSZ signing-root computation; an end-to-end `deposit(...)` that enqueues a record matching a `py_ecc.bls.G2ProofOfPossession.Sign`-produced signature; the `top_up(...)` happy path; the `SYSTEM_ADDRESS` system read returning the exact `request_data` records; the per-block cap and FIFO drain order; rejection of a non-`SYSTEM_ADDRESS` system read; and the input-shape and tampering rejection paths (each asserting nothing is enqueued).

## Reference Implementation

Solidity source for both predeploys is published at [`../assets/eip-draft_builder_deposit/builder_deposit_contract.sol`](../assets/eip-draft_builder_deposit/builder_deposit_contract.sol), with the test harness, fixture generator, and Foundry configuration alongside it. The file defines a shared `RequestQueue` base plus `BuilderDepositContract` and `BuilderTopUpContract`. The optimised runtime bytecode of the current draft is approximately 7.8 KiB for the deposit contract and 1.5 KiB for the top-up contract — both well within the [EIP-170](./eip-170.md) 24 KiB limit, with no on-chain field-arithmetic kernel or decompression path. The final `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE`, `BUILDER_TOPUP_CONTRACT_RUNTIME_CODE`, the predeploy addresses, and the request-type bytes will be locked in once the contracts have been independently audited.

## Security Considerations

- **Signing-domain separation.** `DOMAIN_BUILDER_DEPOSIT` MUST differ from the validator `DOMAIN_DEPOSIT`, so a proof-of-possession signature is never interchangeable between this contract and the validator deposit contract (which would otherwise allow a public validator-deposit signature to be replayed here to force-enrol a validator pubkey as a builder, and vice versa). The builder message also differs structurally — a 2-field `(pubkey, withdrawal_credentials)` container versus the validator's 3-field message — which independently prevents the replay; the distinct domain is kept as the explicit guarantee rather than relying on that structural difference alone.
- **Sign-bit binding.** The supplied affine `Y` MUST agree with the sign flag of the compressed `pubkey`/`signature`. Without this binding, a depositor controlling the key could pass the pairing check on a point `(X, +Y)` while the queued record's `pubkey` bytes decompress to `(X, −Y)`, so the consensus layer registers a key whose proof-of-possession the execution layer never verified (it verified the negation). The deposit record carries no signature, so the consensus layer cannot detect this by re-verification — it trusts the execution-layer check — which is exactly why the binding must be enforced on chain.
- **System-read access control and per-block cap.** Only `SYSTEM_ADDRESS` may invoke the end-of-block dequeue; any other empty-calldata call reverts, so a non-system caller cannot drain or replay the queue. Each contract returns at most `MAX_REQUESTS_PER_BLOCK` records per block, bounding the size each predeploy contributes to the block requests; excess records remain queued for later blocks.
- **Top-up validity at CL.** A top-up appends a request without checking that the target `pubkey` exists. The consensus layer MUST reject top-ups against unregistered builders so that all-zero or junk top-ups cannot register new builders without a verified deposit. `top_up(...)` carries no `withdrawal_credentials`, so an unauthenticated caller cannot rewrite an existing builder's withdrawal target.
- **Replayable deposit records.** A deposit's `(pubkey, withdrawal_credentials, signature, …)` is public in calldata, and the signature commits only to `(pubkey, withdrawal_credentials)`, so a third party can submit a further `0x03` record for an already-registered builder at an arbitrary amount (funding it themselves). The consensus layer MUST treat a `0x03` record for an already-registered `pubkey` as a top-up — crediting stake but never changing the withdrawal credentials or re-registering — so the replay cannot redirect a builder's withdrawals or reset its state (see [Consensus-layer processing of records](#consensus-layer-processing-of-records)). This is harmless beyond a funded stake addition, exactly like a `0x04` top-up.
- **DoS surface.** Verification cost is gas-metered and paid by the depositor; an adversary cannot force consensus-layer pairing work without first paying the corresponding execution-layer gas. Per [EIP-2537](./eip-2537.md) §"Gas burning on error", a precompile that rejects a malformed (off-curve or out-of-subgroup) point burns all gas forwarded to it, so the contract MUST NOT forward `gas()` to the precompiles. Because EIP-2537 pricing is deterministic (a pure function of input length), the contract forwards a fixed gas ceiling to each precompile `staticcall` — set per call at roughly 2.5x the documented cost — which bounds the worst-case burn on a malformed input to that ceiling instead of the whole transaction, while leaving ample headroom for a future reprice. The ceilings MUST be revisited if [EIP-2537](./eip-2537.md) pricing changes.
- **Subgroup membership.** The [EIP-2537](./eip-2537.md) `BLS12_PAIRING_CHECK` precompile performs G1 and G2 subgroup checks; the contract does not need to re-implement them.
- **Compressed-point flags.** The contract must reject infinity-flagged inputs to prevent acceptance of the identity element as a `pubkey` or `signature`.
- **Validator-contract co-existence.** The validator deposit contract is unmodified; nothing in this EIP changes the existing 32-ETH validator deposit semantics.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
