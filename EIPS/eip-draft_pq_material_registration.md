---
title: Post-Quantum Material Registration
description: Execution layer triggered registration of opaque post-quantum material for validators in the beacon state
author: Potuz (@potuz)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-11-02
requires: 7002, 7251, 7685, 7732
---

## Abstract

This EIP adds an [EIP-7685](./eip-7685.md) request type and a predeploy contract with which the execution address in a validator's withdrawal credentials can commit 32 bytes of opaque post-quantum (PQ) material for that validator. The consensus layer stores one `(validator_index, pq_data)` pair per validator in the beacon state. A later request from the same owner overwrites the earlier one. This EIP gives the 32 bytes no meaning. A future fork that migrates Ethereum consensus to post-quantum signatures will define how they are used, for example as a commitment to a hash-based public key and the data needed to verify messages signed with it.

## Motivation

The BLS signatures used by Ethereum consensus are not secure against a sufficiently capable quantum computer. Once such an adversary is credible, a BLS signature no longer proves that a message came from the validator's owner. That includes any message that would announce a new post-quantum key. A migration is only safe if every validator has committed to its post-quantum material *before* BLS is considered broken, through a channel whose authenticity does not depend on BLS.

The execution address in a validator's withdrawal credentials provides such a channel today. It is the owner of the validator's funds, and [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) already let it act on the validator through execution layer requests. This EIP adds one more such request. It lets owners start registering post-quantum commitments now, long before the migration fork, while leaving the design of that fork completely open.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

#### Execution layer

| Name | Value | Comment |
| - | - | - |
| `PQ_REGISTRATION_REQUEST_TYPE` | `0x06` | The [EIP-7685](./eip-7685.md) type prefix for PQ registration requests (provisional, see below) |
| `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS` | `TBD` | Where to call and store relevant details about the PQ registration request mechanism |
| `SYSTEM_ADDRESS` | `0xfffffffffffffffffffffffffffffffffffffffe` | Address used to invoke system operation on contract |
| `EXCESS_PQ_REGISTRATION_REQUESTS_STORAGE_SLOT` | `0` | |
| `PQ_REGISTRATION_REQUEST_COUNT_STORAGE_SLOT` | `1` | |
| `PQ_REGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT` | `2` | Pointer to the head of the PQ registration request message queue |
| `PQ_REGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT` | `3` | Pointer to the tail of the PQ registration request message queue |
| `PQ_REGISTRATION_REQUEST_QUEUE_STORAGE_OFFSET` | `4` | The start memory slot of the in-state PQ registration request message queue |
| `MAX_PQ_REGISTRATION_REQUESTS_PER_BLOCK` | `16` | Maximum number of PQ registration requests that can be dequeued into a block |
| `TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK` | `8` | |
| `MIN_PQ_REGISTRATION_REQUEST_FEE` | `1` | |
| `PQ_REGISTRATION_REQUEST_FEE_UPDATE_FRACTION` | `17` | |
| `EXCESS_INHIBITOR` | `2**256-1` | Excess value that blocks requests before activation and while the queue is disabled |

The request type value MUST be unique across all active [EIP-7685](./eip-7685.md) request types. `0x00` through `0x02` are used by Electra. `0x03` and `0x04` are the builder request types of [EIP-8282](./eip-8282.md). `0x05` is claimed by the draft proposals [EIP-8148](./eip-8148.md) and [EIP-8205](./eip-8205.md). `0x06` is the first value not claimed by any proposal. The final value is coordinated in consensus-specs together with any other request types scheduled for the same fork.

#### Consensus layer

| Name | Value |
| - | - |
| `PQ_REGISTRATION_REQUEST_TYPE` | `Bytes1('0x06')` |
| `MAX_PQ_REGISTRATION_REQUESTS_PER_PAYLOAD` | `Uint64(2**4)` (= 16) |

### Execution layer

#### PQ registration request

The new PQ registration request is an [EIP-7685](./eip-7685.md) request with type `PQ_REGISTRATION_REQUEST_TYPE` consisting of the following fields:

1. `source_address`: `Bytes20`
2. `validator_pubkey`: `Bytes48`
3. `pq_data`: `Bytes32`

The [EIP-7685](./eip-7685.md) encoding of a PQ registration request is as follows. The encoded request value is exactly what the contract returns.

