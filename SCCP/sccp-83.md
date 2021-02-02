---
sccp: 83
title: Apply Market Closure Mechanism on Forex and Commodity Synths
author: Kaleb Keny (@kaleb-keny) , Spreek (@spreek)
discussions-to: governance
status: Implemented
created: 2021-01-31
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Apply going forward the same market closure mechanism, currently applied on stocks, on commodities and forex synths.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Freezing the below mentioned synths until the market is open and a fresh price is pushed. To clarify, no trades on the contracts will be possible when markets are closed.
- sEUR
- sJPY
- sAUD
- sCHF
- sGBP
- sXAU
- sXAG
- sOil
- iOil


## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

During market closures, it is not possible for oracle prices to be updated. The reason for this is because when the major futures and spot markets are closed prices are no longer updating. This creates a risk that when the market is aware of a likely gap up or down upon reopening that traders can enter a position on the wrong price, frontrunning this likely gap in prices when the market opens. 
The core assumption of synthetix is that the oracle price feeds reflect an efficient and liquid market and that is generally not the case for these synths during market closures. Therefore it is prudent that we apply the same mechanism already in place for both FTSE and NIKKEI to prevent exchanges at times when markets are closed. Please note that synths can still be transferred and traded on other venues even during market closure.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
