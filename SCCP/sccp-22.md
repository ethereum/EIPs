---
sccp: 22
title: Reduce Rewards On Curve
status: Implemented
author: Kaleb Keny (@kaleb-keny)
discussions-to: SNX-trading
 
created: 2020-05-16
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Decrease SNX incentives to the Curve pool by around 30% to 48,000 SNX per week

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
64,000 SNX per week from inflation rewards are given to the sUSD pool on curve which incentivizes liquidity provision to the sUSD/ DAI-USDC-USDT pool.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
In previous SCCPs the sETH incentives has been decreased gradually to 8k. Despite this the respective pegs on the sUSD and sETH pools have remained stable. Therefore, lowering the rewards on the sUSD pools would provide information on the impact on the current state of the peg and on the willingness of participants to add liquidity to the pool for lower incremental rewards.
Other reasons include:
1) It is important to not consistently overpay when incentivizing the pools, as it is effectively a transfer of value from snx minters to pool contributors. The incentive should be calibrated depending on the state of the system to pay the least amount of incentive required that achieves the desired effect of peg stability.
2) The 64k currently paid was chosen partially based on previous experience on how much is paid on Uniswap. This number is bound to be adjusted as per the state of the system (peg, supply of synths,...). However, given that the assumed price risk is somewhat  lower for stable coins against ETH, it is only normal to pay lower incentives on Curve. This is partially offset thought by the protocol risk of stable coins (versus the less risky protocol risk of ETH). 


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
