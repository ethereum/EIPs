---
sip: 90
title: Transition SIPs/SCCPs to Snapshot Governance
status: WIP
author: Andy T CF (@andytcf)
discussions-to: https://research.synthetix.io/t/transition-sips-sccps-to-snapshot-governance/209

created: 2020-10-14
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Transition the current SCCP signaling process to off-chain signatures via snapshot (https://github.com/balancer-labs/snapshot).

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Use snapshot’s gas-less, off-chain governance platform (https://snapshot.page/) that will handle the SCCP/SIP signaling process of the Synthetix Protocol. The platform will enable community members to create SCCP/SIP proposals which will be able to be voted on via IPFS messages/signatures. Proposals created on snapshot will feature quadratic voting and votes will be weighted based on the user’s debt percentage in the last fee period.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

The current Synthetix Governance signaling process is non-sybil resistant, easy to contest, and not a good indicator of community participation and sentiment.

Since SIPs/SCCPs handle the configuration and improvement of vital aspects of the Synthetix Protocol, it is essential to ensure that the proposals being implemented are in the best interest of the wider community and the process in gauging this interest should be hard to contest and accurate.

Existing SIPs/SCCPs are carried out in the #governance-polls channel in the official Synthetix discord. Discord polls are easy to manipulate via a Sybil attack (creating multiple discord accounts) since the weight of a single vote is directly mapped to the existence of a unique discord account. On top of this, discord polls do not maintain an accurate history of participation and votes, where each vote on a poll is reversible.

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

In order to improve the Sybil-resistance of the Synthetix Governance process, we will use snapshot’s off-chain, gas-less solution to enable an wallet based voting system, where each user's vote will be weighted based on their debt percentage in the previous fee period. The weights calculated in this way will also be quadratically modified to implement a quadratic voting system to increase the equality of votes.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The selection of snapshot’s platform for handling the SIP/SCCP governance process was due to factors such as the widespread usage amongst other projects, the gas-less nature of voting and the great usability of the platform. Factors which all supplement the improved Sybil resistance of the Synthetix Governance process.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
