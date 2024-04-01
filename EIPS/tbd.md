---
eip: 7777
title: EXTSELFDESTRUCT Opcode
description: Add an OPCODE to initiate the self-destruction of other contracts 
author: Parithosh Jayanthi (@parithosh), Matt Garnett (@lightclient)
discussions-to: 
status: Draft
type: Standards Track
category: Core
created: 2024-04-01
requires: 
---

## Abstract

This proposal introduces a new opcode, `EXTSELFDESTRUCT`, enabling smart contracts to initiate the destruction of other contracts that utilize more than a specified number of storage slots. This mechanism aims to encourage efficient storage use on the Ethereum blockchain and introduces a system where contracts can gain points by clearing unnecessary contracts, thereby contributing to the network's overall efficiency.

## Motivation

The persistent growth in the number of smart contracts on Ethereum has raised concerns about bloated storage and the long-term scalability of the network. Contracts with excessive storage utilization not only increase the state size, but also contribute to network congestion and higher gas prices. Introducing `EXTSELFDESTRUCT` provides an incentive for devs to manage storage efficiently and offers a method to mitigate storage bloat actively.

## Specification

Introduce a new opcode `EXTSELFDESTRUCT` (`0xFC`).

### Input

#### Stack

| Stack      | Value        |
| ---------- | ------------ |
| `top - 0`  | `target`     |

### Output

#### Stack

| Stack      | Value        |
| ---------- | ------------ |
| `top - 0`  | `points`

### Behavior

When invoked, the number of slots used by `target` is summed up and compared to the minimum allowed value for `EXTSELFDESTRUCT`.

When the sum is greater than or equal to `N` (TBD), the operation will delete the account's code and storage from the state trie. Note: this means the nonce will remain unchanged, which will disallow metamorphic contract deployments. At the end, the accumulated points will value will be pushed back onto the stack.

If the sum is less than `N` (TBD), the operation will fail, nothing will be deleted, and a `0` points value will be assigned to the stack.

### Gas Costs

The base cost of the instruction is `10000` gas. Each slot in the sum adds an additional `500` gas to the total.
Gas: `5000 + 500 * numSlots` where `numSlots` is the number of slots 
Conditions: A contract can invoke `EXTSELFDESTRUCT` on another contract if the target contract uses more than N storage slots, where N is to be determined based on further analysis.

### Points Mechanism

The contract invoking `EXTSELFDESTRUCT` receives points based on the storage size of the target contract and the total number of contracts it has successfully purged.

```math
Points awarded = \exp(A(\text{slots used by target} - N)) + i \cdot B \cdot \text{Total contracts purged}
```


A and B are constants to be defined. i is the imaginary unit that is required as points aren't real.

This equation aims to incentivize the purging of larger contracts and of contracts that actively participate in cleaning the network.

#### Leaderboard

| Constant            | Value        |
| ------------------- | ------------ |
| `LEADERBOARD_ADDR`  | `TBD`

A leaderboard will track and display contracts that have accumulated the most points through successful `EXTSELFDESTRUCT` operations, promoting a competitive environment for network optimization.

The leaderboard will be processed by accumulating a map of `address -> points earned` during block execution. The list will be provided as a calldata via a system call to `LEADERBOARD_ADDR` after block execution is completed. The list will be serialized as tuples of `bytes20 ++ bytes32` values.

The top `N - 250` address will be written to storage in descending order (e.g. slot `0` holds the #1 purger). The remaining 250 storage slots will be used to track recent entrants to the purging arena. They will be stored in order 1) of the block which they last purged and then 2) the number of points earned in that block.

## Rationale

The proposed opcode and points system introduces a gamified approach to reducing storage bloat on Ethereum. By providing incentives to eliminate contracts that are inefficiently using storage, it aligns individual contract interests with broader network efficiency goals.

### Alternative Naming

The mnemonic `MURDER` was additionally considered as a possibility, however, it was found to not sufficintly align with the Ethereum ethos of positivity and cooperation.

## Security Considerations

- Potential for Abuse: Careful consideration must be given to the risk of malicious use, such as targeting contracts arbitrarily or gaming the points system. Mechanisms to prevent abuse, such as a validation process for EXTSELFDESTRUCT eligibility, are essential.
- Impact on Decentralization: The ability to remove contracts could centralize power among a few contracts or developers, potentially undermining Ethereum's decentralized nature. Measures to ensure equitable access to EXTSELFDESTRUCT functionality will be necessary.

## Backwards Compatibility

This EIP introduces new functionality without altering existing opcodes, maintaining backward compatibility with existing contracts. However, contracts designed to utilize `EXTSELFDESTRUCT` will need to adhere to the new specifications.

## Test Cases

Test cases will be developed to verify the correct execution of `EXTSELFDESTRUCT` under various scenarios, including edge cases for storage slot usage and points calculation.

We do however believe in the "trust me bro" guarantee offered by client teams would be more than enough to ensure the secure functioning of the OPCODE.

## Implementation

An initial implementation will be provided for testing and evaluation purposes. Feedback from the Ethereum community will be essential for refining the proposal.



## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
