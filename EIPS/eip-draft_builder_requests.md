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

All address and request-type values below are placeholders. The `0x03`/`0x04` request types MUST be unallocated and unique across **all** active [EIP-7685](./eip-7685.md) request types — not only the finalized deposit (`0x00`), withdrawal (`0x01`), and consolidation (`0x02`) types, but also any other in-flight request-type proposals (notably [EIP-7804](./eip-7804.md), a Draft that also defines request type `0x03`) — with final allocation coordinated in consensus-specs.

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

The consensus layer processes the two request types as follows. Both are applied immediately when processed — a `BuilderDepositRequest` is **not** routed through the validator `pending_deposits` queue, so a builder's balance is credited without an activation-churn queue, preserving EIP-7732's existing behavior. (A newly registered builder still becomes active for bidding and exit only once its deposit epoch is finalized, per gloas `is_active_builder`; only the churn queue is skipped, not finality.)

- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **not** yet in the builder set is a first deposit. The consensus layer registers the builder only if both checks pass: its `withdrawal_credentials` begins with the `0x03` `BUILDER_WITHDRAWAL_PREFIX` (`is_builder_withdrawal_credential`), and the proof-of-possession `signature` over the `DepositMessage` `(pubkey, withdrawal_credentials, amount)` under `DOMAIN_DEPOSIT` is valid — the same signature check validator deposits use (gloas `is_valid_deposit_signature`). If both hold, it registers the builder with the record's `withdrawal_credentials` (whose last 20 bytes are the builder's `execution_address`) and credits its `amount`. A record whose `withdrawal_credentials` is not `0x03`-prefixed, or whose signature is invalid, is ignored (consumed, stake forfeited). The prefix check mirrors the credential discrimination `process_deposit_request` applies on the validator path, so a registered builder always carries a `0x03` credential and therefore a well-formed `execution_address`.
- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **already** in the builder set is a top-up: it credits `amount` and MUST NOT change the existing `withdrawal_credentials` or re-register the builder, and its `withdrawal_credentials` and `signature` are ignored. This mirrors the validator deposit contract, where the proof-of-possession is checked only on a pubkey's first appearance and later deposits are stake additions. The builder set still contains entries that have **exited** (a slot is reclaimed only once the builder's `withdrawable_epoch` has passed and its balance is zero), so a deposit to an exited `pubkey` is also a top-up — it credits an entry that EIP-7732 does not reactivate, so the added stake merely sweeps to that entry's `execution_address` and never resumes bidding; re-registering the key requires waiting for its prior slot to be recycled.
- A `BuilderExitRequest` (type `0x04`) MUST be ignored unless its `pubkey` is a registered, active builder (gloas `is_active_builder`: its deposit epoch is finalized and it is not already exiting), its `source_address` equals that builder's `execution_address`, and it has no pending balance to withdraw (`get_pending_balance_to_withdraw_for_builder == 0`). This is precisely EIP-7732's `process_voluntary_exit` builder branch with the BLS-signature check replaced by the `source_address` check; when the predicate holds it runs `initiate_builder_exit` (`withdrawable_epoch = current_epoch + MIN_BUILDER_WITHDRAWABILITY_DELAY`). A request that fails any precondition is **consumed and discarded, not re-queued** — the fee is spent. Because an active builder routinely has a non-zero pending balance from recent bid payments, a legitimate exit may be dropped until those settle, in which case the caller must resubmit once the pending balance has been swept. (The execution layer dequeues the record deterministically regardless, so a dropped request never affects `requests_hash` agreement.)

### Changes to EIP-7732

This EIP modifies EIP-7732's builder lifecycle on the consensus layer:

- **Deposit routing.** `process_deposit_request` no longer creates or tops up builders. Its builder branch — `if is_builder or (is_builder_withdrawal_credential(...) and not is_validator and not is_pending_validator)` → `apply_deposit_for_builder` — is replaced by `if is_builder_withdrawal_credential(deposit_request.withdrawal_credentials): return`: the deposit is inert — it is **not** appended to `pending_deposits` (so no validator is minted) and its ETH is forfeited in the immutable deposit contract, as with any misdirected deposit. All other deposits process as validator deposits unchanged. Consequently a validator-contract deposit to a `pubkey` that is already a builder now creates or credits a **validator** with that key (the same key may be both — see [Rationale](#rationale)), never the builder; builders are created and topped up **only** via `BUILDER_DEPOSIT_REQUEST_TYPE`.
- **Genesis onboarding (at the fork).** `onboard_builders_from_pending_deposits`, run once during the fork upgrade, is retained: builder-credentialed deposits already in `pending_deposits` at the upgrade are onboarded as builders, so builders exist from the activation slot. Operators seed the genesis set by depositing to the existing deposit contract with a `BUILDER_WITHDRAWAL_PREFIX` credential before the fork — late enough that the deposit is still pending at the upgrade (a deposit applied earlier would create a stranded validator). The cutover is then a single deterministic switch with no transition window to parameterize: deposits captured by the snapshot are onboarded, and from the fork onward the deposit-routing rule above drops every `0x03`-credentialed validator-contract deposit. A `0x03`-credentialed deposit that lands too late for the snapshot — included only in the first post-fork block(s) — is therefore **not** onboarded; its stake is forfeited like any other dropped deposit, and the operator re-onboards through `BUILDER_DEPOSIT_REQUEST_TYPE`. No `pubkey` is onboarded by more than one path.
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

- **Deposit proof-of-possession at the consensus layer.** The consensus layer verifies the proof-of-possession over the `DepositMessage` `(pubkey, withdrawal_credentials, amount)` on a builder's first registration, and ignores the signature for top-ups. The per-block cap bounds how many such verifications the consensus layer performs per block; see *Spam and state growth* below for the full anti-abuse picture.
- **Cross-class deposit signatures.** Builder deposits reuse the validator deposit proof-of-possession check — the `DepositMessage` `(pubkey, withdrawal_credentials, amount)` under `DOMAIN_DEPOSIT`, a chain- and fork-agnostic domain — rather than a distinct builder-deposit domain. Two consequences follow. First, because a first deposit registers a builder only when its `withdrawal_credentials` is `0x03`-prefixed (see [Consensus-layer processing of records](#consensus-layer-processing-of-records)), a *validator* deposit proof-of-possession — which commits to a `0x00`/`0x01`/`0x02` credential — cannot be replayed to register a builder, and (post-fork) a *builder* proof-of-possession routed to the validator deposit contract is dropped; the two classes do not cross-register. Second, what remains replayable is a *builder's own* public proof-of-possession: because `DOMAIN_DEPOSIT` ignores the chain and fork, anyone can take a builder deposit's public `(pubkey, withdrawal_credentials, amount, signature)` from any network and resubmit it as a builder deposit, funding the ≥1-ETH stake themselves. This is low-harm: the signature commits to the original signer's own `0x03` credential, so the result is exactly the builder that signer authorized — non-slashable, unable to bid (that needs the BLS key the submitter lacks), with its balance ultimately swept to the signer's chosen `execution_address`; the replayer donates only stake and timing, and can redirect nothing. A distinct builder-deposit signing domain would close even this benign replay, but it would break genesis seeding (which is signed under `DOMAIN_DEPOSIT`) and add a tooling change for no real gain, so it is deliberately not introduced.
- **Exit authorization.** The exit contract records `msg.sender` as `source_address` and performs no further check. Because the request carries no signature, this is the sole authorization: the consensus layer MUST initiate an exit only when `source_address` equals the target builder's `execution_address`, or an arbitrary caller could exit a builder it does not control. A builder's only exit authorizer is therefore its `execution_address`; the voluntary-exit (BLS-key) path is removed for builders.
- **Custodial-split exit standoff.** A builder's exit precondition requires its pending balance to be zero (`get_pending_balance_to_withdraw_for_builder == 0`), every winning bid adds a pending payment, and the `execution_address` is the builder's sole exit authorizer (the BLS voluntary-exit path is removed). When the `execution_address` (the capital owner) and the BLS key (the bidding operator) are held by different parties — a custodial or staking-pool arrangement this design explicitly enables — the operator can keep the pending balance non-zero by continuing to win bids, so the capital owner cannot satisfy the exit precondition and the stake stays locked (a builder that never exits is never swept). The standoff is self-limiting, since the operator's bids must keep being included on-chain, but the protocol gives the `execution_address` holder no on-chain lever to halt bidding. Parties delegating builder operation SHOULD retain off-chain (contractual or operational) control over the operator's bidding, so a delegated builder can always be brought to a state in which it can exit.
- **Same public key as validator and builder.** Because the registries are keyed by independent request types, one public key may exist as both a validator and a builder. The two are distinct entries with distinct indices and distinct lifecycles; neither request type can act on the other registry.
- **Replayable deposit records.** A deposit's `(pubkey, withdrawal_credentials, amount, signature)` is public in calldata, so a third party can submit a further `0x03` record for an already-registered builder at an arbitrary amount (funding it themselves). The consensus layer treats any `0x03` record for an already-registered `pubkey` as a top-up — crediting stake but ignoring the credentials and signature — so the replay cannot redirect a builder's withdrawals or re-register it; it is a harmless funded stake addition.
- **Spam and state growth.** The per-block cap bounds only the drain rate — the consensus-layer verifications and the `request_data` size per block — not enqueue: within a block, appends are limited only by gas, and the in-state queue grows across blocks, reclaiming slots only when it fully drains. Queue growth is instead gated by the value locked per record: every deposit locks at least `BUILDER_MIN_DEPOSIT` (1 ETH) plus the fee, so growing the queue by N records costs at least N ETH locked. A griefer submitting **valid** proofs-of-possession forfeits nothing — the stake becomes a real, withdrawable builder balance (a capital-lock for `MIN_BUILDER_WITHDRAWABILITY_DELAY`, not a burn) — so post-fork onboarding can be throttled behind a FIFO wall of attacker deposits for the cost of locking capital; the cap plus FIFO ordering, not the fee, is the binding throttle. This is tolerable because the time-critical genesis builder set is seeded before the fork through the uncapped onboarding path, not through the steady-state contract.
- **Locked funds.** The request fee, any overpayment or sub-gwei remainder, and the principal of a first deposit the consensus layer rejects — one with an invalid proof-of-possession, or with a `withdrawal_credentials` that is not `0x03`-prefixed — are permanently locked in the predeploy (which has no withdrawal path) and irrecoverable by anyone, including an honest depositor who submits a bad signature, since the execution layer cannot verify BLS and the consensus-layer rejection is silent. This mirrors EIP-7002/7251; submitters SHOULD verify the proof-of-possession and the `0x03` credential prefix off-chain before broadcasting. `BUILDER_MIN_DEPOSIT` is enforced only at the execution layer (as the validator deposit contract enforces its own minimum), with no consensus-layer re-assertion.
- **System-read access control and per-block cap.** Only `SYSTEM_ADDRESS` may invoke the end-of-block dequeue; any other empty-calldata call is the fee getter and does not modify state, so a non-system caller cannot drain or replay the queue. Each contract returns at most `MAX_REQUESTS_PER_BLOCK` records per block, bounding both the size each predeploy contributes to the block requests and the consensus-layer work to process them; excess records remain queued for later blocks.
- **Validator-contract co-existence.** The validator deposit contract and the validator request predeploys are unmodified; this EIP changes only EIP-7732's builder onboarding and exit routing (see [Changes to EIP-7732](#changes-to-eip-7732)).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
