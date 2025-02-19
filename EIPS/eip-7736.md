---
eip: 7736
title: Leaf-level state expiry in verkle trees
description: Simple state expiry scheme in which only "extension-and-suffix trees" are expired.
author: Guillaume Ballet (@gballet), Wei Han Ng (@weiihann)
discussions-to: https://ethereum-magicians.org/t/eip-7736-leaf-level-state-expiry-in-verkle-trees/20474
status: Draft
type: Standards Track
category: Core
created: 2024-07-05
requires: 6800
---

## Abstract

Adds an "update epoch" to the verkle tree extension node. When it is time for an epoch to expire, the extension node and its suffix nodes can be deleted.

A new transaction type with a simple verkle proof pays for the costs of reactivating the extension and suffix nodes, and updating the epoch counter.

## Motivation

Previous attempts at implementing state expiry have been stalled by the quickly-increasing complexity, require heavy change in the structure of ethereum (address space extension, oil, multiple trees, ...). This proposal is offering a simpler albeit non-exhaustive approach to state expiry: only removing the leaf nodes and leaving the rest of the tree intact. This removes the need for methods that would be detrimental to the user and developer experience.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Constants

|Name|Description|Value|
|----|-----------|-----|
|`FORK_TIME`|Fork activation time|TBD|
|`EPOCH_LENGTH`|Duration of an epoch, in s|15778800 (6 months)|
|`INITIAL_EPOCH_COUNTER`|The epoch that ends at timestamp `FORK_TIME`|0|
|`NUM_ACTIVE_EPOCHS`|Number of concurrently unexpired epochs|2|
|`RESURRECT_TX_TYPE`|Type ID for resurrection transactions|TBD|

### Change to the verkle tree

Add an integral variable called `current_epoch`. It is initialized to `INITIAL_EPOCH_COUNTER` before the fork, and contains the current epoch number.

Add a new `last_epoch` field to the extension node:

```python
def extension_and_suffix_tree(stem: bytes31, values: Dict[byte, bytes32], last_epoch: int) -> int:
    sub_leaves = [0] * 512
    for suffix, value in values.items():
        sub_leaves[2 * suffix] = int.from_bytes(value[:16], 'little') + 2**128
        sub_leaves[2 * suffix + 1] = int.from_bytes(value[16:], 'little')
    C1 = compute_commitment_root(sub_leaves[:256])
    C2 = compute_commitment_root(sub_leaves[256:])
    return compute_commitment_root([1, # Extension marker
                                    int.from_bytes(stem, "little"),
                                    group_to_scalar_field(C1),
                                    group_to_scalar_field(C2),
                                    last_epoch] + # Added in this EIP
                                    [0] * 251)
```

The following rules are added to tree update operations:

 * For a read or write event to the tree, check that `current_epoch < last_epoch + NUM_ACTIVE_EPOCHS`.
     * If this is `true`, proceed with the write/read
     * Otherwise, revert.
 * `last_epoch` is updated with the value of `current_epoch` each time that a _write_ event is processed for this extension node.

### Expiry

At the start of block processing, before transactions are executed, run `check_epoch_end`:

```python
def check_epoch_end(block):
    if block.timestamp >= FORK_TIME + current_epoch * EPOCH_LENGTH:
        current_epoch = current_epoch + 1
        schedule_epiry(current_epoch-NUM_ACTIVE_EPOCHS)
```

It is left to client implementers to decide on the behavior of the `schedule_expiry` function.

Data that needs to be kept for the expiry:

 * the `stem` value, so that siblings can be inserted
 * The commitment `C` to the node

That data is referred to as the _keepsake_ for this extension-and-suffix node.

**Note**: that actual deletion may not happen before the first block in the epoch has finalized, unless there is a way for the client to recover the block in case of a reorg.

### Resurrection

The resurrection transaction is defined as follows:

`RESURRECT_TX_TYPE|ssz(Vector[stem,last_epoch,values])`

Where:

 * `stem` is used to find the location in the tree, so that the node can be recreated;
 * `last_epoch` and `values` are the items that were deleted;

At the start of the validation, charge the costs using constants defined in [EIP-4762](./eip-4762.md):

```python
def resurrect_gas_cost(values) -> int:
    return WITNESS_BRANCH_COST + 
            SUBTREE_EDIT_COST +
            sum(WITNESS_CHUNK_COST + CHUNK_EDIT_COST + CHUNK_FILL_COST for i in values)
```

Once the gas cost has been paid, the validation process begins:

```python
def validate_subtrees(tree, tx, current_epoch) -> bool:
    # The tx is a SSZ payload
    subtrees = deserialize_ssz(tx[1:])
    if subtrees == None:
        return false
    
    # Process all subtrees in the transaction
    for subtree in subtrees:
        ok = validate_subtree(tree, subtree.stem, subtree.values, subtree.last_epoch, current_epoch)
        if not ok:
            return false
        
    return true

def validate_subtree(tree, stem, values, last_epoch, current_epoch) -> bool:
    # Compute the commitment to the expired
    # tree, get the 
    expired_C = extension_and_suffix_tree(stem, values, last_epoch)
    expired = tree.get_keepsake(stem)
    if keepsake.C != expired_C:
        return false

    # Replace the keepsake with the resurrected
    # extension-and-suffix tree.
    new_C = extension_and_suffix_tree(stem, values, current_epoch)
    return tree.resurrect_subtree(stem, new_C, values, current_epoch) == None
```

where `resurrect_subtree` will return `None` upon success, and an error otherwise.

## Rationale

This approach has the benefit of simplicity, over previous proposals for state expiry:

* no Address Space Extension (ASE) required
* it only uses a single tree instead of multiple, per-epoch trees
* smaller resurrection proofs, as only providing the data is necessary to resurrect.
* clear gas costs
* only expire "cold" data, the "hot" data set remains active
* it is forward-compatible, as ASE or multiple trees are still possible.
* the exponentiation/addition computation for `current_epoch` need only be paid once per epoch, which is quickly amortized.

While it's not deleting _all_ the data, it deletes _most_ of it, namely the values and subcommitments, while retaining the ability to easily insert siblings.

It is also more expensive than resurrecting a single leaf, which is the cost paid for simplification.
    
The reason why only writes update the resurrection counter, is that any update to the resurrection counter has the effect of a write. Doing so would mean either:
    
 * Increasing the cost of a read to that of a write. This would increase the gas costs even more than they did in EIP-4762.
 * Effectively doing a write for the cost of a read. This would both neuter state expiry and possibly add a DOS vector.

## Backwards Compatibility

This proposal is backwards-compatible with verkle, as by default the value for the 4th (index starting at 0) evaluation point is set to `0` in [EIP-6800](./eip-6800.md), which is the value of `INITIAL_EPOCH_COUNTER`.

## Test Cases

TODO
    
## Reference Implementation

TODO

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
