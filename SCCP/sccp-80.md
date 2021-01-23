---
sccp: 80
title: Lower Fees on Selected Synths
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Proposed
created: 2021-01-22

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Analysis of on-chain data showed that it is possible to lower rates on several synths, as the risk of front-running has reduced significantly with the recent implementation of SCCP-68.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

The fee levied on trade into a certain synth is usually set based on the chainlink push frequency (adjusted for leverage). Analysis of on-chain data revealed that it is possible to further lower rates on certain low-vol synths.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Analysis of on-chain data showed that lowering fees as per the below table is possible and does not expose minters to the risk of front-running. That said, trades will be monitored and if front-running is seen, the current fee structure will be revisited.
I should mention that fees could potentially pushed further lower, on the synths proposed below and others (such as forex synths and commodity synths) based on further review of incoming data.


|  CCY  | Previous Rate | New Rate | Rate Decrease|
|:-----:|:-------------:|:--------:|:-----------:|
|  sETH |       30      |    25    |       5     |
|  iETH |       70      |    50    |      20     |
|  sXTZ |      100      |    85    |      15     |
|  iXTZ |      100      |    85    |      15     |
|  sEOS |      100      |    85    |      15     |
|  iEOS |      100      |    90    |      10     |
|  sETC |      100      |    85    |      15     |
| sLINK |      100      |    85    |      15     |
| sDASH |      100      |    90    |      10     |
| iDASH |      100      |    90    |      10     |
|  sXRP |      100      |    90    |      10     |


I'd like to thank every member of the synthetix community for their continued unrelenting support and trust through out 2020. 
I look forward to a period where we have consistent healthy robust exchange volume, with fees and fee-adjustment period lowered to the minimum on L1 (in future work).

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).