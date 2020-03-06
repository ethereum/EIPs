---
sip: 47
title: Prevent Empty Exchanges
status: Proposed
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-03-05
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Prevent exchanges, burns and transferAndSettles from succeeding with 0 amounts.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Fix an edge-case that was introduced with SIP-37 that reduces exchanges, burns and transferAndSettle invocations down to the user's balance - even if no settlement occurred.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Since [SIP-37](./sip-37.md) exchanges of invalid amounts for the user have been succeeding as `0` exchanges, emitting events. These successful transactions may cause users to think their exchanges have gone through and they also create noise in event monitoring tools such as The Graph.

For example, this user performed the same transaction twice with increasing nonces. The [first succeeded](https://etherscan.io/tx/0xe05e71203c2c703663a5df5d37ea1edd94e111b212de6153020cce9cedba6957) and exchanged `0.003` sBTC into `sUSD` and the [second also succeeded](https://etherscan.io/tx/0x481fbfaab71b15ef97b2830df7ff7601183c2b4a5530233392ce405da8b1e26c) but exchanged `0`.

This proposal is to simply check for any unsettled exchanges and only then to amend the amount, otherwise to treat the amount incoming as before SIP-37 was introduced (that is, revert if the amount is more than the user has).

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

- `Exchanger.settlementOwing` to return the number of entries in the queue for that synth.
- `Exchanger.settle` to return the number of entries removed in the settlement as `numEntriesSettled`
- `Exchanger.exchage`, `Issuer.burnSynths`, `Synth.transferAndSettle` and `Synth.transferFromAndSettle` to all take this `numEntriesSettled` into consideration - if `numEntriesSettled == 0` then the amount to use is what's been given the function - as per the pre-SIP-37 implementation. If `numEntriesSettled > 0` then adjust the amount as per SIP-37.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Admending `settlementOwing` to return `numEntries` prevents any further cross-contract calls, thereby limiting gas.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
