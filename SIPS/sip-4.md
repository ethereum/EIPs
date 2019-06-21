---
sip: 4
title: Change Fee Claim Window
status: Approved
author: Kain Warwick <@kaiynne>, Clinton Ennis <@hav-noms>
discussions-to: https://discord.gg/aApjG26
created: 2019-06-17
updated: 2019-06-21
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
The current fee window of 6 weeks is not configurable and creates a significant lag between changes to incentives and user action. This SIP changes the fee period to two weeks, it does not address the current issues with fee rollover which will be addressed in a later SIP.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The current fee claim window is not configurable, but the community has indicated that reducing it to two weeks is neccesary to increase the responsiveness of minters to the incentives within the system. Due to the way fees are currently claimed, and the way unclaimed fees rollover there needs to be at least six fee periods worth of fees unclaimed before fees begin to rollover and be claimable. Simply reducing the number of claimable periods does not resolve this. However, the fee rollover issue can be resolved in a later SIP as the higher priority issue is reducing the lag between changing incentives and user action.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
There are currently several SCCPs proposed to increase the incentives in the system to ensure the sUSD peg is maintained. These configuration changes are likely to have minimal effect and significant lag between implementation and user action given the current six week claim window. The reason for this is that a user is not sufficiently motivated to adjust their c ratio when they can wait for either the SNX price to rise in a later fee period or wait until their fees are about to expire before adjusting their ratio.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
https://github.com/Synthetixio/synthetix/blob/develop/test/FeePool.js#L503
https://github.com/Synthetixio/synthetix/blob/develop/test/RewardsIntegrationTests.js


## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
https://github.com/Synthetixio/synthetix/blob/develop/contracts/FeePool.sol#L100


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
