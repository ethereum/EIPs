---
sccp: 77
title: Update sDEFI and iDEFI
status: Proposal
author: Farmwell (@farmwell), CryptoToit (@CryptoToit)
discussions-to: https://research.synthetix.io/
created: 2021-01-21
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
It is proposed to update the composition of the sDEFI index synth. The DeFi space moves quickly. The index tracking DeFi should reflect the rapid pace of innovation and development.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
In light of efforts to make the sDEFI and iDEFI index products reflect the rapidly changing DeFi sector, the proposal is to keep with a quartlerly cadence to update the index by adding and removing components while rebalancing the index composition.
This SCCP provides for adding to sDEFI:
  * SushiSwap's SUSHI
  * 1inch.exchange's 1INCH
  * Bancor's BNT
  

This SCCP furher provides for removing from sDEFI:
  * Wrapped version of Nexus Mutual, wNXM

The Spartan Council was presented with three different options for weighting the index. 
The Council in principle agreed to the following proposed weightage: 

| % Weightage  |  Ticker  |  Units |
|--------------|----------|--------|
| 15.00%       |  AAVE    | 0.87   |
| 15.00%       |  SNX     | 11.15  |
| 15.00%       |  UNI     | 18.4   |
| 10.00%       |  MKR     | 0.079  |
| 7.50%        |  YFI     | 0.0016 |
| 7.50%        |  SUSHI   | 7.87   |
| 5.00%        |  COMP    | 0.268  |
| 5.00%        |  UMA     | 4.97   |
| 5.00%        |  REN     | 75.09  |
| 5.00%        |  CRV     | 26.45  |
| 5.00%        |  KNC     | 36.23  |
| 5.00%        |  BAL     | 2.5    |
| 2.50%        |  1INCH   | 14.79  |
| 2.50%        |  BNT     | 15.53  |
  
## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The purpose of the updated sDEFI and iDEFI index synth is to attract traders wishing to gain exposure to the burgeoning DeFi sector.

Some have claimed the January is month 6 of a 36 month DeFi bear market, while numerous ALT/USD pairs have nevertheless appreciated considerably since last fall.

The goal of the index is to provide exposure to the most innovative projects in DeFi right now. As the DeFi space continues to move quickly it is quite possible for previously excluded assets to rejoin the index. 
BNT is an example of this. In previous indices, BNT was removed. In the latest iteration BNT managed to get back into the index. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
 
