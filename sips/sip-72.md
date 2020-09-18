---
sip: 72
title: Add More Assets to the Binary Options Markets
status: WIP
author: psybull (@psybull)
discussions-to: https://research.synthetix.io/t/sip-add-more-binary-options-markets/116

created: 2020-07-25
requires (*optional): N/A
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->
This SIP seeks to expand the list of assets available to Binary Options market creators, with a focus on mid-small market cap assets, to satify latent trading demand for these assets in the broader market.

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->
I propose that the following assets be added to the Binary Options market creation list:

[ AKRO, AMPL, BAL, BZRX, MTA, RUNE, SWTH, YFI ]

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->
While the Binary Options markets started off strong, interest has waned since launch, and this SIP seeks to expand the available asset list to play to the strengths of the system and capitalizing on underserved market demand.  I will outline 3 categories of assets that I feel exemplify this idea: 'DeFi Farming/governance', 'non-ETH-native', and 'unique mechanic'.



This SIP 

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
By expanding the asset list available to the Binary Options market creators in the following categories, we can better serve market demand, which will ultimately result in more users and higher revenues for the Synthetix ecosystem.

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The general rationale is that by adding assets in some key sectors, we can target underserved demand in the trading market.  

One overarching point to add, is that while, due to the nature of the system, SNX mintrs are not at risk, the markets themselves are still easily manipulated, and thus the Binary Options participants will be at risk of fraud.  This is not easily mitigated, so as a precautionary measure I would recommend that total market sizes be capped at some fraction of overall asset marketcap or volume metric, but without deeper analysis I would say no more than 25,000 sUSD should be able to be bet on any individual market listed here, until such a time as a more objective cap can be determined.

The rationale behind specific sectors is as follows:

### DeFi Farming/Governance

The liquidity mining craze has resulted in a number of project which seek to reward long term users though distribution of highly-inflationary tokens, which has become a source of concern for many users in the market.  Having binary options available for these tokens will give the market an ability to hedge these long term risks with appropriate price strikes and expiry dates.

Suggested assets in this class: [ AKRO, BAL, BZRX, MTA, YFI ]

### Non-ETH-Native

Another class of markets should be centered around tokens that do not exist natively on the ETH chain.  This is already a core value proposition of the Synthetix Exchange, and we should certainly be aggressively fulfilling that promise where we can.  Larger cap coins from other chains are already broadly available (many with full synths), but expanding our list to mid and small marketcap, non-ETH-native assets should be fully aligned with our goals.

Suggested assets in this class: [ SWTH, RUNE ]

### Unique Mechanic

The final class of asset I am defining 'Unique Mechanic' to explain assets which, through a specific mechanism of their design, have a strong market-potential for a Price-and-Time specific bet.  I am suggesting this based on the `rebase` mechanic of the Ampleforth project.  I suggest that there is latent demand for traders who would like to make plays on the outcome of the `rebase`, but who do not trust the asset itself enough to buy it and expose themselves to the full asset price exposure.  As crypto matures, I can only expect more of these assets will emerge.

Suggested assets in this class: [ AMPL ]

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
Same technical spec as added for the COMP/LEND/KNC/REN addition, but for AKRO/AMPL/BAL/BZRX/MTA/RUNE/SWTH/YFI (couldnt find SIP for this to emulate, though)

As an added technical requirement, capping all markets listed here at 25,000 sUSD total value.

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Same test cases as added for the COMP/LEND/KNC/REN addition

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
While I believe the list of available assets should be configurable by SCCP, I also think that a more general 'make the binary options list fully SCCP' is a separate SIP to work on after this SIP is deployed and analyzed.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
