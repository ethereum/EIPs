---
sip: 39
title: Set up GrantsDAO
status: Implemented
author: Garth Travers (@garthtravers)
discussions-to: https://discordapp.com/invite/AEdUHzt
created: 2020-01-30
updated: N/A
---
## Simple Summary

Create a DAO that determines how to disburse funding for community grants. 

## Abstract

Build a smart contract + frontend that allows 5 individuals to vet grant proposals for contributing to the Synthetix ecosystem.

## Motivation

Community grants are currently disbursed by the Foundation. However, moving this process to a DAO will add transparency to the grants decision-making as well as providing invaluable data around how to coordinate future Synthetix DAOs. This will represent the first, transitional phase of Synthetix's shift to decentralised governance. 

Of the 5 individuals, 2 will be team members and the other three will be from the Synthetix community. We will be using a multi-sig contract to vote and send out funds as that is the simplest form of determining consensus. 

## Specification

It should work as follows:
A grant proposal gets submitted to the grantsDAO repo, and a DAO member submits its key details to the smart contract through the web3 frontend. There is a 24 hour grace period where the other DAO members can discuss the new proposal without voting, after which they can vote by signing a txn. For a grant to pass and receive funding it will require 4 approvals. 

In the future (not in the first design), if the community reaches negative consensus around a signer's performance, they can vote to replace that signer. 

## Rationale

This is a relatively light-touch way to ensure that strong, community-weighted consensus can be measured through the group of signers. The rationale behind creating a DAO is to ensure the project stays censorship-resistant. 

It's important to have a grants process because there are many talented developers who wish to see the Synthetix ecosystem mature and are willing to put their skills to work for this purpose, so the grantsDAO will facilitate this growth. 

## Test Cases

N/A

## Implementation

We have already engaged a team to build this contract. 

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
