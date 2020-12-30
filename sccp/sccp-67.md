---
sccp: 67
title: Change Configurable Values for SIP-97 and SIP-103
author: SynthaMan, Kaleb
status: Implemented
discussions-to: https://discord.gg/7nMZMdbf
created: 2020-12-22
---

## Simple Summary

Set Initial Configurable Values for <a href="https://sips.synthetix.io/sips/sip-97">SIP-97</a> and <a href="https://sips.synthetix.io/sips/sip-103">SIP-103</a>

## Abstract

<b>Set Initial Configurable Values for <a href="https://sips.synthetix.io/sips/sip-97">SIP-97</a> to following:</b>

CollateralEth.sol <br />

synths: sUSD, sETH <br />
minCratio: 130% <br />
minCollateral: 2 <br />
issueFeeRate: 0.001 <br />

CollateralErc20.sol <br />

synths: sUSD, sBTC <br />
minCratio: 130% <br />
minCollateral: 0.05 <br />
issueFeeRate: 0.001 <br />
underlyingAsset: 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D (renBTC address) <br />

CollateralManager.sol <br />

baseBorrowRate: 0.005 (0.5%) <br />
baseShortRate: 0.005 (0.5%) <br />
maxDebt: 10000000 <br />

<b>Set Initial Configurable Values for <a href="https://sips.synthetix.io/sips/sip-103">SIP-103</a> to following:</B>

CollateralShort.sol<br />

synths: sBTC, sETH<br />
minCratio: 120%<br />
minCollateral: 1000<br />
issueFeeRate: 0.005<br />
interactionDelay: 3600 <br />

## Motivation

- 130% min c-ratio equates to 76.9%, thats quite competitive against other lending protocols such as Aave/Compound which allows 75% and liquidation at 80% for ETH for example
- Inception fee needs to be 0.5% on SIP-103 due to chainlink oracle latency.
- Min collateral is set as close as possible to 1000 sUSD to allow bigger audience to be able to use Synthetix
- Max debt is set initially at 10 Millions sUSD for security purposes and might be expanded later as we hit the ceiling

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
