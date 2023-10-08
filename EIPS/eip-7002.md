---
eip: 7002
title: Execution layer triggerable exits
description: Allows validators to trigger exits via their execution layer (0x01) withdrawal credentials
author: Danny Ryan (@djrtwo), Mikhail Kalinin (@mkalinin), Ansgar Dietrichs (@adietrichs), Hsiao-Wei Wang (@hwwhww)
discussions-to: https://ethereum-magicians.org/t/eip-7002-execution-layer-triggerable-exits/14195
status: Draft
type: Standards Track
category: Core
created: 2023-05-09
---

## Abstract

Adds a new *stateful* precompile that allows validators to trigger exits to the beacon chain from their execution layer (0x01) withdrawal credentials.

These new execution layer exit messages are appended to the execution layer block to reading by the consensus layer.

## Motivation

Validators have two keys -- an active key and a withdrawal credential. The active key takes the form of a BLS key, whereas the withdrawal credential can either be a BLS key (0x00) or an execution layer address (0x01). The active key is "hot", actively signing and performing validator duties, whereas the withdrawal credential can remain "cold", only performing limited operations in relation to withdrawing and ownership of the staked ETH. Due to this security relationship, the withdrawal credential ultimately is the key that owns the staked ETH and any rewards. 

As currently specified, only the active key can initiate a validator exit. This means that in any non-standard custody relationships (i.e. active key is separate entity from withdrawal credentials), that the ultimate owner of the funds -- the possessor of the withdrawal credentials -- cannot independently choose to exit and begin the withdrawal process. This leads to either trust issues (e.g. ETH can be "held hostage" by the active key owner) or insufficient work-arounds such as pre-signed exits. Additionally, in the event that active keys are lost, a user should still be able to recover their funds by using their cold withdrawal credentials.

To ensure that the withdrawal credentials (owned by both EOAs and smart contracts) can trustlessly control the destiny of the staked ETH, this specification enables exits triggerable by 0x01 withdrawal credentials.

Note, 0x00 withdrawal credentials can be changed into 0x01 withdrawal credentials with a one-time signed message. Thus any functionality enabled for 0x01 credentials is defacto enabled for 0x00 credentials.

## Specification

### Constants

| Name | Value | Comment |
| - | - | - |
|`FORK_TIMESTAMP` | *TBD* | Mainnet |

### Configuration

| Name | Value | Comment |
| - | - | - |
| `VALIDATOR_EXIT_PRECOMPILE_ADDRESS` | *TBD* | Where to call and store relevant details about exit mechanism |
| `EXCESS_EXITS_STORAGE_SLOT` | 0 | |
| `EXIT_COUNT_STORAGE_SLOT` | 1 | |
| `EXIT_MESSAGE_QUEUE_HEAD_STORAGE_SLOT` | 2 | Pointer to head of the exit message queue |
| `EXIT_MESSAGE_QUEUE_TAIL_STORAGE_SLOT` | 3 | Pointer to the tail of the exit message queue|
| `EXIT_MESSAGE_QUEUE_STORAGE_OFFSET` | 4 | The start memory slot of the in-state exit message queue|
| `MAX_EXITS_PER_BLOCK` | 16 | Maximum number of exits that can be dequeued into a block |
| `TARGET_EXITS_PER_BLOCK` | 2 | |
| `MIN_EXIT_FEE` | 1 | |
| `EXIT_FEE_UPDATE_FRACTION` | 17 | | 
| `EXCESS_RETURN_GAS_STIPEND` | 2300 | |

### Execution layer

#### Definitions

* **`FORK_BLOCK`** -- the first block in a blockchain with the `timestamp` greater or equal to `FORK_TIMESTAMP`.

#### Exit operation

The new exit operation consists of the following fields:

1. `source_address: Bytes20`
2. `validator_pubkey: Bytes48`

RLP encoding of an exit **MUST** be computed as the following:

```python
rlp_encoded_exit = RLP([
    source_address,
    validator_pubkey,
])
```

#### Validator Exit precompile

The precompile requires a single `48` byte input, aliased to `validator_pubkey`.

`CALL`s to `VALIDATOR_EXIT_PRECOMPILE_ADDRESS` perform the following:

