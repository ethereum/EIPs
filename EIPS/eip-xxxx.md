---
eip: xxxx
title: Non-Malleable Block Gas Target
author: Philippe Castonguay (@PhABC)
discussions-to: xxxx
status: Draft
type: Standards Track
category: Core
created: 2020-03-13

---

## Simple Summary

Hardcode the block gas target (previously known as gas limit before [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md)) to 12,500,000 gas per block.

## Abstract

Ethereum's block gas target is currently dictated by block producers and is not enforced when validating blocks in clients. This EIP proposes to hardcode the block gas target to 12,500,000.

## Motivation

Both Ethereum's Proof of Work and Proof of Stake designs assume that block producers are financially rational, but does not assume block producers to be benevolent. There is one exception however, and it is when block producers choose the gas limit of a block, where it is assumed that block producers care about the long term health and decentralisation of the chain. Indeed, the block gas limit is one of the only parameters in Ethereum that is not dictated by node consensus, but instead is chosen by block producers. This decision was initially made to allow urgent changes in the block gas limit if necessary. However, as the last two years have shown, increasing the block gas limit leads to marginal benefits regarding gas prices, but can cause significant damage to the long term health of the chain. It is therefore a critical parameters that should require node consensus to avoid any sudden harmful change imposed by a small number of actors on the rest of the network.

## Specification
This EIP assumes that EIP-1559 is implemented and blocks' `gasLimit` was replaced with `gasTarget`.

#### Block Header

As of `FORK_BLOCK_NUMBER`, remove `gas_target` field from block headers.

#### Consensus

As of `FORK_BLOCK_NUMBER`, change the headers gas target validity check such that `header.gasUsed` **MUST** be smaller than `BLOCK_GAS_TARGET * ELASTICITY_MULTIPLIER` where `BLOCK_GAS_LIMIT` is a hard-coded constant set to 12,500,000, not the current gas target included in block headers and ELASTICITY_MULTIPLIER is **2** as per defined in [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md#specification).

#### EVM

The `GASLIMIT` opcode (0x45) should return the constant 12,500,000 as of `FORK_BLOCK_NUMBER`.

## Rationale

#### Removing the gasTarget from the header

The gas target was only present in block headers as it was defined by the block producers. Since this value is now a constant accessible to all nodes, there is little benefit to having the gasLimit in the block headers. 

#### Gas Target Selected

The 12,500,000 value is being proposed as it's the current block gas limit as of time of writing this EIP. The actual amount could be altered with a subsequent EIP to avoid deviating from the core intent of this EIP.

## Backwards Compatibility

Removing the gasLimit value from the header may break some analytic tools that rely on this field.

## Security Considerations



## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
