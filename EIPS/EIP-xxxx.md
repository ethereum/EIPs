---
eip: <to be assigned>
title: Fix block reward at 2 ETH
author: MicahZoltu (@MicahZoltu)
discussions-to: TBD
status: Draft
type: Standards Track
category Core
created: 2018-07-31
---

## Simple Summary
Changes the block reward to be a fixed amount per block of 2 ETH.

## Abstract
As of FORK_BLOCK_NUMBER, set the block reward to 2 ETH and the Uncle and Nephew reward following the same formula as before.

## Motivation
There has been an expectation of block reward reduction up to now as a side effect of the ice age.  If the Ice Age is removed or delayed, there will be an increase in block reward per time.  This change makes the most sense on a chain that removes or delays the Ice Age, but it can be implemented on a chain in isolation.

## Specification
```
new_block_reward = 2_000_000_000_000_000_000 if block.number >= FORK_BLOCK_NUMBER else block.reward
```
(2E18 attoeth, or 2,000,000,000,000,000,000 attoeth, or 2 ETH).

If an uncle is included in a block for `block.number >= FORK_BLOCK_NUMBER` such that `block.number - uncle.number = k`, the uncle reward is
```
new_uncle_reward = (8 - k) * new_block_reward / 8
```
This is the existing pre-fork formula for uncle rewards, simply adjusted with `new_block_reward`.

The nephew reward for `block.number >= FORK_BLOCK_NUMBER` is
```
new_nephew_reward = new_block_reward / 32
```
This is the existing pre-fork formula for nephew rewards, simply adjusted with `new_block_reward`.

## Rationale
This change will keep ETH issuance per day stable with pre-fork values in the face of a permanent decrease in blocks per day down to 15 seconds per block.

If there is a desire to keep ETH issuance per day stable in the face of decreasing blocks per day then this EIP is not a good solution and another EIP should be implemented that adjusts the block reward formula to be a function of time rather than a function of block number.

## Backwards Compatibility
This EIP is not forward compatible and introduces backwards incompatibilities in the block, uncle and nephew reward structure. Therefore, it should be included in a scheduled hardfork at a certain block number.

## Test Cases
Test cases shall be created once the specification is to be accepted by the developers or implemented by the clients.

## Implementation
None yet.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
