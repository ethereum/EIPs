---
sip: 116
title: Conditionally skipping fee reclamation
status: Proposed
author:
discussions-to:
created: 2020-02-25
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Allow waiting period to be set to zero and avoid unecessary fee reclamation functionality.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

[SIP-114](./sip-114.md) will enable synth exchanging on L2. Given that transaction (and hence oracle) frontrunning is not possible on Optimisic Ethereum (OE), there is no need for storing exchanges and settling them after a certain amount of time has elpased. This SIP proposes to set the waiting period to 0 when possible, as is the case with Optimism.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

In Phase 1 of the [transition to Optimistic Ethereum](https://blog.synthetix.io/the-optimistic-ethereum-transition), basic synth functionality is going to be enabled ([SIP-114](./sip-114.md))
Every time a user exchnages a synth for another, the trade is stored temporarily and can be settled after a certain waiting period (`waitingPeriodSecs` in `SystemSettings`) has elapsed, currently set to 6 minutes. This is mainly done to address oracle front running i.e. monitoring the mempool for oracle price updates and making a favourable trade before the price is updated. After the aforementioend waiting period has expired, the exchange can be settle on the fair price and the user gets either a rebate or a reclaim. This whole procedure is not needed on OE, thus the waiting period can be set to 0 and skip part of the overhead imposed by settlement.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview

<!--  -->
<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

No new contracts were developed for this SIP, contract functionality was slightly altered. The waiting period should be set to 0 when deploying an OVM instance and no rebate/reclaim takes place. This can done by specifying a WAITING_PERIOD_SECS entry in the `params.json` file of the corresponding deployment. In the `Exchanger` contract, an extra check is added to prevent storing exchanges and subsequently having to settle them, reducing in this way both the computational and storing overhead and saving gas.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Due to the near-instant confirmation time of the transactions on L2, oracle front-running is no longer an issue, thus, exchanging needs no settlement. The waiting period parameter is set to 0 when deploying on L2 and there are extra checks in the code that bypass storing exchanging information to reduce unnecessary functionality and contract calls and hence gas costs. More specifically, no exchange entries are created via `appendExchange()` when the waiting period is 0. However, when a subsequent exchange takes place, the code that settles and calculates the 'fair' amount, namely `_settleAndCalcSourceAmountRemaining()`, is still being called. This is done to protect the system from the edge case where the waiting period is switched from a non-zero value to zero and there are still exchanges in need of settlement stored in the system.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

> Note: code snippet taken from Exchanger.sol

```solidity
 // iff the waiting period is gt 0
 if (getWaitingPeriodSecs() > 0) {
            // persist the exchange information for the dest key
            appendExchange(
                destinationAddress,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                amountReceived,
                exchangeFeeRate
            );
        }
```

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
