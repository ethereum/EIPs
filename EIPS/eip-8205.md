---
eip: 8205
title: Withdrawal credentials preregistration
description: Bind a validator public key to withdrawal credentials before validator deposit via an EL system contract enforced by the CL
author: George Avsetsin (@avsetsin), Dmitry Gusakov (@dgusakov), Greg Koumoutsos (@gkoumout), Eugene Mamin (@TheDZhon)
discussions-to: https://ethereum-magicians.org/t/eip-8205-withdrawal-credentials-preregistration/28084
status: Draft
type: Standards Track
category: Core
created: 2026-03-26
requires: 6110, 7685, 7732
---

## Abstract

This EIP introduces a preregistration mechanism that allows a validator key holder to commit to specific withdrawal credentials before any validator deposit is made, addressing a known deposit front-running vulnerability in delegated staking. Preregistrations are submitted through a new [EIP-7685](./eip-7685.md) request contract on the execution layer, following the same queue, fee, and system-call pattern as [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md). The consensus layer stores the expirable preregistration in beacon state and enforces it at deposit processing time: matching deposits proceed and the preregistration is consumed; mismatched deposits are silently rejected. The mechanism is fully optional — deposits for public keys without a preregistration are processed exactly as today.

## Motivation

In delegated staking, the entity funding a validator and the entity generating the BLS keypair are distinct parties. This separation is common across liquid staking protocols, staking-as-a-service providers, and any arrangement where one party provides capital and another operates the validator. The BLS key is the validator's identity: the first deposit for a given pubkey establishes the withdrawal credentials permanently under first-deposit-wins semantics. The key holder can therefore submit a deposit with attacker-controlled withdrawal credentials before the funding party's deposit is processed. The funding party has no on-chain guarantee that the withdrawal credentials it intends will be honored.

At least a third of all staked ETH flows through delegated architectures with identifiable protocol-level protections against this attack. Since no on-chain mechanism exists to bind a public key to withdrawal credentials before the first deposit, every affected product has independently built application-layer defenses — bond-based pre-deposit schemes, guardian committees, or both. These defenses work (no known exploits have occurred in production), but each one is built, audited, and maintained independently, and new entrants are vulnerable by default until they do the same.

Preregistration addresses this at the protocol layer: the key holder signs a binding commitment to specific withdrawal credentials before any validator deposit is made, and the consensus layer enforces this commitment at deposit processing time.

For an extended analysis of the problem scope, existing application-layer defenses, and data sources, see the discussion thread linked in the header.

## Specification

### Configuration

#### Execution layer

| Name                                              | Value                                        | Comment                                                                      |
| ------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------- |
| `PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS`       | `TBD`                                        | Where to call and store relevant details about preregistration mechanism     |
| `PREREGISTRATION_REQUEST_TYPE`                    | `TBD`                                        | The [EIP-7685](./eip-7685.md) type prefix for preregistration request        |
| `SYSTEM_ADDRESS`                                  | `0xfffffffffffffffffffffffffffffffffffffffe` | Address used to invoke system operation on contract                          |
| `EXCESS_PREREGISTRATION_REQUESTS_STORAGE_SLOT`    | `0`                                          |                                                                              |
| `PREREGISTRATION_REQUEST_COUNT_STORAGE_SLOT`      | `1`                                          |                                                                              |
| `PREREGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT` | `2`                                          | Pointer to head of the preregistration request message queue                 |
| `PREREGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT` | `3`                                          | Pointer to the tail of the preregistration request message queue             |
| `PREREGISTRATION_REQUEST_QUEUE_STORAGE_OFFSET`    | `4`                                          | The start memory slot of the in-state preregistration request message queue  |
| `MAX_PREREGISTRATION_REQUESTS_PER_BLOCK`          | `4`                                          | Maximum number of preregistration requests that can be dequeued into a block |
| `TARGET_PREREGISTRATION_REQUESTS_PER_BLOCK`       | `1`                                          |                                                                              |
| `MIN_PREREGISTRATION_REQUEST_FEE`                 | `1`                                          |                                                                              |
| `PREREGISTRATION_REQUEST_FEE_UPDATE_FRACTION`     | `17`                                         |                                                                              |
| `EXCESS_INHIBITOR`                                | `2**256-1`                                   | Excess value that blocks requests before activation and while disabled       |

