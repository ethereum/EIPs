---
title: Builder Deposit Contract
description: Predeploy a BLS-verifying builder deposit contract using EIP-2537 precompiles, for EIP-7732 builders
author: Cayman (@wemeetagain)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2026-05-22
requires: 2537, 7732
---

## Abstract

Predeploy a builder deposit contract at a fixed address. The contract exposes two entrypoints:

- `deposit(...)`, which verifies a BLS proof-of-possession signature against the supplied `DepositMessage` using the [EIP-2537](./eip-2537.md) precompiles before emitting a deposit log; and
- `top_up(...)`, which accepts an additional deposit for an existing builder without on-chain signature verification.

This contract is independent of the existing validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa` and serves the [EIP-7732](./eip-7732.md) builder population only.

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

| Name | Value | Comment |
| --- | --- | --- |
| `BUILDER_DEPOSIT_CONTRACT_ADDRESS` | `0x0000000000000000000000000000000000007732` | Predeploy address of the builder deposit contract (placeholder; final value assigned alongside the EIP number) |
| `DOMAIN_BUILDER_DEPOSIT` | `0x0b000000f5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a9` | Signing domain for builder deposit messages. The `0x0b000000` domain type is a placeholder pending consensus-specs allocation; it MUST differ from the validator `DOMAIN_DEPOSIT` (`0x03000000…`) so signatures are not interchangeable between the two contracts |
| `BLS12_G2ADD` | `0x0d` | [EIP-2537](./eip-2537.md) precompile address |
| `BLS12_PAIRING_CHECK` | `0x0f` | [EIP-2537](./eip-2537.md) precompile address |
| `BLS12_MAP_FP2_TO_G2` | `0x11` | [EIP-2537](./eip-2537.md) precompile address |
| `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` | _see [Reference Implementation](#reference-implementation)_ | Runtime bytecode of the builder deposit contract |

### Fork transition

At the start of processing the first block where this EIP is active, before processing transactions, execution clients MUST install `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` at `BUILDER_DEPOSIT_CONTRACT_ADDRESS` if the account at that address is empty (zero `nonce`, empty `code`, empty `storage`, zero `balance`). The installation MUST set `code = BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE`, `nonce = 1`, `balance = 0`, and leave `storage` empty.

If the account at `BUILDER_DEPOSIT_CONTRACT_ADDRESS` is not empty at fork time, clients MUST abort initialisation. This matches the predeploy pattern used by [EIP-2935](./eip-2935.md), [EIP-4788](./eip-4788.md), [EIP-7002](./eip-7002.md), and [EIP-7251](./eip-7251.md).

### Builder deposit contract behavior

The contract exposes two external entrypoints. Both MUST emit a log record at `BUILDER_DEPOSIT_CONTRACT_ADDRESS` that the consensus layer can extract and process as a builder deposit operation.

#### Verified entrypoint

```
deposit(
    bytes pubkey,                    // 48-byte compressed G1 (X with sign+infinity flags)
    bytes withdrawal_credentials,    // 32-byte commitment
    bytes signature,                 // 96-byte compressed G2 (X with sign+infinity flags)
    Fp    pubkey_y,                  // affine Y of pubkey, in EIP-2537 encoding
    Fp2   signature_y                // affine Y of signature, in EIP-2537 encoding
) payable
```

`deposit(...)` MUST perform the following, in order, before emitting any log:

1. Validate input lengths and the deposit amount.
2. Reject `pubkey` or `signature` whose infinity flag is set.
3. Verify that the supplied `pubkey_y` and `signature_y` agree with the sign flag of the corresponding compressed encoding (i.e. `sign(pubkey_y)` equals the sign bit of `pubkey`, and likewise for the signature). This binds the point used in the pairing check to the encoding that is emitted and that the consensus layer decompresses; without it the verified point could be the negation of the registered point.
4. Compute the signing root
   `compute_signing_root(DepositMessage(pubkey, withdrawal_credentials, amount), DOMAIN_BUILDER_DEPOSIT)`.
5. Verify the BLS proof-of-possession via the [EIP-2537](./eip-2537.md) `BLS12_PAIRING_CHECK` precompile, using the supplied affine `Y` coordinates to construct the G1 and G2 points.
6. Revert the entire call if the pairing check fails.

On success, `deposit(...)` MUST emit a `BuilderDepositEvent` carrying `pubkey`, `withdrawal_credentials`, `amount`, `signature`, and the contract's monotonic deposit index.

#### Unverified top-up entrypoint

```
top_up(
    bytes pubkey                     // 48-byte compressed G1 of an existing builder
) payable
```

`top_up(...)` MUST perform the length and amount checks but MUST NOT perform any signature verification. On success it MUST emit a `BuilderTopUpEvent` carrying `pubkey`, `amount`, and the contract's monotonic deposit index.

`top_up(...)` deliberately takes no `withdrawal_credentials`. A top-up only adds stake to an already-registered builder; the credentials are fixed by that builder's verified `BuilderDepositEvent`. Omitting the field denies an unauthenticated caller any influence over a builder's withdrawal target. The consensus layer is responsible for rejecting `BuilderTopUpEvent` records that target a `pubkey` not already registered as an EIP-7732 builder.

## Rationale

- **A separate contract, not a replacement.** The deployed validator contract has an immutable two-mode API. Replacing its runtime would either break the all-zero-signature top-up flow that mainnet uses today, or would require keeping an unverified entrypoint in the spec — bringing the same DoS surface forward. A separate contract lets the existing validator semantics stay fixed.

- **Y coordinates supplied by the caller.** On-chain decompression of a compressed G1 or G2 point requires an Fp or Fp2 square root, which in turn requires several thousand bytes of runtime code and an order-of-magnitude more gas than the pairing check itself. Because builders already work with affine BLS points in their off-chain infrastructure, requiring the Y coordinates as call data shrinks the canonical bytecode considerably and removes the Fp-arithmetic and Sarkar/Adj sqrt code from the audit surface.

- **Caller-supplied Y is bound to the compressed sign bit.** The contract requires `sign(pubkey_y)` to equal the sign flag of the compressed `pubkey` (and likewise for the signature). The pairing check alone does NOT make this redundant: because a depositor jointly chooses the key, the emitted sign bit, and the signature, they can verify a point `(X, +Y)` while the emitted bytes decompress to `(X, −Y)`, keeping the pairing self-consistent but causing the consensus layer to register a point whose proof-of-possession was never actually verified. Binding the sign bit closes this gap with a single field comparison and short-circuits before any pairing work.

- **Two entrypoints rather than a single overloaded one.** Keeping `top_up(...)` separate makes the consensus-layer log handling unambiguous: a `BuilderDepositEvent` is the first sighting of a builder pubkey and is accompanied by an execution-layer-verified signature; a `BuilderTopUpEvent` is an increment against an already-registered builder and carries no signature.

- **Gas-metered verification as the DoS gate.** Verification cost (`BLS12_PAIRING_CHECK` + `BLS12_MAP_FP2_TO_G2` + supporting work) is paid by the depositor's transaction. Submitting an invalid signature therefore costs the same as submitting a valid one; there is no asymmetric drain on the consensus layer.

- **Distinct signing domain (`DOMAIN_BUILDER_DEPOSIT`).** Builder deposit signatures use a domain type distinct from the validator deposit domain. This is a deliberate departure from "reuse existing signing tooling unchanged": sharing `DOMAIN_DEPOSIT` and the identical `DepositMessage` structure would make a proof-of-possession byte-for-byte interchangeable between this contract and the validator deposit contract, letting a public validator-deposit signature be replayed here to force-enrol a validator pubkey as a builder (and vice versa). Domain separation removes that cross-context replay in both directions; signing tooling needs only a one-constant domain change.

## Backwards Compatibility

This EIP is additive at the execution layer: it introduces a new contract at a previously empty address. It does not modify the validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa`, does not change the `DepositEvent` layout that contract emits, and does not affect any existing validator's ability to make first deposits or top-ups.

