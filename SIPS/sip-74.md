---
sip: 74
title: Binary Markets with custom questions
status: WIP
author: Danijel (@dgornjakovic), Farmwell (@farmwell)
discussions-to: https://research.synthetix.io/t/sip-custom-binary-options/118

created: 2020-07-25
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

So far Binary Markets can only be created on asset strike prices on a certain date.
It would be very attractive to be able to create custom markets, such as: "Will ETH 2.0. be released in 2020?"

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Allow for Markets to be created with a custom binary question.
Introduce a mechanism to resolve such markets.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Binary Markets are risk free profit for stakers. With that in mind we want to attract as many bidders as possible.
Bidding on asset prices has attracted a good portion of bidders, but having the possibility to bet on anything you can think of will surely attract many more bidders.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

The sip would allow users to create markets with a custom binary question. It would also propose how those markets would be resolved.

### Overview

<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

We have already seen interest to create custom markets, such as "Will Trump win the next elections?". If we can implement this in the Synthetix framework, we could create a much bigger value of SNX stakers.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

It would be the responsibility of the Market creator to create a question that would attract bidders. If his question is not clearly formulated, or the bidders find the market risky to manipulation, they would stay away from it, but the important aspect is that there is no risk to the stakers.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

Allow a free text question to be entered on market creation. Bidding date and Maturity date mechanisms are kept.

#### Resolving custom markets

As resolving such custom markets is not feasible using price feeds and the curent mechanism, the proposed solution is to formulate a governance for resolving custom questions.

- We would define 10 addresses allowed to resolve a binary market with a custom question.
- The votes can be cast only after maturity date
- if 7 governance votes have been cast for a single outcome, the market is resolved
- The addresses should be those of the core team and volunteering guardians

#### Dealing with cases where the market can not be resolved

Some question may depend on unpredictable circumstance, such as elections being cancelled due to Covid situation.
To deal with such cases these markets should have a contract function allowing the governance addresses to cancel it.
The cancelation would mean all bidders can reclaim their bids (get refunds), minus the gas costs.

In summary, it means every custom market will have three potential outcomes:

- Yes
- No
- Cancelled
  The same rule for number of governance votes apply to any of those: Minimum 7 votes needed.

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- Will ETH 2.0. be released 2020.?
- Will Trump win the next presidential elections?

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