#### Consensus layer

| Name                                       | Value                       | Comment                                                |
| ------------------------------------------ | --------------------------- | ------------------------------------------------------ |
| `DOMAIN_PREREGISTRATION`                   | `DomainType('0x11000000')`  | Uses `GENESIS_FORK_VERSION` (stable across forks)      |
| `MAX_PREREGISTRATION_REQUESTS_PER_PAYLOAD` | `Uint64(2**2)` (= 4)        | Maximum preregistration requests per execution payload |
| `PREREGISTRATIONS_LIMIT`                   | `Uint64(2**19)` (= 524,288) | State-transition limit on active preregistrations      |
| `PREREGISTRATION_EXPIRY_SLOTS`             | `Slot(2**18)` (= 262,144)   | Lifetime in slots (~36 days at 12 seconds per slot)    |

### Execution layer

#### Definitions

- **`FORK_BLOCK`** — the first block in a blockchain after this EIP has been activated.

#### Preregistration request operation

The new preregistration request is an [EIP-7685](./eip-7685.md) request with type `PREREGISTRATION_REQUEST_TYPE` and consists of the following fields:

1. `pubkey`: `Bytes48`
2. `withdrawal_credentials`: `Bytes32`
3. `signature`: `Bytes96`

The [EIP-7685](./eip-7685.md) encoding of a preregistration request is computed as follows.

```python
request_type = PREREGISTRATION_REQUEST_TYPE
request_data = read_preregistration_requests()
```

Each serialized request record is 176 bytes (`pubkey ++ withdrawal_credentials ++ signature`), and `request_data` is the flat concatenation of all dequeued records in queue order.

#### Preregistration Request Contract

The contract has three different code paths, which can be summarized at a high level as follows:

1. System process - if called by system address, pop off the preregistration requests for the current block from the queue. If the call carries non-empty calldata, additionally disable the queue (see Rationale).
2. Add preregistration request - for any other caller, requires a `176` byte input, the validator's public key concatenated with withdrawal credentials and a BLS signature. An accepted request is emitted verbatim as an anonymous log (`LOG0`, no topics).
3. Fee getter - for any other caller, if the input length is zero, return the current fee required to add a preregistration request.

For non-system callers, any other input length MUST cause the call to revert.

##### Add Preregistration Request

If call data input to the contract is exactly `176` bytes, perform the following:

1. Ensure enough ETH was sent to cover the current preregistration request fee (`check_fee()`)
2. Increase preregistration request count by `1` for the current block (`increment_count()`)
3. Insert a preregistration request into the queue for the pubkey, withdrawal credentials, and signature (`insert_preregistration_request_into_queue()`)
4. Emit the accepted `pubkey ++ withdrawal_credentials ++ signature` request as an anonymous log

Specifically, the functionality is defined in pseudocode as the function `add_preregistration_request()`:

```python
def add_preregistration_request(Bytes48: pubkey, Bytes32: withdrawal_credentials,
                                Bytes96: signature):
    """
    Add preregistration request adds new request to the preregistration request queue,
    so long as a sufficient fee is provided.
    """

    # Verify sufficient fee was provided.
    fee = get_fee()
    require(msg.value >= fee, 'Insufficient value for fee')

    # Increment preregistration request count.
    count = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_COUNT_STORAGE_SLOT)
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_COUNT_STORAGE_SLOT, count + 1)

    # Insert into queue.
    queue_tail_index = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT)
    queue_storage_slot = PREREGISTRATION_REQUEST_QUEUE_STORAGE_OFFSET + queue_tail_index * 6
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot, pubkey[0:32])
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 1, pubkey[32:48] ++ withdrawal_credentials[0:16])
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 2, withdrawal_credentials[16:32] ++ signature[0:16])
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 3, signature[16:48])
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 4, signature[48:80])
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 5, signature[80:96])
    log0(pubkey ++ withdrawal_credentials ++ signature)
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT, queue_tail_index + 1)
```

###### Fee calculation

The following pseudocode can compute the cost of an individual preregistration request, given a certain number of excess preregistration requests.

