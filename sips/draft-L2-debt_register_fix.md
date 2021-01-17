---
sip: TBC 
title: L2 Debt Register
status: Proposed
author: Kain Warwick (@kaiynne)
discussions-to: https://research.synthetix.io/t/tbc

created: 2021-01-17 
requires (*optional): 
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

After the deployment of Synthetix to L2 a bug was identified in the debt register calculation causing debt to increase as more SNX was staked, this fix addresses the issue in the debt register and fixing the debt balance for each staker.

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

The debt register uses a rolled up calculation of all minting and burning events to enable the debt of each staker to be stored on chain. During post deployment testing two small mints of ~2 wei of sUSD were performed. These mints caused the precision in the debt register to be lost resulting in each additional mint increasing the debt for all stakers. This fix addresses the loss of precision in the debt register restoring the correct debt balances.

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Phase 0 of OE was designed to minimise the risk to stakers, so it is critical that debt does not fluctuate until exchanges are enabled. This fix addresses an edge case where the debt register does not accurately reflect the minted debt of each staker without the need to make any further changes to the debt calculation functionality or requiring all stakers to take any action thus reducing the impact to L2 stakers.

## Specification
<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
-->

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

There is an alternative to fixing the debt register, which would be to to redeploy the entire L2 system and ensure that the fix mint even is sufficientlt large as to not trigger this issue in the debt register. This would require all SNX stakers to migrate again, which given the impact to the system and the cost of migration appears to be a much worse alternative.

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases are included with the implementation in [its pull request](https://github.com/Synthetixio/synthetix/pull/811).

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
