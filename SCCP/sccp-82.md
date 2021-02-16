---
sccp: 82
title: Decrease Collateralization&Liquidation Ratio on sUSD Loans to 130% from 150%
author: Kaleb Keny (@kaleb-keny)
discussions-to: governance
status: Proposed
created: 2021-01-25

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Decrease the `collateralisationRatio` and `liquidationRatio` on sUSD ETH backed loans (for the old loan trial contract) to 130% from 150%.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Given the state of the peg, this sccp proposes to decrease the collateralization and liquidation ratio of sUSD loans to 130% from 150% in order to increase the attractiveness of these loans through a higher maximum leverage.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

The peg seem to be increasingly pressured as can be seen [here](https://www.curve.fi/trade/susdv2/SUSD-USDC/4h). 
This is mostly likely due to an increase in usage of synth liquidity for farming and trading purposes as well as the substantial increase in snx held on [exchange wallets](https://snx.watch/holders).
Decreasing the collateralization ratio aims at achieving the following:
 - Increase it's utilization, which stands at around 30%, through increased leverage incentive.
 - Allow people who have already taken out loans to draw out more ETH held, with minimal risk of liquidation.

I should mention that the loan program is well suited to address the peg issue, given that it bears no cost on borrowers (no minting fee - no interest rate) and the only deterrent is the risk of being liquidated at 130% if this sccp passes. Although if you're an ETH Ultra Bull, as most of us are, this is a non-issue. 
Also would need to mention that despite the loan trial end date, I would not vote on ending the program until at least a month, given that the state of the peg which requires that borrowers tap these loans without worrying about having to unwind them in the near future.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
