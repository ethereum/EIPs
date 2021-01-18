---
sip: 94
title: Virtual Synth Fix to Ensure Settlement Is Connected
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: https://research.synthetix.io

created: 2020-11-12
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Ensure the Virtual Synth (vSynth) implementation (SIP-89) correctly tracks the virtual synth address for settlement

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Patch release the vSynth implementation to ensure the following:

1. **Major**: Exchange settlement tracks the virtual synth not the `msg.sender`.
2. **Minor**: vSynths to use synth proxies not the underlying address
3. **Incidental**: Adding `trackingCode` as final argument to `exchangeWithVirtual`
4. **Incidental**: Minor changes to `VirtualSynthCreated` event signature

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

1. The vSynth release in Mimosa had a bug whereby the exchange settlement was using the `msg.sender` not the vSynth contract `address`. This meant that settling the vSynth wasn't connected to the underlying synth settlement, and would require an additional settlement at the synth level
2. vSynths use underlying Synth addresses to transfer synths after settlement, however this is brittle when the protocol upgrades and disconnects the old underlying Synths. The solution is to use their proxies.
3. Adding an optional tracking code helps include volume incentive when necessary
4. Minor changes to include the `address recipient` of the vSynth supply.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

Please see [https://github.com/Synthetixio/synthetix/pull/881](https://github.com/Synthetixio/synthetix/pull/881)

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