* Ensure enough ETH was sent to cover the current exit fee (`check_exit_fee()`)
* Increase exit count by 1 for the current block (`increment_exit_count()`)
* Insert an exit into the queue for the source address and validator pubkey (`insert_exit_to_queue()`)
* Return any unspent ETH in excess of the exit fee with an `EXCESS_RETURN_GAS_STIPEND` gas stipend (`return_excess_payment()`)

Specifically, the functionality is defined in pseudocode as the function `trigger_exit()`:

```python
###################
# Public function #
###################

def trigger_exit(Bytes48: validator_pubkey):
    check_exit_fee(msg.value)
    increment_exit_count()
    insert_exit_to_queue(msg.sender, validator_pubkey)
    return_excess_payment(msg.value)

###################
# Primary Helpers #
###################

def check_exit_fee(int: fee_sent):
    exit_fee = get_exit_fee()
    require(fee_sent >= exit_fee, 'Insufficient exit fee')
    # Note: consider mapping `MIN_EXIT_FEE` -> 0 fee

def insert_exit_to_queue(address: source_address, Bytes48: validator_pubkey):
    queue_tail_index = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_TAIL_STORAGE_SLOT)
    # Each exit takes 3 storage slots: 1 for source_address, 2 for validator_pubkey
    queue_storage_slot = EXIT_MESSAGE_QUEUE_STORAGE_OFFSET + queue_tail_index * 3
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot, source_address)
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot + 1, validator_pubkey[0:32])
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot + 2, validator_pubkey[32:48])
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_TAIL_STORAGE_SLOT, queue_tail_index + 1)

def increment_exit_count():
    exit_count = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_COUNT_STORAGE_SLOT)
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_COUNT_STORAGE_SLOT, exit_count + 1)
    
def return_excess_payment(int: fee_sent, address: source_address):
    excess_payment = fee_sent - get_exit_fee()
    if excess_payment > 0:
        (bool sent, bytes memory data) = source_address.call{value: excess_payment, gas: EXCESS_RETURN_GAS_STIPEND}("")
        require(sent, "Failed to return excess fee payment")

######################
# Additional Helpers #
######################
        
def get_exit_fee() -> int:
    excess_exits = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXCESS_EXITS_STORAGE_SLOT)
    return fake_exponential(
        MIN_EXIT_FEE,
        excess_exits,
        EXIT_FEE_UPDATE_FRACTION
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

##### Gas cost

TBD

Once functionality is reviewed and solidified, we'll estimate the cost of running the above computations fully in the EVM, and then potentially apply some discount due to reduced EVM overhead of being able to execute the above logic natively.

#### Block structure

Beginning with the `FORK_BLOCK`, the block body **MUST** be appended with a list of exit operations. RLP encoding of the extended block body structure **MUST** be computed as follows:

```python
block_body_rlp = RLP([
    field_0,
    ...,
    # Latest block body field before `exits`
    field_n,
    
    [exit_0, ..., exit_k],
])
```

Beginning with the `FORK_BLOCK`, the block header **MUST** be appended with the new **`exits_root`** field. The value of this field is the trie root committing to the list of exits in the block body. **`exits_root`** field value **MUST** be computed as follows:

```python
def compute_trie_root_from_indexed_data(data):
    trie = Trie.from([(i, obj) for i, obj in enumerate(data)])
    return trie.root

block.header.exits_root = compute_trie_root_from_indexed_data(block.body.exits)
```

#### Block validity

Beginning with the `FORK_BLOCK`, client software **MUST** extend block validity rule set with the following conditions:

1. Value of **`exits_root`** block header field equals to the trie root committing to the list of exit operations contained in the block. To illustrate:

```python
def compute_trie_root_from_indexed_data(data):
    trie = Trie.from([(i, obj) for i, obj in enumerate(data)])
    return trie.root

assert block.header.exits_root == compute_trie_root_from_indexed_data(block.body.exits)
```

2. The list of exit operations contained in the block body **MUST** be equivalent to list of exits at the head of the exit precompile's exit message queue up to the maximum of `MAX_EXITS_PER_BLOCK`, respecting the order in the queue. This validation **MUST** be run after all transactions in the current block are processed and **MUST** be run before per-block precompile storage calculations (i.e. a call to `update_exit_precompile()`) are performed. To illustrate:

```python
class ValidatorExit(object):
    source_address: Bytes20
    validator_pubkey: Bytes48