```python
request_type = PQ_REGISTRATION_REQUEST_TYPE
request_data = dequeue_pq_registration_requests()
```

Each record is 100 bytes (`source_address ++ validator_pubkey ++ pq_data`), and `request_data` is the concatenation of all dequeued records in queue order. This is exactly the concatenation of the fixed-size SSZ serializations of the consensus layer `PQRegistrationRequest` containers, in the same order.

#### PQ registration request contract

The contract has the same queue design and storage layout as the [EIP-7251](./eip-7251.md) consolidation request contract, with the two modifications of the [EIP-8282](./eip-8282.md) builder request contracts: the fee charged on each write already accounts for the requests added earlier in the same block, and a system call with non-empty calldata disables the queue. There is no Solidity-compatible ABI. The contract dispatches on the caller and on `calldatasize` alone, through three code paths:

1. Add PQ registration request: a call from any address other than `SYSTEM_ADDRESS` with exactly `80` bytes of calldata.
2. Fee getter: a call from any address other than `SYSTEM_ADDRESS` with empty calldata returns the current fee.
3. System process: a call from `SYSTEM_ADDRESS` dequeues the PQ registration requests for the current block.

Calls that match none of these cases MUST revert.

The `80` byte input of a PQ registration request is:

| Bytes | Field | Description |
| - | - | - |
| `0:48` | `validator_pubkey` | 48-byte BLS public key of the validator |
| `48:80` | `pq_data` | 32 bytes of opaque post-quantum material |

The contract records `msg.sender` as `source_address` and performs no further check. In particular, it does not check that the public key belongs to a validator or that `msg.sender` controls it. The consensus layer honors the request only when `source_address` equals the execution address in the validator's withdrawal credentials.

##### Add PQ registration request

If the call data input to the contract is exactly `80` bytes, perform the following:

1. Ensure enough ETH was sent to cover the current PQ registration request fee (`msg.value >= get_fee()`)
2. Increase the PQ registration request count by `1` for the current block (`increment_count()`)
3. Insert a PQ registration request into the queue for the source address, validator public key and PQ data (`insert_pq_registration_request_into_queue()`)
4. Emit the accepted 100-byte record as an anonymous log (`LOG0`)

Specifically, the functionality is defined in pseudocode as the function `add_pq_registration_request()`:

```python
def add_pq_registration_request(Bytes48: validator_pubkey, Bytes32: pq_data):
    """
    Add PQ registration request adds a new request to the PQ registration request queue,
    so long as a sufficient fee is provided.
    """

    # Verify sufficient fee was provided.
    fee = get_fee()
    require(msg.value >= fee, 'Insufficient value for fee')

    # Increment PQ registration request count.
    count = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_COUNT_STORAGE_SLOT)
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_COUNT_STORAGE_SLOT, count + 1)

    # Insert into queue.
    queue_tail_index = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT)
    queue_storage_slot = PQ_REGISTRATION_REQUEST_QUEUE_STORAGE_OFFSET + queue_tail_index * 4
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot, msg.sender)
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 1, validator_pubkey[0:32])
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 2, validator_pubkey[32:48] ++ pq_data[0:16])
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 3, pq_data[16:32])
    log0(msg.sender ++ validator_pubkey ++ pq_data)
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT, queue_tail_index + 1)
```

###### Fee calculation

The following pseudocode computes the cost of an individual PQ registration request, given a certain number of excess PQ registration requests.