```python
def get_fee() -> int:
    excess = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PREREGISTRATION_REQUESTS_STORAGE_SLOT)
    require(excess != EXCESS_INHIBITOR, 'Inhibitor still active')
    return fake_exponential(
        MIN_PREREGISTRATION_REQUEST_FEE,
        excess,
        PREREGISTRATION_REQUEST_FEE_UPDATE_FRACTION
    )

def fake_exponential(factor: int, numerator: int, denominator: int) -> int:
    i = 1
    output = 0
    numerator_accum = factor * denominator
    while numerator_accum > 0:
        output += numerator_accum
        numerator_accum = (numerator_accum * numerator) // (denominator * i)
        i += 1
    return output // denominator
```

As in [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md), `get_fee()` uses only the persisted `excess` value. It does not include requests accumulated in `count` during the current block. The end-of-block system call incorporates `count` into `excess`, so requests submitted in block `N` affect the fee starting in block `N + 1`.

##### Fee Getter

When the input to the contract is length zero and the caller is not `SYSTEM_ADDRESS`, interpret this as a get request for the current fee. The call MUST carry no value and returns the result of `get_fee()` without modifying state; a value-bearing fee getter call MUST revert.

##### System Call

At the end of processing any execution block starting from the `FORK_BLOCK`, call `PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS` as `SYSTEM_ADDRESS` with no calldata. The invocation triggers the following:

- The contract's queue is updated based on preregistration requests dequeued and the preregistration requests queue head/tail are reset if the queue has been cleared (`dequeue_preregistration_requests()`)
- The contract's excess preregistration requests are updated based on usage in the current block (`update_excess_preregistration_requests()`)
- The contract's preregistration requests count is reset to `0` (`reset_preregistration_requests_count()`)

Each preregistration request must appear in the [EIP-7685](./eip-7685.md) requests list in the exact order returned by `dequeue_preregistration_requests()`.

Additionally, the system call and the processing of that block must conform to the following:

- The call has a dedicated gas limit of `30_000_000`.
- Gas consumed by this call does not count against the block's overall gas usage.
- Both the gas limit assigned to the call and the gas consumed are excluded from any checks against the block's gas limit.
- The call does not follow [EIP-1559](./eip-1559.md) fee burn semantics — no value should be transferred as part of this call.
- If there is no code at `PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS`, the corresponding block **MUST** be marked invalid.
- If the call to the contract fails or returns an error, the block **MUST** be invalidated.

A system call with non-empty calldata dequeues requests as usual but then stores `EXCESS_INHIBITOR` into the excess slot, disabling the queue: subsequent preregistration requests revert until a system call with empty calldata re-enables it. Under this EIP the system call is always made with empty calldata, so this path is unreachable; it is reserved for a future upgrade (see Rationale).

The functionality triggered by the system call is defined in pseudocode as the function `read_preregistration_requests()`:

```python
###################
# Public function #
###################

def read_preregistration_requests():
    reqs = dequeue_preregistration_requests()
    update_excess_preregistration_requests()
    reset_preregistration_requests_count()
    return ssz.serialize(reqs)

###########
# Helpers #
###########

class PreregistrationRequest(object):
    pubkey: Bytes48
    withdrawal_credentials: Bytes32
    signature: Bytes96

def dequeue_preregistration_requests():
    queue_head_index = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT)
    queue_tail_index = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT)
    num_in_queue = queue_tail_index - queue_head_index
    num_dequeued = min(num_in_queue, MAX_PREREGISTRATION_REQUESTS_PER_BLOCK)

    reqs = []
    for i in range(num_dequeued):
        queue_storage_slot = PREREGISTRATION_REQUEST_QUEUE_STORAGE_OFFSET + (queue_head_index + i) * 6
        pubkey = (
            sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot)[0:32]
            + sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 1)[0:16]
        )
        withdrawal_credentials = (
            sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 1)[16:32]
            + sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 2)[0:16]
        )
        signature = (
            sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 2)[16:32]
            + sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 3)[0:32]
            + sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 4)[0:32]
            + sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 5)[0:16]
        )
        req = PreregistrationRequest(
            pubkey=Bytes48(pubkey),
            withdrawal_credentials=Bytes32(withdrawal_credentials),
            signature=Bytes96(signature)
        )
        reqs.append(req)

    new_queue_head_index = queue_head_index + num_dequeued
    if new_queue_head_index == queue_tail_index:
        # Queue is empty, reset queue pointers
        sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT, 0)
        sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT, 0)
    else:
        sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT, new_queue_head_index)

    return reqs

def update_excess_preregistration_requests():
    # A system call with non-empty calldata disables the queue (see Rationale)
    if len(msg.data) > 0:
        sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PREREGISTRATION_REQUESTS_STORAGE_SLOT, EXCESS_INHIBITOR)
        return

    previous_excess = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PREREGISTRATION_REQUESTS_STORAGE_SLOT)
    # Reset excess to 0 on the first system call after activation and when
    # re-enabling a disabled queue
    if previous_excess == EXCESS_INHIBITOR:
        previous_excess = 0

    count = sload(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_COUNT_STORAGE_SLOT)

    new_excess = 0
    if previous_excess + count > TARGET_PREREGISTRATION_REQUESTS_PER_BLOCK:
        new_excess = previous_excess + count - TARGET_PREREGISTRATION_REQUESTS_PER_BLOCK

    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PREREGISTRATION_REQUESTS_STORAGE_SLOT, new_excess)

def reset_preregistration_requests_count():
    sstore(PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PREREGISTRATION_REQUEST_COUNT_STORAGE_SLOT, 0)
```

