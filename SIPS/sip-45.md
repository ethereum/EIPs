---
sip: 45
title: Deprecate ERC223 sUSD Deposits from Depot 
author: Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/DQ8ehX4
status: Implemented
created: 2020-03-01
---


## Simple Summary
Deploy a new Depot contract allowing ERC20 Deposits only and removing ERC223 support. 

## Abstract
ERC223 support was deprecated from Synthetix in [sip-30](https://sips.synthetix.io/sips/sip-30). This disabled the [MAINNET Synthetix Depot](https://etherscan.io/address/0x172e09691dfbbc035e37c73b62095caa16ee2388) from being able to accept anymore sUSD deposits. A new ERC20 only version of the Depot is required to enable sUSD deposits again once this one sold its ~1M in sUSD desposits.  

## Motivation
Since the bZx attack on Feb 18 2020 the [Synthetix Depot was drained of all its 943,837 sUSD in exchange for 2388 ETH](https://blog.synthetix.io/bzx-susd-update/) rendering it empty and end of life. This occurred prematurely and a new version was quickly deployed in the [Achernar release](https://blog.synthetix.io/the-achernar-release)

## Specification
Modify depositSynths to use the ERC20 transferFrom workflow, requiring users to perform an approve transaction first. [Mintr](https://mintr.synthetix.io/) to have the updated approve UX for sUSD deposits.

## Rationale
ERC223 did provide a better UX for users to only perform and pay for 1 transaction to depoist sUSD into the Depot. However was the only use case for ERC223 within Synthetix and the gas overhead for each transaction was about an extra 100K gwei which was causing composability friction for protocols like Kyber where the tokens might transfer to 3 different addresses in an exchange causing an additional 300K overhead in gas.

It was always intedended to replace the Depot with an ERC20 version but the [bZx attack](https://etherscan.io/tx/0x762881b07feb63c436dee38edd4ff1f7a74c33091e534af56c9f7d49b5ecac15) brought this forward sooner than planned.

## Test Cases
https://github.com/Synthetixio/synthetix/blob/v2.20.0/test/contracts/Depot.js

## Implementation

Source
https://github.com/Synthetixio/synthetix/blob/v2.20.0/contracts/Depot.sol

MAINNET Contract
https://etherscan.io/address/0xE1f64079aDa6Ef07b03982Ca34f1dD7152AA3b86


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
