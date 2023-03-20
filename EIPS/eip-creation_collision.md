---
eip: <not assigned>
title: Revert creation in case of collision
description: Revert contract creation if address already has code
author: Renan Rodrigues de Souza (@RenanSouza2)
discussions-to: https://ethereum-magicians.org/t/eip-revert-on-address-collision/13442
status: Draft
type: Standards Track
category: Core
created: 2023-03-20
---

## Abstract

There is no current definition to what happens when a contract creation happens in an address with code already deployed. This fix prevents an attack of deploying a contract code and later changing the code arbitrarily.

## Motivation

In EIP-3607 it was estimated that to create an address collision it would take something about 10 billion USD and this number decreases as computers processing power grow.

## Specification

In contract creation where `new contract address` has a `CODEHASH != EMPTYCODEHASH` MUST have its current environment execution reverted, where `EMPTYCODEHASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470`.

## Rationale

One of the core tenants of smart contracts is it's code being guranteed not to change, with enougth computing power an attacker can change the code stored in an address to any other code allowing them to remove funds or transfer tokens.

## Backwards Compatibility

There is a very small possibility of this collision happening to contract cration by contracts.

## Test Cases

Given a genesis allocation of

```
Address : 0x5FbDB2315678afecb367f032d93F642f64180aa3,
Balance : 1000000000000000000, // 1 ether
Nonce   : 0,
code    : "",

Address : 0x5FbDB2315678afecb367f032d93F642f64180aa3,
Balance : 0,
Nonce   : 1,
Code    : "0xB0B0FACE",
```
A contract created in the first transaction from EOA `0x5FbDB2...` (`227bcc6959669226360814723ed739f1214201584b6a27409dfb8228b8be5f59`), with no salt, should revert.


## Reference Implementation

The following check MUST be included in the function create function, MUST revert in case the check fails.

```
// During the execution of the create function Λ, defined in the yellow paper
// after computing the address of the new contract 'a'

a ≡ ADDR(s, σ[s]n − 1, ζ, i)

require(σ[a]c != EMPTYCODEHASH)
```

## Security Considerations

This EIP is a security upgrade: it reinforces the imutability of a deployed code.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

## Citation

Please cite this document as Renan Souza, "EIP-creation_collision: Revert creation in case of collision"