queue_head_index = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_HEAD_STORAGE_SLOT)
queue_tail_index = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_TAIL_STORAGE_SLOT)
num_exits_in_queue = queue_tail_index - queue_head_index
num_exits_to_dequeue = min(num_exits_in_queue, MAX_EXITS_PER_BLOCK)

# Retrieve exits from the queue
expected_exits = []
for i in range(num_exits_to_dequeue):
    queue_storage_slot = EXIT_MESSAGE_QUEUE_STORAGE_OFFSET + (queue_head_index + i) * 2
    source_address = address(SLOAD(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot)[0:20]
    validator_pubkey = (
        SLOAD(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot + 1) + SLOAD(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot + 1)
        + SLOAD(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot + 1) + SLOAD(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, queue_storage_slot + 1)[0:16]
    )
    exit = ValidatorExit(
        source_address=Bytes20(source_address),
        validator_pubkey=Bytes48(validator_pubkey),
    )
    expected_exits.append(exit)

# Compare retrieved exits to the list in the block body
assert block.body.exits == expected_exits
```

A block that does not satisfy the above conditions **MUST** be deemed invalid.

#### Block processing

##### Per-block precompile storage calculations

At the end of processing any execution block where `block.timestamp >= FORK_TIMESTAMP` (i.e. after processing all transactions and after performing the block body exit validations):

* The exit precompile's exit queue is updated based on exits dequeued and the exit queue head/tail are reset if the queue has been cleared (`update_exit_queue()`)
* The exit precompile’s excess exits are updated based on usage in the current block (`update_excess_exits()`)
* The exit precompile's exit count is reset to 0 (`reset_exit_count()`)

Specifically, the functionality is defined in pseudocode as the function `update_exit_precompile()`:

```python
###################
# Public function #
###################

def update_exit_precompile():
    update_exit_queue()
    update_excess_exits()
    reset_exit_count()
    
###########
# Helpers #
###########

def update_exit_queue():
    queue_head_index = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_HEAD_STORAGE_SLOT)
    queue_tail_index = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_TAIL_STORAGE_SLOT)
    
    num_exits_in_queue = queue_tail_index - queue_head_index
    num_exits_dequeued = min(num_exits_in_queue, MAX_EXITS_PER_BLOCK)
    new_queue_head_index = queue_head_index + num_exits_dequeued
    if new_queue_head_index == queue_tail_index:
        # Queue is empty, reset queue pointers
        sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_HEAD_STORAGE_SLOT, 0)
        sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_TAIL_STORAGE_SLOT, 0)
    else:
        sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_MESSAGE_QUEUE_HEAD_STORAGE_SLOT, new_queue_head_index)

def update_excess_exits():
    previous_excess_exits = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXCESS_EXITS_STORAGE_SLOT)
    exit_count = sload(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_COUNT_STORAGE_SLOT)

    new_excess_exits = 0
    if previous_excess_exits + exit_count > TARGET_EXITS_PER_BLOCK:
        new_excess_exits = previous_excess_exits + exit_count - TARGET_EXITS_PER_BLOCK
    
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXCESS_EXITS_STORAGE_SLOT, new_excess_exits)
    
def reset_exit_count():
    sstore(VALIDATOR_EXIT_PRECOMPILE_ADDRESS, EXIT_COUNT_STORAGE_SLOT, 0)