##### Bytecode

TBD — the runtime bytecode will be provided with the reference implementation.

##### Deployment

TBD — the deterministic deployment transaction will be provided with the reference implementation.

### Consensus layer

A sketch of the key consensus layer changes is included below.

#### New types

```python
class PreregistrationRequests(ProgressiveList[PreregistrationRequest]):
    """The preregistration requests pertaining to a single execution payload."""

class ValidatorPreregistrations(ProgressiveList[StoredPreregistration]):
    """The stored preregistrations, including expired records not yet garbage-collected."""
```

#### New containers

```python
class ValidatorPreregistration(Container):
    pubkey: BLSPubkey                  # 48 bytes — the validator key being registered
    withdrawal_credentials: Bytes32    # 32 bytes — withdrawal credentials to lock in

class PreregistrationRequest(Container):
    pubkey: BLSPubkey                  # 48 bytes
    withdrawal_credentials: Bytes32    # 32 bytes
    signature: BLSSignature            # 96 bytes — BLS proof of key ownership

class StoredPreregistration(Container):
    pubkey: BLSPubkey
    withdrawal_credentials: Bytes32
    expiry_slot: Slot                  # absolute expiry slot, set when the preregistration is stored
```

#### Modified containers

`ExecutionRequests` is extended with a new field:

```python
preregistrations: PreregistrationRequests  # [New]
```

Preregistration requests are applied from `parent_execution_requests` after deposit requests — under [EIP-7732](./eip-7732.md), a payload's execution requests are carried in the next block and applied while processing it. The number of preregistration requests in a payload MUST NOT exceed `MAX_PREREGISTRATION_REQUESTS_PER_PAYLOAD`.

`BeaconState` is extended with a new field:

```python
validator_preregistrations: ValidatorPreregistrations  # [New]
```

#### Helper functions

```python
def get_stored_preregistration_index(state: BeaconState, pubkey: BLSPubkey) -> Optional[Uint64]:
    for index, pre_reg in enumerate(state.validator_preregistrations):
        if pre_reg.pubkey == pubkey:
            return Uint64(index)
    return None

def is_active_preregistration(state: BeaconState, pre_reg: StoredPreregistration) -> bool:
    # Activity is evaluated against the outstanding parent payload, whose
    # execution requests are the ones being applied during block processing
    parent_slot = state.latest_execution_payload_bid.slot
    return parent_slot < pre_reg.expiry_slot

def remove_stored_preregistration(state: BeaconState, pubkey: BLSPubkey) -> None:
    state.validator_preregistrations = ValidatorPreregistrations([
        pre_reg for pre_reg in state.validator_preregistrations
        if pre_reg.pubkey != pubkey
    ])

def is_pending_validator(pending_deposits: Sequence[PendingDeposit], pubkey: BLSPubkey) -> bool:
    for pending_deposit in pending_deposits:
        if pending_deposit.pubkey != pubkey:
            continue
        if is_valid_deposit_signature(
            pending_deposit.pubkey,
            pending_deposit.withdrawal_credentials,
            pending_deposit.amount,
            pending_deposit.signature,
        ):
            return True
    return False
```

