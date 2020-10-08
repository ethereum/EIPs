---
sip: 88
title: ExchangeRates patch - Chainlink aggregator V2V3
status: Implemented
author: Clement Balestrat (@clementbalestrat)
created: 2020-10-06
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

During the [Formalhaut](https://blog.synthetix.io/the-fomalhaut-release/) release, an update was made to the `ExchangeRates` contract to be using Chainlink's aggregator V2V3 ([SIP-86](https://sips.synthetix.io/sips/sip-86)).

Just after the change was made, we found an edge case where transfers are reverting if a price has not been updated after a user exchanges into a Synth. The issue relates to how fee reclamation is calculated.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

This SIP will fix the issue by using low level calls to the Chainlink aggregator's `latestRoundData` and `getRoundData` functions in order to avoid any reverts in case the requested round ID does not exist.

This will act as a `try/catch` method which will allow the `ExchangeRates` contract to only update a rate if the previous call to the aggregator was successful.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is inaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

In the previous version of Chainlink's aggregator interface, the function `getRoundData(uint roundId)` was returning 0 in case `roundId` was not found.

This was helpful for the `ExchangeRates` contract to know if a new round ID existed or not during the calculation of fee reclamation, by calling `getRoundData(roundId + 1)`. If the result was returning 0, the current round ID was kept for the next steps.

However, this logic was changed in the latest aggregator interface. Calling `getRoundData(roundId)` is now reverting if `roundId` cannot be found, which makes the current logic obsolete.

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

This SIP will implement low-level calls to Chainlink aggregator's `getRoundData()` and `getLatestRoundData()` functions in order to suppress any reverts.

```
    bytes memory payload = abi.encodeWithSignature("getRoundData(uint80)", roundId);
    (bool success, bytes memory returnData) = address(aggregator).staticcall(payload);
```

As shown above, `staticcall` is used here to avoid `getRoundData()` from reverting, returning `success` and `returnData`.

If `success` is true, `ExchangeRates` will then update the rates with `returnData`.
If `success` is false, we do nothing.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

A production test will need to be added with the following scenario:

- Exchange a synth from sUSD to sETH
- Wait the required amount of time for a transaction to be allowed to settle (`SystemSettings.waitingPeriodsSecs()`)
- Settle sETH

This scenario will only pass if the patch described in this SIP is implemented. It will fail otherwise.

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
