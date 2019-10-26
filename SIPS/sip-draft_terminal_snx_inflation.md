---
sip: <to be assigned>
title: Terminal SNX Inflation
status: WIP
author: Michael Anderson (@meanderson), Deltatiger (@deltatigernz)
discussions-to: governance

created: 2019-10-25
requires: Inflation Smoothing (SIP# TBD)
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This proposal will add a perpetual weekly reward of 100,000 SNX following the inflation smoothing changes which end on July 22nd, 2022 (as per the Inflation Smoothing SIP).

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
- Current SNX monetary policy calls for a step-down function for weekly inflation rewards ending in March 2023.
- Current weekly issuance of 1.44m SNX drops in half every 52 weeks.
- To combat the abrupt changes in weekly inflation, a new policy smooths these weekly changes using a % decay model.
- Instead of ending the weekly inflation rewards, the protocol will continue to issue SNX at a rate of 100,000 per week.
- This issuance will continue into perpetuity.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The Foundation and community have shown a strong proclivity to use SNX funds to incentivize desired user behavior and drive growth. Perpetual weekly issuance prolongs the runway of these initiatives while having little effect on the SNX value. Issuing 100,000 SNX tokens each week allows for continuous funding of growth initiatives while also incurring a declining percentage inflation each year.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
Adjust [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/master/contracts/SupplySchedule.sol) to account for the following changes:
- Starting on July 22nd, 2022, the weekly issuance of SNX tokens will adjust to 100,000.
- This model will stay in place until it is stopped or adjusted.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
While we expect some growth initiatives in place today to be adjusted or diverted to new initatives in the future, we don't want to a halting of all growth initiaties due to lack of funding. Doing so could potentially cause a "Black Swan" event where a negative feedback loop brings down the Synthetix platform. Having a decreasing inflation rate via an absolute-value issuance model will have smaller inflationary effects on existing SNX holders vs. a percentage-based issuance model.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Standard test cases for Solidity contract compling and deploying onto Ethereum testnets before updating the contract on mainnet. 

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
- Update and deploy [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/master/contracts/SupplySchedule.sol) to Ropsten, Rinkby, and Kovan
- Update and deploy changes to proxy contracts that reference SupplySchedule.sol on Ethereum testnets
- Update and deploy [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/master/contracts/SupplySchedule.sol) to Ethereum mainnet
- Update and deploy changes to Ethereum mainnet proxy contracts that reference SupplySchedule.sol

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
