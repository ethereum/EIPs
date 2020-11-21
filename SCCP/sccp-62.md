---
sccp: 62
title: Increase fees on iETH to 0.75% and sETH to 0.50%
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Proposed
created: 2020-11-21
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Raise exchange fees of trades into `iETH`by 25 bp to `0.75%` and on `sETH` by 20 bp to '0.50%'.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increasing fees by 20 bp on `sETH` and by 25 bp on `iETH` should narrow down the front-running gap which remained possible after yesterday's rate increase.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Analysis of on-chain data showed that front-running continued to be possible on iETH, as the synth is close to it's lower limit. Furthermore, due to the chainlink push threshold of 0.50%, fees on sETH should be raised to match the push frequency and close up the front-running window completely.
It should be mentioned that I will be advocating for lowering fees on iETH back to previous levels (and will write the needed SCCP), after the synth is frozen and the leverage is reset.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
