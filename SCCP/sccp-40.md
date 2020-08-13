---
sccp: 40
title: Increase Fee Reclamation Waiting Period to 10 minutes
author: Clinton Ennis (@hav-noms), Jackson Chan (@jacko125), Justin J Moses (@justinjmoses), Kain Warwick (@kaiynne)
discussions-to: https://discordapp.com/invite/AEdUHzt
status: Implemented
created: 2020-08-13
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Temporarily increase fee reclamation waiting period to 10 minutes (600 seconds).

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increase fee reclamation waiting period to 10 minutes to accommodate high network congestion and consistent high gas costs.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Network congestion is currently incredibly high - fast GWEI is around 250-280. 

Increasing the waiting period will allow us to reduce the update frequency of the oracle to save sDAO treasury gas costs.

The Synthetix Oracle for crypto price feeds is burning too much ETH from the synthetixDAO treasury. It is intended to include the SNX community on voting on the use of these funds and in this congested period some evasive action is required to temporarily slow down the ETH burn rate until Chainlink Phase 2 in the Pollux release in a few weeks.

There is a chance there could be follow up SCCPs to be voted on to increase the waiting period further if the gwei keeps rising. 

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