```python
def get_fee() -> int:
    excess = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PQ_REGISTRATION_REQUESTS_STORAGE_SLOT)
    require(excess != EXCESS_INHIBITOR, 'Inhibitor active')

    # Account for the requests already added in the current block.
    count = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_COUNT_STORAGE_SLOT)
    if count > TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK:
        excess += count - TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK

    return fake_exponential(
        MIN_PQ_REGISTRATION_REQUEST_FEE,
        excess,
        PQ_REGISTRATION_REQUEST_FEE_UPDATE_FRACTION
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

Unlike [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md), and as in [EIP-8282](./eip-8282.md), `get_fee()` adds the requests submitted earlier in the current block above `TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK` to the persisted `excess`. The fee therefore rises within a block as soon as the target is exceeded, rather than only from the next block. The fee, and any value sent above it, is left locked in the contract.

##### Fee getter

When the input to the contract is length zero and the caller is not `SYSTEM_ADDRESS`, interpret this as a get request for the current fee, i.e. the contract returns the result of `get_fee()`. The call MUST carry no value. A value-bearing fee getter call reverts.

##### System call

At the end of processing any execution block where this EIP is active (i.e. after processing all transactions), call `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS` as `SYSTEM_ADDRESS` with no calldata. The invocation triggers the following:

* The contract's queue is updated based on the PQ registration requests dequeued, and the queue head/tail are reset if the queue has been cleared (`dequeue_pq_registration_requests()`)
* The contract's excess PQ registration requests are updated based on usage in the current block (`update_excess_pq_registration_requests()`)
* The contract's PQ registration request count is reset to `0` (`reset_pq_registration_requests_count()`)

Each PQ registration request MUST appear in the [EIP-7685](./eip-7685.md) requests list in the exact order returned by `dequeue_pq_registration_requests()`.

A system call with non-empty calldata dequeues requests as usual but then stores `EXCESS_INHIBITOR` into the excess slot, disabling the queue: subsequent PQ registration requests and fee getter calls revert. The next system call with empty calldata resets the excess to zero and re-enables the queue. Under this EIP the system call is always made with empty calldata, so this path is unused. It is reserved for the future fork that consumes the registered material, which can use it to stop accepting registrations.

Additionally, the system call and the processing of that block MUST conform to the following:

* The call has a dedicated gas limit of `30_000_000`.
* Gas consumed by this call does not count against the block's overall gas usage.
* Both the gas limit assigned to the call and the gas consumed are excluded from any checks against the block's gas limit.
* The call does not follow [EIP-1559](./eip-1559.md) fee burn semantics: no value is transferred as part of this call.
* If there is no code at `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS`, the corresponding block **MUST** be marked invalid.
* If the call to the contract fails or returns an error, the block **MUST** be invalidated.

The functionality triggered by the system call is defined in pseudocode as the function `process_pq_registration_requests()`:

```python
###################
# Public function #
###################

def process_pq_registration_requests(calldata: bytes):
    reqs = dequeue_pq_registration_requests()
    update_excess_pq_registration_requests(calldata)
    reset_pq_registration_requests_count()
    return ssz.serialize(reqs)

###########
# Helpers #
###########

class PQRegistrationRequest(object):
    source_address: Bytes20
    validator_pubkey: Bytes48
    pq_data: Bytes32

def dequeue_pq_registration_requests():
    queue_head_index = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT)
    queue_tail_index = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT)
    num_in_queue = queue_tail_index - queue_head_index
    num_dequeued = min(num_in_queue, MAX_PQ_REGISTRATION_REQUESTS_PER_BLOCK)

    reqs = []
    for i in range(num_dequeued):
        queue_storage_slot = PQ_REGISTRATION_REQUEST_QUEUE_STORAGE_OFFSET + (queue_head_index + i) * 4
        source_address = address(sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot)[0:20])
        validator_pubkey = (
            sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 1)[0:32]
            + sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 2)[0:16]
        )
        pq_data = (
            sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 2)[16:32]
            + sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, queue_storage_slot + 3)[0:16]
        )
        req = PQRegistrationRequest(
            source_address=Bytes20(source_address),
            validator_pubkey=Bytes48(validator_pubkey),
            pq_data=Bytes32(pq_data)
        )
        reqs.append(req)

    new_queue_head_index = queue_head_index + num_dequeued
    if new_queue_head_index == queue_tail_index:
        # Queue is empty, reset queue pointers
        sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT, 0)
        sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_TAIL_STORAGE_SLOT, 0)
    else:
        sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_QUEUE_HEAD_STORAGE_SLOT, new_queue_head_index)

    return reqs

def update_excess_pq_registration_requests(calldata: bytes):
    # Any calldata disables the queue
    if len(calldata) > 0:
        sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PQ_REGISTRATION_REQUESTS_STORAGE_SLOT, EXCESS_INHIBITOR)
        return

    previous_excess = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PQ_REGISTRATION_REQUESTS_STORAGE_SLOT)
    count = sload(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_COUNT_STORAGE_SLOT)

    new_excess = 0
    # If the inhibitor is set (first system call after activation, or the queue
    # was disabled), the excess is reset to 0, enabling the queue
    if previous_excess != EXCESS_INHIBITOR and previous_excess + count > TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK:
        new_excess = previous_excess + count - TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK

    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, EXCESS_PQ_REGISTRATION_REQUESTS_STORAGE_SLOT, new_excess)

