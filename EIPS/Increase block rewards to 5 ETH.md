---
eip: 3143
title: Increase block rewards to 5 ETH
author: Ben Tinner (@Terra854)
discussions-to: https://github.com/ethereum/EIPs/issues/3145
status: Draft
type: Standards Track
category: Core
created: 2020-12-01
---

## Simple Summary
Changes the block reward paid to proof-of-work (POW) miners to 5 ETH.

## Abstract
Starting with `FORK_BLKNUM` block rewards will be increased to a base of 5 ETH, uncle and nephew rewards will be adjusted accordingly.

## Motivation
Currently, the transaction fees (tx fees) portion of the mining rewards makes up a significant portion of the total rewards per block, at times almost exceeded the block reward of 2 ETH. This have resulted in situations where at times of low tx fees, POW miners decide to point their rigs away from ETH as they will always prefer to mine coins that are the most profitable at any point in time, reducing the security of the ETH network till transaction activity picks up again. By increasing the block rewards back to the original 5 ETH when the network first started, the voliatility will be reduced in terms of the percentage of tx fees that make up the mining rewards per block while increasing the total rewards per block, making it more financially attractive to POW miners to mine ETH barring any gigantic ETH price drops. The increase in block rewards will also allow smaller POW miners ample opporturnity to build up their stores of ETH so that when the time comes to fully transition to ETH 2.0, they may be more willing to become validators as they already have earned the requite amount of ETH needed to do so as opposed to having to spend tens of thousands of dollars to purchase the required ETH directly, increasing the number of validators in the network and therefore strengthening network security.

Therefore, the ultimate end goal for this EIP is to give POW miners more incentive to switch to POS once ETH 2.0 is fully implemented since the transition will take a few years to complete and during that time, they will be incentivised to hold on to the tokens instead of selling it straightaway in order to prepare to be a validator for ETH 2.0, reducing the selling pressure on ETH and increasing it's value in the long run. A side effect of miners staying on Ethereum is that network security will be assured during the transition period.

## Specification
#### Adjust Block, Uncle, and Nephew rewards
To ensure a constant Ether issuance, adjust the block reward to `new_block_reward`, where

    new_block_reward = 5_000_000_000_000_000_000 if block.number >= FORK_BLKNUM else block.reward

(5E18 wei, or 5,000,000,000,000,000,000 wei, or 5 ETH).

Analogue, if an uncle is included in a block for `block.number >= FORK_BLKNUM` such that `block.number - uncle.number = k`, the uncle reward is

    new_uncle_reward = (8 - k) * new_block_reward / 8

This is the existing formula for uncle rewards, simply adjusted with `new_block_reward`.

The nephew reward for `block.number >= FORK_BLKNUM` is

    new_nephew_reward = new_block_reward / 32

This is the existing formula for nephew rewards, simply adjusted with `new_block_reward`.

## Rationale
I have decided to go with a 5 ETH base reward as i believe that it is a good middle ground between wanting to prevent too high of an inflation rate (10.4% per annum for the first year if we go with 5 ETH) and the desires to convert as many POW miners as possible into POS validators by making it easier to amass the required ETH needed through POW mining.

## Backwards Compatibility
There are no known backward compatibility issues with the introduction of this EIP.

## Test Cases
Test cases shall be created once the specification is to be accepted by the developers or implemented by the clients.

## Implementation
The implementation in it's logic does not differ from [EIP-649](./eip-649.md) or [EIP-1234](./eip-1234.md); an implementation shall be created once the specification is to be accepted by the developers or implemented by the clients.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
