---
sip: 84
title: Pause Synths Below Open Interest Threshold
status: Proposed
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125)
discussions-to: https://research.synthetix.io/t/sip-84-pause-synths-below-open-interest-threshold/189

created: 2020-08-31
requires: Insert SIP for debt aggregation calcs
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Pause synths that are below the open interest threshold in order to reduce the gas costs of issuance, fee claiming and transfers

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

This SIP proposes to pause synths with a supply below `50k USD` until a new SIP can be implemented that leverages Chainlink to reduce the cost of calculating the debt pool. Pausing these synths will reduce the cost of minting and burning by as much as 75%. While this proposal is not ideal, it is important as without it the migration to external oracles will increase the cost of minting and burning by more than 50%.

We propose to freeze the prices of synths below the open interest threshold of `50k USD`, we will then purge them into `sUSD` and temporarily disconnect them until we can get a workaround implemented ([sip-83](https://sips.synthetix.io/sips/sip-83)).

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

In the current gas environment minting and burning costs can reach \$50 USD per tx or higher. This is because the protocol needs to know the size of the debt pool, and it is calculated by summing up the `USD` value of all 40+ synths `totalSupply`.

With the migration to decentralized oracles in [SIP-36](https://sips.synthetix.io/sips/sip-36), there is even more additional gas costs of reading state from external contracts via the `CALL` opcode for each and every synth, along with the existing `SLOAD` required to read contract state. These additional `CALL` codes impact issuance transactions by `5-100%`. By temporarily reducing the number of Synths we can reduce the gas costs below the current amount even after factoring in the increase.

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

We will specificy a threshold for Synth open interest, any synth that falls below this threshold will be frozen and purged following the _Pollux_ release. [SIP-83](https://sips.synthetix.io/sips/sip-83) has been proposed that once implemented, will reduce gas such that these synths can be resumed. The changes will allow us to significantly expand the range of support synths without incurring incremental gas costs.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Once temporarily reducing the number of Synths was deemed necessary we needed to choose a mechanism for removing them. While many of the the synths below the threshold have minimal open interst several have `10-45k USD` in value, in order to minimise the impact to holders purging them into `sUSD` was deemed the optimal path. The alternative is to freeze the price and leave the Synths disconnected until such time as they could be reconnected and the price updated. The issue with this approach is that a holder would be unable to exit the position until the synth was reconnected expositing them to price volatility with no means of exit.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