def reset_pq_registration_requests_count():
    sstore(PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS, PQ_REGISTRATION_REQUEST_COUNT_STORAGE_SLOT, 0)
```

##### Bytecode

The contract is written in geas assembly. The source is available in [`main.eas`](../assets/eip-draft_pq_material_registration/main.eas) (which includes [`fake_expo.eas`](../assets/eip-draft_pq_material_registration/fake_expo.eas)) and the constructor in [`ctor.eas`](../assets/eip-draft_pq_material_registration/ctor.eas). The fee-computation path and the system-call excess update are identical to the [EIP-8282](./eip-8282.md) builder exit contract, and the queue read and write paths are identical to the [EIP-7251](./eip-7251.md) consolidation request contract, apart from constants: the input size (`0x50`), the record size (`0x64`), `TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK` (`0x08`) and `MAX_PQ_REGISTRATION_REQUESTS_PER_BLOCK` (`0x10`).

Runtime bytecode:

```
0x3373fffffffffffffffffffffffffffffffffffffffe1460e9575f54807fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff146101d85760015460088111605157506057565b60089003015b601190600182026001905f5b5f821115607e57810190830284830290049160010191906063565b909390049250505036605014609e57366101d857346101d8575f5260205ff35b34106101d857600154600101600155600354806004026004013381556001015f358155600101602035815560010160403590553360601b5f5260505f60143760645fa0600101600355005b6003546002548082038060101160fd575060105b5f5b81811461013f5782810160040260040181606402815460601b815260140181600101548152602001816002015481526020019060030154905260010160ff565b9101809214610151579060025561015c565b90505f6002555f6003555b366101aa575f54600154817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff14610198576008828201116101a0575b50505f6101cc565b01600890036101cc565b7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5b5f555f6001556064025ff35b5f5ffd
```

Init code (sets `EXCESS_INHIBITOR` and returns the runtime code):

```
0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5f556101dc80602d5f395ff33373fffffffffffffffffffffffffffffffffffffffe1460e9575f54807fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff146101d85760015460088111605157506057565b60089003015b601190600182026001905f5b5f821115607e57810190830284830290049160010191906063565b909390049250505036605014609e57366101d857346101d8575f5260205ff35b34106101d857600154600101600155600354806004026004013381556001015f358155600101602035815560010160403590553360601b5f5260505f60143760645fa0600101600355005b6003546002548082038060101160fd575060105b5f5b81811461013f5782810160040260040181606402815460601b815260140181600101548152602001816002015481526020019060030154905260010160ff565b9101809214610151579060025561015c565b90505f6002555f6003555b366101aa575f54600154817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff14610198576008828201116101a0575b50505f6101cc565b01600890036101cc565b7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5b5f555f6001556064025ff35b5f5ffd
```

##### Deployment

TBD. The contract will be deployed before the fork through the [EIP-7997](./eip-7997.md) `CREATE2` factory, and `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS` will be fixed once the salt is chosen. If there is no code at `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS` once this EIP is active, every block from activation onward MUST be invalid.

### Consensus layer

The minimum consensus layer changes are sketched below against the [EIP-7732](./eip-7732.md) (Gloas) specification. Under EIP-7732, execution requests are no longer part of the beacon block body. A payload's requests are carried in `ExecutionPayloadEnvelope.execution_requests`, committed to by the `execution_requests_root` of the builder's bid, and applied to the beacon state by `apply_parent_execution_payload` when the child block is processed. Adding a field to `ExecutionRequests` is therefore enough to carry the new request type through the envelope, the bid commitment and the child block.

#### New containers

```python
class PQRegistrationRequest(Container):
    source_address: ExecutionAddress
    validator_pubkey: BLSPubkey
    pq_data: Bytes32

class PQRegistration(Container):
    validator_index: ValidatorIndex
    pq_data: Bytes32
