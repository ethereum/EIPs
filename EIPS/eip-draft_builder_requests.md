---
title: Builder Execution Requests
description: Predeploy builder deposit and exit request contracts for EIP-7732 builders on the EIP-7685 request bus
author: Cayman (@wemeetagain), Nico Flaig <nflaig@protonmail.com>, Matthew Keil <me@matthewkeil.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2026-05-22
requires: 7685, 7732
---

## Abstract

Predeploy two [EIP-7685](./eip-7685.md) request contracts for the [EIP-7732](./eip-7732.md) builder population, modelled on the request bus that [EIP-7002](./eip-7002.md) (withdrawals) and [EIP-7251](./eip-7251.md) (consolidations) use:

- a builder **deposit** contract whose `deposit(...)` appends a record carrying the `pubkey`, `withdrawal_credentials`, `amount`, and the BLS `signature` to its queue. It serves both first deposits and top-ups: the consensus layer registers a builder on a `pubkey`'s first appearance and credits additional stake on later deposits. The signature is carried in the record and verified by the consensus layer on dequeue.
- a builder **exit** contract whose `exit(pubkey)` appends a full-exit record authorized by the caller's address (recorded as `source_address`).

Each contract maintains an in-state request queue drained by an end-of-block `SYSTEM_ADDRESS` system call; the dequeued records become the contract's [EIP-7685](./eip-7685.md) `request_data`, committed in the block `requests_hash`. Neither contract emits logs. Both are independent of the existing validator deposit contract and the validator request predeploys, and they replace EIP-7732's builder onboarding through the validator deposit flow for builders created after the fork.

## Motivation

[EIP-7732](./eip-7732.md) introduces builders as a separate, staked consensus-layer class. A builder is created by a deposit, can have stake added, and must be able to exit. Today EIP-7732 sources this lifecycle from the *validator* flows: a builder is registered by an ordinary validator deposit request whose withdrawal credential carries the `0x03` `BUILDER_WITHDRAWAL_PREFIX`, and a builder exits through a builder branch of the consensus-layer voluntary-exit operation. This EIP instead gives builders their own dedicated [EIP-7685](./eip-7685.md) request contracts.

**Dedicated request types remove cross-actor coupling.** Routing builders through the validator contracts forces the consensus layer to decide, on every request, whether it acts on the validator set or the builder set (today by inspecting the credential prefix). Dedicated builder request types make the actor explicit from the request type alone, so the validator and builder registries are keyed independently. A single public key can then be registered as both a validator and a builder; the protocol currently disallows that overlap, and this EIP allows the rule to be removed.

**The deposit bounds a consensus-side denial-of-service surface.** A builder deposit's proof-of-possession is verified by the consensus layer (as it already is in EIP-7732). Routed through the validator deposit request — which admits thousands of deposits per block — an attacker submitting invalid-signature builder deposits at the 1-ETH builder minimum could force that many proof-of-possession checks per block. Delivering builder deposits through a *dedicated* request bus caps them at `MAX_REQUESTS_PER_BLOCK` per block and charges an [EIP-1559](./eip-1559.md)-style fee on top of the staked value, bounding both the consensus-layer verification work and the spam economics.

**Exit gains a cold-key path builders lack today.** EIP-7732 lets a builder exit only via a voluntary exit signed by its BLS key — the same hot key it uses to sign bids. The exit contract instead authorizes a full exit by the builder's `execution_address` (the address that owns its stake), exactly as [EIP-7002](./eip-7002.md) lets a validator's withdrawal credential trigger an exit. Routing builder exits through this request makes the consensus-layer voluntary-exit operation validator-only again.

Builders that must exist at the fork are unaffected: EIP-7732's fork-transition onboarding of builder-credentialed pending deposits is retained (see [Changes to EIP-7732](#changes-to-eip-7732)); only post-fork onboarding moves to the deposit contract. The deployed validator deposit contract is left untouched, and builder stake withdrawals continue to flow through EIP-7732's existing full-balance sweep.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

