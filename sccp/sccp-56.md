---
sccp: 56
title: Reduce exchange fees of sETH and sBTC to 0.3%
author: Justin J Moses (@justinjmoses)
discussions-to: governance
status: Implemented
created: 2020-11-03
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Reduce exchange fees of trades into `sETH`, `iETH`, `sBTC` and `iBTC` to `0.3%` to align with all other non-crypto synths.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

As [ETHUSD](https://feeds.chain.link/eth-usd) and [BTCUSD](https://feeds.chain.link/btc-usd) price networks are now based on `0.5%` deviations, lower the exchange fees into those synths to the base `0.3%` fee that is used elsewhere.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Other synths in the Synthetix protocol - forex, commodities, equities and indexes - are all based on `0.5%` deviations on their respective Chainlink networks yet all use `0.3%` exchange fees. The [BTCUSD](https://feeds.chain.link/btc-usd) network has recently been lowered to use a `0.5%` deviation to be in line with [ETHUSD](https://feeds.chain.link/eth-usd), so it seems timely to a) reduce the fees on `sBTC` and `iBTC` to match `sETH` and `iETH` and b) reduce them both to `0.3%` to line up with the rest of the non-crypto synths using `0.5%` deviations.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