_Note_: Clients SHOULD maintain a secondary index by pubkey for efficient lookup rather than performing a linear scan.

#### Process preregistration request

```python
def process_preregistration_request(
    state: BeaconState,
    preregistration_request: PreregistrationRequest,
) -> None:
    pubkey = preregistration_request.pubkey
    withdrawal_credentials = preregistration_request.withdrawal_credentials
    signature = preregistration_request.signature
    index = get_stored_preregistration_index(state, pubkey)

    # Reject if an active preregistration already exists for this pubkey
    if index is not None and is_active_preregistration(state, state.validator_preregistrations[index]):
        return

    # Reject if a validator with this pubkey already exists
    if pubkey in [v.pubkey for v in state.validators]:
        return

    # Reject if this pubkey already has a valid pending deposit
    if is_pending_validator(state.pending_deposits, pubkey):
        return

    # Reject if active records are at capacity. Only active records count, so
    # the timing of the garbage-collection sweep does not affect admission.
    # The check applies to appends and to replacements alike, since both
    # create an active binding
    active_count = len([
        pre_reg for pre_reg in state.validator_preregistrations
        if is_active_preregistration(state, pre_reg)
    ])
    if active_count >= PREREGISTRATIONS_LIMIT:
        return

    # Verify BLS signature: proof of key ownership.
    # Domain uses GENESIS_FORK_VERSION (fork_version=None default) + genesis_validators_root.
    preregistration = ValidatorPreregistration(
        pubkey=pubkey,
        withdrawal_credentials=withdrawal_credentials,
    )
    domain = compute_domain(
        DOMAIN_PREREGISTRATION,
        genesis_validators_root=state.genesis_validators_root,
    )
    signing_root = compute_signing_root(preregistration, domain)
    if not bls.Verify(pubkey, signing_root, signature):
        return

    stored = StoredPreregistration(
        pubkey=pubkey,
        withdrawal_credentials=withdrawal_credentials,
        expiry_slot=Slot(state.slot + PREREGISTRATION_EXPIRY_SLOTS),
    )
    if index is not None:
        # Replace the expired record in place
        state.validator_preregistrations[index] = stored
    else:
        state.validator_preregistrations.append(stored)
```

#### Modified deposit request ingestion

`process_deposit_request` ([EIP-6110](./eip-6110.md)) is modified to enforce preregistration constraints for validator deposits. Builder deposits use a separate request type and `process_builder_deposit_request`. When an active preregistration exists, the validator deposit is accepted only if both the withdrawal credentials match and the deposit BLS signature is valid. This early BLS check prevents an attacker from consuming a preregistration with an invalid-signature deposit (see Security Considerations).

```python
def process_deposit_request(
    state: BeaconState,
    deposit_request: DepositRequest,
) -> None:
    # Only an active binding is enforced; an expired record is ignored
    index = get_stored_preregistration_index(state, deposit_request.pubkey)
    if index is not None and is_active_preregistration(state, state.validator_preregistrations[index]):
        pre_reg = state.validator_preregistrations[index]
        if deposit_request.withdrawal_credentials != pre_reg.withdrawal_credentials:
            return  # Withdrawal credentials mismatch: reject
        if not is_valid_deposit_signature(
            deposit_request.pubkey,
            deposit_request.withdrawal_credentials,
            deposit_request.amount,
            deposit_request.signature,
        ):
            return  # Invalid BLS sig: reject, preserve preregistration
        remove_stored_preregistration(state, deposit_request.pubkey)

    state.pending_deposits.append(PendingDeposit(
        pubkey=deposit_request.pubkey,
        withdrawal_credentials=deposit_request.withdrawal_credentials,
        amount=deposit_request.amount,
        signature=deposit_request.signature,
        slot=state.slot,
    ))
```

The key invariant: **a valid pending new-validator deposit cannot coexist with an active preregistration for the same pubkey.** An invalid-signature `PendingDeposit` may coexist when it was queued before the preregistration and is ignored by normal pending-deposit processing. `apply_pending_deposit` requires no modifications.

#### Preregistration expiry

```python
def process_preregistration_expiry(state: BeaconState) -> None:
    state.validator_preregistrations = ValidatorPreregistrations([
        pre_reg for pre_reg in state.validator_preregistrations
        if is_active_preregistration(state, pre_reg)
    ])
```

