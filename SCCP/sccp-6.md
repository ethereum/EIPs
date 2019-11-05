---
sccp: 6
title: Reduce Ratio Fee Claim Buffer
author: Kain Warwick (@kaiynne)
discussions-to: https://github.com/Synthetixio/synthetix/issues/296
status: Proposed
created: 2019-11-05
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->
Reduce Ratio Fee Claim Buffer
 

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
An aspect of the system that allows users to remain undercollateralised indefinitely is the c-ratio buffer. This was initially required to avoid users being slashed by rapid price drops in SNX when the original mechanism reduced fees by 25%+ if a user claimed while undercollateralised. Given that now a user will only have a tx fail, the need for this buffer to be so large has been removed. By changing the buffer to 2% we should see relatively few failed claims due to SNX price shifts, while raising the global c-ratio by 10% during times of SNX price decline.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Target Threshold is used in FeePool.claimFees() https://github.com/Synthetixio/synthetix/blob/v2.11.2/contracts/FeePool.sol#L759
When the owner calls FeePool.setTargetThreshold(2) this will update the FeePool.claimFees() threshold. 
Users will now have to burn more each fee period to be able to claim their exchange fees and SNX rewards.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The buffer was implemented as a protection mechanism for slashing of fees, as fee slashing is no longer implemented there is no need for this buffer. We will keep a small 2% buffer to ensure that small price fluctuations do not lead to high fee claim failure rates.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
