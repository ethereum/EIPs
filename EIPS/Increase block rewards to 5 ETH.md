---
eip: <to be assigned>
title: Increase block rewards to 5 ETH
author: Ben Tinner (@Terra854)
discussions-to: https://www.reddit.com/r/ethereum/comments/k4252u/thoughts_about_increasing_block_rewards_till_we/
status: Draft
type: Standards Track
category Core
created: 2020-12-01
---

## Simple Summary
This EIP will increase the block reward paid to proof-of-work (POW) miners, giving them more opporturnities to acquire the minimum number of ETH needed to run a standalone proof-of-stake (POS) validator node before full implementation of ETH 2.0

## Abstract
By increasing the block rewards back to the original 5 ETH when the network first started, it will convince POW miners to stay on mining Ethereum without worrying too much on profitability. It will also give smaller POW miners more opporturnities to be able to acquire the minimum amount of ETH needed to become a POS validator before we transition fully to ETH 2.0

## Motivation
Currently, the transaction fees (tx fees) portion of the mining rewards makes up a significant portion of the total rewards per block, at times almost exceeded the block reward of 2 ETH. This have resulted in situations where at times of low tx fees, POW miners decide to point their rigs away from ETH as they will always prefer to mine coins that are the most profitable at any point in time, reducing the security of the ETH network till transaction activity picks up again. By increasing the block rewards, the voliatility will be reduced in terms of the percentage of tx fees that make up the mining rewards per block while increasing the total rewards per block, making it more financially attractive to POW miners to mine ETH barring any gigantic ETH price drops. The increase in block rewards will also allow smaller POW miners ample opporturnity to build up their stores of ETH so that when the time comes to fully transition to ETH 2.0, they may be more willing to become validators as they already have earned the requite amount of ETH needed to do so as opposed to having to spend tens of thousands of dollars to purchase the required ETH directly, increasing the number of validators in the network and therefore strengthening network security.

## Specification
All we need to do is to modify the parameters that define the block reward inside the source code

## Rationale
The ultimate end goal for this EIP is to give POW miners more incentive to switch to POS once ETH 2.0 is fully implemented since the transition will take a few years to complete and during that time, they will be incentivised to hold on to the tokens instead of selling it straightaway in order to prepare to be a validator for ETH 2.0, reducing the selling pressure on ETH and increasing it's value in the long run. A side effect of miners staying on Ethereum is that network security will be assured during the transition period.

## Backwards Compatibility
This EIP is not forward compatible as there will be changes to the block, uncle and nephew reward structure. Therefore, it should be included in a scheduled hardfork at a certain block number.

## Security Considerations
There will be short term economic drawbacks such as a significantly higher inflation rate (estimated 10.4% per annum for the first year) for a few years, but I believe that these concerns will be moot once the transition is complete.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