The sweep runs during epoch processing (`process_epoch`) and is garbage collection only: once stored, a binding remains active for subsequently processed payloads whose slots are below its stored `expiry_slot`, even if the expired record remains stored until the next sweep (see Rationale).

## Rationale

### Enforcement at deposit ingestion

Invalid deposits are already silently ignored by the consensus layer if the signature is invalid. This EIP adds one optional validation condition: if an active preregistration exists for a pubkey, only deposits with matching withdrawal credentials and a valid BLS signature are accepted. Deposits with mismatched credentials or invalid signatures are treated as invalid and ignored. The check only applies to pubkeys with an active preregistration — all other deposits are processed as before.

### Permanent rejection of mismatched deposits

When a deposit's withdrawal credentials do not match an active preregistration, the deposit is silently rejected — the ETH remains in the Deposit Contract, which has no withdrawal function. This is a deliberate design choice: returning mismatched deposits would allow an attacker to front-run at no cost (deposit, get rejected, recover funds, repeat). Permanent loss makes front-running economically self-defeating.

The risk of accidental mismatch is low in practice. Preregistration requires a dedicated BLS signing step separate from deposit data. Staking protocols verify the preregistration on-chain via [EIP-4788](./eip-4788.md) before submitting deposits. At the current 12-second slot duration, preregistrations expire automatically after ~36 days if unused, freeing beacon state.

### System contract vs CL gossip

CL gossip has no economic cost — generating BLS keypairs is cheap (~2ms), and verification cost (~1.5ms per message) falls on every node, creating an asymmetry favoring an attacker. The EL system contract adds an [EIP-1559](./eip-1559.md)-style fee that starts at 1 wei and increases exponentially in response to sustained demand above the target rate. The fee update takes effect in the following block. Staking protocols can call the system contract directly from their own contracts.

### Expiry keyed to the outstanding payload slot

Expiry is enforced logically through `is_active_preregistration`, which compares the outstanding parent bid's slot against the stored `expiry_slot`, not against the slot in which the requests are applied. Under [EIP-7732](./eip-7732.md) a payload's requests are applied one block later, so this guarantees that a deposit is checked against the bindings that were active for the slot in which its payload was created. The comparison is strict: a payload at `expiry_slot` is no longer protected. The epoch-processing sweep is pure garbage collection: its timing does not affect whether a binding is enforced or a request is admitted. Consequently, an expired record may remain physically present until the next sweep and can be replaced by a new preregistration in place, subject to the active-capacity check.

The absolute deadline is computed once, when the preregistration is stored. This prevents a future change to `PREREGISTRATION_EXPIRY_SLOTS` from retroactively changing existing deadlines and makes the same window exactly verifiable on the execution layer without knowing the lifetime parameter, slot duration, or `SLOTS_PER_EPOCH`: a verification contract proves `expiry_slot` through [EIP-4788](./eip-4788.md) and requires the current [EIP-7843](./eip-7843.md) `SLOTNUM` to be below it, making the deposit atomically either protected or reverted. Expiry does not depend on finality and therefore continues while finality stalls. A binding that expires unused can be re-established by replaying the same signed message.

### Domain choice

`DOMAIN_PREREGISTRATION` uses `GENESIS_FORK_VERSION` (the default when no `fork_version` is passed to `compute_domain`), so a preregistration signed once is valid across all past and future forks. This allows signing on air-gapped hardware without knowledge of the current fork version. Chain separation is achieved via `genesis_validators_root`, which is an immutable per-chain constant.

A dedicated domain is used rather than reusing `DOMAIN_DEPOSIT` because `DOMAIN_DEPOSIT` does not include `genesis_validators_root`, meaning deposit-domain signatures can be replayed across chains.

### BLS verification on CL only

BLS verification happens on the CL, not in the EL system contract. The signing domain includes `genesis_validators_root`, and the CL must perform semantic validation before storing the preregistration. Repeating the verification on the EL would duplicate that work, so the system contract acts only as a rate-limited queue. Submission is permissionless, and the BLS signature is the sole authorization mechanism. Invalid signatures are silently discarded by the CL, costing only the system contract fee.

### Disabling the queue

