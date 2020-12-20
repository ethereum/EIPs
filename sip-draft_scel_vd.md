---
sip: <to be assigned>
title: Spartan Council Epoch Lock & Vote Dilution
status: WIP
author: rubber^duck (@rubberducketh)
discussions-to: https://research.synthetix.io/t/spartan-council-stability-liquidity/243/5

created: 2020-12-14
requires (*optional): 93
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->
This SIP proposes to lock the Spartan Council composition of Council members for the duration of a Council Epoch and introduces the ability for SNX holders to dilute the voting power of a Council member for a specific SCCP. 

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->
Following the end of an Election Period as described in SIP 93, the elected Council members will lock their position in the Council for the duration of the Council Epoch. The composition of the Council can change again only after a new Election period is held. 

Throughout a Council Epoch, the voting power of a Council Member can be diluted on a specific SCCP proposal vote by the respective and relative SNX holder's Weigh Debt (WD). This will not affect the Council Member's position on the Council. Proposals must still reach a supermajority agreement to be enacted under the (N/2 + 1) rule. 

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->
The existing implementation of SIP-93 introduces an instability to the composition of the Spartan Council, with frequent changes due to vote swings, both throughout a Council Epoch and throughout SCCP proposal voting.

Locking the composition of a Council for the duration of a Council Epoch negatively impacts liquidity in democracy, where a Council member may vote for a SCCP proposal in a way where his SNX holder's backing him disagree with. To adress this potential disconnect, we propose the ability to dilute a Council members voting power no a specific SCCP proposal.

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
There are two major components of this proposal:
1. Spartan Council composition lock
2. Vote dilution

##### Spartan Council composition lock

Upon the conclusion of an Election Period, the elected Council members will lock their position in the Council for the duration of the Council Epoch.

##### Vote dilution

At any time during a Timelock period of a proposal that Council Members are voting on, a SNX holder can dilute the voting power of the Council member they voted for in the election by relative value of their election WD. 

The voting power of a Council member on a proposal is calculated as following:

N = 1 - (withdrawn WD / total Council member’s WD)

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Following the first Spartan Council election, the community recognized an issue, where the council shuffled 10+ times before the first SCCP proposal was issued, which creates further problems with timing a SCCP proposal to give a chance for a stable council composition to review and vote on it in a timely manner, let alone to consider multiple proposals in parallel. The community debated on how to solve this issue, while at the same time retaining elements of a liquid democracy, with a general consensus leading to this SIP proposal. 

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
Modifications to the current “Synthetix” governance app https://gov.synthetix.io/ on Snapshot, to house the dilution features of this proposal. 

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
