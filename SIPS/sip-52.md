---
sip: 52
title: Add Next Price to Fee Reclamation
status: Proposed
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-03-04
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Expand fee reclamation to use next price update for certain synths

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Add an optional mechanism to fee reclamation where instead of a waiting period in time for calculating price differences, some synths would require a new price update.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

The underlying assets of certain synths - such as forex, commodities, stocks and indicies - undergo spot market closures. For forex and commodities, spot market closures are weekends across all world timezones (Friday at 5 pm EST - Sunday 5 pm EST). For stocks and indicies, there are evenings, weekends and public holidays for in each market's region. During these periods where spot markets are closed, the futures markets continue to operate and world news continues to be delivered that may impact futures and shift the spot price at next market open. In order to prevent Synthetix traders taking advantage of these upcoming movements, we propose expanding fee reclamation for these synths, so that instead of waiting some number of time in the future, fee reclamation will wait until a new price has been received.

Moreover, this functionality would be useful for leveraged synths. If on-chain prices are only updated every hour (and potentially variant per pricing network) and on a 1% deviation via Chainlink's decentralized pricing networks, leveraged synths with only a timed fee reclamation waiting period could expose the debt pool to significant frontrunning opportunites. Instead, this proposal would allow adding leveraged synths into this

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

1. `Exchanger` would need a new `mapping(bytes32 => bool)` to track which synths require this new "next price" waiting period (others would continue to use the timed waiting period)
2. `Exchanger.maxSecsLeftInWaitingPeriod()` would always return `0` for those using the "next price" feature
3. `ExchangeRates` needs new function to `getNextRoundId(fromRoundId, bytes32)`
4. `Synthetix.isWaitingPeriod(bytes32)` would need to be amended, if any exchange into (`dest`), out of (`src`) (or both) a "next price" synth, then needs to lookup in `ExchangeRates.getNextRoundId()` to see if a new price has been received or not (for one or both)
5. `Exchanger.settle()` would need to determine next price for `src` and `dest` using either timed waiting period (as now) or "next price" (via #3 above), depending on each synth's parameters from #1 above.

Given the additional mechanism, an exchange's waiting period needs to consider both the `src` and the `dest` synths. The waiting period would be timed if and only if both synths are using timed. In all other cases, a combination of "next price" and timed will be required, and the waiting period will be the longer of the two.

For example, imagine Alice exchanges `100 sAUD` (a next price synth) to `sETH` (a timed synth) on a weekend. Her exchange succeeds but now the next price waiting period on `sAUD` would extend until forex market open at Sunday 5pm ET. This would mean she couldn't exchange or transfer any `sETH` until then.

> One potential way to solve this is to amend Fee Reclamation logic ([SIP-37](./sip-37.md)) to allow exchanges and transfers that are from funds not undergoing a waiting period. Imagine in the above scenario where Alice would have 0.5 sETH (if ETHUSD was at 200) after the exchange, she could be permitted to exchange or transfer ETH as long as she'd be left with at least 0.5 sETH to potentially reclaim from.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The current fee reclamation system relies on tracking `12` (configurable) exchanges into some given synth before requiring settlement. Then, at settlement, it calculates how much is owed and reclaims or rebates the amount. Expanding it for this functionality is not too difficult (as outlined above), though it makes reasoning about ongoing waiting periods more cumbersome for users.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
