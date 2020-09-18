---
sccp: 43
title: Pollux Updates for Chainlink Oracles
author: Kain Warwick (@kaiynne), Justin Moses (@justinjmoses)
discussions-to: https://research.synthetix.io/t/sccp-43-pollux-changes/186
status: Implemented
created: 2020-08-31
requires: TBC
---


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
As part of the Pollux deployment and transition to Chainlink Oracles a number of SCCP controlled variables need to be updated to improve trading UX and reduce frontrunning attacks.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The changes proposed are listed below:

1. SystemSettings.rateStalePeriod: 25hrs
2. SystemSettings.waitingPeriodSecs: 5mins x 60 = 300s
3. SystemSettings.exchangeFeeRate(bytes32):

    a. Forex: 0.3% (same as current)
    
    b. Commodity: 0.3% (down from 1% currently)
    
    c. Equities: 0.3% (down from 0.5% currently)
    
    d. Crypto: 0.3% (same as current)
    
    e. Index: 0.3% (same as current)

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
For points 1 and 2 these updated variables will ensure that stale rates monitoring which ensures that oracles are still live is not triggered by the transition to 24 hour heartbeats with CL Oracles. With this change to longer heartbeats and lower deviations it is possible to reduce the fee reclamation waiting period from the current ten minutes to five minutes. This will improve UX, however, ideally this will be reduced further to the original three minute window in the future after some monitoring on mainnet. With point 3 a number of exchange fee rates have been increased recently to reduce the potential for frontrunning oracle latency. With the transition to CL and changes to the heartbeat and price change thresholds these fee rates can be reduced to the original 30bps. As with the changes in 1 & 2, these changes will be monitored closely and ideally further fee reductions will be proposed once the data supports it.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
