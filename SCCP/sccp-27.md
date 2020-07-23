---
sccp: 27
title: Reduce Collateral Ratio For sETH Loans
status: Approved
author: Kaleb Keny (@kaleb-keny)
discussions-to: sip-35-eth-collateral 
created: 2020-05-25
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Reduce the collateral ratio on ETH backed loans from 150% to 125% in the second trial.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The collateral ratio determines the loan amount that can be taken (in sETH) based on the amount of collateral locked (in ETH).

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

During the first trial, the collateral requirement was set at a precautionary rate of 150% as to provide the community with a initial measure of traders appetite for sETH loans. In addition, the ratio was set this high as to limit any unexpected negative repercussions on different parts of the Synthetix environment (i.e. the peg, debt-pool and synth funding rates). It is worth noting that the high collateral requirement has a direct dilutive impact on the leverage that can be assumed by borrowers wishing to trade into synths (as compared to traders acquiring synths directly from a liquidity pool). Therefore, lowering the collateral requirement would make it more worthwhile for traders to borrow sETH but this needs to be balanced against the need to maintain a high enough incentive for borrowers to not default on their loans. 
In other words, the value of the locked ETH needs to exceed the value of the loan amount, after considering the associated loan origination fees and interest charge. Using the fee structure of the initial trial and adding a precautionary buffer, a collateral ratio of 125% should ensure that borrowers have enough of an incentive to repay their loans during at least 1-year time frame. Should borrowers abandon their wallets, the 125% collateral requirement would guarantee that minters would not bear any credit risk.


| Component | Proposed Rate |
| :-------------: | :-------------: |
| Principal | 100% |
| Minting Fee  | 0.5% |
| Interest Rate | 5% |
| Buffer | 19.5% |
| **Total** | **125%** |

It is worth pointing out, that nocturnalsheet had pointed out, that it would be risky to have a very very low collateral level because of the risk that bad faith actor would minting large quantities sETH and dumping it in one go on the market as an attack on the peg. Then the attacker would buy back slowly the sETH at depressed prices to settle the loan debt and profiting from this attack. Althought this kind of attack is somewhat defended by having a deep sUSD pool, this risk calls for a precautionary buffer which is proposed to be 19.5%.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
