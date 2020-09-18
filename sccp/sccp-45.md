---
sccp: 45
title: Lower iETH rewards to 0K and add to RewardsDistribution
status: Proposed
author: Clinton Ennis (@hav-noms)
discussions-to: governance
created: 2020-08-31
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Decrease the iETH SNX rewards incentive from 32k SNX to 0k SNX per week and add it to the RewardsDistribution contract from the inflationary supply.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The iETH trial incentive has run for several months being paid by the synthetixDAO at a consistent rate of 32,000 SNX per week. Given the value of this incentive in balancing the debt pool the iETH incentive should be included in the weekly inflationary supply rewards distribution.

Configure the [RewardsDistribution](http://contracts.synthetix.io/RewardsDistribution) to add the iETH contract address to automate the distribution of SNX weekly. The amount is to be determined by another SCCP.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The synthetixDAO cannot fund this incentive forever and the iETH incentive mechanism is important to all SNX stakers to help netualize the shared debt pool.

With [SCCP-42](https://sips.synthetix.io/sccp/sccp-42) proposing to reduce sUSD SNX incentive from 24K to 8K there is no negative impact on SNX stakers weekly staking rewards.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
