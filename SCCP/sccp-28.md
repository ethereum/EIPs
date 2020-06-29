---
sccp: 28
title: Reduce Rewards On Curve - SNX 32,000
status: Proposed
author: Kaleb Keny (@kaleb-keny)
discussions-to: Governance
 
created: 2020-06-14
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Decrease SNX incentives to the Curve pool to 32,000 SNX per week

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
48,000 SNX per week from inflation rewards are currently paid to the sUSD pool on curve which incentivizes liquidity provision to the sUSD/ DAI-USDC-USDT pool.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
After we reduced the incentive paid on Curve pool, we did not notice any decrease in the amount staked. Rather, the amount staked increased slightly to reach 13 million in recent days. In addition, the current recovery in SNX prices means that users are now getting an APY of 22% in USD terms (equivalent to the APY pre-decrease to SNX 48k). Another motive is the peg, which has been more resilient recently. Please see the [chart](asset/curve_decrease_32/charts.PNG) for reference.

Other reasons to decrease the incentive, as noted in the previous SCCP:
1) It is important to not consistently overpay when incentivizing the pools, as it is effectively a transfer of value from snx minters to pool contributors. The incentive should be calibrated depending on the state of the system to pay the least amount of incentive required that achieves the desired effect of peg stability.
2) The 48k previously proposed was bound to be recalibrated as per the state of the system (peg, supply of synths,...). However, given that the amount staked and the peg both remain resilient despite the reward reduction and recent c-ratio decrease, it is possible to continue to lower these rewards on Curve until we reach the optimal point of maximum elasticity.

## Source
- [data](asset/curve_decrease_32/data.xlsx)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
