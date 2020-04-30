---
sccp: 19
title: Cancel ArbRewarder's SNX Rewards
author: Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/kPPKsPb
status: Proposed
created: 2020-04-30
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Cancel the [ArbRewarder](http://contracts.synthetix.io/ArbRewarder)'s current 64K distribution of the [weekly Inflationary Supply](0xab641a688b5637677dc665d1d4ca950f0e0ad74517266c39ea34ab4c4f69dbb8). 

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
This configuration change proposes to delete the [ArbRewarder](http://contracts.synthetix.io/ArbRewarder) entry from the [RewardsDistribution](https://contracts.synthetix.io/RewardsDistribution) contract. This reduction will increase the amount sent to the [Staking Rewards](http://contracts.synthetix.io/RewardEscrow) contract distributed weekly to SNX stakers.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

The [ArbRewarder's purpose](https://blog.synthetix.io/snx-arbitrage-pool/) was to fix the sETH/ETH uniswap pools peg. Since then a new [sUSD curve pool](https://blog.synthetix.io/susd-curve-pool-vulnerability-next-steps/) has been created to create a stable synth liquidity pool that keeps the stakers debt pool more netural.

Since the ArbRewarder was found to be manipulated it was paused then deprecated, but it has now acumulated 1M SNX tokens which will be used to help maintain the peg in the future. The SNX will be withdrawn to the Synthetix DAO and used for the [eSNX mechanism](https://blog.synthetix.io/snx-dfusion-trial-and-esnx/) to build up an emergency ETH fund to defend the peg against future deviations.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
