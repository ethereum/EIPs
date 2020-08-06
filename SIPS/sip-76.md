---
sip: 76
title: Integrate Warning Flags to Disable Transactions
status: Proposed
author: Justin J Moses <@justinjmoses>
discussions-to: https://research.synthetix.io/t/sip-76-chainlink-warning-flags/167

created: 2020-08-05
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Integrate Chainlink’s warning flags contract into Synthetix to prevent any mutative action against a synth that has its price feed flagged.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Chainlink have prepared a flags contract which allows them to indicate if there's an issue with a given `Aggregator`. During an `exchange` of `src` to `dest` synth, if the corresponding `Aggregator` is flagged, then the `exchange` will fail. In addition, all issuance functions (`issue`, `burn`, `claim`) also need to be prevented as these require the calculation of the entire debt pool, which cannot be done if any synth has an invalid price.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

As the Synthetix protocol migrates to Chainlink feeds for all remaining prices (in the upcoming [SIP-36](./sip-36.md)), the primary responsibility of monitoring and maintenance shifts from Synthetix to Chainlink. Having a flags contract controlled by the Chainlink team allows their monitoring teams to flip a warning switch in the case of any outage and prevents spurious actions on the Synthetix protocol taking advantage of incorrect pricing.

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

The interface proposed by Chainlink is a `view` that takes an `Aggregator` `address` and returns a `bool`. This value is `true` if there is an issue and `false` otherwise.

Synthetix's `ExchangeRates` contract will need to expose this functionality so other contracts can check it at the time of exchanging or issuance. It currently exposes `rateIsStale`, so this functionality can be replicated by a function `rateIsInvalid` that encompasses either `rateIsStale` OR `rateIsFlagged`.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

`ExchangeRates` is the only contract that currently knows about the pricing `Aggregator` addresses. The various issuance and exchanging functionality already interfaces with `ExchangeRates` to check for stale rates. This check can be modified into a new function `rateIsInvalid` that can combine a stale check with a flag check. If a transaction fails due to `rateIsInvalid`, the specific reason can be inferred from reading the state of the `ExchangeRates` contract for that `currencyKey` - either stale or flagged.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

- `ExchangeRates` to be given a new function `rateIsInvalid` that returns `true` if the given `currencyKey` is either stale or flagged. In addition `ratesAndStaleForCurrencies` and `anyRateIsStale` will be renamed to replace `Stale` with `Invalid` and modified to iniclude the flagged state.
- All uses of `rateIsStale` and its associated functions in other Synthetix contracts, to be replaced with the aforementioned `Invalid` counterparts

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Given there exists a user Marie with `100 SNX`, `5 sUSD`, `1 sETH` and `0.1 sBTC`
And the flag contract returns `true` for the aggregator address of `sETH`

- When Marie attempts to exchange all her `sUSD` for `sETH`,
- ❌ Then the transaction fails as the rate of `sETH` is invalid

- When Marie attempts to exchange all her `sETH` for `sUSD`
- ❌ Then the transaction fails as the rate of `sETH` is invalid

- When Marie attempts to exchange all her `sBTC` for `sUSD`
- ✅ Then the transaction succeeds as the rate of `sBTC` is valid (`sUSD` is always valid)

- When Marie attemps to issue more `sUSD`, burn her `sUSD` or claim any outstanding rewards
- ❌ Then the transaction fails as one of the synth rates (`sETH`) is invalid

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

None.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
