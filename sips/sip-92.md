---
sip: 92
title: Historical iSynths Pricing Tracks When Last Frozen
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: https://research.synthetix.io

created: 2020-11-09
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Ensure historical pricing in `ExchangeRates` is aware of when an iSynth was last frozen.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Add historical pricing of when an iSynth was frozen to fix a bug with fee reclamation ([SIP-37](./sip-37.md)) that incorrectly applies existing frozen iSynth status to past settlements.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

The current implementation of fee reclamation settlement asks the `ExchangeRates` contract what was the rate of the `src` and `dest` synths `waitingPeriodSecs` seconds after the trade completed. If either synth is an iSynth, then it also checks to see if the iSynth is currenly frozen, and if so, applies those iSynth limits regardless. This is problematic in the cases where an iSynth is frozen (or unfrozen) after the waiting period expires but before a settlement is processed, as fee reclamation incorrectly applies the current frozen bands to a price that may not have required it at the time.

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

The solution is to track which `roundId` an iSynth is frozen at and if a price is requested at a `roundId` at or before then, to only apply the inverse frozen status in those cases. Then, when unfrozen, this tracking needs to be removed.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

This is the simplest solution that has the least impact to gas usage and the current system. There is slightly more gas required looking up any frozen `roundId` with an additional SLOAD, but this impact is minimal.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

Add a new `mapping(bytes32 => uint) roundFrozen` property to `ExchangeRates` that is populated during `freezeRate()` and removed during `setInversePricing()`

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Implementation and tests: https://github.com/Synthetixio/synthetix/pull/858

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
