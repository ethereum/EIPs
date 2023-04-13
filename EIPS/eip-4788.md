---
eip: 4788
title: Beacon block root in the EVM
description: Expose beacon chain roots in the EVM
author: Alex Stokes (@ralexstokes), Ansgar Dietrichs (@adietrichs), Danny Ryan (@djrtwo)
discussions-to: https://ethereum-magicians.org/t/eip-4788-beacon-root-in-evm/8281
status: Draft
type: Standards Track
category: Core
created: 2022-02-10
---

## Abstract

Commit to the hash tree root of each beacon chain block in the corresponding execution payload header.

Store each of these roots in a contract that lives in the execution state and add a new opcode that reads this contract.

## Motivation

Roots of the beacon chain blocks are crytographic accumulators that allow proofs of arbitrary consensus state. Exposing these roots inside the EVM allows for trust-minimized access to the consensus layer. This functionality supports a wide variety of use cases that improve trust assumptions of staking pools, restaking constructions, smart contract bridges, MEV mitigations and more.

## Specification

| constants                   | value                                        | units
|---                          |---                                           |---
| `FORK_TIMESTAMP`            | TBD                                          |
| `HISTORY_STORAGE_ADDRESS`   | `0xfffffffffffffffffffffffffffffffffffffffd` |
| `OPCODE_VALUE`              | `0x48`                                       |
| `G_beacon_root`             | 20                                           | gas
| `SLOTS_PER_HISTORICAL_ROOT` | 8192                                         | slot(s)

### Background

The high-level idea is that each execution block contains the parent beacon block root. Even in the event of missed slots since the previous block root does not change,
we only need a constant amount of space to represent this "oracle" in each execution block. To improve the usability of this oracle, block roots are stored
in a canonical place in the execution state analogous to a `SSTORE` in given contract's storage for each update. Roots are stored keyed by the slot(s) they pertain to.
To bound the amount of storage this construction consumes, a ring buffer is used that mirrors a block root accumulator on the consensus layer.
The method for exposing the root data via opcode is inspired by [EIP-2935](./eip-2935.md).

### Block structure and validity

Beginning at the execution timestamp `FORK_TIMESTAMP`, execution clients **MUST**:

1. set 32 bytes of the execution block header after the `withdrawals_root` to the 32 byte [hash tree root](https://github.com/ethereum/consensus-specs/blob/fa09d896484bbe240334fa21ffaa454bafe5842e/ssz/simple-serialize.md#merkleization) of the parent beacon block.

*NOTE*: this field is appended to the current block header structure with this EIP so that the size of the header grows after (and including) the `FORK_TIMESTAMP`.

### EVM changes

#### Block processing

At the start of processing any execution block where `block.timestamp >= FORK_TIMESTAMP` (i.e. before processing any transactions), write the parent beacon root provided in the block header into the storage of the contract at `HISTORY_STORAGE_ADDRESS`. This data is keyed by the slot number.

In pseudocode:

```python
start_timestamp = get_block(block_header.parent_hash).header.timestamp
start_slot = convert_to_slot(start_timestamp)

end_timestamp = block_header.timestamp
end_slot = convert_to_slot(end_timestamp)

parent_beacon_block_root = block_header.parent_beacon_block_root

for slot in range(start_slot, end_slot):
    sstore(HISTORY_STORAGE_ADDRESS, slot % SLOTS_PER_HISTORICAL_ROOT, parent_beacon_block_root)
```

When using any slot value as a key to the storage, the value under consideration must be converted to 32 bytes with big-endian encoding.

#### New opcode

Beginning at the execution timestamp `FORK_TIMESTAMP`, introduce a new opcode `BEACON_ROOT` at `OPCODE_VALUE`.
This opcode consumes one word from the stack encoding the slot number for the desired root under big-endian discipline.
The opcode has a gas cost of `G_beacon_state_root`.

The result of executing this opcode leaves one word on the stack corresponding to a read of the history contract's storage; in pseudocode:

```python
slot = evm.stack.pop()
sload(HISTORY_STORAGE_ADDRESS, slot % SLOTS_PER_HISTORICAL_ROOT)
```

If there is no root stored at the requested slot number, the opcode follows the existing EVM semantics of `sload` returning `0`.

## Rationale

### Gas cost of opcode

The suggested gas cost is just using the value for the `BLOCKHASH` opcode as `BEACON_ROOT` is an analogous operation.

### Why not repurpose `BLOCKHASH`?

The `BLOCKHASH` opcode could be repurposed to provide the beacon root instead of some execution block hash.
To minimize code change, avoid breaking changes to smart contracts, and simplify deployment to mainnet, this EIP suggests leaving `BLOCKHASH` alone and adding a new opcode with the desired semantics.

### Beacon block root instead of state root

Block roots are preferred over state roots so there is a constant amount of work to do with each new execution block. Otherwise, skipped slots would require
a linear amount of work with each new payload. While skipped slots are quite rare on mainnet, it is best to not add additional load under what would already
be nonfavorable conditions.

Use of block root over state root does mean proofs will require a few additional nodes but this cost is negligible (and could be amortized across all consumers,
e.g. with a singleton state root contract that caches the proof per slot).

## Backwards Compatibility

No issues.

## Test Cases

TODO

## Reference Implementation

TODO

## Security Considerations

TODO

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