A system call with non-empty calldata stores `EXCESS_INHIBITOR` into the excess slot and thereby disables the queue; a later system call with empty calldata restores it, through the same code path that clears the inhibitor at activation. Under this EIP every system call is made with empty calldata, so the path is unreachable. It exists for a future upgrade that retires or suspends the contract: without it, once the protocol stops making the per-block system call, the contract would keep accepting requests and fees into a queue that never drains. The [EIP-8282](./eip-8282.md) builder request contracts' reference implementation uses the same mechanism.

### Parameter choices

`TARGET_PREREGISTRATION_REQUESTS_PER_BLOCK = 1` keeps the baseline fee minimal for an infrequent operation. `MAX_PREREGISTRATION_REQUESTS_PER_BLOCK = 4` allows up to four queued requests to be dequeued into each block; it does not cap the number of submissions accepted by the contract within a block.

`PREREGISTRATIONS_LIMIT = 524,288` (2^19) is chosen so that active capacity cannot be exhausted at the target rate. At 1 preregistration per block, accumulating 2^19 active entries takes ~72.8 days at 12 seconds per slot — well beyond the 2^18-slot expiry window (~36 days at 12 seconds per slot). In steady state at target rate, the active count stabilizes around 2^18 entries (~50% of the limit) as new arrivals are balanced by expiring entries. Sustained saturation requires an average rate above target, which causes `excess` to accumulate and the fee to grow exponentially — making prolonged spam economically prohibitive. Worst-case state size is ~46 MB of active records (88 bytes × 524,288 entries), plus bounded headroom for expired records awaiting the next epoch's sweep — at most `MAX_PREREGISTRATION_REQUESTS_PER_PAYLOAD × (SLOTS_PER_EPOCH − 1)` = 124 additional records.

### Deposit process for staking protocols

Protocols that already have their own defenses can adopt preregistration at their own pace, or not at all. For protocols that do adopt it, the intended flow is: the operator signs a preregistration, the protocol submits it to the system contract, verifies its presence in beacon state on-chain via an [EIP-4788](./eip-4788.md) Merkle proof, and submits the deposit. When the verification and the deposit are combined into a single transaction — using a shared verification contract, not part of this specification but provided separately as a reference implementation — no finality wait is needed: on any fork branch that lacks the preregistration, the proof fails and the transaction reverts. When verification is a separate transaction, the protocol MUST wait until a beacon state containing the preregistration is finalized before depositing. In both flows, the deposit transaction MUST revert unless the current [EIP-7843](./eip-7843.md) `SLOTNUM` is below the proven `expiry_slot`: an expired record may remain provable in beacon state until it is garbage-collected, while the consensus layer no longer enforces it.

## Backwards Compatibility

This EIP introduces backward-incompatible changes to the block structure and validation rules on both the consensus and execution layers, and must be scheduled with a hard fork.

**Execution layer**: a new system contract is deployed and a new [EIP-7685](./eip-7685.md) request type is introduced.

**Consensus layer**: the `ExecutionRequests` container and `BeaconState` are extended with new fields.

## Test Cases

TBD — test vectors will be provided with the reference implementation.

## Reference Implementation

TBD

## Security Considerations

### Impact on existing deposit workflows

Preregistration is fully optional. Without a preregistration for a given pubkey, deposits are processed exactly as today — the `first-deposit-wins` rule applies unchanged. Existing validators, top-up deposits, and non-delegated staking are entirely unaffected.

**Non-delegated staking** (solo stakers, exchanges, institutions) controls both funds and keys, so the front-running vulnerability does not apply. These stakers may optionally preregister, but gain no benefit from doing so.

**Bond-based protocols** that verify withdrawal credentials via [EIP-4788](./eip-4788.md) after a pre-deposit can adopt preregistration to skip the verification delay and avoid locking capital in the entry queue. Their existing flow continues to work without changes.

**Guardian-committee protocols** that rely on `depositRoot` snapshot signing would need to update their deposit flow. Preregistration replaces the guardian infrastructure with a protocol-level guarantee, eliminating `depositRoot` rotation attacks and committee liveness dependencies.

### Preregistration signature is permanent

