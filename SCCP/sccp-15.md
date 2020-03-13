---
sccp: 15
title: Increase ETH Collateral sETH Limit
author: Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/kPPKsPb
status: Implemented
created: 2020-03-11
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Increase ETH Collateral sETH Limit from 1000 to 2000.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The [ETH Collateral contract](https://etherscan.io/address/0x0F3d8ad599Be443A54c7934B433A87464Ed0DFdC) has almost reached its limit with currently 962 locked ETH of a potential 1500. If someone wants to issue more than the remainder they currently cannot. You can see the latest issuance numbers at [synthetix.exchange](https://synthetix.exchange/loans).

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The [trial of ETH Collateral](https://sips.synthetix.io/sips/sip-35) was originally specified to have a limit of 5000 sETH issuable or 7500 locked ETH. In light of the recent flash loan attacks in the DeFi space we opted for a very conservative limit of only 1000 sETH. 
This proposal is to only increase the limit to 2000 issuable sETH and continue to monitor its usage.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
