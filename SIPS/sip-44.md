---
sip: 44
title: Synthetix & Synth Disabling
status: Proposed
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-02-28
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Add a new `SystemStatus` contract to allow both synth pausing and system upgrades.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

A `SystemStatus` contract can hold various types of state for system events. These include: system upgrades, synths frozen due to inverse limits being hit, synths disabled due to security concerns, synths paused during out-of-trading hours for the underlying asset.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

There are a number of conditions where the Synthetix system needs to be able to pause. These are as follows:

1. **During upgrades**: Currently we have a workaround to disable the entire protocol by setting `ExchangeRates.rateIsStale` period to `1`. This is fairly rudimentary and needs improvement. Moreover a better reject reason will go a ways towards helping users address concerns during these windows.
2. **Security meaures**: There have been occasions where synths have needed to be disabled immediately, such as during the attack on sMKR and iMKR (see [SIP-34](./sip-34.md)). This gives the team and community time to investigate the situation and determine the next steps with minimal impact to the rest of the system. Moreover, we're continuing to build live monitoring software that can detect and disable synths whenever an attack is launched.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

1. **System Pause**: All synth and SNX transfers disabled. All exchange, issue, burn, claim, loan and mint functionality disabled. This is both for system upgrades and under possible emergency situations. This will controlled by an access control (see below).
2. **Synth Disabling**: For the synth in question, all transfers and exchanges into or out of disabled. Also controlled by an access control list.
3. **Access Control**: A whitelist of addresses that can toggle the `System Pause` and the `Synth Disabling` processes, along with whether they can disable or re-enable. This whitelist will be managed by the `owner`.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The Access Control allows the `owner` to configure the right kind of emergency system pause access to a range of manual and automated protection mechanism if anomalies or exploits are detected.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TDB

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TDB

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
