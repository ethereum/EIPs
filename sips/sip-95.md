---
sip: 95
title: Delist sBCH and iBCH for evaluation
status: Implemented
author: Jackson Chan (@jacko125), Garth Travers (@garthtravers), Clinton Ennis (@hav-noms)
discussions-to: https://discordapp.com/invite/AEdUHzt

created: 2020-11-16
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Delist sBCH & iBCH due to the contentious Bitcoin Cash (BCH) fork to BCHN and Bitcoin Cash ABC, as BCH as it was formerly known no longer exists in the same sense and price feeds are unreliable at this stage.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Delist BCH and wait until the dominant fork and price feeds are established and then re-examine its listing using the Delphi asset listing framework.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

There is uncertainty around the identity of BCH, as it has been forked into two separate versions. To protect traders and SNX stakers against this uncertainty, it will be prudent to remove BCH until the situation is clarified or resolved.

## Rationale

Since the BCH asset has forked into two new assets, each would need to be subject to the Delphi asset listing framework to meet the requirements to be able to be added back to the protocol.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

Delist sBCH & iBCH

1. Upgrade iBCH without purge exchange limit of 100,000 sUSD
2. Upgrade sBCH to a Purgeable Synth
3. Purge sBCH & iBCH into sUSD
4. Remove sBCH & iBCH from the protocol and the exchange

Relist sBCH & iBCH

1. In a few weeks consider the dominate chain and potential change in symbol.
2. Re-evaluate using Delphi asset listing framework
3. Get updated Chainlink Oracle price feeds
4. Deploy new Synths

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