```

The SSZ serialization of `PQRegistrationRequest` is the 100-byte record returned by the contract.

#### New types

```python
class PQRegistrationRequests(ProgressiveList[PQRegistrationRequest]):
    """
    The PQ registration requests pertaining to a single execution payload.
    """

class PQRegistrations(ProgressiveList[PQRegistration]):
    """
    The registered PQ material, at most one entry per validator.
    """
```

#### Modified containers

`ExecutionRequests` is extended with a new field:

```python
class ExecutionRequests(ProgressiveContainer):
    ...
    pq_registrations: PQRegistrationRequests  # [New in EIP-XXXX]
```

`BeaconState` is extended with a new field:

```python
class BeaconState(ProgressiveContainer):
    ...
    pq_registrations: PQRegistrations  # [New in EIP-XXXX]
```

The field is initialized to an empty list at the fork.

#### Modified `get_execution_requests_list`

The pair `(PQ_REGISTRATION_REQUEST_TYPE, execution_requests.pq_registrations)` is appended to the list of request types, and the execution requests parsing in the honest validator guide is extended accordingly.

#### Modified `apply_parent_execution_payload`

The number of PQ registration requests is bounded together with the other request types:

```python
assert len(requests.pq_registrations) <= MAX_PQ_REGISTRATION_REQUESTS_PER_PAYLOAD
```

and they are processed after the existing request types:

```python
    for_ops(requests.deposits, process_deposit_request)
    for_ops(requests.withdrawals, process_withdrawal_request)
    for_ops(requests.consolidations, process_consolidation_request)
    for_ops(requests.builder_deposits, process_builder_deposit_request)
    for_ops(requests.builder_exits, process_builder_exit_request)
    # [New in EIP-XXXX]
    for_ops(requests.pq_registrations, process_pq_registration_request)
```

#### New `process_pq_registration_request`

```python
def process_pq_registration_request(
    state: BeaconState,
    pq_registration_request: PQRegistrationRequest,
) -> None:
    # Verify the validator exists
    validator_pubkeys = [v.pubkey for v in state.validators]
    request_pubkey = pq_registration_request.validator_pubkey
    if request_pubkey not in validator_pubkeys:
        return
    validator_index = ValidatorIndex(validator_pubkeys.index(request_pubkey))
    validator = state.validators[validator_index]

    # Verify the request comes from the validator's withdrawal address
    has_correct_credential = has_execution_withdrawal_credential(validator)
    is_correct_source_address = (
        validator.withdrawal_credentials[12:] == pq_registration_request.source_address
    )
    if not (has_correct_credential and is_correct_source_address):
        return

    # Overwrite an existing registration for this validator
    for registration in state.pq_registrations:
        if registration.validator_index == validator_index:
            registration.pq_data = pq_registration_request.pq_data
            return

    # Otherwise append a new registration
    state.pq_registrations.append(
        PQRegistration(
            validator_index=validator_index,
            pq_data=pq_registration_request.pq_data,
        )
    )
