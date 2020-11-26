---
sip: 98
title: Re-implement double exchange fee rate on swing trades
author: Jackson Chan (@jacko125), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/CDTvjHY
status: Proposed
created: 2020-11-27
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Double the exchange fee rate on any swing trade. That is any move to or from an `s` Synth to an `i` Synth. e.g. `sTRX` <> `iBTC` or `iETH` <> `sBNB`. The one Synth excluded from this is `sUSD` - moving in or out of `sUSD` will _not_ double the fee.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Doubling the exchange fee rate would reduce the amount of opportunities for a front runner swing trading between the long and inverse synth of a feed, i,e `sBTC` and `iBTC` without moving into `sUSD` first. This mechanism was previously implemented in [SIP-21](./sip-21). This SIP targets swing trading and reduces the need to increase fees on the synths via SCCP's which affect other traders / users of the platform.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

There is already a leveraged benefit on the inverse Synths and currently being able to trade short <> long in a volatile market is a continuous advantage to front runners.

It has been observed that there are possibilities to frontrun real world prices and the on-chain oracle prices between the long `s` synth and the inverse synth, without moving in between `sUSD` which would incur a 30bips fee to sell the short or long position first before opening a swing trade.

Exchanging in or out of `sUSD` will _not_ double the fee.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

- In `Synthetix.exchange()` detect a swing trade, that is any exchange to or from any synth beginning with s or i.
- Double the `ExchangeRates.exchangeFeeRate()`

For example, if the exchange fee rate is 30 bips, it would make the swing trade 60 bips both direction.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
https://github.com/Synthetixio/synthetix/blob/v2.12.2/test/Synthetix.js#L2833

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
https://github.com/Synthetixio/synthetix/commit/4022200fbe82ff25f6113993dc3bc84c442240c1

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
