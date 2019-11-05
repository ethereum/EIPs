---
sip: 25
title: Decouple Gas Limiter from Oracle
status: Approved
author: Justin J. Moses (@justinjmoses)
discussions-to: https://discord.gg/3uJ5rAy

created: 2019-10-29
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Allow the control of setting the `gasPriceLimit` to be detached from the centralized SNX `oracle`.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

The current `gasPriceLimit` in Synthetix can only [be changed by the central SNX Oracle](https://github.com/Synthetixio/synthetix/blob/v2.11.2/contracts/Synthetix.sol#L216). This proposal is to change this access to a separate address, controlled by a setter only callable by the `owner`.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Due to the way Ethereum handles nonces, all transactions from a single account have to be mined in (nonce-based) order, one at a time. Thus any invocation of the `setGasPriceLimit()` function has to be mined before a price update can be mined on-chain. This creates an unnecessary delay in serving timely oracle updates.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

In `Synthetix.sol`:

- Add a new public `address` property on `Synthetix` called `gasLimitOracle`
- Add a new `onlyOwner` setter function to mutate the `gasLimitController` called `setGasLimitOracle`
- Modify `setGasPriceLimit()`, removing the `onlyOracle` modifier and adding a `require(msg.sender == gasLimitOracle)`

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

I propose modifying `Synthetix.sol` rather than moving the limiter into `ExchangeRates` and thus requiring a change of that contract as well. Further, I propose using a `require` rather than a modifier for the `setGasPriceLimit` function, to reduce gas usage on the already very large `Synthetix` contract.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases will be included with the implementation.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

> The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
