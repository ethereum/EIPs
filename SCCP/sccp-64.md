---
sccp: 64
title: Increase fees on iBTC and sBTC to 0.40%
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Proposed
created: 2020-11-25

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Raise exchange fees of trades into `iBTC` and `sBTC` by 10 bp to `0.40%`.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increasing fees to 10 bp should help close down any available front-running opportunities.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Analysis of on-chain data showed that front-running is possible on iBTC and sBTC, due to the mismatch against chainlink rate push frequency of 0.50%. Raising fees to almost match the chainlink push frequency will effectively help in closing that gap.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
