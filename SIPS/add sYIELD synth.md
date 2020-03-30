---
sip: to be assigned
title: Add sYIELD synth
status: Proposed
author: Nocturnalsheet (@nocturnalsheet), IanC
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-03-09
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

This SIP proposes to introduce sYIELD, an automatic sUSD which earns interest every block.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

sYIELD will be similar to other synths, freely traded on synthetix.exchange. Fees should be 0% between sUSD/sYIELD pair. Standard fees for any other sYIELD/sXXX pairs. This will allow traders to move into sYIELD to earn interest, even for short periods of time when they are waiting to re-enter their long/short positions

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Current debt pool has heavy exposure to sETH which is a systemic risk to the SNX minters as the impact of ETH price movement creates an imbalance to debt pool exposure for all SNX minters. Ideally the overall debt pool exposure should be neutral so that SNX minters will profit regardless of how sETH or sBTC prices move.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

An initial annual fixed interest rate of X% (to be determined) will be set and the price of sYIELD will increase automatically at every price oracle update, accruing interest on every block.

Exchange of sUSD <-> sYIELD can be done via synthetix.exchange or an external simple UI (like defizap) which calls the underlying contract function. This swap will incur no fees and no slippage or limitation of size.

Interest rate options on sYIELD:

Fixed rate (recommended): Propose to start with an interest rate of 10-15% APR as a trial to monitor the demand and impact

Variable rate (In future): Rates will increase to neutralise the debt pool if the majority of synths are in long positions. Rates will decrease when the debt pool is balanced with more sUSD/sYIELD than long positions

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

sYIELD is a solution which aims to:

1) Encourage traders to hold sYIELD in between trades and keep them in the ecosystem. 


2) Attract people looking for higher stablecoins yield 


3) Encourage SNX minters to hold their debt in sYIELD instead of sETH


4) Create more demand for sUSD, helping to maintain and restore the peg 


5) Create more external borrowing and lending markets for sUSD as arbitrageurs will borrow sUSD to place into sYIELD if the interest rate of sYIELD is higher than the borrowing cost of sUSD


## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