```


### Consensus layer

<!-- TODO: ref to the merged commit of PR https://github.com/ethereum/consensus-specs/pull/3349 -->

Sketch of spec:

* New operation `ExecutionLayerExit`
* Will show up in `ExecutionPayload` as an SSZ List bound by length `MAX_EXITS_PER_BLOCK`
* New function in `process_execution_layer_exit` that has similar functionality to `process_voluntary_exit` but that can fail validations (e.g. validator is already exited) without the block failing (similar to deposit coming from EL)
* `process_execution_layer_exit` called in `process_operations` for each `ExecutionLayerExit` found in the `ExecutionPayload`

## Rationale

### Stateful precompile

<!-- TODO: explicitly list what parts of that mechanism will be more future proof vs malleable (more of an implementation) -->

This specification utilizes a *stateful* precompile for simplicity and future-proofness. While precompiles are a well-known quantity, none to date have associated EVM state at the address.

The alternative designs are (1) to utilize a precompile or opcode for the functionality and write a separate specified space in the EVM -- e.g. `0xFF..FF` -- or (2) to place the required state into the block and require the previous block header as an input into the state transition function (e.g. like [EIP-1559](./eip-1559.md) `base_fee`).

Alternative design (1) is essentially using a stateful precompile but dissociating the state into a separate address. At first glance, this split appears unnecessarily convoluted when we could store the location of the `CALL` and the associated state in the same address. That said, there might be unexpected engineering constraints around precompiles in existing clients that make this a preferable path.

Alternative design (2) has two main drawbacks. The first is that with the message queue contains an unbounded amount of state (as opposed to simple the `base_fee` in the similar EIP-1559 design). Additionally, even if the state was constrained to a single variable or two, this design pattern reinforces that the Ethereum state transition function signature be more than `f(pre_state, block) -> post_state` by putting another dependency on the `pre_block_header`. These additional dependencies hinder the elegance of future stateless designs. Providing these dependencies within the EVM state as specified, allows for them to show up naturally in block witnesses.

### `validator_pubkey` field

<!-- TODO: re-work this now that 4788 is shipping in Cancun -->

Multiple validators can utilize the same execution layer withdrawal credential, thus the `validator_pubkey` field is utilized to disambiguate which validator is being exited.

Note, `validator_index` also disambiguates validators but is not used because the execution-layer cannot currently trustlessly ascertain this value.

### Exit message queue

The exit precompile maintains and in-state queue of exit messages to be dequeued each block into the block and thus into the execution layer.

The number of exits that can be passed into the consensus layer are bound by `MAX_EXITS_PER_BLOCK` to bound the load both on the block size as well as on the consensus layer processing. `16` has been chosen for `MAX_EXITS_PER_BLOCK` to be in line with the bounds of similar operations on the beacon chain -- e.g. `VoluntaryExit` and `Deposit`.

Although there is a maximum number of exits that can passed to the consensus layer each block, the execution layer gas limit can provide for far more calls to the exit precompile at each block. The queue then allows for these calls to successfully be made while still maintaining a system rate limit.

The alternative design considered was to have calls to the exit precompile fail after `MAX_EXITS_PER_BLOCK` successful calls were made within the context of a single block. This would eliminate the need for the message queue, but would come at the cost of a bad UX of precompile call failures in times of high exiting. The complexity to mitigate this bad UX is relatively low and is currently favored.

### Utilizing `CALL` to return excess payment

Calls to the exit precompile require a fee payment defined by the current state of the precompile. Smart contracts can easily perform a read/calculation to pay the precise fee, whereas EOAs will likely need to compute and send some amount over the current fee at time of signing the transaction. This will result in EOAs having fee payment overages in the normal case. These should be returned to the caller.

There are two potential designs to return excess fee payments to the caller (1) use an EVM `CALL` with some gas stipend or (2) have special functionality to allow the precompile to "credit" the caller's account with the excess fee.

Option (1) has been selected in the current specification because it utilizes less exceptional functionality and is likely simpler to implement and ensure correctness. The current version sends a gas stipen of 2300. This is following the (outdated) solidity pattern primarily to simplify precompile gas accounting (allowing it to be a fixed instead of dynamic cost). The `CALL` could forward the maximum allowed gas but would then require the cost of the precompile to be dynamic.

Option (2) utilizes custom logic (exceptional to base EVM logic) to credit the excess back to the callers balance. This would potentially simplify concerns around precompile gas costs/metering, but at the cost of non-standard EVM complexity. We are open to this path, but want to solicit more input before writing it into the speficiation.

### Rate limiting using exit fee

Transactions are naturally rate-limited in the execution layer via the gas limit, but an adversary willing to pay market-rate gas fees (and potentially utilize builder markets to pay for front-of-block transaction inclusion) can fill up the exit operation limits for relatively cheap, thus griefing honest validators that want to exit.

There are two general approaches to combat this griefing -- (a) only allow validators to send such messages and with a limit per time period or (b) utilize an economic method to make such griefing increasingly costly.

Method (a) (not used in this EIP) would require [EIP-4788](./eip-4788.md) (the `BEACON_ROOT` opcode) against which to prove withdrawal credentials in relation to validator pubkeys as well as a data-structure to track exits per-unit-time (e.g. 4 months) to ensure that a validator cannot grief the mechanism by submitting many exits. The downsides of this method are that it requires another cross-layer EIP and that it is of higher cross-layer complexity (e.g. care that might need to be taken in future upgrades if, for example, the shape of the merkle tree of `BEACON_ROOT` changes, then the exit precompile and proof structure might need to be updated).

Method (b) has been utilized in this EIP to eliminate additional EIP requirements and to reduce cross-layer complexity to allow for correctness of this EIP (now and in the future) to be easier to analyze. The EIP-1559-style mechanism with a dynamically adjusting fee mechanism allows for users to pay `MIN_EXIT_FEE` for exits in the normal case (fewer than 2 per block on average), but scales the fee up exponentially in response to high usage (i.e. potential abuse).

### `TARGET_EXITS_PER_BLOCK` configuration value

`TARGET_EXITS_PER_BLOCK` has been selected as `2` such that even if all ETH is staked (~120M ETH -> 3.75M validators), the 64 validator per epoch target (`2 * 32 slots`) still exceeds the per-epoch exit churn limit on the consensus layer (defined by `get_validator_churn_limit()`) at such values -- 57 validators per epoch (`3.75M // 65536`).

