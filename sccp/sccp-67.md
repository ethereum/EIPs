---
sccp: 67
title: Change Configurable Values for SIP-97 and SIP-103  
author: SynthaMan, Kaleb
status: Proposed
discussions-to: https://discord.gg/7nMZMdbf
created: 2020-12-22

---

## Simple Summary

Set Initial Configurable Values for <a href="https://sips.synthetix.io/sips/sip-97">SIP-97</a> and <a href="https://sips.synthetix.io/sips/sip-103">SIP-103</a>

## Abstract

Set Initial Configurable Values for <a href="https://sips.synthetix.io/sips/sip-97">SIP-97</a> to following:

<b>CollateralEth.sol</b>

synths: sUSD, sETH
minCratio: 130%
minCollateral: 2
issueFeeRate: 0.001

<b>CollateralErc20.sol</b>

synths: sUSD, sBTC
minCratio: 130%
minCollateral: 0.05
issueFeeRate: 0.001
underlyingAsset: 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D (renBTC address)

<b>CollateralManager.sol</b>

baseBorrowRate 0.0005
baseShortRate 0.0005
maxDebt 10000000

Set Initial Configurable Values for <a href="https://sips.synthetix.io/sips/sip-103">SIP-103</a> to following:

<b>CollateralShort.sol</b>

synths: sBTC, sETH
minCratio 120%
minCollateral 1000
issueFeeRate 0.003

## Motivation

- 130% min c-ratio equates to 76.9%, thats quite competitive against other lending protocols such as Aave/Compound which allows 75% and liquidation at 80% for ETH for example
- Inception fee needs to be 0.30% on SIP-103 due to chainlink oracle latency.
- Min collateral is set as close as possible to 1000 sUSD to allow bigger audience to be able to use Synthetix
- Max debt is set initially at 10 Millions sUSD for security purposes and might be expanded later as we hit the ceiling

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
