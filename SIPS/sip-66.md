---
sip: 66
title: Reduce gas of SNX transfers for non-stakers
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-06-30
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Reduce gas of `SNX` transfers for non stakers.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

When an account has no debt, then reduce gas requirement of SNX transfers by not checking any stale rates.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Prior to [SIP-48](./sip-48.md), transfers of `SNX` would initially check for any debt and if none, skip checking the total size of the debt pool. SIP-48 inadventently undid this, meaning that `SNX` transfers for non-stakers caused much higher gas limits than necessary.

Checking the total size of the debt pool involves looping over every synth in Synthetix (currently 40-odd), calculating their USD value (`totalSupply * rate`), which is very gas intensive (~500k gas).

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

Add a check in `Synthetix.transfer` and `Synthetix.transferFrom` to only check `Issuer.transferableSynthetixAndAnyRateIsStale` when there is debt for the account.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Put the check back into the functions that are impacted.

> Note that with this change, `SNX` transfers will be allowed for accounts with no debt even when the `SNX` or any synth rates are stale.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

In both `transfer` and `transferFrom`, perform an initial check for `SynthetixState.issuanceData()` and if no debt ownership, then proceed with a regular transfer.

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- Given a user has SNX
  - and they have not issued any debt
    - and the rate of SNX or any synth is stale
      - when they transfer any amount of their SNX
        - it succeeds
    - and no synth rate nor SNX is stale
      - when they transfer any amount of their SNX
        - it succeeds
  - and they have issued debt
    - and the rate of SNX or any synth is stale
      - when they transfer any amount of their SNX
        - it fails
    - and no synth rate nor SNX is stale
      - when they transfer any amount of their SNX
        - it succeeds

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
