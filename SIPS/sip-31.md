---
sip: 31
title: sETH LP rewards contract
status: WIP
author: Clinton Ennis (@hav-noms), Anton Bukov (@k06a) 
discussions-to: https://discord.gg/3uJ5rAy

created: 2019-11-04
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Replace the current uniswap sETH Liquidity Provider mechanism with an onchain LP rewards staking contract.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->
Note: LP = Liquidity Provider

The current deployed solution is inefficient and buggy. There are weekly issues with valid LP's not getting rewards and cheaters getting rewards that should be disqualified. 
This onchain solution fixes all the issues and can be automated and self serve requiring much less steps than the current solution. 

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

- Current solution uses an off-chain [python script](http://18.222.88.2:5000/pool-rewards/8926035/8967962) to determine sETH Liquidity providers between two blocks which are manually entered.
- We must download a CSV and manually verify the addresses and their LP amounts.
- There are so many LPs now that it takes 2 multi-sig multi-send transactions to send out the LP SNX rewards.
- The co-ordination amongst the 5 multi-sigs signers and overhead each manually verifying is inefficient given this could all be offloaded to a trusted smart contract to calculate on-chain in a trust-less manner. 
- The [gnosis multi-sig](https://wallet.gnosis.pm/#/wallet/0x53265D3D34c9ECB5685Be3176430366b4e392010) freezes and is very slow to react since the payloads of the transactions are so big.
- LP providers have noted is that if they withdraw / rebalance any amount of their liquidity from the pool during the week then all their rewards will be forfeited. The python script checks that no withdrawals / transfer of LP tokens have been made from the pool to prevent people from gaming the rewards.


## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Workflow
1. User adds liquidity to [sETH uniswap exchange](https://etherscan.io/address/0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244#writeContract) and receives uniswap uni tokens
2. User then stakes the uni tokens at unipool time staking contract
3. Anyone can call [Synthetix](http://contracts.synthetix.io/Synthetix).mint() to mint the inflationary supply. This will then be sent to the [RewardsDistribution](https://contracts.synthetix.io/RewardsDistribution) contract where it will send an amount of tokens to the unipool contract. [example transaction](https://etherscan.io/tx/0x88213d8ff5462a0359c98d0365762063ba32e0e0e9f49ecd9af392063e2068b4)
4. LP stakers will be assigned their % amount of SNX rewards based on their % of staked uni tokens against the pool of LP providers.
5. LP stakers will need to come to the uni pool contract to claim their SNX rewards weekly. 

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

This onchain self service model is precicsly the use case for smart contracts and should replace the offchain rewards process eradicating the need for the;

- [python script](http://18.222.88.2:5000/pool-rewards/8926035/8967962)
- [gnosis multi-sig](https://wallet.gnosis.pm/#/wallet/0x53265D3D34c9ECB5685Be3176430366b4e392010) & the 5 signers signing. 
- [Synthetix AirDropper](https://etherscan.io/address/0xa8bbb0155e7ea36d7dacb3c59d45c4fcd4a6d73e#code) contract.
- Mintrs Multi-sig page <https://mintr.synthetix.io/multisig>


The greatest disadvantage to LP's is that they are current automatically sent their SNX. This model will require each LP to withdraw their SNX.


## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
<https://github.com/k06a/Unipool/blob/master/test/Unipool.js>


## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The proposed implementation <https://github.com/k06a/Unipool>


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
