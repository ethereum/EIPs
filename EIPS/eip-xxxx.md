---
eip: xxxx
title: Non-Malleable Block Gas Limit
author: Philippe Castonguay (@PhABC)
discussions-to: xxxx
status: Draft
type: Standards Track
category: Core
created: 2020-03-13

---

## Simple Summary

Hardcode the block gas limit to 25,000,000 gas per block.

## Abstract

Ethereum's block gas limit is currently dictated by block producers and is not enforced when validating blocks in clients. This EIP proposes to hardcode the block gas limit to 25,000,000 and enforce this validation in clients.

## Motivation

Both Ethereum's Proof of Work and Proof of Stake designs assume that block producers are financially rational, but does not assume block producers to be benevolent, except when it comes to choosing the block gas limit, where it is assume that block producers care about the long term health and decentralisation of the chain. Indeed, the block gas limit is one of the only parameters in Ethereum that is not dictated by node consensus, but instead is chosen by block producers. This decision was initially made to allow quick changes in the block gas limit in case in became urgent. However, as the last two years have shown, increasing the block gas limit leads to marginal benefits regarding gas prices, but can cause significant damage to the long term health of the chain. It is therefore a critical parameters that should require node consensus to avoid any sudden harmful change by a small number of actors.

## Specification

## Rationale

## Backwards Compatibility

## Security Considerations

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).