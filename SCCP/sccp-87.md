---
sccp: 87
title: Lower Fees on Forex Synths
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Proposed
created: 2021-02-21

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Lower fees on all FX synths to 15 bp.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

The fee levied on trades into a FX synths is usually set based on the chainlink push frequency. Analysis of the oracle price feed against real-time price feed revealed that it is possible to lower fees on these FX synths.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Analysis of on-chain data showed that lowering fees as per the below  is possible and does not expose minters to the risk of front-running.  This is mostly due to the low volatility of the forex synth which can visualized  in  this [code pen](https://codepen.io/justinjmoses/full/gOYdJNX) .

|  CCY  | Previous Rate | New Rate | Rate Decrease|
|:-----:|:-------------:|:--------:|:-----------:|
|  sAUD |       30      |    15    |       15     |
|  sEUR |      30      |    15   |      15     |
| sJPY |      30      |    15    |      15     |
|  sCHF |      30      |    15    |      15     |
|  sGBP |      30      |    15    |      15     |



## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
