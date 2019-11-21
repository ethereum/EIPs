---
sip: 22
title: Add sDEFI Synth
status: Implemented
author: Garth Travers (@garthtravers)
discussions-to: (https://discordapp.com/invite/CDTvjHY)

created: 2019-10-18
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Add sDEFI/iDEFI Index Synths that track an index of DeFi tokens. 

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The DeFi ecosystem is growing in maturity and awareness. Adding long/short exposure to a basket of DeFi tokens will allow traders to profit from bullish or bearish bets on the value of some of the utility tokens in the ecosystem. 

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
These Synths will be implemented in much the same way as the sCEX/iCEX Synths. iDEFI will have upper and lower thresholds which will be added to the SIP before deployment. The weighting will also be added before deployment, and the following nine tokens will be used in the basket: KNC, LINK, SNX, REN, LRC, MLN, BNT, ZRX, and MKR. 

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Additional Index Synths will add further utility to Synthetix.Exchange. The DeFi tokens were chosen through two rounds of community votes on Twitter. 

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
TBC

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
iDEFI thresholds and index weighting to be added before deployment. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
