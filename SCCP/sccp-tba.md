---
sccp: TBA
title: End SNX rewards for sETH/ETH Uniswap pool v1
author: Kaleb Keny (@kaleb-keny)
discussions-to: https://discord.gg/4GvuB3
status: Proposed
created: 2020-06-24
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
End the SNX incentives for sETH/ETH Uniswap pool, currently rewards stand at 4,000 SNX per week.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
4,000 SNX per week from inflation rewards are currently provided to the sETH/ETH pool, which incentivizes liquidity provision to the sETH/ETH pair.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
Given the low amount of incentive currently being contributed to the sETH/ETH pool, removing the rest of the rewards is not expected to have a material impact, due to the utility of these tokens where they can be collateralized on AAVE in order to take out a loan and generate farming yield.
Furthermore, looking at the [chart](asset/uniswap_seth_end/chart.PNG) of staked tokens against SNX reward amount shows that although rewards have decreased considerably (by around 95%) the amount staked has only halved. This provides support that on the lack of need for these SNX rewards.
Finally, it is worth mentioning that rewards from the inflation pool that have no pre-determined end-date essentially serve the purpose of peg maintenance, with the recent stability of the peg these rewards could be unwound safely.

One point mentioned by `nocturnalsheet` is that depositing sETH tokens on Balancer along with wETH would yield investors BAL tokens which is more than enough of an incentive on it's own, due to the low impairment risk.
This also contributes to peg maintenance between sETH (inside money) and ETH (outside money).


## Source
- [data](asset/uniswap_seth_end/data.xlsx)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
