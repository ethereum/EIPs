---
sip: 36
title: Chainlink Oracles Phase 2 - Cryptocurrencies, indexes 
status: Implemented
author: Garth Travers (@garthtravers), Justin J Moses (@justinjmoses)
discussions-to: https://discord.gg/3uJ5rAy

created: 2020-01-20
---
## Simple Summary

Phase two of migrating to decentralized oracles involves transitioning the rest of our Synths to Chainlink networks. 

## Abstract

As part of the migration towards [decentralized oracles with Chainlink](https://github.com/Synthetixio/synthetix/issues/293), we have been implementing the transition in phases. [Phase 1](https://github.com/Synthetixio/SIPs/blob/master/SIPS/sip-32.md) involved migrating our forex and commodity synths to Chainlink pricing networks, and phase 2 will be all remaining Synths. 

## Motivation

As [discussed in this issue](https://github.com/Synthetixio/synthetix/issues/293), it is imperative that the Synthetix ecosystem continue to move away from a centralized oracle to decentralized pricing networks.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Our `ExchangeRates` contract (https://contracts.synthetix.io/ExchangeRates) will continue to be fed prices from the decentralized oracle. However, the logic for looking up prices will be extended with a mapping of Chainlink Aggregator contracts for each Synth.

Rather than using Chainlink updates for our inverse Synths, we will simply calculate the inverse Synth rates by using the prices of their partner 'long' Synths. The opposite is true of the 'index' Synths (i.e. sDEFI) — Chainlink oracles will calculate the indexes off-chain and push that single price on-chain rather than pushing each price portion of the index on-chain separately. 

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

_To be added_

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

_To be added_

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

_To be added_

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
