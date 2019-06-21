---
sip: 5
title: New Crypto Synths June '19
status: Approved
author: Kain Warwick (@kaiynne), Clinton Ennis (@hav-noms)
created: 2019-06-18
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
We are adding six new synths sTRX, iTRX, sXTZ, iXTZ, sMKR & iMKR.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
Crypto Synths have seen the most adoption since the launch of sBTC in early 2019. We have also observed that the long/short bias of BNB is different to that of BTC and ETH and expect that the same is likely to be the case of these new crypto synths which will help to offset the risk of asset correlation.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
These synths will be implemented using the same spec as sBTC and iBTC, the specific thresholds for each iSynth will be listed in the implementaion section prior to deployment based on the latest prices.
We'll also be adding PurgeableSynth subclass to the Inverse Synths so the foundation can purge the balances to the holders when the Sysnth becomes frozen once it hits its upper or lower limit.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Additional crypto synths will add utility to synthetix exchange.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
TBC

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
iSynth values to be inserted here:
iTRX: Upper bound: X, Lower Bound: Y
iXTZ: Upper bound: X, Lower Bound: Y
iMKR: Upper bound: X, Lower Bound: Y

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
