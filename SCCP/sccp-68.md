---
sccp: 68
title: Increase Fee Reclamation Waiting Period to 6 minutes
author: Kaleb Keny (@kalebkeny)
discussions-to: governance
status: Implemented
created: 2020-12-24
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Increase fee reclamation waiting period to 6 minutes.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increase fee reclamation waiting period to 6 minutes to accommodate network congestion.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

With the consistently high gas prices it has been taking chainlink around 8 minutes to fully reflect the price update of a significant price swing. This results in a narrow but potential front-running exploit to try and target the price update despite the high fees levied on crypto-to-crypto exchanges.
Increasing fee reclamation time to 6 minutes will help close the potential exploit until I am able to propose other alternatives.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
