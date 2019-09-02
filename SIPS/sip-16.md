---
sip: 16
title: Improved Upgrades - Utilise Proxies internally
status: WIP
author: Clinton Ennis (@hav-noms), Jackson Chan (@wacko-jacko)
discussions-to: https://discord.gg/CDTvjHY
created: 2019-08-25
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Synthetix upgrades take too long as the owner needs to make call upto 60 calls to configure the system.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Most of these calls are setSynthetix and setFeePool on all of the Synths. We propose to point the Synths to the
Synthetix Proxy and FeePool Proxy.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

This would reduce the amount of time the system is offline. Making upgrades a lot faster, cheaper (gas) and minimize the impact on users with reduced downtime.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Not required at this stage

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

Not required at this stage

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
