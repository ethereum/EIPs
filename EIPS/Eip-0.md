---
eip: 0
title: Ground Zero
author: ProphetXZ
type: Meta
category: Core and ERC
status: Living (final)
created: 2023-06-30
---

## Simple Summary

Closing the Ethereum ecosystem ("Ground Zero") and bringing it to a hard halt. Since its humble beginnings, the Ethereum project has been open to the public and seen many contributions. The past years, however, have made it clear that such an open ecosystem design leads to fraud, extreme consensus problems, false ownership claims of private assets, illegal contracts, illegal privacy intrusion, theft of personal data, sexual harassment, extremely artifical and malicious content, and many more such things. 

Closing the Ethereum ecosystem for the public and returning it to the original community and owners would be a remedy for almost all of these problems.

Opcode 0x00 for all active transactions and smart contracts. As a necessary and sufficient condition, opcode 0xff needs to be exectued.

## Abstract

Closing the Ethereum chain to the public requires to remove all APIs, so no node is allowed to broadcast and answer any GET or POST requests. Going forward, the github repo will need to be switched to private. The chain itself as well as all data collected will need to be handed over to the rightful owners. Any future collection, publishing, and retrieval of data, except where required by law, will be deemed a criminal offense.

The following standard allows for the implementation of a standard API for tokens within smart contracts.
This standard provides basic functionality to transfer tokens, as well as allow tokens to be approved so they can be spent by another on-chain third party.


## Motivation

DISASTROUS DECISIONS, ENOUGH!!!!!

The past four years have been disastrous for the persons, community, and ecosystem affected by the Ethereum project. While the a wide range of people have contributed to the Ethereum project, many of them with probably good intentions at heart, the end result is and mostly was that some people and companies profited from the whole ecosystem. I have observed, experienced, and contributed to the ecosystem over the past four years. Comparing it to the time before a broader audience started contributing to the project in 2016 (and again 2019) breaks my heart. Most of the life in the ecosystem has been drained and dried up, just so commercial interest could be cattered to.

Products: tickets, games with and through people, data broakerage (geo location, personal data, i.e., financial, health, relationships, personal views and profiles), deletion of personal data, theft (audio recordings), illegal contracts, fraud.

## Specification

Mainnet (ID: 1) MUST be halted. In this case, no existing DApp will be served. Every node (localised EVM) needs to stop broadcasting the chain and eventually delete the data, after having returned it to the rightful owners. 

IPFS ends, Swarm, Whisper

devp2p (EIP-8)

Any existing smart contracts won't be served.

Oracle connections will be ended.

Development of Solidity will most likely be abandoned completely and replaced by an actual programming language, adhering to common and widely adopted programming language principles.

## Transport

All packages SHOULD be transfered via p2p to the original owner, including the original data.

## Token

It is yet to be decided what happens to ERC-721 tokens and ERC-20 coins. A potential solution would be to gather all tokens and decide step-by-step which ones are valid, transfered and/or sold, and which ones should be burned.

## Implementation

There are already plenty of ERC20-compliant tokens deployed on the Ethereum network.
Different implementations have been written by various teams that have different trade-offs: from gas saving to improved security.

#### Example implementations are available at
- [OpenZeppelin implementation](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol)
- [ConsenSys implementation](https://github.com/ConsenSys/Tokens/blob/fdf687c69d998266a95f15216b1955a4965a0a6d/contracts/eip20/EIP20.sol)



## Copyright
Copyright and related rights via ??? [CC0](../LICENSE.md).
