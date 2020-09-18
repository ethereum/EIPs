---
sccp: 6
title: Reduce Claim Buffer
author: Kain Warwick (@kaiynne)
discussions-to: https://github.com/Synthetixio/synthetix/issues/296
status: Implemented
created: 2019-11-05
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
An aspect of the system that allows users to remain undercollateralised indefinitely is the c-ratio buffer. This was initially required to avoid users being slashed by rapid price drops in SNX when the original mechanism reduced fees by 25%+ if a user claimed while undercollateralised. Given that the only penalty now is a failed tx, the need for this buffer to be large has been removed. There is a limitation in the way the buffer is implemented which imposes a minimum buffer of 1% of the current c-ratio. We propose to set the buffer to this minimum of 1% which will result in c-ratios below 742.6% being blocked from claiming. We should see relatively few failed claims due to SNX price shifts, while raising the effective global c-ratio by ~10% during times of SNX price decline.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Target Threshold is used in FeePool.claimFees() https://github.com/Synthetixio/synthetix/blob/v2.11.2/contracts/FeePool.sol#L759

The owner calls FeePool.setTargetThreshold(1) this will update the FeePool.claimFees() threshold. 

The calculation is as follows:

issuance ratio is currently 0.133333333333333333 
a 1% buffer is 0.134666666666666666
To get the c-ratio % , we divide (1 / 0.134666666666666666 ) * 100 = 742.5742574257

Users will now need to be above 742.5742574257% to be able to call claimFees.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The buffer was implemented as a protection mechanism for slashing of fees, as fee slashing is no longer implemented there is no need for this buffer. We will keep a small 1% buffer to ensure that small price fluctuations do not lead to high fee claim failure rates.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
