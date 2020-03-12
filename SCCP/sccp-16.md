---
sccp: 16
title: Increase Fee Reclamation Waiting Period to 1 hour
author: Justin J Moses (@justinjmoses), Kain Warwick (@kaiynne)
discussions-to: https://discordapp.com/invite/AEdUHzt
status: Proposed
created: 2020-03-12
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Temporarily increase fee reclamation waiting period to an hour.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increase fee reclamation waiting period to an hour to accommodate extreme network congestion.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Network congestion is currently incredibly high - fast GWEI is around 200. Increasing the waiting period will allow us to reduce the update frequency of the oracle and guarantee exchanges can still get through even with such high congestion.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
