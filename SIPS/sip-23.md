---
sip: 23
title: Inflation Smoothing
status: Implemented
author: Deltatiger (@deltatigernz), Vance Spencer(@frameworkvance)
discussions-to: https://github.com/Synthetixio/SIPs/issues/36

created: 2019-09-24
---

## Simple Summary

This SIP gradually decreases SNX inflation by 1.25% per week starting on GMT Wednesday, 11 December 2019 00:00:00 - week 40 of the current inflation schedule. There is a separate [SIP-24](https://sips.synthetix.io/sips/sip-24) that proposes an annual inflation rate of 2.5% on week 234 of the inflation schedule. This is the week when the smoothed inflation schedule would first go below 2.5% on an annualized basis.

This SIP is the formal spec successor of deltatiger's [Draft SIP Proposal #36](https://github.com/Synthetixio/SIPs/issues/36). The formalization of specifics (week starting, % decrease per week) reflects the consensus reached during the October 24, 2019 governance call.

## Abstract

- SNX's current inflation schedule creates a total of 245M tokens
- SNX's current inflation schedule started on March 6, 2019
- SNX's current inflation schedule issues 1.44M SNX per week, and halves weekly rewards every 52 weeks for 260 weeks
- Smoothing (gradually decreasing vs. abruptly halvening) this inflation schedule decreases the potential risk that an inflation halvening poses
- Smoothing the inflation schedule immediately allows for a more gradual inflation decline

## Motivation

After 6 months of gathering data on current inflation rates and assessing the community's sentiment in regards to future inflation halvening, the community's consensus is that the inflation halvening presents an easily avoidable risk that we can address through a gradually decreased inflation curve starting as soon as possible.

## Specification

Starting on GMT Wednesday, 11 December 2019 00:00:00, SNX inflation decreases by 1.25% per week per this [final model](https://docs.google.com/spreadsheets/d/1a5r9aFP5bh6wGG4-HIW2MWPf4yMthZvesZOurnG-v_8/edit#gid=0), which is based on the [origional model](https://docs.google.com/spreadsheets/d/1rVXFnZSMvHEv5XpA5Q23x-cXEo7w-2T80wlAfT-YbuI/edit#gid=1445735519) proposed in the draft SIP.

If the inflation smoothing and fixed terminal inflation SIPs both get approved, inflation would look like the below graph.
![](https://user-images.githubusercontent.com/55753617/69513159-b38a8000-0efb-11ea-894e-2a89064a0998.png)

![](https://user-images.githubusercontent.com/55753617/69513160-b38a8000-0efb-11ea-9a96-4cfa95eb8ccd.png)

## Rationale

An abrupt inflation halvening could lead to:

- minters packing up at the same time
- synth supply shrinking
- SNX unlocking to be sold down
- SNX price dropping
- sETH LPs getting their income halved and also now dropping in value
- sETH LPs exiting by withdrawing and converting sETH to ETH
- sETH getting smashed out of peg
- arb pool being unattractive as SNX drops relative to ETH

## Test Cases

Standard test cases for Solidity contract compiling and deploying onto Ethereum testnets before updating the contract on mainnet.

[SupplySchedule] https://github.com/Synthetixio/synthetix/blob/v2.16.4/test/contracts/SupplySchedule.js

[Synthetix] https://github.com/Synthetixio/synthetix/blob/v2.16.4/test/contracts/Synthetix.js#L2326

[RewardsIntegrationTests] https://github.com/Synthetixio/synthetix/blob/v2.16.4/test/contracts/RewardsIntegrationTests.js

## Implementation

- Update and deploy [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/v2.16.4/contracts/SupplySchedule.sol) to Ropsten, Rinkby, and Kovan
- Update and deploy changes to proxy contracts that reference SupplySchedule.sol on Ethereum testnets
- Update and deploy [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/v2.16.4/contracts/SupplySchedule.sol) to Ethereum mainnet
- Update and deploy changes to Ethereum mainnet proxy contracts that reference SupplySchedule.sol

### Removing time slippage on lastMintEvent and minting day buffer

- `lastMintEvent` is recorded when synthetix.mint() is executed each week (7 days) and to ensure that slippage is removed, the `lastMintEvent` is set from `INFLATION_START_DATE` + `number of weeks of inflation` + `MINT_BUFFER`. 

- Relying on the blocktime `now` when synthetix.mint() is called resulted in the inflation supply not be mintable again until after another 7 days had passed, i.e. if mint was called 1 day late on Friday, instead of a Thursday this slippage would compound. By setting `lastMintEvent` to the start of the week that was last minted ensures that the next inflation mint would be available earlier.

- `MINT_BUFFER` of 1 DAYS was added to ensure that inflationary supply is minted a day after feePeriod closes. 

[SupplySchedule] https://github.com/Synthetixio/synthetix/blob/v2.16.4/contracts/SupplySchedule.sol#L220

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
