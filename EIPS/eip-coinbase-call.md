---
eip: <to be assigned>
title: Coinbase calls
author: Ricardo Guilherme Schmidt (@3esmit)
discussions-to: https://ethresear.ch/t/gas-abstraction-non-signed-block-validator-only-procedures/4388/2
status: Draft
type: Standards Track 
category: Core
created: 2020-01-19

---

## Simple Summary

Allow contracts to be called by validator/miner (`block.coinbase`) without a transaction.

## Abstract

Validators/miners can choose become Gas Relayers to pick up fees from meta transactions, they do so by signing a transaction wrapping the meta transaction. However this brings an overhead of a signed transaction by validator that does nothing. This proposal makes possible to remove this unused ecrecover.

## Motivation

In order to reduce the overall overhead of gas abstraction.

## Specification

The calls to be executed by `block.coinbase` would be included first at block, and would consume normally the gas of block, however they won't pay/cost gas, instead the call logic would pay the validator in other form. 

Would be valid to execute any calls without a transaction by the block coinbase, except when the validator call tries to read `msg.sender`, which would throw an invalid jump.

Calls included by the validator would have `tx.origin = block.coinbase` and `gas.price = 0` for the rest of call stack, the rest follows a normal transactions.

## Rationale

TBD

## Backwards Compatibility

TBD

## Test Cases

TBD

## Implementation

TBD

## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
