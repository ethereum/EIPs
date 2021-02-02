---
sccp: 79
title: Increase Account Mergers Deadline 
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Implemented
created: 2021-01-23
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Increase the account mergers duration from 7 days to 2 weeks (1209600 seconds) and put into effect a new merging window.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Proposing to change the account `accountMergingDuration` state variable to 14 days and triggering the `startMergingWindow` method in order to start a new merging epoch.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Given the recent implementation of [SIP-13](https://sips.synthetix.io/sips/sip-13), as well as the development of a UI by `vbstreetz`, the sccp aims to extending the merging duration which had expired recently, so that users can have a chance to merge different wallets having escrowed tokens.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
