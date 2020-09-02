---
sccp: tbd
title: Lower C-Ratio by 100% to 500%
status: Proposed
author: Nocturnalsheet (@nocturnalsheet)
discussions-to: governance
created: 2020-09-02
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
This SCCP proposes to decrease the Collateralization Ratio to 500% from the current 600%. 

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
There is currently a premium on sUSD compared to other stablecoins on Curve. Decreasing the Collateralization Ratio will help lift the supply of sUSD, with the aim of reducing the current price premium.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The recent premium on the sUSD peg on Curve calls for taking action as traders feel a disincentive to pay the premium to partake in trading on the platform. 
The premium has been consistently high for the last month as can be seen [here](https://www.curve.fi/trade/susdv2/SUSD-USDC/1d). The main underlying reasons are as follows: 

1. Sushi and other protocols that offer governance tokens for SNX (hence less SNX being staked and synth in circulation).
2. BASED and other platforms that are offering a high interest rate for capturing sUSD
3. CRV governance tokens being farmed
4. SNX prices which are encouraging more trading of SNX, rather then staking for inflationary returns
4. High gas prices accompanied with the high cost of doing transactions on SNX contracts, which is discouraging those with low amounts of SNX from managing their wallets and taking advantage of the recent run up in SNX prices

I believe it is important to protect the sUSD peg against USD, whether in premium or discount as it helps gives confidence to traders on the unit of account that keep  synth flavors aligned with their underlyings. 

It is important to note that although the 100% c-ratio decrease might not be enough to stabilize the peg, more action will be proposed to the community in the coming weeks until the peg falls back to parity. 

Further action could take the following forms

1. More decreases in the collateralization ratio gradually until we hit a lower bound (450%)
2. Reducing SNX rewards on curve gradually
3. Limiting burning to 1 week after a mint (instead of 24 hours)
4. Increasing inflationary rewards (to encourage minting)

Worth adding here the main arguments in the camp of not lowering the c-ratio:
1. The current premium is temporary farming frenzy that will pass (Farming frenzy has shown that it is here to stay)
2. The recent c-ratio cut has had little if no impact on the peg
3. The foundation driven rewards which are nearing their end are bound to create some synth selling pressure

Although I do think that these arguments and many others are valid, any change in c-ratio can be changed later via community vote in case the peg stabilizes. Until then, we as a community need to do our part in order to peg our main unit of account to its underlying. 

Since the c-ratio was designed to be the lever for supporting supply and demand. It is forseen that the end of the yield farming incentives to drop the peg in which the c-ratio may need to be used to increase the target c-ratio to reduce the sUSD supply.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