At the consensus layer, EIP-7732 builders MUST be sourced from `BuilderDepositEvent` and `BuilderTopUpEvent` logs at `BUILDER_DEPOSIT_CONTRACT_ADDRESS`; the validator deposit contract continues to be the sole source of validator deposits.

## Test Cases

A Foundry test suite under `../assets/eip-draft_builder_deposit/test/` cross-verifies the contract against `py_ecc` (the canonical Eth2 Python reference). Coverage includes the SSZ signing-root computation, an end-to-end `deposit(...)` round-trip against a `py_ecc.bls.G2ProofOfPossession.Sign`-produced signature, the `top_up(...)` happy path, the monotonic deposit-index invariant, and the input-shape and tampering rejection paths.

## Reference Implementation

Solidity source for the proposed runtime is published at [`../assets/eip-draft_builder_deposit/builder_deposit_contract.sol`](../assets/eip-draft_builder_deposit/builder_deposit_contract.sol), with the test harness, fixture generator, and Foundry configuration alongside it. The compiled, optimised runtime bytecode of the current draft is approximately 7.6 KiB — well within the [EIP-170](./eip-170.md) 24 KiB limit, with no on-chain field-arithmetic kernel or decompression path. The final `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` and `BUILDER_DEPOSIT_CONTRACT_ADDRESS` will be locked in once the contract has been independently audited.

