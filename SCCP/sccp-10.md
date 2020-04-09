---
sccp: 10
title: Reduce minter reward for supply schedule 
author: Jackson Chan (@jacko125), Justin J Moses (@justinjmoses)
status: Implemented

created: 2020-01/23
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
I propose reducing the minter reward to 30 SNX per minting of reward supply from the current 200 SNX per week. When supply schedule was released initially the minter reward was set to incentivise people to call synthetix.mint() and cover the cost of gas incurred. At the time the reward value was about $20USD however with the increase of SNX's value this has now ballooned into over ~$280USD at current value.

Furthermore we've observed that synthetix.mint() is now called sufficiently on time by automated bots and traded into ETH immediately for the reward.   

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Reduce minter reward to 30 SNX each time synthetix.mint() is called. 

Owner of supplySchedule to call ```function setMinterReward(uint amount)```to set minter reward to 30 SNX.


## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The existing minter reward is now too big 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
