---
sccp: 64
title: Increase fees on iBTC to 0.50%
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Proposed
created: 2020-11-25

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Raise exchange fees of trades into `iBTC` by 20 bp to `0.50%`.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increasing fees by 20 bp to 50 bp on iBTC should help reduce the gap against the oracle price push.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Analysis of on-chain data showed that front-running is possible on iBTC and sBTC, due to the mismatch against chainlink rate push frequency of 0.50%.
Raising fees on one synth of the sBTC/iBTC pair, so that it matches the chainlink push frequency, should help close up the front-running gap and significantly impair the effectiveness of a front-running swing-based trade.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