## Security Considerations

- **Signing-domain separation.** `DOMAIN_BUILDER_DEPOSIT` MUST differ from the validator `DOMAIN_DEPOSIT`. Because both contracts use the identical `DepositMessage` SSZ structure, a shared domain would make proof-of-possession signatures byte-for-byte interchangeable, allowing a public validator-deposit signature to be replayed into this contract (force-enrolling a validator pubkey as a builder) and vice versa. The distinct domain type closes this in both directions.
- **Sign-bit binding.** The supplied affine `Y` MUST agree with the sign flag of the compressed `pubkey`/`signature`. Without this binding, a depositor controlling the key could pass the pairing check on a point `(X, +Y)` while emitting bytes that the consensus layer decompresses to `(X, −Y)`, so the registered key's proof-of-possession would never have been verified — and any CL client that defensively re-verified the emitted `(pubkey, signature)` would reject a deposit other clients accept, risking a builder-set split.
- **Top-up validity at CL.** The contract emits `BuilderTopUpEvent` without checking that the target `pubkey` exists. The consensus layer MUST reject top-ups against unregistered builders so that all-zero or junk top-ups cannot register new builders without a verified deposit. `top_up(...)` carries no `withdrawal_credentials`, so an unauthenticated caller cannot rewrite an existing builder's withdrawal target.
- **DoS surface.** Verification cost is gas-metered and paid by the depositor; an adversary cannot force consensus-layer pairing work without first paying the corresponding execution-layer gas. Per [EIP-2537](./eip-2537.md) §"Gas burning on error", a precompile that rejects a malformed (off-curve or out-of-subgroup) point burns all gas forwarded to it, so the contract MUST NOT forward `gas()` to the precompiles. Because EIP-2537 pricing is deterministic (a pure function of input length), the contract forwards a fixed gas ceiling to each precompile `staticcall` — set per call at roughly 2.5x the documented cost — which bounds the worst-case burn on a malformed input to that ceiling instead of the whole transaction, while leaving ample headroom for a future reprice. The ceilings MUST be revisited if [EIP-2537](./eip-2537.md) pricing changes.
- **Subgroup membership.** The [EIP-2537](./eip-2537.md) `BLS12_PAIRING_CHECK` precompile performs G1 and G2 subgroup checks; the contract does not need to re-implement them.
- **Compressed-point flags.** The contract must reject infinity-flagged inputs to prevent acceptance of the identity element as a `pubkey` or `signature`.
- **Validator-contract co-existence.** The validator deposit contract is unmodified; nothing in this EIP changes the existing 32-ETH validator deposit semantics.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