All address and request-type values below are placeholders. The `0x03`/`0x04` request types MUST be unallocated and unique across **all** active [EIP-7685](./eip-7685.md) request types — not only the finalized deposit (`0x00`), withdrawal (`0x01`), and consolidation (`0x02`) types, but also any other in-flight request-type proposals — with final allocation coordinated in consensus-specs.

| Name | Value | Comment |
| --- | --- | --- |
| `BUILDER_DEPOSIT_CONTRACT_ADDRESS` | `0x0000000000000000000000000000000000007732` | Predeploy address of the builder deposit contract (placeholder) |
| `BUILDER_EXIT_CONTRACT_ADDRESS` | `0x0000000000000000000000000000000000007733` | Predeploy address of the builder exit contract (placeholder) |
| `BUILDER_DEPOSIT_REQUEST_TYPE` | `0x03` | [EIP-7685](./eip-7685.md) request-type byte for builder deposits (placeholder) |
| `BUILDER_EXIT_REQUEST_TYPE` | `0x04` | [EIP-7685](./eip-7685.md) request-type byte for builder exits (placeholder) |
| `SYSTEM_ADDRESS` | `0xfffffffffffffffffffffffffffffffffffffffe` | Address that invokes the end-of-block system call (as in [EIP-7002](./eip-7002.md)) |
| `MAX_REQUESTS_PER_BLOCK` | `16` | Maximum records each contract drains into one block |
| `TARGET_REQUESTS_PER_BLOCK` | `2` | Per-block request count above which the fee rises |
| `MIN_REQUEST_FEE` | `1` | Minimum request fee, in wei |
| `REQUEST_FEE_UPDATE_FRACTION` | `17` | Controls the fee's rate of change |
| `EXCESS_INHIBITOR` | `2**256-1` | Excess value that makes the fee getter revert before the first system call (as in [EIP-7002](./eip-7002.md)/[EIP-7251](./eip-7251.md)); set at deployment, cleared by the first system call |
| `BUILDER_MIN_DEPOSIT` | `1000000000000000000` | Minimum credited stake for a deposit, in wei (1 ETH — the [EIP-7732](./eip-7732.md) builder minimum) |
| `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` | _see [Reference Implementation](#reference-implementation)_ | Runtime bytecode of the builder deposit contract |
| `BUILDER_EXIT_CONTRACT_RUNTIME_CODE` | _see [Reference Implementation](#reference-implementation)_ | Runtime bytecode of the builder exit contract |

### Deployment

Each predeploy is deployed exactly as the [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) request contracts are: by a one-time presigned transaction from a single-use deployer account (the Nick's-method scheme), so that `BUILDER_DEPOSIT_CONTRACT_ADDRESS` and `BUILDER_EXIT_CONTRACT_ADDRESS` are the addresses cryptographically derived from those transactions. Each contract's init code sets its `excess` slot to `EXCESS_INHIBITOR`, so no request can be enqueued until the inhibitor is cleared (see [Request fee](#request-fee)). The concrete transactions — and therefore the final addresses — will be fixed once the runtime bytecode is audited and frozen (see [Reference Implementation](#reference-implementation)).

The deployment transactions MUST be included before the fork that activates this EIP. If there is no code at either predeploy address once the EIP is active, every block from activation onward MUST be invalid — the same handling [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) specify for their predeploys.

### Request queue and system call

Both predeploys follow the [EIP-7002](./eip-7002.md) / [EIP-7251](./eip-7251.md) request-bus pattern. Each maintains a FIFO queue of request records in its own storage and an EIP-1559-style `excess` counter. A user-facing entrypoint validates a request, charges the current fee, and appends one record.

A call with empty calldata dispatches on the caller:

- From `SYSTEM_ADDRESS` (the end-of-block system call): the predeploy MUST dequeue up to `MAX_REQUESTS_PER_BLOCK` records (oldest first), return their concatenation as that contract's `request_data`, advance its queue head past the returned records, then update `excess` from the number of requests added in the block (`excess = max(0, excess + count - TARGET_REQUESTS_PER_BLOCK)`, treating a current value of `EXCESS_INHIBITOR` as `0` so the first system call clears the inhibitor) and reset that count. Records beyond the per-block cap remain queued for subsequent blocks.
- From any other caller: the predeploy MUST return the current fee (the fee getter), without modifying state.

The execution layer prepends the contract's request-type byte and includes `request_type ++ request_data` in the block requests list, committed via the `requests_hash` ([EIP-7685](./eip-7685.md)). Neither contract emits logs.

The end-of-block system call to each predeploy follows the same rules [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) specify, restated here because [EIP-7685](./eip-7685.md) does not: the call is made as `SYSTEM_ADDRESS` with a dedicated gas limit of `30_000_000`; the gas it consumes does not count against the block gas limit and no value is transferred; and **if any of the predeploys' system calls fails or returns an error, the block MUST be invalid.**

### Request fee

Each request carries a fee, computed exactly as in [EIP-7002](./eip-7002.md):

```
fee = fake_exponential(MIN_REQUEST_FEE, excess, REQUEST_FEE_UPDATE_FRACTION)
```

where `fake_exponential` is the integer approximation of `MIN_REQUEST_FEE · e^(excess / REQUEST_FEE_UPDATE_FRACTION)` used by [EIP-1559](./eip-1559.md). Because `excess` grows whenever a block contains more than `TARGET_REQUESTS_PER_BLOCK` requests and decays otherwise, the fee rises super-linearly under sustained demand and returns to `MIN_REQUEST_FEE` when demand subsides. The fee is charged on top of any staked value (see the entrypoints below) and is left locked in the contract.

As in EIP-7002/7251, each contract's `excess` is initialized to `EXCESS_INHIBITOR` at deployment, and the fee getter reverts while `excess == EXCESS_INHIBITOR`. Since a request is only appended after its fee is paid, this blocks every request between deployment and the first end-of-block system call; that call clears the inhibitor (treating the prior `excess` as `0`), and normal fee operation runs from the activation block onward.

### Deposit entrypoint

```
deposit(
    bytes pubkey,                    // 48-byte BLS public key
    bytes32 withdrawal_credentials,  // 32-byte commitment (execution_address + prefix)
    uint64 amount_gwei,              // stake to credit, in gwei
    bytes signature                  // 96-byte BLS proof-of-possession
) payable
```

`deposit(...)` serves both a builder's first deposit and subsequent top-ups. It MUST:

1. Validate that `pubkey` is 48 bytes and `signature` is 96 bytes.
2. Require `amount_gwei * 1 gwei >= BUILDER_MIN_DEPOSIT`.
3. Require `msg.value >= amount_gwei * 1 gwei + fee`, where `fee` is the current request fee. Any value beyond `amount_gwei * 1 gwei` is retained by the contract (the fee, plus any overpayment, is not credited to the builder).

On success it MUST append a `BUILDER_DEPOSIT_REQUEST_TYPE` record of `pubkey (48) ++ withdrawal_credentials (32) ++ amount_gwei (8, little-endian) ++ signature (96)` to its queue. The `signature` is carried in the record and verified by the consensus layer, which checks the proof-of-possession only on the `pubkey`'s first appearance and treats a later deposit to an existing builder as a stake top-up (see [Consensus-layer processing of records](#consensus-layer-processing-of-records)).

### Exit entrypoint

```
exit(
    bytes pubkey   // 48-byte builder public key
) payable
```

`exit(...)` requests a full exit of the builder identified by `pubkey`. It MUST validate that `pubkey` is 48 bytes and require `msg.value >= fee` (the same request fee as `deposit`); it stakes no value and moves no ETH on the execution layer. On success it MUST append a `BUILDER_EXIT_REQUEST_TYPE` record of `source_address (20) ++ pubkey (48)` to its queue, where `source_address` is `msg.sender`.

Authorization is by `source_address`, as in [EIP-7002](./eip-7002.md): the caller proves control of the builder by transacting from the builder's `execution_address`. The contract records `msg.sender` verbatim and performs no further check; the consensus layer honours the request only when `source_address` equals the target builder's `execution_address` (see [Consensus-layer processing of records](#consensus-layer-processing-of-records)).

### Consensus layer request objects

The consensus layer decodes each dequeued record into one of two SSZ containers, selected by request type:

```python
class BuilderDepositRequest(object):
    pubkey: Bytes48
    withdrawal_credentials: Bytes32
    amount: uint64  # Gwei
    signature: Bytes96

class BuilderExitRequest(object):
    source_address: Bytes20
    pubkey: Bytes48
```

A type's `request_data` is the concatenation of the fixed-size SSZ serializations of its records — 184 bytes per `BuilderDepositRequest` (`pubkey ++ withdrawal_credentials ++ amount ++ signature`) and 68 bytes per `BuilderExitRequest` (`source_address ++ pubkey`), with `amount` little-endian — in the FIFO order the system call returns them. This matches the bytes each contract appends to its queue. `BuilderDepositRequest` is the validator [EIP-6110](./eip-6110.md) `DepositRequest` without the `index` field; the consensus layer verifies its `signature` (the proof-of-possession) on the builder's first registration.

### Consensus-layer processing of records

The consensus layer processes the two request types as follows. Both are applied immediately when processed — a `BuilderDepositRequest` is **not** routed through the validator `pending_deposits` queue — so builder onboarding has no churn or finalization delay, preserving EIP-7732's existing behavior.

- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **not** yet in the builder set is a first deposit: the consensus layer verifies the proof-of-possession `signature` over `(pubkey, withdrawal_credentials)` under the builder-deposit signing domain and, if valid, registers the builder with the record's `withdrawal_credentials` and credits its `amount`; an invalid signature is ignored.
- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **already** in the builder set is a top-up: it credits `amount` and MUST NOT change the existing `withdrawal_credentials` or re-register the builder, and its `withdrawal_credentials` and `signature` are ignored. This mirrors the validator deposit contract, where the proof-of-possession is checked only on a pubkey's first appearance and later deposits are stake additions.
- A `BuilderExitRequest` (type `0x04`) MUST be ignored unless its `pubkey` is a registered builder, its `source_address` equals that builder's `execution_address`, and the builder has no pending balance to withdraw. When valid, it initiates the builder's exit — setting `withdrawable_epoch = current_epoch + MIN_BUILDER_WITHDRAWABILITY_DELAY`, and is a no-op if the builder is already exiting. This is EIP-7732's existing `initiate_builder_exit`, now reached through this request rather than through a voluntary exit.

### Changes to EIP-7732

This EIP modifies EIP-7732's builder lifecycle on the consensus layer:

- **Deposit routing (post-fork).** The builder branch of `process_deposit_request` (which applies a deposit as a builder when its withdrawal credential carries `BUILDER_WITHDRAWAL_PREFIX`) is removed. After the fork, builders are sourced **only** from `BUILDER_DEPOSIT_REQUEST_TYPE`. A standard validator deposit (type `0x00`) whose withdrawal credential carries `BUILDER_WITHDRAWAL_PREFIX` MUST be rejected — it is applied neither as a validator nor as a builder.
- **Genesis onboarding (at the fork).** `onboard_builders_from_pending_deposits`, run once during the fork upgrade, is retained: builder-credentialed deposits already pending at the fork are onboarded as builders, so builders exist from the activation slot. Operators seed the genesis builder set by depositing to the existing deposit contract with a `BUILDER_WITHDRAWAL_PREFIX` credential before the fork.
- **Exit routing.** The builder branch of `process_voluntary_exit` is removed, making the voluntary-exit operation validator-only; builders exit only via `BUILDER_EXIT_REQUEST_TYPE`.

## Rationale

- **Two predeploys, two request types.** Mirroring withdrawals (`0x01`) and consolidations (`0x02`) — each a single-type request predeploy — builder deposits (`0x03`) and exits (`0x04`) are separate predeploys sharing a common queue implementation. Each is a standard single-type request contract: an empty-calldata `SYSTEM_ADDRESS` call returns a flat `request_data`, so the execution layer needs no new read semantics, and the consensus layer routes by request type rather than by inspecting credentials.

- **One request for deposits and top-ups.** A single deposit request serves both: a deposit to a new `pubkey` registers a builder (the consensus layer verifies the proof-of-possession), and a deposit to an existing builder tops up its stake — exactly as the validator deposit contract does. A top-up cannot redirect a builder's withdrawal target, because the consensus layer ignores the supplied `withdrawal_credentials` and `signature` for an existing builder; and a junk deposit to a new `pubkey` cannot register a builder without a valid proof-of-possession.

- **Exit by `execution_address`; voluntary exit becomes validator-only.** A builder's BLS key is hot — it signs bids continuously — so authorizing exit with that key is undesirable. Routing exit through the `execution_address` (the cold address that owns the builder's stake and receives its withdrawals) mirrors EIP-7002's rationale for letting `0x01` credentials trigger validator exits, and removing the builder branch from the voluntary-exit operation gives builders a single, well-defined exit authorizer. Losing the `execution_address` key strands no funds that were not already stranded: that address is where the builder's balance is swept regardless.

- **EIP-1559-style request fee.** Each request carries the same dynamic, demand-responsive fee as EIP-7002/7251. When a block exceeds `TARGET_REQUESTS_PER_BLOCK`, `excess` grows and the fee rises super-linearly, throttling demand; it decays back to `MIN_REQUEST_FEE` when demand subsides. Together with the per-block cap and the per-deposit stake, the fee is what meters submission to each predeploy.

- **Genesis onboarding via the fork transition.** Some applications depend on builders existing from the first slot of the fork. EIP-7732 already onboards builder-credentialed pending deposits during the fork upgrade; retaining that — rather than relying on post-fork deposits to the new contract, which cannot populate the activation slot — keeps the genesis builder set available immediately. That one-time onboarding is bounded, so it needs neither the per-block cap nor the fee that the steady-state contract provides.

## Backwards Compatibility

This EIP is additive at the execution layer: it introduces new contracts at previously empty addresses. It does not modify the validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa`, the validator withdrawal/consolidation predeploys, or any existing validator's lifecycle.

At the consensus layer it modifies EIP-7732 (see [Changes to EIP-7732](#changes-to-eip-7732)): post-fork builder onboarding moves from the validator deposit request to `BUILDER_DEPOSIT_REQUEST_TYPE`, and builder exits move from the voluntary-exit operation to `BUILDER_EXIT_REQUEST_TYPE`. The fork-transition onboarding of builder-credentialed pending deposits is unchanged, so builders present at the fork are unaffected. The new request types are additive — blocks that contain no builder requests produce empty `request_data` for these types, which [EIP-7685](./eip-7685.md) excludes from the `requests_hash`.

## Test Cases

A Foundry test suite under `../assets/eip-draft_builder_requests/test/` exercises both predeploys against the shared queue. Coverage includes: the `deposit(...)` happy path (the `SYSTEM_ADDRESS` read returns the exact 184-byte `pubkey ++ withdrawal_credentials ++ amount ++ signature` record) and its input-shape and insufficient-value rejections; the `exit(...)` happy path (the read returns the exact 68-byte `source_address ++ pubkey` record, with `source_address` taken from the caller) and its rejections; the EIP-1559 fee (minimum at `excess == 0`, rising after a block above `TARGET_REQUESTS_PER_BLOCK`, and the fee getter); the per-block cap and FIFO drain order, queue reset on empty, and rejection of a non-`SYSTEM_ADDRESS` system read; and the `EXCESS_INHIBITOR` (fee getter and requests revert before activation, and the first system call clears the inhibitor).

## Reference Implementation

Solidity source for both predeploys is published at [`../assets/eip-draft_builder_requests/builder_requests.sol`](../assets/eip-draft_builder_requests/builder_requests.sol), with the test harness and Foundry configuration alongside it. The file defines a shared `RequestQueue` base (queue, EIP-1559 fee, `EXCESS_INHIBITOR`, and `SYSTEM_ADDRESS` end-of-block read) plus `BuilderDepositContract` and `BuilderExitContract`. The optimised runtime bytecode of the current draft is approximately 1.8 KiB for the deposit contract and 1.3 KiB for the exit contract — both far within the [EIP-170](./eip-170.md) 24 KiB limit.

The final `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` and `BUILDER_EXIT_CONTRACT_RUNTIME_CODE`, the predeploy addresses, and the request-type bytes will be locked in once the contracts have been independently audited. The runtime bytecode, the exact compiler version and settings used to produce it, and the contracts' storage layout MUST be pinned together at that point, so the canonical bytecode is independently reproducible.

## Security Considerations

- **Deposit proof-of-possession at the consensus layer.** The consensus layer verifies the proof-of-possession over `(pubkey, withdrawal_credentials)` on a builder's first registration and ignores the signature for top-ups. The per-block cap bounds the number of verifications the consensus layer performs per block, and the fee plus the 1-ETH stake (forfeited if the signature is invalid) make spamming invalid registrations expensive.
- **Builder-deposit signing-domain separation.** The signing domain the consensus layer uses to verify a builder deposit MUST differ from the validator `DOMAIN_DEPOSIT` and from every EIP-7732 domain, so a proof-of-possession signature is not interchangeable between a builder deposit, a validator deposit, and an EIP-7732 builder message. This is a consensus-layer concern (the contract holds no signing domain).
- **Exit authorization.** The exit contract records `msg.sender` as `source_address` and performs no further check. Because the request carries no signature, this is the sole authorization: the consensus layer MUST initiate an exit only when `source_address` equals the target builder's `execution_address`, or an arbitrary caller could exit a builder it does not control. A builder's only exit authorizer is therefore its `execution_address`; the voluntary-exit (BLS-key) path is removed for builders.
- **Same public key as validator and builder.** Because the registries are keyed by independent request types, one public key may exist as both a validator and a builder. The two are distinct entries with distinct indices and distinct lifecycles; neither request type can act on the other registry.
- **Replayable deposit records.** A deposit's `(pubkey, withdrawal_credentials, amount, signature)` is public in calldata, so a third party can submit a further `0x03` record for an already-registered builder at an arbitrary amount (funding it themselves). The consensus layer treats any `0x03` record for an already-registered `pubkey` as a top-up — crediting stake but ignoring the credentials and signature — so the replay cannot redirect a builder's withdrawals or re-register it; it is a harmless funded stake addition.
- **System-read access control and per-block cap.** Only `SYSTEM_ADDRESS` may invoke the end-of-block dequeue; any other empty-calldata call is the fee getter and does not modify state, so a non-system caller cannot drain or replay the queue. Each contract returns at most `MAX_REQUESTS_PER_BLOCK` records per block, bounding both the size each predeploy contributes to the block requests and the consensus-layer work to process them; excess records remain queued for later blocks.
- **Validator-contract co-existence.** The validator deposit contract and the validator request predeploys are unmodified; this EIP changes only EIP-7732's builder onboarding and exit routing (see [Changes to EIP-7732](#changes-to-eip-7732)).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
