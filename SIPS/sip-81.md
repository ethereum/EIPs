---
sip: 81
title: Remove Centralized Oracle
status: WIP
author: Justin J Moses (@justinjmoses)
discussions-to: https://research.synthetix.io/t/sip-x-removal-of-snx-oracle/184

created: 2020-08-25
requires (*optional): 36, 75
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Remove all centralized oracle code from Synthetix.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Remove the `oracle` functionality from the `ExchangeRates` contract.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Once [SIP-36](./sip-36.md) and [SIP-75](./sip-75.md) have been implemented, the centralized Synthetix oracle is no longer being used. In order to decentralize even more, this SIP proposes to remove the power of a centralized oracle to update rates.

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

`updateRates` and `setOracle` are to be removed from the `ExchangeRates` contract. This will mean that only decentralized Agggregator price feeds can be used in the future. This includes all synths, `SNX`, `ETH` and binary option markets. This also includes all testnets.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The centralized oracle code is currently alongside the decentralized code in `ExchangeRates`. This SIP simply proposes removing the former altogether.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

- Remove `ExchangeRates.oracle`
- Remove `ExchangeRates.currentRoundForRate`
- Remove `ExchangeRates.updateRates()`
- Remove `ExchangeRates.setOracle()`

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

N/A

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
