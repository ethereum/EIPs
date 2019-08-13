---
sip: 9
title: Change Fee Claim Window To One Period
status: Proposed
author: Kain Warwick <@kaiynne>, Clinton Ennis <@hav-noms>, Jackson Chan (@jacko125)
discussions-to: https://discord.gg/TK5Vt4h
created: 2019-07-16
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This SIP changes the fee period claimable to one fee period, which aims to address current issues with fees rollover and a providing a clear strategy for stakers in regards to how often they should claim their rewards. Reducing the fee period claimable to one period also reduces the complexity and reduces the gas cost of claiming fees for stakers.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The current fee claim window of two periods creates ambiguity about the fee rollover mechanism and was scheduled to be resolved by making fee claimable only in one period before they rollover. The period duration is configurable by setting the fee period duration and can be adjusted to two weeks based on community feedback and responsiveness. Also reducing fee periods to one period is neccesary to increase the responsiveness of minters to the incentives within the system. Due to the way fees are currently claimed, and the way unclaimed fees rollover there needs to be at least two fee periods worth of fees unclaimed before fees begin to rollover and be claimable. This SIP aims to fix the fee rollover issue as described in SIP-4.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
There are currently several SCCPs proposed to increase the incentives in the system to ensure the sUSD peg is maintained. The reason for this is that a user is not sufficiently motivated to adjust their c ratio when they can wait for either the SNX price to rise in a later fee period or wait until their fees are about to expire before adjusting their ratio.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
https://github.com/Synthetixio/synthetix/blob/develop/contracts/FeePool.sol#L100


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
