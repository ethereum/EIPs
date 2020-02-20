---
sccp: 13
title: Temporarily lower fee claim buffer to 500%
author: Garth Travers (@garthtravers)
discussions-to: Discord
status: Implemented
created: 2020-02-19
---

## Update (2020-02/20)
The fee claim buffer has since been reinstated to its usual 750%. 

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Lower the fee claim buffer to 500% to allow stakers to claim without incurring the temporary 2% trading fee. 

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
A high number of stakers are below the target C-Ratio, yet to burn enough Synths to reach the target many of them need to trade Synths back into sUSD. However, there's currently a 2% trading fee until fee reclamation is launched with the Achernar release, so we're reducing the fee claim buffer this one time to allow stakers to claim as long as their C-Ratio is above 500%. 

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
A temporarily high trading fee was added to ward off frontrunners until fee reclamation, but had the added effect of punishing people trading genuinely (including SNX stakers who are holding Synth positions). Allowing stakers to temporarily claim with a lower C-Ratio ensures they don't get unduly punished. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
