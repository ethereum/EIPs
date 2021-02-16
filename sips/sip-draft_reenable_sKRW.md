---
sip: <to be assigned>
title: Reenable sKRW
status: WIP
author: Andre Cronje (@andrecronje), Kain Warwick (@kaiynne)
discussions-to: <Create a new thread on https://research.synthetix.io and drop the link here>

created: 2021-02-16

---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->
Add an sKRW Synth to enable cross asset swaps on Curve.

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->
This SIP will reenable the previously deprecated sKRW Synth that tracks the price of the Korean Won.

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->
Due to the success of cross asset swaps on Curve there are a number of new pools being proposed. The sKRW synth was previously deprecated along with a number of other low volume Synths due to the cost overhead they created for the debt pool. This SIP proposes to reenable them in order to support cross asset swaps on Curve from sKRW<>ETH and sKRW<>BTC and potentially other assets.

Further to the above, there are emerging KRW assets that are gaining momentum. Most notably KRT. Other organizations are also working on wKRW implementations. As at time of writing Binance also has a bKRW pair, however this is in the process of being deprecated for regulatory uncertainty. With the emergence of KRT and wKRW this will allow for sKRW <> KRT <> wKRW pairs on Curve. These pairs would allow for KRW holders to be able to arbitrage the Kimchi premium / discount. They could Trade from exchanges that have KRT (such as Coinone), use Curve's cross-asset swap to go from KRT to BTC/ETH in large volumes and arbitrage back to KRT. Quick calculations shows that it would require a few orders of magnitude more than $100MM volume to be able to arbitrage this premium.

As a disclaimer to the above however, there is new regulatory decisions being made in South Korea in March specifically related to the rulings around digital assets, so there is currently caution with regards to KRW <> wKRW onboarding. The organisations we are working with are monitoring this closely however and if favorable will move forward with KRW custodianship and issuance. We have also started discussion with a few Korean exchanges and interest & demand for such a product has been high.

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
An sKRW Synth will be deployed and connected to a Chainlink Aggregator contract, which is yet to be deployed, pending CL feasibility confirmation.

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
This Synth will be implemented as per the standard deployment mechanism, however, an iSynth is not proposed in line with other fiat currency Synths.

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
TBC

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
Please list all values configurable via SCCP under this implementation.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
