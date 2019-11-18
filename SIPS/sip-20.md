---
sip: 20
title: Gas Optimisations
author: Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/CDTvjHY
status: Implemented
created: 2019-10-15
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Optimize the gas on critical, high use functions that are used almost weekly by users that currently cost a lot in gas usage.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

To make transactions cost less gas usage for Synthetix users, a [gitcoin bounty](https://gitcoin.co/issue/Synthetixio/synthetix/196/3430) was created to R&D gas optimisations on the upgradable contracts across these high use functions;

- Synthetix.issueSynths (& issueMaxSynths)
- Synthetix.burnSynths
- Synthetix.exchange
- Synthetix.transfer (& transferFrom)
- FeePool.claimFees
- ExchangeRates.updateRates (onlyOracle function)

#### Excludes

- using solidity compilers optimize runs
- ownerOnly functions

The bounty resulted in several PRs for the team to validate and integrate into the system with some high value gas savings achieved.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

### Public functions

For SNX holders/[mintr](https://mintr.synthetix.io) users, reducing the cost of maintaining SNX collateralisation ratio via mint & burn, claiming fees and rewards and token transfers and [Synthetix.exchange](https://synthetix.exchange) trades.

### onlyOracle functions

Reduce the cost of the ExchangeRates.updateRates function in storing pricing data onching will save the foundation in ETH running costs for the oracle.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

(@k06a) Gas Opt results

`alpha` (2eaef0dddf95d6c0e3a1acd4a96482aab8143d30):

```
·--------------------------------------------------------|---------------------------|-------------|----------------------------·
|          Solc version: 0.4.25+commit.59dbf8f1          ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 8000000 gas  │
·························································|···························|·············|·····························
|  Methods                                               ·               4 gwei/gas                ·       180.56 usd/eth       │
························|································|·············|·············|·············|··············|··············
|  Contract             ·  Method                        ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
························|································|·············|·············|·············|··············|··············
|  Synthetix            ·  issueSynths                   ·     306850  ·     582310  ·     423915  ·         284  ·       0.31  │
························|································|·············|·············|·············|··············|··············
|  Synthetix            ·  burnSynths                    ·     476976  ·     664025  ·     561884  ·          99  ·       0.41  │
························|································|·············|·············|·············|··············|··············
|  ExchangeRates        ·  updateRates                   ·      56015  ·    6535679  ·     117042  ·         486  ·       0.08  │
························|································|·············|·············|·············|··············|··············
|  FeePool              ·  claimFees                     ·     390436  ·     514240  ·     441358  ·          41  ·       0.32  │
························|································|·············|·············|·············|··············|··············
|  Synthetix            ·  exchange                      ·      59871  ·     249564  ·     224765  ·          45  ·       0.16  │
························|································|·············|·············|·············|··············|··············
```

`optimize/rates-storage` (1e2196d59bbd921bce144195e00d198548c64c28):

```
·--------------------------------------------------------|---------------------------|-------------|----------------------------·
|          Solc version: 0.4.25+commit.59dbf8f1          ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 8000000 gas  │
·························································|···························|·············|·····························
|  Methods                                               ·               4 gwei/gas                ·       180.56 usd/eth       │
························|································|·············|·············|·············|··············|··············
|  Contract             ·  Method                        ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
························|································|·············|·············|·············|··············|··············
|  Synthetix            ·  issueSynths                   ·     307688  ·     584059  ·     426344  ·         284  ·       0.31  │
························|································|·············|·············|·············|··············|··············
|  Synthetix            ·  burnSynths                    ·     479100  ·     666231  ·     564608  ·          99  ·       0.41  │
························|································|·············|·············|·············|··············|··············
|  ExchangeRates        ·  updateRates                   ·      46830  ·    3566459  ·      84580  ·         486  ·       0.06  │
························|································|·············|·············|·············|··············|··············
|  FeePool              ·  claimFees                     ·     391534  ·     515471  ·     442495  ·          41  ·       0.32  │
························|································|·············|·············|·············|··············|··············
|  Synthetix            ·  exchange                      ·      59871  ·     249871  ·     225068  ·          45  ·       0.16  │
························|································|·············|·············|·············|··············|··············
```

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

https://github.com/Synthetixio/synthetix/commit/05c42daefb282a49f791e7e626e10cf1f8352f36

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
