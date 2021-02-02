---
sccp: 70
title: Raise maxDebt on Multi-Collateral Loans to sUSD 20 million from sUSD 10 million
author: Kaleb
discussions-to: governance
status: Implemented
created: 2020-12-31

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Raise the `maxDebt` on multi-collateral and shorting loans to sUSD 20 million.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

The `maxDebt` parameters governs a ceiling on the total sUSD value of the loans that can be taken out by borrowers on the Multi-Collateral and Shorting contracts.
Normally setting a high rate exposes minters to extra leverage on their debt.

## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

The max debt currently set at sUSD 10 million, is proposed to be increased sUSD 20 million to accommodate for two things essentially:
- The increase demand for sUSD loans for farming purposes `https://mith.cash/`
- The sDAO has also taken around sUSD 5 million worth of ETH and BTC shorts

The former has no effect on the debt pool, as the debt in sUSD does not result in an increase in debt volatility and the latter actually helps the skew in the debt pool without having minters needing to incentivize balancing out the debt pool skew.

The current break down of loans are as follows:


|                        	| Total Loans (Revalued to sUSD) 	|
|------------------------	|:------------------------------:	|
| ETH backed sUSD Loans  	|             6,523K             	|
| sUSD Backed sBTC Short 	|              957K              	|
| sUSD Backed sETH Short 	|             4,440K             	|
| ren Backed sBTC Loan   	|               15K              	|
| ren Backed sUSD Loan   	|               87K              	|


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
