---
sip: 58
title: Emit every fee reclamation outcome during trade settlement
status: Implemented
author: Jackson Chan (@jacko125)
discussions-to: <https://discord.gg/ShGSzny>

created: 2020-05-11
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Emit list of individual fee reclamations and rebates during trade settlement for Dapps and Synthetix Exchange.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

In order to help users track fees claimed or rebated from individual transactions, emit events during settlement that match each individual exchange being settled with the amount reclaimed or rebated.

Upgrade the Exchanger `settle()` function to emit individual fee reclaimation / rebate amounts for each trade.

Emit an extra event on each Exchange to provide information on the source and destination currencyKey RoundID the exchange was executed at.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

We want to display on Synthetix exchange the corresponding fee reclamation amounts (if any) for each individual exchange made when exchange settlement is invoked.

Currently invoking `settle()` will only emit one event, if any, with the total aggregated sum of any fee reclamation or rebate amounts. This makes it difficult and complex for users trying to determine the dividual settlement rates on previous trades they've made.

It is important that traders can see on each trade the fee reclamation and rebates for calculating trading profits and loses based on the amounts and effective price they recieved on each individual trade.

Vice versa emitting extra information when an exchange transaction occurs such as the RoundID's for the source and destination currencies will allow Dapp's to get effective rate for the pair by querying the ExchangeRates contract.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

### Exchanger.settle ###

Add an internal function `_settlementsOwing` that will emit an event `ExchangeEntrySettled` for each reclaim and  rebate when `Exchanger.settle()` is invoked.

`Exchanger.settle()` will calculate the fee reclamation amounts and emit the event.

**Event**

Emit an event `ExchangeEntrySettled` for each exchangeEntry when `Exchanger.settle()` is invoked.

```solidity
event ExchangeEntrySettled(address indexed from, bytes32 src, uint amount, bytes32 dest, uint reclaimAmount, uint rebateAmount, uint srcRoundIdAtPeriodEnd, uint destRoundIdAtPeriodEnd, uint exchangeTimestamp);
```

### Exchanger.appendExchange ###

Emit an event `ExchangeEntryAppended` for each exchangeEntry created when a user makes an exchange. Capture details such as roundIdForSrc, roundIdForDest for Dapps to calculate the effectiveValue of the exchange at anytime by querying the onchain data.

```solidity
event ExchangeEntryAppended(address indexed account, bytes32 src, uint amount, bytes32 dest, uint amountReceived, uint exchangeFeeRate, uint roundIdForSrc, uint roundIdForDest, uint timestamp);
```

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The decision to add an internal function `_settlementsOwing` that will emit individual fee reclaim and rebate events when `Exchanger.settle()` is invoked allows the public view function `settlementOwing(address account, bytes32 currencyKey)` to be kept for users to query the total aggregated reclaim and rebate amounts they have to settle.

`_settlementsOwing` will be used for settlements and emit the individual events persisting them onto the blockchain once the transaction is confirmed.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- The events are emitted off the Exchanger contract.
- When `Exchanger.settle()` is invoked, the `_settlementsOwing` function is invoked and returns (uint reclaimAmount, uint rebateAmount, uint numEntries, ExchangeEntrySettlements[] settlements).
- When `Exchanger.settle()` is invoked, it emits `ExchangeEntrySettled` event with a non-zero reclaimAmount for each ExchangeEntry that has a reclaim amount - (`amountReceived > amountShouldHaveReceived`).
- When `Exchanger.settle()` is invoked, it emits `ExchangeEntrySettled` event with a non-zero rebateAmount for each ExchangeEntry that has a rebate amount - (`amountShouldHaveReceived > amountReceived`).
- When `Exchanger._exchange()` is invoked, it emits `ExchangeEntryAppended` event for each ExchangeEntry appended to the ExchangeState with details combined in.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

(None)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
