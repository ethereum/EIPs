---
eip: 8282
title: Builder Execution Requests
description: Predeploy builder deposit and exit request contracts for EIP-7732 builders on the EIP-7685 request bus
author: Cayman (@wemeetagain), Nico Flaig <nflaig@protonmail.com>, Justin Traglia <jtraglia@ethereum.org>
discussions-to: https://ethereum-magicians.org/t/eip-8282-builder-execution-requests/28699
status: Draft
type: Standards Track
category: Core
created: 2026-05-22
requires: 1559, 7685, 7732
---

## Abstract

Predeploy two [EIP-7685](./eip-7685.md) request contracts for [EIP-7732](./eip-7732.md) builders, modelled on the request bus that [EIP-7002](./eip-7002.md) (withdrawals) and [EIP-7251](./eip-7251.md) (consolidations) use:

- a builder **deposit** contract that takes a raw 184-byte request — `pubkey ++ withdrawal_credentials ++ amount ++ signature` — and appends it to its queue. It serves both first deposits and top-ups: the consensus layer registers a builder on a `pubkey`'s first appearance and credits additional stake on later deposits. The signature is carried in the record and verified by the consensus layer on dequeue.
- a builder **exit** contract that takes a raw 48-byte `pubkey` and appends a full-exit record authorized by the caller's address (recorded as `source_address`).

Each contract maintains an in-state request queue drained by an end-of-block `SYSTEM_ADDRESS` system call; the dequeued records become the contract's [EIP-7685](./eip-7685.md) `request_data`, committed in the block `requests_hash`, and each accepted request is also emitted as an anonymous log. Neither touches the validator deposit contract or the validator request predeploys; for builders created after the fork, they replace EIP-7732's onboarding through the validator deposit flow.

## Motivation

[EIP-7732](./eip-7732.md) introduces builders as a separate, staked consensus-layer class. A builder is created by a deposit, can have stake added, and must be able to exit. Today EIP-7732 sources this lifecycle from the *validator* flows: a builder is registered by an ordinary validator deposit request whose withdrawal credential carries the `0xB0` `BUILDER_WITHDRAWAL_PREFIX`, and a builder exits through a builder branch of the consensus-layer voluntary-exit operation. This EIP instead gives builders their own dedicated [EIP-7685](./eip-7685.md) request contracts.

