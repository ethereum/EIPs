---
sip: 56
title: Differential Fees
status: WIP
author: Clinton Ennis (hav-noms)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-05-01
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Ability for the protocol DAO to configure different exchange fee rates for each `Synth`.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Currently there is one universal exchange rate for exchanging synths which is set onchain in the `FeePool`.

Upgrading the `FeePool` to allow an array of Synths exchange rates to be set allowing unique pricing per asset or class.

There could be multiple pricing options TBD such as;

1. Charge the fee rate of the synth being exchanged into. e.g. If sETH is 1% and sUSD was 0% then it would be free to exchange from sETH to sUSD.
2. Charge the sum of the pair. e.g. if sETH is .5% and sUSD is .1% the total exchange fee would be 0.6%
3. Charge the lowest of the pair. e.g. if sETH is .5% and sUSD is .1% the exchange fee would be 0.1%

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

With a universal exchange fee rate the protocol is limited in its ability to price markets fairly or apply incentive mechanisms. To deter front runners setting a high exchange rate was used to reduce profiitability affecting all Synth markets and discouraging good actors from trading.

Unique pricing per synth would allow potential outcomes such as;

a) Different price categories such as fiat, crypto, inverse, indices, commodities or stocks.

b) Used as a configurable protocol mechanism via SCCP to increase rates to deter new trades exchanging into a synth where there is an oversupply or potential debt risk to the system.

c) Configure a synth's exchange rate such as sUSD as low as possible to encourage traders to move into it or for SNX stakers to return to sUSD at no cost to be able to burn it to maintain the systems target c-ratio.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Storage of the rates should use the `uint mappings` in the `FeePoolEternalStorage` contract so `FeePool` logic can be upgraded maintaining the exchange fee rate state.

New functions required in the upgradable `FeePool` contract.

### setExchangeFeeRateForSynths

Will allow the protocol DAO to set n number of exchangeFeeRates for n number of synths in one transaction.

**Function signature**

`setExchangeFeeRateForSynths(bytes32 [synthKeys], uint256 [exchangeFeeRates]) onlyOwner`

- `bytes32 [synthKeys]`: The array of currencyKeys for the synths to set
- `uint256 [exchangeFeeRates]`: The array of rates

### exchangeFeeRateForSynth

Return the exchange fee rate for a synth

**Function signature**

`exchangeFeeForSynth(bytes32 synth) public view returns (uint)`

- `bytes32 synth`: synth key to request the rate for 

### deleteExchangeFeeRateForSynths (optional)

Will allow the protocol DAO to delete n number of synth rate entries freeing up the storage of removed / deprecated synths

**Function signature**

`deleteExchangeFeeRateForSynths(bytes32 [synthKeys]) onlyOwner`

- `bytes32 [synthKeys]`: The array of currencyKeys for the synths to delete


New functions required in the upgradable `Exchanger` contract.

### exchangeFeeForTrade

Returns the exchange fee in sUSD.

Deprecate existing fee view function `FeePool.exchangeFeeIncurred(uint value) public view returns (uint)`
and move to `Exchanger.feeRateForExchange`
to accept the Synth trading pair as arguments to determine the exchange fee for the trade. 

**Function signature**

`exchangeFeeForTrade(uint amount, bytes32 source, bytes32 destination) public view returns (uint)`

- `uint amount`: Amount of the source Synth to exchange
- `bytes32 source`: Synth exchanging from 
- `bytes32 destination`: Synth to exchange into 

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

It was considered that a `Synth` should store its own rate by having a setter for `exchangeFeeRate`. However the rate storage would be lost on each upgrade and need to be reset again adding overhead to the upgrade process. Also each Synths external `TokenState` is already immutable and not upgradable.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
