---
eip: <to be assigned>
title: Predictable Proof-of-Work (POW) Sunsetting 
author: @Query0x
discussions-to: <tbd>
status: Draft
type: Standards Track
category: Core
created: 2021-03-13
---

## Simple Summary
Provides for a predictable, issuance neutral reduction of block rewards to 1 over a one year time span while reducing the uncertainties and risks associated with sudden changes to mining economics.

## Abstract
Sets the block reward to 3 ETH and then incrementally decreases it every block for 4,000,000 blocks (approximately 1 year) until it reaches 1 ETH.

## Motivation
A sudden drop in PoW mining rewards could result in a sudden precipitous decrease in mining profitability that may drive miners to auction off their hashrate to the highest bidder while they figure out what to do with their now "worthless" hardware. If enough hashrate is auctioned off in this way at the same time, an attacker will be able to rent a large amount of hashing power for a short period of time at relatively low cost and potentially attack the network. By setting the block reward to X (where X is enough to offset the sudden profitability decrease) and then decreasing it over time to Y (where Y is a number below the sudden profitability decrease), we both avoid introducing long term inflation while at the same time spreading out the rate that individual miners cross into the unprofitable range. This allows miners time to sell off/repurpose their hardware rather than a large amount of hashing power being put up for auction at the same time while people try to figure out what to do with their now "worthless" hardware. Additionally the decay promotes a known schedule of a deflationary curve of the next few years in prep for Proof of Stake consensus replacement of Proof of Work.

## Specification
Adjust block, uncle, and nephew rewards
### Constants
* `TRANSITION_START_BLOCK_NUMBER: TBD`
* `TRANSITION_DURATION: 4_000_000` (about one years)
* `TRANSITION_END_BLOCK_NUMBER: FORK_BLOCK_NUMBER + TRANSITION_DURATION`
* `STARTING_REWARD: 3_000_000_000_000_000_000`
* `ENDING_REWARD: 1_000_000_000_000_000_000`
* `REWARD_DELTA: STARTING_REWARD - ENDING_REWARD`
### Block Reward
```py
if block.number >= TRANSITION_END_BLOCK_NUMBER:
    block_reward = ENDING_REWARD
elif block.number >= TRANSITION_START_BLOCK_NUMBER:
    block_reward = STARTING_REWARD - REWARD_DELTA * TRANSITION_DURATION / (block.number - TRANSITION_START_BLOCK_NUMBER)
```

## Rationale
This proposal smooths the effect of EIP-1559 on mining economics, without affecting the fee burn or increasing total ETH issuance, and mitigates the risks and uncertainties that sudden changes to mining economics impart on network security.  Temporarily raising the mining reward to 3 blunts the initial impact of EIP-1559 and the continual reductions thereafter codify Ethereum's move to POS by increasingly disincentivizing POW.  Importantly, this approach moderates the rate of change so impacts and threats can be measured and monitored.

## Backwards Compatibility
There are no known backward compatibility issues with the introduction of this EIP.

## Security Considerations
There are no known security issues with the introduction of this EIP.

## Copyright
Copyright and related rights waived via CC0.