**Dedicated request types remove cross-actor coupling.** Routing builders through the validator contracts forces the consensus layer to decide, on every request, whether it acts on the validator set or the builder set (today by inspecting the credential prefix). Dedicated builder request types make the actor explicit from the request type alone, so the validator and builder registries are keyed independently. A single public key can then be registered as both a validator and a builder. Under EIP-7732 the two cannot coexist for one key — a builder deposit is routed to the builder registry only when the key is not already a validator or pending validator, so deposit *routing*, not an explicit prohibition, keeps each key in at most one registry. Keying by request type removes that coupling: the registries become independent, and a key may appear in both with distinct indices and lifecycles (the only practical consequence is implementation-side; see [Security Considerations](#security-considerations)).

**The deposit bounds a consensus-side denial-of-service surface.** A builder deposit's proof-of-possession is verified *inline* by the consensus layer when the deposit is processed — unlike a validator deposit, which is deferred to the churn-limited `pending_deposits` queue. Carried on the validator deposit request, builder deposits inherit its high per-payload ceiling, so an attacker submitting invalid-signature builder deposits at the 1-ETH builder minimum could force a full payload's worth of proof-of-possession checks. The coupled deposit request scheme also requires verifying all matching pending validator deposit signatures at builder deposit verification time. A *dedicated* request bus **separates** builder deposits from validator deposits — isolating the builder-side verification work — and caps them at `MAX_DEPOSIT_REQUESTS_PER_BLOCK` per block. The cap and separation are what bound the builder-side verification the consensus layer performs per block.

**Exit gains a cold-key path builders lack today.** EIP-7732 lets a builder exit only via a voluntary exit signed by its BLS key — the same hot key it uses to sign bids. The exit contract instead authorizes a full exit by the builder's `execution_address` (the address that owns its stake), exactly as [EIP-7002](./eip-7002.md) lets a validator's withdrawal credential trigger an exit. Routing builder exits through this request makes the consensus-layer voluntary-exit operation validator-only again.

Builders that must exist at the fork are unaffected: EIP-7732's fork-transition onboarding of builder-credentialed pending deposits is retained (see [Changes to EIP-7732](#changes-to-eip-7732)); only post-fork onboarding moves to the deposit contract. The deployed validator deposit contract is left untouched, and builder stake withdrawals continue to flow through EIP-7732's existing full-balance sweep.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

The `0x03`/`0x04` request types MUST be unique across **all** active [EIP-7685](./eip-7685.md) request types, including in-flight proposals ([EIP-7804](./eip-7804.md), a Draft, also claims `0x03`); final allocation is coordinated in consensus-specs.

| Name | Value | Comment |
| --- | --- | --- |
| `BUILDER_DEPOSIT_CONTRACT_ADDRESS` | `0x0000bFF46984e3725691FA540a8C7589300D8282` | Predeploy address of the builder deposit contract |
| `BUILDER_EXIT_CONTRACT_ADDRESS` | `0x000064D678505ad48F8cCb093BC65613800E8282` | Predeploy address of the builder exit contract |
| `BUILDER_DEPOSIT_REQUEST_TYPE` | `0x03` | [EIP-7685](./eip-7685.md) request-type byte for builder deposits |
| `BUILDER_EXIT_REQUEST_TYPE` | `0x04` | [EIP-7685](./eip-7685.md) request-type byte for builder exits  |
| `SYSTEM_ADDRESS` | `0xfffffffffffffffffffffffffffffffffffffffe` | Address that invokes the end-of-block system call (as in [EIP-7002](./eip-7002.md)) |
| `MAX_DEPOSIT_REQUESTS_PER_BLOCK` | `64` | Maximum records the builder deposit contract drains into one block |
| `TARGET_DEPOSIT_REQUESTS_PER_BLOCK` | `8` | Per-block request count above which the fee rises for the deposit contract |
| `MAX_EXIT_REQUESTS_PER_BLOCK` | `16` | Maximum records the builder exit contract drains into one block |
| `TARGET_EXIT_REQUESTS_PER_BLOCK` | `2` | Per-block request count above which the fee rises for the exit contract |
| `MIN_REQUEST_FEE` | `1` | Minimum request fee, in wei |
| `REQUEST_FEE_UPDATE_FRACTION` | `17` | Controls the fee's rate of change |
| `EXCESS_INHIBITOR` | `2**256-1` | Excess value that makes the fee getter revert before the first system call (as in [EIP-7002](./eip-7002.md)/[EIP-7251](./eip-7251.md)); set at deployment, cleared by the first system call |
| `BUILDER_MIN_DEPOSIT` | `1000000000000000000` | Minimum credited stake for a deposit, in wei (1 ETH — the [EIP-7732](./eip-7732.md) builder minimum) |
| `BUILDER_DEPOSIT_CONTRACT_RUNTIME_CODE` | *see [Reference Implementation](#reference-implementation)* | Runtime bytecode of the builder deposit contract |
| `BUILDER_EXIT_CONTRACT_RUNTIME_CODE` | *see [Reference Implementation](#reference-implementation)* | Runtime bytecode of the builder exit contract |

### Deployment

Each predeploy is deployed exactly as the [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) request contracts are: by a one-time presigned transaction from a single-use deployer account (the Nick's-method scheme), so that `BUILDER_DEPOSIT_CONTRACT_ADDRESS` and `BUILDER_EXIT_CONTRACT_ADDRESS` are the addresses cryptographically derived from those transactions. Each contract's init code sets its `excess` slot to `EXCESS_INHIBITOR`, so no request can be enqueued until the inhibitor is cleared (see [Request fee](#request-fee)). The addresses above are derived from the presigned deployment transactions for the current reference bytecode; they will change if the runtime bytecode changes before it is audited and frozen (see [Reference Implementation](#reference-implementation)).

The deployment transactions MUST be included before the fork that activates this EIP. If there is no code at either predeploy address once the EIP is active, every block from activation onward MUST be invalid — the same handling [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) specify for their predeploys.

### Request queue and system call

Both predeploys follow the [EIP-7002](./eip-7002.md) / [EIP-7251](./eip-7251.md) request-bus pattern, reusing those contracts' storage layout: the [EIP-1559](./eip-1559.md)-style `excess` counter in slot 0, the per-block request `count` in slot 1, the FIFO queue's head and tail indices in slots 2 and 3, and the queued records from slot 4 onward. There is no ABI: like EIP-7002/EIP-7251, each contract dispatches on the caller and on `calldatasize` alone.

- From `SYSTEM_ADDRESS` (the end-of-block system call): the predeploy MUST dequeue up to `MAX_REQUESTS_PER_BLOCK` records (oldest first), return their concatenation as that contract's `request_data`, advance its queue head past the returned records (resetting head and tail to zero when the queue fully drains, so the storage slots are reused), then update `excess` from the number of requests added in the block (`excess = max(0, excess + count - TARGET_REQUESTS_PER_BLOCK)`, treating a current value of `EXCESS_INHIBITOR` as `0` so the first system call clears the inhibitor) and reset that count. Records beyond the per-block cap remain queued for subsequent blocks.
- From any other caller with calldata of exactly the contract's input size: the write path. The predeploy MUST validate the request and the value sent (see the request sections below), append one record to its queue, increment the per-block count, and emit the accepted request as an anonymous log (`LOG0`, no topics).
- From any other caller with empty calldata: the fee getter. The predeploy MUST return the current fee without modifying state, and MUST revert if any value is attached (preventing accidentally lost funds).
- Any other calldata size MUST revert.

The execution layer prepends the contract's request-type byte and includes `request_type ++ request_data` in the block requests list, committed via the `requests_hash` ([EIP-7685](./eip-7685.md)). The logs are informational only — the canonical flow of a request into the chain is the `requests_hash`.

The end-of-block system call to each predeploy follows the same rules [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) specify, restated here because [EIP-7685](./eip-7685.md) does not: the call is made as `SYSTEM_ADDRESS` with a dedicated gas limit of `30_000_000`; the gas it consumes does not count against the block gas limit and no value is transferred; and **if any of the predeploys' system calls fails or returns an error, the block MUST be invalid.**

### Request fee

Each request carries a fee, computed exactly as in [EIP-7002](./eip-7002.md):

```
fee = fake_exponential(MIN_REQUEST_FEE, excess, REQUEST_FEE_UPDATE_FRACTION)
```

where `fake_exponential` is the integer approximation of `MIN_REQUEST_FEE · e^(excess / REQUEST_FEE_UPDATE_FRACTION)` used by [EIP-1559](./eip-1559.md). Because `excess` grows whenever a block contains more than `TARGET_REQUESTS_PER_BLOCK` requests and decays otherwise, the fee rises super-linearly under sustained demand and returns to `MIN_REQUEST_FEE` when demand subsides. The fee is charged on top of any staked value (see the request sections below) and is left locked in the contract.

As in EIP-7002/EIP-7251, each contract's `excess` is initialized to `EXCESS_INHIBITOR` at deployment, and the fee getter reverts while `excess == EXCESS_INHIBITOR`. Since a request is only appended after its fee is paid, this blocks every request between deployment and the first end-of-block system call; that call clears the inhibitor (treating the prior `excess` as `0`), and normal fee operation runs from the activation block onward.

### Deposit requests

A deposit request is submitted by calling the deposit contract with calldata of exactly `184` bytes:

| Bytes | Field |
| --- | --- |
| `0:48` | `pubkey` — 48-byte BLS public key |
| `48:80` | `withdrawal_credentials` — 32-byte commitment (`version` byte + `execution_address`) |
| `80:88` | `amount` — big-endian `uint64`, in gwei ([EIP-7002](./eip-7002.md)'s input convention) |
| `88:184` | `signature` — 96-byte BLS proof-of-possession |

A deposit request serves both a builder's first deposit and subsequent top-ups. The contract MUST reject the request unless both of the following hold:

1. `amount * 1 gwei >= BUILDER_MIN_DEPOSIT`.
2. `msg.value >= fee`, where `fee` is the current request fee, **and** `msg.value - fee >= amount * 1 gwei` — the value beyond the fee fully funds the stake. Any value beyond `amount * 1 gwei + fee` is retained by the contract and not credited to the builder.

On success it MUST append the 184 input bytes to its queue and emit them as an anonymous log (which therefore carries the amount big-endian, as submitted). The dequeued `BUILDER_DEPOSIT_REQUEST_TYPE` record is `pubkey (48) ++ withdrawal_credentials (32) ++ amount (8, little-endian) ++ signature (96)`: the input verbatim, with the amount converted to its little-endian SSZ encoding, as [EIP-7002](./eip-7002.md) returns its amount. The `signature` is carried in the record and verified by the consensus layer, which checks the proof-of-possession only on the `pubkey`'s first appearance and treats a later deposit to an existing builder as a stake top-up (see [Consensus-layer processing of records](#consensus-layer-processing-of-records)).

### Exit requests

An exit request is submitted by calling the exit contract with calldata of exactly `48` bytes: the `pubkey` of the builder to exit. The contract MUST require `msg.value >= fee` (the same request fee as the deposit contract); it stakes no value and moves no ETH on the execution layer. On success it MUST append a `BUILDER_EXIT_REQUEST_TYPE` record of `source_address (20) ++ pubkey (48)` to its queue, where `source_address` is `msg.sender`, and emit the record as an anonymous log.

Authorization is by `source_address`, as in [EIP-7002](./eip-7002.md): the caller proves control of the builder by transacting from the builder's `execution_address`. The contract records `msg.sender` verbatim and performs no further check; the consensus layer honours the request only when `source_address` equals the target builder's `execution_address` (see [Consensus-layer processing of records](#consensus-layer-processing-of-records)).

### Consensus layer request objects

The consensus layer decodes each dequeued record into one of two SSZ containers, selected by request type:

```python
class BuilderDepositRequest(Container):
    pubkey: Bytes48
    withdrawal_credentials: Bytes32
    amount: uint64  # Gwei
    signature: Bytes96

class BuilderExitRequest(Container):
    source_address: Bytes20
    pubkey: Bytes48
```

A type's `request_data` is the concatenation of the fixed-size SSZ serializations of its records — 184 bytes per `BuilderDepositRequest` (`pubkey ++ withdrawal_credentials ++ amount ++ signature`) and 68 bytes per `BuilderExitRequest` (`source_address ++ pubkey`), with `amount` little-endian — exactly the bytes the system call returns, in the same order. `BuilderDepositRequest` is the validator [EIP-6110](./eip-6110.md) `DepositRequest` without the `index` field; the consensus layer verifies its `signature` (the proof-of-possession) on the builder's first registration.

### Consensus-layer processing of records

Both request types are applied immediately when processed — a `BuilderDepositRequest` is **not** routed through the validator `pending_deposits` queue, so a builder's balance is credited without an activation-churn queue, preserving EIP-7732's existing behavior. (A newly registered builder still becomes active for bidding and exit only once its deposit epoch is finalized, per Gloas `is_active_builder`; only the churn queue is skipped, not finality.)

- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **not** yet in the builder set is a first deposit, handled by Gloas `process_builder_deposit_request`. The consensus layer registers the builder if the proof-of-possession `signature` over the `DepositMessage` `(pubkey, withdrawal_credentials, amount)` under `DOMAIN_BUILDER_DEPOSIT` is valid (`is_valid_builder_deposit_signature`) — a builder-specific signing domain, distinct from the validator deposit's `DOMAIN_DEPOSIT` (see [Security Considerations](#security-considerations)). On a valid signature it adds the builder with `balance = amount`, `execution_address` = the credential's last 20 bytes (`withdrawal_credentials[12:]`), and `version = withdrawal_credentials[0]` — the first credential byte is recorded as the builder's *version* (the only currently defined value is `PAYLOAD_BUILDER_VERSION`, `0`), **not** checked against a fixed prefix. A record whose signature is invalid is ignored (consumed, stake forfeited). There is no on-chain credential-prefix check on this path: the `0xB0` `BUILDER_WITHDRAWAL_PREFIX` is used only to mark deposits for builder onboarding *at the fork* (see [Changes to EIP-7732](#changes-to-eip-7732)) and is deprecated afterward.
- A `BuilderDepositRequest` (type `0x03`) for a `pubkey` **already** in the builder set is a top-up: it credits `amount` to the existing entry, and the record's `withdrawal_credentials` and `signature` are ignored — the registration is unchanged. This mirrors the validator deposit contract, where the proof-of-possession is checked only on a pubkey's first appearance and later deposits are stake additions. A builder index is reclaimed only once the builder has exited and its balance has swept to zero (`get_index_for_new_builder`); until the index is reclaimed, a deposit to that **exited** `pubkey` is still a top-up, not a fresh registration. Per `process_builder_deposit_request`, the top-up always credits `amount` to the exited entry; and *only* if that entry has already swept to zero (`withdrawable_epoch != FAR_FUTURE_EPOCH` and `balance == 0`) does it additionally *reset* `withdrawable_epoch` to `current_epoch + MIN_BUILDER_WITHDRAWABILITY_DELAY`, re-arming the withdrawal delay on the newly credited balance and deferring index reclamation. A top-up to an exited builder that has **not yet** swept simply adds to the balance, which still sweeps at the already-scheduled `withdrawable_epoch`. It does **not** reactivate the builder for bidding (`is_active_builder` requires `withdrawable_epoch == FAR_FUTURE_EPOCH`); the stake ultimately sweeps to the entry's `execution_address`. Re-registering the key as a fresh builder requires waiting for its index to be recycled.
- A `BuilderExitRequest` (type `0x04`) is handled by Gloas `process_builder_exit_request` and MUST be ignored unless its `pubkey` is a registered, active builder (`is_active_builder`: its deposit epoch is finalized and it is not already exiting), its `source_address` equals that builder's `execution_address`, and the builder has no pending balance to withdraw (`get_pending_balance_to_withdraw_for_builder == 0`). When all hold it runs `initiate_builder_exit` (`withdrawable_epoch = current_epoch + MIN_BUILDER_WITHDRAWABILITY_DELAY`). Like EIP-7002's `process_withdrawal_request`, it authorizes by `source_address` (no BLS signature) and silently returns on any failed check — the record is **consumed and discarded, not re-queued**, and the fee is spent. There is no builder-version check on exit; the `execution_address`, fixed at registration, is the sole authorizer. Because an active builder routinely has a non-zero pending balance from recent bid payments, a legitimate exit may be dropped until those settle, in which case the caller must resubmit once the pending balance has been swept. (The execution layer dequeues the record deterministically regardless, so a dropped request never affects `requests_hash` agreement.)

### Changes to EIP-7732

This EIP modifies EIP-7732's builder lifecycle on the consensus layer:

- **Deposit routing.** Builder onboarding and top-ups move off the validator deposit flow. Gloas no longer overrides `process_deposit_request` — the former builder branch (the `apply_deposit_for_builder` path) is removed, so the function reverts to its validator-only [EIP-6110](./eip-6110.md) behavior — and builders are created and topped up **only** through `BUILDER_DEPOSIT_REQUEST_TYPE`, handled by the new `process_builder_deposit_request`. A consequence operators must heed: a deposit to the **validator** deposit contract is now always an ordinary validator deposit, even if its `withdrawal_credentials` carries the `0xB0` prefix. Such a deposit is queued in `pending_deposits` and mints a validator that cannot withdraw its balance (a `0xB0` credential is neither a BLS nor an execution withdrawal credential). Builder deposits MUST therefore be sent to the builder deposit contract.
- **Fork-transition onboarding (at the Gloas fork).** `onboard_builders_from_pending_deposits`, run once by `upgrade_to_gloas`, is retained: builder-credentialed deposits already in `pending_deposits` at the upgrade are onboarded as builders, so builders exist from the first slot of the fork. This is the **only** path that onboards builders through the validator deposit contract. Operators seed the initial set by depositing to the existing deposit contract with a `BUILDER_WITHDRAWAL_PREFIX` (`0xB0`) credential before the fork — late enough that the deposit is still pending at the upgrade (a deposit applied earlier would create a stranded validator). These seed deposits are validated under `DOMAIN_DEPOSIT` (the only domain the validator deposit contract signs for) by `is_valid_deposit_signature`, and each onboarded builder is recorded with `version = PAYLOAD_BUILDER_VERSION`. After the fork, `BUILDER_WITHDRAWAL_PREFIX` is deprecated; a `0xB0`-credentialed deposit that misses the snapshot is processed as the stranded validator above, so the operator must onboard through `BUILDER_DEPOSIT_REQUEST_TYPE` instead. No `pubkey` is onboarded by more than one path.
- **Exit routing.** Gloas no longer overrides `process_voluntary_exit` — its former builder branch is removed, making the voluntary-exit operation validator-only again — and builders exit only via `BUILDER_EXIT_REQUEST_TYPE`, handled by the new `process_builder_exit_request`.

## Rationale

- **Two predeploys, two request types.** Mirroring withdrawals (`0x01`) and consolidations (`0x02`) — each a single-type request predeploy — builder deposits (`0x03`) and exits (`0x04`) are separate predeploys sharing a common queue implementation. An empty-calldata `SYSTEM_ADDRESS` call returns a flat `request_data`, so the execution layer needs no new read semantics, and the consensus layer routes by request type rather than by inspecting credentials.

- **One request for deposits and top-ups.** A single deposit request serves both: a deposit to a new `pubkey` registers a builder (the consensus layer verifies the proof-of-possession), and a deposit to an existing builder tops up its stake — exactly as the validator deposit contract does. A top-up cannot redirect a builder's withdrawal target, because the consensus layer ignores the supplied `withdrawal_credentials` and `signature` for an existing builder; and a junk deposit to a new `pubkey` cannot register a builder without a valid proof-of-possession.

- **Exit by `execution_address`; voluntary exit becomes validator-only.** A builder's BLS key is hot — it signs bids continuously — so authorizing exit with that key is undesirable. Routing exit through the `execution_address` (the cold address that owns the builder's stake and receives its withdrawals) mirrors EIP-7002's rationale for letting `0x01` credentials trigger validator exits, and removing the builder branch from the voluntary-exit operation gives builders a single, well-defined exit authorizer. Losing the `execution_address` key strands no funds that were not already stranded: that address is where the builder's balance is swept regardless.

- **EIP-1559-style request fee.** Each request carries the same demand-responsive fee as EIP-7002/EIP-7251: super-linear above `TARGET_REQUESTS_PER_BLOCK`, decaying back to `MIN_REQUEST_FEE` when demand subsides. Together with the per-block cap and the per-deposit stake, the fee meters submission to each predeploy.

- **Onboarding via the fork transition.** Some applications depend on builders existing from the first slot of the fork. EIP-7732 already onboards builder-credentialed pending deposits during the fork upgrade; retaining that — rather than relying on post-fork deposits to the new contract, which cannot populate the first slot — keeps the initial builder set available immediately. This onboarding runs once, atomically, inside `upgrade_to_gloas`, so the per-block cap and request fee — which meter ongoing, adversarial submission to the steady-state contract — do not apply to it. Its cost is not constant-bounded: it processes the entire `pending_deposits` queue and verifies a proof-of-possession per new builder, which the consensus-layer spec notes may be slow and which clients SHOULD pre-verify and cache in the slots before the fork.

## Backwards Compatibility

This EIP is additive at the execution layer: it introduces new contracts at previously empty addresses. It does not modify the validator deposit contract at `0x00000000219ab540356cbb839cbe05303d7705fa`, the validator withdrawal/consolidation predeploys, or any existing validator's lifecycle.

At the consensus layer it modifies EIP-7732 (see [Changes to EIP-7732](#changes-to-eip-7732)): post-fork builder onboarding moves from the validator deposit request to `BUILDER_DEPOSIT_REQUEST_TYPE`, and builder exits move from the voluntary-exit operation to `BUILDER_EXIT_REQUEST_TYPE`. The fork-transition onboarding of builder-credentialed pending deposits is unchanged, so builders present at the fork are unaffected. The new request types are additive — blocks that contain no builder requests produce empty `request_data` for these types, which [EIP-7685](./eip-7685.md) excludes from the `requests_hash`.

## Reference Implementation

<!-- TODO: Add test cases and reference implementation -->

## Security Considerations

- **Deposit proof-of-possession at the consensus layer.** The consensus layer verifies the proof-of-possession over the `DepositMessage` `(pubkey, withdrawal_credentials, amount)` under `DOMAIN_BUILDER_DEPOSIT` on a builder's first registration, and ignores the signature for top-ups. The per-block cap bounds how many such verifications the consensus layer performs per block; see *Spam and state growth* below for the full anti-abuse picture.
- **Cross-class deposit signatures.** Builder deposits are signed under `DOMAIN_BUILDER_DEPOSIT`, a signing domain distinct from the validator deposit's `DOMAIN_DEPOSIT`. The separate domain prevents cross-contract replay between the two deposit classes: a *validator* deposit proof-of-possession cannot be resubmitted as a builder deposit, and a *builder* deposit proof-of-possession cannot be resubmitted to the validator deposit contract — each contract's consensus-layer handler verifies only its own domain, so the two classes cannot cross-register. The single exception is fork-transition onboarding: the initial builder set is seeded through the validator deposit contract *before* the fork, so those seed deposits are necessarily signed under `DOMAIN_DEPOSIT` and validated under it by `onboard_builders_from_pending_deposits`, with the `0xB0` `BUILDER_WITHDRAWAL_PREFIX` on the credential distinguishing them for builder onboarding; after the fork the prefix is deprecated and steady-state builder deposits use `DOMAIN_BUILDER_DEPOSIT`. Like `DOMAIN_DEPOSIT`, the builder domain is chain- and fork-agnostic, so a builder's *own* public proof-of-possession remains replayable as a top-up (see *Replayable deposit records* below) — but only within the builder class, funding stake the original signer already authorized, and it can redirect nothing.
- **Exit authorization.** The exit contract records `msg.sender` as `source_address` and performs no further check. Because the request carries no signature, this is the sole authorization: the consensus layer MUST initiate an exit only when `source_address` equals the target builder's `execution_address`, or an arbitrary caller could exit a builder it does not control. A builder's only exit authorizer is therefore its `execution_address`; the voluntary-exit (BLS-key) path is removed for builders.
- **Custodial-split exit standoff.** A builder's exit precondition requires its pending balance to be zero (`get_pending_balance_to_withdraw_for_builder == 0`), every winning bid adds a pending payment, and the `execution_address` is the builder's sole exit authorizer (the BLS voluntary-exit path is removed). When the `execution_address` (the capital owner) and the BLS key (the bidding operator) are held by different parties — a custodial or staking-pool arrangement this design explicitly enables — the operator can keep the pending balance non-zero by continuing to win bids, so the capital owner cannot satisfy the exit precondition and the stake stays locked (a builder that never exits is never swept). The standoff is self-limiting, since the operator's bids must keep being included on-chain, but the protocol gives the `execution_address` holder no on-chain lever to halt bidding. Parties delegating builder operation SHOULD retain off-chain (contractual or operational) control over the operator's bidding, so a delegated builder can always be brought to a state in which it can exit.
- **Same public key as validator and builder.** Because the registries are keyed by independent request types, one public key may exist as both a validator and a builder. The two are distinct entries with distinct indices and distinct lifecycles; neither request type can act on the other registry. There is no shared-slashing or cross-registry safety concern. The only implementation consideration is that builder indices are **reusable** — an exited builder's index may later be reassigned to a different key (`process_builder_deposit_request` notes this) — so clients that cache builder state by index MUST account for reuse.
- **Replayable deposit records.** A deposit's `(pubkey, withdrawal_credentials, amount, signature)` is public in calldata, so a third party can submit a further `0x03` record for an already-registered builder at an arbitrary amount (funding it themselves). The consensus layer treats any `0x03` record for an already-registered `pubkey` as a top-up — crediting stake but ignoring the credentials and signature — so the replay cannot redirect a builder's withdrawals or re-register it; it is a harmless funded stake addition.
- **Spam and state growth.** The per-block cap bounds only the drain rate — the consensus-layer verifications and the `request_data` size per block — not enqueue: within a block, appends are limited only by gas, and the in-state queue grows across blocks, reclaiming slots only when it fully drains. Queue growth is instead gated by the value locked per record: every deposit locks at least `BUILDER_MIN_DEPOSIT` (1 ETH) plus the fee, so growing the queue by N records costs at least N ETH locked. A griefer submitting **valid** proofs-of-possession forfeits nothing — the stake becomes a real, withdrawable builder balance (a capital-lock for `MIN_BUILDER_WITHDRAWABILITY_DELAY`, not a burn) — so post-fork onboarding can be throttled behind a FIFO wall of attacker deposits for the cost of locking capital; the cap plus FIFO ordering, not the fee, is the binding throttle. This is tolerable because the time-critical initial builder set is seeded before the fork through the uncapped onboarding path, not through the steady-state contract.
- **Locked funds.** The request fee, any overpayment or sub-gwei remainder, and the principal of a first deposit the consensus layer rejects for an invalid proof-of-possession are permanently locked in the predeploy (which has no withdrawal path) and irrecoverable by anyone, including an honest depositor who submits a bad signature, since the execution layer does not verify BLS and the consensus-layer rejection is silent. This mirrors EIP-7002/EIP-7251; submitters SHOULD verify the proof-of-possession off-chain before broadcasting. (As in those contracts, the fee getter reverts when value is attached, so a mistaken value-bearing fee query cannot lose funds.) `BUILDER_MIN_DEPOSIT` is enforced only at the execution layer (as the validator deposit contract enforces its own minimum), with no consensus-layer re-assertion.
- **System-read access control and per-block cap.** Only `SYSTEM_ADDRESS` may invoke the end-of-block dequeue; any other empty-calldata call is the fee getter and does not modify state, so a non-system caller cannot drain or replay the queue. Each contract returns at most `MAX_REQUESTS_PER_BLOCK` records per block, bounding both the size each predeploy contributes to the block requests and the consensus-layer work to process them; excess records remain queued for later blocks.
- **Validator-contract co-existence.** The validator deposit contract and the validator request predeploys are unmodified; this EIP changes only EIP-7732's builder onboarding and exit routing (see [Changes to EIP-7732](#changes-to-eip-7732)).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
