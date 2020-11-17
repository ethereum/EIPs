---
sip: 96
title: Blockchain Forks Framework for Synths
status: Proposed
author: Jackson Chan (@jacko125), Garth Travers (@garthtravers), Clinton Ennis (@hav-noms)
discussions-to: <https://research.synthetix.io/>

created: 2020-11-16
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Proposes a blockchain fork framework for Synthetix protocol. When the underlying blockchain asset has an upcoming hard fork, the related synths will be suspended 72 hours beforehand and exchanges stopped. Blockchain hard forks can split the consensus of the forked network and price feeds become unreliable.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Suspend synths 72 hours before an upcoming hard fork. This will prevent the synths from being exchanged and transferred. If the fork is contentious and there are two resulting chains, the framework provides the option to delist the synths temporarily, until the dominant fork and price feeds are established and then re-examine its listing using the Delphi asset listing framework.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

When a blockchain undergoes a hard fork, there could be two different versions of the chain that are running simultaneously creating uncertainity in the price feeds for the asset. Exchanges and miners can choose to adopt a prevailing fork of a chain and this process could take a few days to stabilise.

To protect traders and SNX stakers against this uncertainty, this framework proposes to suspend the affected Synths 72 hours before the hard fork event.

In the case of contentious hard forks where there are two competing forks, a SIP could be proposed, for example in the case of the recent [BCH fork](.sip-95.md), to the community and stakers to delist the synths and then re-examine relisting the synths once the dominant fork and price feeds are established.

## Rationale

Hard forks happens when a blockchain protocol makes an upgrade to their underlying software and require miners (which can be measured in hashrate) to choose to adopt the hard fork or not. Some upgrades can be contentious whereby the majority of a blockchain community (miners and exchanges) may choose to not adopt.

The uncertainity a hard fork introduces requires the protocol to suspend the exchange and trading of the synths until the community and stakers can decide on whether to re-enable trading or delisting the affected synths.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

1. Notify stakers and traders that the synths will be suspended 72 hours ahead of the fork.
2. The Protocol DAO will suspend the long and inverse synths.
3. SIP raised if the synths need to be delisted and purged back into sUSD before the fork happens.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
