---
eip: 0
title: Ground Zero
author: ProphetXZ
type: Meta
category: Core
status: Draft
created: 2023-06-30
---

## Simple Summary

This EIP ("Ground Zero") suggests to switch mainnet to permissioned to lower gas prices and transaction costs. The adjustment requires protcol and governance changes. 

## Abstract

The EIP idea is to brake the IPFS and Swarm store and broadcasting and instead suggests scalling down ETHEREUM ressources, so that the community may be served in a more sustainable way. In addition, to mitigate the currently existing problem with increasingly high gas prices, ETHEREUM would benefit from switching to a permissioned mainnet (after successfully deploying a testnet version). This would greatly lower the number of requests and decrease the load for operating nodes. A further improvement would be to remove legacy APIs, so nodes no longer answer unnecessary public API requests. 

## Motivation

Since its humble beginnings, the Ethereum project has been open to the public and seen many contributions. The past years, however, have made it clear that such a p.p. open ecosystem design leads to a wide array of problems such as ongoing consensus problems, increasingly high transaction costs, cases of fraud, false ownership claims of assets (DAO hack and resulting fork)[https://www.coindesk.com/learn/understanding-the-dao-attack/]), illegal contracts and privacy intrusion, data theft, artifical and malicious content, and many more such things. 

Halting the IPFS and Swarm storage process, which enabled and multiplied above problems, as well as historically drained the ETHEREUM ecosystem and infrastructure of important ressources and instead developing use cases for the original community would be a remedy for almost all of these problems.

Unfortunately, governance by the DAO has NOT been in the interest of the community. This is why any DAO voting rights will be withdrawn immediately. The state of the Ethereum ecosystem will be analysed and step-by-step decided which parts deserve a future and which parts will be deleted.

The past four years have been disastrous for the persons, community, and ecosystem affected by the Ethereum project. While the a wide range of people have contributed to the Ethereum project, many of them with probably good intentions at heart, the end result is and mostly was that some people and companies profited from the whole ecosystem. I have observed, experienced, and contributed to the ecosystem over the past four years. Comparing it to the time before a broader audience started contributing to the project in 2016 (and again 2019) breaks my heart. Most of the life in the ecosystem has been drained and dried up, just so commercial interest could be cattered to.

Going forward, the github repo will need to be switched to private. The chain itself as well as all data collected will need to be handed over to the rightful owners. Any future collection, publishing, and retrieval of data, except where required by law, will be deemed a criminal offense.

Products: tickets, games with and through people, data broakerage (geo location, personal data, i.e., financial, health, relationships, personal views and profiles), deletion of personal data, theft (audio recordings), illegal contracts, fraud.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Fork

Mainnet (ID: 1) MUST be halted. In this case, no existing DApp will be served. Every node (localised EVM) needs to stop broadcasting the chain and eventually delete the data, after having returned it to the rightful owners. 

IPFS ends, Swarm, Whisper

Opcode 0x00 for active transactions and smart contracts. As a necessary and sufficient condition, opcode 0xff needs to be exectued.

devp2p (EIP-8)

Any existing smart contracts won't be served.

Oracle connections will be ended.

Development of Solidity will most likely be abandoned completely and replaced by an actual programming language, adhering to common and widely adopted programming language principles.

## Transport

All packages SHOULD be transfered via p2p to the original owner, including the original data.

## Token

It is yet to be decided what happens to ERC-721 tokens and ERC-20 coins. A potential solution would be to gather all tokens and decide step-by-step which ones are valid, transfered and/or sold, and which ones should be burned.

## Implementation

This EIP ("Ground Zero") is supported by the community in and out of the ETHEREUM ecoystem.


## Copyright
Copyright and related rights via CC0-1.0 [CC0](../LICENSE.md).