### Exit fee update rule

The exit fee update rule is intended to approximate the formula `exit_fee = MIN_EXIT_FEE * e**(excess_exits / EXIT_FEE_UPDATE_FRACTION)`,
where `excess_exits` is the total "extra" amount of exits that the chain has processed relative to the "targeted" number (`TARGET_EXITS_PER_BLOCK` per block).

Like EIP-1559, it’s a self-correcting formula: as the excess goes higher, the `exit_fee` increases exponentially, reducing usage and eventually forcing the excess back down.

The block-by-block behavior is roughly as follows. If block `N` processes `X` exits, then at the end of block `N` `excess_exits` increases by `X - TARGET_EXITS_PER_BLOCK`, and so the `exit_fee` in block `N+1` increases by a factor of `e**((X - TARGET_EXITS_PER_BLOCK) / EXIT_FEE_UPDATE_FRACTION)`. Hence, it has a similar effect to the existing EIP-1559, but is more "stable" in the sense that it responds in the same way to the same total exits regardless of how they are distributed over time.

The parameter `EXIT_FEE_UPDATE_FRACTION` controls the maximum downwards rate of change of the blob gas price. It is chosen to target a maximum downwards change rate of `e(TARGET_EXITS_PER_BLOCK / EXIT_FEE_UPDATE_FRACTION) ≈ 1.125` per block. The maximum upwards change per block is `e((MAX_EXITS_PER_BLOCK - TARGET_EXITS_PER_BLOCK) / EXIT_FEE_UPDATE_FRACTION) ≈ 2.279`.

### Exits inside of the block

Exits are placed into the actual body of the block (and execution payload in the consensus layer).

There is a strong design requirement that the consensus layer and execution layer can execute independently of each other. This means, in this case, that the consensus layer cannot rely upon a synchronous call to the execution layer to get the required exits for the current block. Instead, the exits must be embedded in the shared data-structure of the execution payload such that if the execution layer is offline, the consensus layer still has the requisite data to fully execute the consensus portion of the state transition function.

## Backwards Compatibility

This EIP introduces backwards incompatible changes to the block structure and block validation rule set. But neither of these changes break anything related to current user activity and experience.

## Security Considerations

### Impact on existing custody relationships

There might be existing custody relationships and/or products that rely upon the assumption that the withdrawal credentials *cannot* trigger exits. We are currently confident that the additional withdrawal credentials feature does not impact the security of existing validators because:

1. The withdrawal credentials ultimately own the funds so allowing them to exit staking is natural with respect to ownership.
2. We are currently not aware of any such custody relationships and/or products that do rely on the lack of this feature.

In the event that existing validators/custodians rely on this, then the validators can be exited and restaked utilizing 0x01 withdrawal credentials pointing to a smart contract that simulates this behaviour.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
