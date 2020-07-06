---
sip: 67
title: Binary Options bid phases
status: WIP
author: dgornjakovic
discussions-to: https://discord.gg/e9c5Cs

created: 2020-07-05
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->
The current binary options system doesn't have any support for early bidders, thus it makes sense for everyone to wait untill the last possible moment before casting their bids.
This is a proposal on how to achieve a system where bidders would be incentivisized to cast their bids as soon as possible

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->
There would be three bidding phases, automatically created on the creation of the market. Earlier phases will have smaller bid and withdrawal fees. Early bidders will have their withdrawal fee locked even when the bid gets to later phases, so they still achieve the "discount".

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->
With the current system for Binary Options it makes sense for bidder to wait until the last possbile moment:
1. They will have a clear picture on the final odds
2. They mitigate the withdrawal need and can use their funds in different places until the bid gets to final stages
3. So finally they have no reason to lock their funds early in a bid

For this reason currently only markets with shortterm bid windows make sense.
We want to balance this out so that long term bid windows are also attractive for both market creators and bidders.

## Specification
<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview
<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->
As soon as a binary market is created the bid window is split into 3 phases equal in length:
1. **Early Bird**: 0.5% fee, 3% withdrawal
2. **Standard** 1% fee, 5% withdrawal
3. **Late Riser** 2% fee, 7% withdrawal

Early birds will have 0.5% fee on bids and 3% withdrawal cost till end of the bid phase.
Standard bidders will have the current 1% bid fee and 5% withdrawal cost until the end of the bid phase.
Late Risers will have 2% bid fee and 7% withdrawal fee.


UI will have to be adapted to support these phases.
Markets already created will keep their default configuration.
### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
  

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
John Doe create a market with bid deadline in 72h:
1. Early bird phase is until hour 24, with 0.5% bidding fee. Everyone who joined on the bid phase has 3% withdrawal fee until the end of the bid deadline.
2. Standard phase is 1% fee. Everyone who joined in the standard phase has 5% withdrawal fee until the end of the bid deadline.
3. Late Riser phase is from hour 48 till hour 72, with 2% fee and 7% withdrawal fee.

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
1. All fees are subject to configuration
2. Number of phases is subject to configuration

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