```

Invalid requests are ignored. No validator status is checked: pending, active, exited and slashed validators can all register PQ material, as long as the request comes from their withdrawal address.

*Note*: The linear scan over `state.pq_registrations` is for specification clarity. Clients SHOULD maintain a cache mapping validator indices to positions in `state.pq_registrations`, as they already do for validator public keys.

## Rationale

### Opaque data keeps the design space open

This EIP deliberately does not specify a post-quantum signature scheme, a key format, or how the registered bytes will be checked. The 32 bytes only need to be enough to later authenticate a message signed by the owner of the PQ key. One way a future fork could use them:

1. The 32 bytes are a hash commitment to the validator's PQ material, for example a hash-based (XMSS or SPHINCS+ style) public key together with the public data of a post-quantum VRF.
2. At the migration fork, the very first message the validator signs with its PQ key reveals that material and is checked against the commitment.
3. Once verified, that message registers the full PQ public key, the VRF data and anything else needed to verify the validator's future messages. It could also register PQ-safe withdrawal credentials, through a mechanism decided at that fork.

Fixing a single 32-byte commitment now is enough for any scheme of this shape. Choosing the scheme, the parameters and the activation flow is left to the fork that actually needs them, when research on post-quantum signature aggregation, VRFs and key formats will have progressed.

### Execution layer requests instead of a BLS-signed consensus layer message

A consensus layer operation signed with the validator's BLS key could carry the same data. This EIP uses an execution layer request instead, for the following reasons:

- **Built-in DoS protection.** Every request pays gas and the [EIP-7002](./eip-7002.md) style dynamic fee, and the per-block maximum bounds the work in each block. A consensus layer operation would need its own gossip validation, inclusion limits and anti-spam rules.
- **Already implemented.** Consensus layer clients already process [EIP-7002](./eip-7002.md), [EIP-7251](./eip-7251.md) and [EIP-8282](./eip-8282.md) requests, and execution layer clients already run their system calls. The contract combines the [EIP-7251](./eip-7251.md) queue with the [EIP-8282](./eip-8282.md) fee and inhibitor logic, changing only constants, and the consensus layer change is a single request handler modeled on `process_consolidation_request`.
- **The owner of the funds is the right authority.** The withdrawal address owns the stake. The BLS key is often held by a node operator rather than the owner, and it is exactly the key that becomes untrustworthy once quantum attacks are credible. Binding the PQ material to the withdrawal address puts it under the control of the party who stands to lose the funds.
- **Simplicity.** No new signing domain, signature verification, gossip topic or beacon block operation is needed. The request travels in the existing `ExecutionRequests` container.
- **Flexibility.** Smart contract withdrawal addresses, such as those used by staking pools, can register material for many validators under arbitrary custom logic, including multisig or governance approval.

### Storing the data in the beacon state instead of an execution layer contract

The contract could simply keep the latest registration per validator in its own storage. However, the consumer of this data at the migration fork will be the consensus layer. Storing it in the beacon state means the consensus layer will have everything it needs at that fork without proofs against execution layer state or new cross-layer reads. The cost is at most 40 bytes per validator in the beacon state.

### Leaving future use unspecified

Specifying now how the bytes will be used would commit Ethereum to a post-quantum design years before it is needed. Keeping the bytes opaque means the migration fork can choose any scheme that can be committed to in 32 bytes. Validators who registered early lose nothing if the scheme changes. They can overwrite their registration with a new commitment.

### Replacing instead of dropping existing registrations

A later valid request for the same validator overwrites the earlier registration instead of being ignored. This lets owners correct mistakes, such as a wrong commitment or a lost PQ secret key, and rotate their PQ material before the migration fork. The authority to overwrite is the same as the authority to register, so allowing replacement does not weaken the authorization model.

### A separate list instead of a new `Validator` field

The PQ material is stored as `(validator_index, pq_data)` pairs in a new `BeaconState` list rather than as a new field of the `Validator` container. Adding a field to `Validator` would touch one of the most heavily used and cached structures in consensus clients. It would affect the hashing, serialization and memory layout of every validator, and every client's validator-registry caches and database schemas, for data that nothing reads until a later fork. A separate list keeps this fork's changes to a new request handler and one new state field.

The `Validator` container will have to change anyway at the migration fork, when the registered material is used to register the validator's PQ public key and related data. That fork can then move the data from `pq_registrations` into the new validator structure in a single migration and drop the list, so the validator layout is changed once and not twice.

### Public key in the request, index in the state

The request identifies the validator by its public key, as [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) requests do. This is the identifier owners and tooling already use, and it is unambiguous even if validator indices are reused in the future. The state stores the resolved `ValidatorIndex`, which is smaller than a public key.

### Validators with BLS withdrawal credentials

Validators with `0x00` (BLS) withdrawal credentials have no execution address and cannot register. They must first change to execution withdrawal credentials with a `BLSToExecutionChange`. This is the same requirement as in [EIP-7002](./eip-7002.md).

### Contract modifications from EIP-7251

The contract adopts the two modifications that the [EIP-8282](./eip-8282.md) builder request contracts make to the [EIP-7251](./eip-7251.md) design. Charging each write for the requests already added in the same block makes the fee respond immediately to a burst of submissions, instead of letting a single block absorb an unbounded number of requests at the previous block's price. The calldata-triggered inhibitor gives the migration fork a way to stop accepting registrations with no new predeploy and no change to the execution layer, by passing calldata to the existing system call.

### Parameter choices

Every validator is expected to register at least once before the migration fork, so throughput matters more than for consolidations. With `TARGET_PQ_REGISTRATION_REQUESTS_PER_BLOCK = 8`, about 57,600 registrations can be processed per day (at 7,200 blocks per day) at the minimum fee, and `MAX_PQ_REGISTRATION_REQUESTS_PER_BLOCK = 16` doubles that during bursts. Processing a request on the consensus layer requires no signature verification, only a public key lookup and a write, so these limits add negligible block processing cost.

## Backwards Compatibility

This EIP introduces backward incompatible changes to the block validation rule set and must be accompanied by a hard fork. On the execution layer it introduces a new contract at a previously empty address and a new request type. On the consensus layer it adds a field to `ExecutionRequests` and a field to `BeaconState`. Existing request types and validator flows are unchanged.

## Test Cases

TBD

## Reference Implementation

The contract source is available in [`main.eas`](../assets/eip-draft_pq_material_registration/main.eas), [`fake_expo.eas`](../assets/eip-draft_pq_material_registration/fake_expo.eas) and [`ctor.eas`](../assets/eip-draft_pq_material_registration/ctor.eas).

## Security Considerations

### Authorization by source address

The contract records `msg.sender` as `source_address` and performs no further check. The request carries no signature, so, as in [EIP-7002](./eip-7002.md), the consensus layer check that `source_address` matches the validator's execution withdrawal credentials is the only authorization. Without it, an arbitrary caller could overwrite any validator's PQ material.

### Ignored requests

A request for an unknown public key, for a validator with BLS withdrawal credentials, or from an address other than the validator's withdrawal address is dropped by the consensus layer rather than re-queued. The fee is not refunded. In particular, a request submitted before the validator's deposit has been processed by the consensus layer is ignored and must be resubmitted.

### Public PQ material

The `pq_data` is public: it appears in calldata, in the contract log and in the beacon state. It MUST therefore be a public value, such as a hash commitment to public keys, and never secret key material. A third party can resubmit a record it observed, but the resubmission carries the third party's own address as `source_address` and is ignored by the consensus layer.

### Compromised withdrawal address

Whoever controls the withdrawal address can register or overwrite the PQ material of its validators. This gives no new power to an attacker who controls the withdrawal address, since that attacker can already withdraw the entire stake. Owners SHOULD check their registered material in the beacon state before the migration fork.

### Overwriting before the migration fork

Because registrations can be replaced, the material that counts is the material registered when the migration fork activates. The future fork MAY decide to ignore requests processed after a certain point, for example to stop a withdrawal address that is compromised late from replacing the material.

### Fee overpayment

Calls to the system contract require a fee payment defined by the current contract state. Overpaid fees are not returned to the caller. It is not generally possible to compute the exact required fee ahead of time. When adding a PQ registration request from a contract, the contract can read the current fee first and then pay exactly that amount, as described in [EIP-7251](./eip-7251.md). Note that the system contract uses the `CALLER` opcode, so the address that calls it must be the execution address in the validator's withdrawal credentials.

### State growth

There is at most one entry per validator in `state.pq_registrations`, of 40 bytes each, so the list is bounded by the validator registry. With one million validators, the list is at most about 40 MB. Repeated registrations for the same validator overwrite rather than grow the list.

The per-block maximum bounds the drain rate, not the enqueue rate, so the execution layer queue can grow across blocks if requests are submitted faster than `MAX_PQ_REGISTRATION_REQUESTS_PER_BLOCK`. Growth is gated by the dynamic fee, which rises quickly while demand exceeds the target.

### Processing cost

Each request needs a public key lookup and a lookup in `state.pq_registrations`. With the caches recommended above both are constant-time, and the number of requests per payload is bounded by `MAX_PQ_REGISTRATION_REQUESTS_PER_PAYLOAD`.

### Validator index reuse

The state stores the validator index. If a future fork introduces validator index reuse, it MUST clear the `pq_registrations` entry of a reused index. Otherwise the new validator would inherit the previous validator's PQ material.

### System call failure

Although the likelihood of a failed system call to `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS` is extremely low, the behavior in such cases is well-defined: the block is marked as invalid. This follows [EIP-7002](./eip-7002.md#system-call-failure).

### Empty code failure

This EIP should not be activated if there is no code at `PQ_REGISTRATION_REQUEST_PREDEPLOY_ADDRESS`. This is similar to the consideration in [EIP-7002](./eip-7002.md#empty-code-failure).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
