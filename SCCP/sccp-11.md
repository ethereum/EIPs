---
sccp: 11
title: Raise Trading Fee to 100bps
author: Kain Warwick (@kaiynne)
discussions-to: TBC
status: Implemented
created: 2020-02-03
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
The volume of front running transactions has increased again over the last several weeks as we get closer to the implementation of Fee Reclamation. Unfortunately the Fee Reclamation changes have not yet been submitted for audit so we likely have several weeks before they can be deployed to mainnet. Given this delay and the current volume of front-running we feel it is prudent to raise fees until this change can be deployed.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Raise the exchange transaction fee to 100 basis points (1%).

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
To reduce the incidence of front-running until Fee Reclamation is implemented. Once Fee reclamation is live we will need to reduce fees to the standard 30bps to test the efficacy of the change in preventing front-running.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
