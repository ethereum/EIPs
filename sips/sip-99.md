---
sip: 99
title: Upgrade sOIL to use diversified Chainlink aggregator
status: Proposed
author: Clinton Ennis (@hav-noms)
created: 2020-11-26
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Upgrade sOIL to track new price sources such as OTC desk trading.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Aim is to diversify the amount of data sources we use for the oil feed in order to not rely on a limited number of data sources and help decentralize the reliability of the pair as a result.


## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is inaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

The current pair doesn’t rely on enough data sources we aim to improve this by working with Chainlink adding OTC trade data and deploying a new aggregator.


## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

Change ExchangeRates to point to the new WTI Aggregator for sOIL will require these steps;

1. Suspend sOIL, iOIL synths to pause trading
2. Purge holders back to sUSD (~$1500 in holdings)
3. Update ExchangeRates OIL aggregators
    v3 Aggregator Contract Address 0x2747254824f1731e016352e3267735fd9a6331C0
    v3 Proxy Contract Address 0xf3584F4dd3b467e73C2339EfD008665a70A4185c
4. Set new Inverse Pricing based on current price data
5. Unsuspend sOIL and iOIL to resume trading


### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
