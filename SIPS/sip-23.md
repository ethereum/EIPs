---
sip: 23
title: Inflation Smoothing
status: Approved
author: Deltatiger (@deltatigernz), Vance Spencer(@frameworkvance)
discussions-to: https://github.com/Synthetixio/SIPs/issues/36

created: 2019-09-24
---

## Simple Summary 

This SIP gradually decreases SNX inflation by 1.4% per week starting on AEST December 12th, 2019 - week 38 of the current inflation schedule. There is a separate [SIP-24](https://sips.synthetix.io/sips/sip-24) that proposes a fixed rate of inflation of 100K per week starting on week 222 of the inflation schedule. This is the week when the smoothed inflation schedule would first go below 100K SNX per week and when the original inflation schedule would be issuing 90.1K per week.  

If the inflation smoothing and fixed terminal inflation SIPs both get approved, inflation would look like the below graph. 

![](https://media.discordapp.net/attachments/637348888713625626/637736129013088295/Screen_Shot_2019-10-26_at_12.20.50_PM.png)

This SIP is the formal spec successor of deltatiger's [Draft SIP Proposal #36](https://github.com/Synthetixio/SIPs/issues/36). The formalization of specifics (week starting, % decrease per week) reflects the consensus reached during the October 24, 2019 governance call. 

## Abstract

* SNX's current inflation schedule creates a total of 245M tokens 
* SNX's current inflation schedule started on March 13, 2019
* SNX's current inflation schedule issues 1.44M SNX per week, and halves weekly rewards every 52 weeks for 260 weeks
* Smoothing (gradually decreasing vs. abruptly halvening) this inflation schedule decreases the potential risk that an inflation halvening poses
* Smoothing the inflation schedule immediately allows for a more gradual inflation decline while adhering to the original protocol target of ~245M total tokens

## Motivation

After 6 months of gathering data on current inflation rates and assessing the community's sentiment in regards to future inflation halvening, the community's consensus is that the inflation halvening presents an easily avoidable risk that we can address through a gradually decreased inflation curve starting as soon as possible. 

## Specification

Starting on November 15th, 2019, SNX inflation decreases by 1.4% per week. 

[Model](https://docs.google.com/spreadsheets/d/1rVXFnZSMvHEv5XpA5Q23x-cXEo7w-2T80wlAfT-YbuI/edit#gid=1640166717)

![image](https://media.discordapp.net/attachments/637348888713625626/637735328454541314/Screen_Shot_2019-10-26_at_12.21.26_PM.png)

![image](https://cdn.discordapp.com/attachments/637348888713625626/637735491168632875/Screen_Shot_2019-10-26_at_12.32.50_PM.png)

## Rationale

An abrupt inflation halvening could lead to:

* minters packing up at the same time
* synth supply shrinking
* SNX unlocking to be sold down
* SNX price dropping
* sETH LPs getting their income halved and also now dropping in value
* sETH LPs exiting by withdrawing and converting sETH to ETH
* sETH getting smashed out of peg
* arb pool being unattractive as SNX drops relative to ETH

## Test Cases

Standard test cases for Solidity contract compiling and deploying onto Ethereum testnets before updating the contract on mainnet. 

## Implementation

- Update and deploy [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/master/contracts/SupplySchedule.sol) to Ropsten, Rinkby, and Kovan
- Update and deploy changes to proxy contracts that reference SupplySchedule.sol on Ethereum testnets
- Update and deploy [SupplySchedule.sol](https://github.com/Synthetixio/synthetix/blob/master/contracts/SupplySchedule.sol) to Ethereum mainnet
- Update and deploy changes to Ethereum mainnet proxy contracts that reference SupplySchedule.sol


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