The preregistration signature is fork-agnostic and does not expire cryptographically — only the on-chain record has a 262,144-slot validity window (~36 days at the current 12-second slot duration). Anyone who obtains a signed preregistration message can resubmit it at any time to re-establish the on-chain record after expiry. Once an operator signs a preregistration binding a pubkey to specific withdrawal credentials, that commitment is effectively permanent. The protocol does not restrict credential prefixes beyond the existing validator deposit rules, so operators must ensure that the selected credentials are supported by their intended withdrawal flow.

### Builder deposits

Preregistration applies only to validator deposits. Builder deposits ([EIP-8282](./eip-8282.md)) use an independent request type and registry: a preregistration may coexist with a builder for the same pubkey and is neither checked nor consumed by builder deposits. It MUST NOT be treated as authorization of a builder's execution address. In particular, preregistering `0xB0` withdrawal credentials does not register or protect a builder; submitted through the validator deposit path, matching `0xB0` credentials create a validator that cannot currently withdraw.

### Race between preregistration and deposit

If an attacker deposits for a pubkey before the preregistration is processed, the deposit creates a validator under `first-deposit-wins` and the preregistration is rejected. If both arrive in the same execution payload, deposits are processed before preregistrations, so the same outcome applies. Staking protocols detect this via [EIP-4788](./eip-4788.md): they MUST verify an active preregistration — both its presence in beacon state and its expiry deadline — atomically with the deposit. When verifying in a separate transaction instead, they MUST wait until its inclusion is finalized and enforce the deadline in the deposit transaction.

### Invalid-signature deposit attack

An adversary could attempt to strip preregistration protection by depositing with matching withdrawal credentials but an invalid BLS signature. This EIP prevents this attack by verifying the deposit's BLS signature in `process_deposit_request` before consuming the preregistration. Only deposits with both matching withdrawal credentials and a valid BLS signature can consume a preregistration. Invalid-signature deposits are silently rejected without affecting the preregistration.

### DoS and state growth

The [EIP-1559](./eip-1559.md)-style fee mechanism is the primary defense against sustained above-target spam. Every accepted submission in block `N` increments `count`, while all submissions in that block face the same required minimum fee computed from the `excess` stored before transaction processing. At the end of block `N`, the system call updates `excess` to `max(0, previous_excess + count − TARGET_PREREGISTRATION_REQUESTS_PER_BLOCK)`; the resulting fee, which approximates `e**(excess / 17)` wei, applies in block `N + 1`. Thus, a high-volume block does not increase the fee for later submissions in the same block, but it does increase the fee for requests in subsequent blocks. At a sustained rate of `n` accepted submissions per block where `n > 1`, `excess` grows by `n − 1` per block and the fee exceeds 1 ETH after roughly `17 × ln(10^18) / (n − 1)` blocks.

Under normal operation, the state list stays near zero (preregistrations consumed within hours). However, starting from zero `excess`, one accepted request per block keeps the fee at its minimum and can maintain approximately 2^18 active entries — about 23 MB of serialized records plus client overhead. The 524,288 active-entry limit is sized so that saturation requires a sustained rate above target — and therefore an exponentially growing fee.

At exactly the target rate, `excess` and the current fee do not decay. Maintaining an elevated `excess` still requires paying the elevated fee on every request; once demand falls below target, `excess` decays. The fee is a rate limiter, not a guarantee of low-cost availability.

### Censorship resistance

The 262,144-slot validity window (~36 days at 12 seconds per slot) is deliberately generous because the workflow spans preregistration, operational coordination, proof availability, and a deposit transaction. The lifetime is intentionally defined in slots, so a future slot-duration change changes its wall-clock duration without changing its consensus or contract interpretation. A much shorter window would make completion more sensitive to temporary censorship, congestion, or high fees; replaying the signature restarts that flow rather than eliminating it.

### Fee overpayment

The system contract does not refund excess fee payment. Callers should query the current fee via the fee getter (empty calldata) before submitting. This is the same behavior as [EIP-7002](./eip-7002.md).

### System call failure

If the system call to the preregistration contract fails for any reason, the block MUST be deemed invalid. This is the same consideration as in [EIP-7002](./eip-7002.md).

### Empty code failure

If there is no code at `PREREGISTRATION_REQUEST_PREDEPLOY_ADDRESS`, the block MUST be deemed invalid. This is the same consideration as in [EIP-7002](./eip-7002.md).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
