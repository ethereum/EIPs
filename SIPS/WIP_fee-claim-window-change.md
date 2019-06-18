---
sip: TBA
title: Change Fee Claim Window
status: WIP
author: Kain Warwick <@kaiynne>, Clinton Ennis <@hav-noms>
discussions-to: https://discord.gg/aApjG26
created: 2019-06-17
updated: 2019-06-18
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
This is the template for SIPs.

Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-wip_title_abbrev.md`.

The title should be 44 characters or less.

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
The current fee window of 6 weeks is not configurable and creates a significant lag between changes to incentives and user action. This SIP updates the fee period to two weeks and only allows for fee claims for a single claim period.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The current fee claim window is not configurable, but the community has indicated that reducing it to two weeks is neccesary to increase the responsiveness of minters to the incentives within the system. Due to the way fees are currently claimed, and the way unclaimed fees rollover there needs to be at least six fee periods worth of fees unclaimed before fees begin to rollover and be claimable. Simply reducing the number of claimable periods does not resolve this. We are proposing to adjust the fee claiming mechanism to ensure that fees rollover faster and become claimable by minters who are actively claiming. The immediate solution is to change the length of fee periods to two weeks, and to force minters to claim fees for every period. This strikes a balance between the intent of the community to ensure that incentives have a timely impact on user behaviour while reducing the engineering effort to implement the change so as to not delay deployment to mainnet.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
There are currently several SCCPs proposed to increase the incentives in the system to ensure the sUSD peg is maintained. These configuration changes are likely to have minimal effect and significant lag between implementation and user action given the current six week claim window. The reason for this is that a user is not sufficiently motivated to adjust their c ratio when they can wait for either the SNX price to rise in a later fee period or wait until their fees are about to expire before adjusting their ratio.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
TBC

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
TBC

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
