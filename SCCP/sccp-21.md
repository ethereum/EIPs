---
sccp: 21
title: Widen iSynth Price Bands
author: Kain Warwick (@kaiynne)
discussions-to: SIPS-WIPS
status: Proposed
created: 2020-05-05
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
The original price bands chosen for the iSynths have proven to be a poor trade-off between tracking the underlying price and frequency of hitting price limits.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->

The current upper and lower price bands for iSynths are set at 1.5x the underlying and .5x the underlying. This SCCP proposes to change the price bands to 1.75x and .25x to align with the change to the iETH price bands implemented in SCCP-17.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

The current price bands cause the iSynths to be frozen regularly which has a significant impact on their usability. By increasing the price bands the iSynths will freeze less frequently. The trade-off is that the amount of leverage at the upper and lower bounds increases from 4x to 7x at the upper limit of the underlying and from 1/2 to 1/7th at the lower bound.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
