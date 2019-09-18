---
sip: 11
title: Allow fee period to be closed by any address 
status: Implemented
author: Nocturnalsheet (@nocturnalsheet)
discussions-to: https://discord.gg/CDTvjHY
created: 2019-07-10
---


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This SIP proposes to allow SNX weekly fee period to be closed by any wallet address 

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Currently only authorised wallet address is able to send the close fee period transaction to the fee pool contract and this auto bot closing has failed twice already in the last 2 weeks

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
Weekly close of fee period gives all minters their weekly SNX and sUSD rewards so it is highly important that the close is done on time as we have seen in the last 2 fee period close, minters become more uneasy in discord when they don't see their rewards awarded at the regular snapshot timing. Getting paid on time as a minter is apparently quite a big thing for minters, myself included.  

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
Allowed address to close fee period - Any
Fee Period Close is true: Minimum 168 hours (7 days) lapse from last close 

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

By allowing any wallet address to close the fee period, we can expect the fee period can be closed without much delay in almost any situations, even in network congestion where any minter can manually pay for high gas fee to close the fee period
 
## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Not required at this stage

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
FeePool.closeCurrentFeePeriod() is now open for anyone to publicly call. For the latest FeePool Contract see here https://developer.synthetix.io/api/docs/deployed-contracts.html.

The FeePool Authority Service is still hosted and will run every 10 minutes to check if FeePool.recentFeePeriods[0].startTime <= (now - feePeriodDuration). If so it will call FeePool.closeCurrentFeePeriod(). However if this service is down for what ever reason any SNX holder may call this to reveal the claimable rewards for everyone. 


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
