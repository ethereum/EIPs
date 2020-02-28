---
sip: 41
title: ProtocolDAO phase zero
status: Proposed
author: Garth Travers (@garthtravers)
discussions-to: https://discordapp.com/invite/AEdUHzt
created: 2020-02-28
updated: N/A
---
## Simple Summary

Proposal to move Synthetix contracts owner to a Gnosis multisig wallet. 

## Abstract

The current contract owner is an airgapped EOA. In order to support the functionality required by the ProtocolDAO we need to migrate the owner account to a multisig. We plan to transition to a 3/5 multisig ahead of the launch of the proxy migrator contract. This contract will be the owner of all of the existing contracts and will be owned by the multisig, which will allow us to implement timelocking on contract upgrades as well as other security features.

## Motivation

Security has become a growing concern in DeFi as several high-profile exploits have caused some people to become more vocal about DeFi protocols. Transitioning to the ProtocolDAO will significantly enhance the security and transparency of protocol upgrades.

## Specification

We will deploy a 3/5 multisig and transition contract ownership to this contract from the existing EOA.

## Rationale

We chose the Gnosis Multisig as we have used it in several other implementations including the management of Uniswap staking rewards. 

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
