---
sccp: 69
title: Increase Fees on Leveraged Inverse Synths
author: Kaleb, Spreek, Danijel, farmwell
discussions-to: governance
status: Proposed
created: 2020-12-29

---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->

Raise exchange fees on inverses based on the leverage stemming from the token price.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increasing fees on inverse tokens who's price has decreased considerably relative to the synth price should close up front-running opportunities that were noticed recently.


## Motivation

<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

Analysis of on-chain data showed that front-running is possible on the below listed synths, as the chainlink rate push frequency is calibrated for price changes of the synths and not those of inverses, opening up a front-running gap.
Raising fees as per the below configuration and continuing to monitor the change leverage would help ensure that minters debt are not exploited.


|       	|   iRate  	|   sRate  	| Leverage 	| Fee Proposed 	| Fee Previously 	|
|-------	|:--------:	|:--------:	|:--------:	|:------------:	|----------------	|
| iADA  	| 0.083777 	| 0.1822   	| 2.17     	| 150          	| 100            	|
| iDEFI 	| 1883.947 	| 3,569.81 	| 1.89     	| 150          	| 100            	|
| iETH  	| 444.91   	| 711      	| 1.60     	| 80           	| 30             	|

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
