---
eip: 
title: Separation of Block Gas Limit and Transaction Gas Limit.
author: Jet Lim (@Nitro888)
discussions-to:
status: Draft
type: Standards Track
category: Core
created: 2018-11-21
---

## Simple Summary
By separating the block gas limit and the transaction gas limit, more smart contracts can be executed when the block is created.

## Abstract
Since the values of block gas limit and transaction gas limit are the same, theoretically, one block may process only one transaction.
In practice, transactions are often generated that use more than 200 million gases, which means that the number of smart contracts executed in a block is reduced.
At the same time, it is suggested that the transaction gas limit be lower than the block gas limit in order to improve the multitasking capability of the blockchain by executing many smart contracts.

## Motivation
Often, transactions that consume huge amounts of gas occur. This will reduce the number of transactions in the block containing the transaction, and the number of smart contacts operating at the same time will also decrease.
Reducing the number of smart contracts means a decrease in the performance of the World Computer, Eiderium. 
Therefore, we need to limit the gas consumption of transactions to allow more transactions to run, so that many smart contacts can run at the same time.

## Specification
Differentiate between the size of the gas usage in the transactions in which the smart contract is deployed and the transactions in which the smart contract is executed. For a transaction deploy, it allows the same amount of gas as the block gas limit. The gas limit in the transaction to execute the smart contact allows for a much smaller amount of gas to be consumed.
### Block Gas Limit
Block gas limit is used in the same sense as before.
### Deploy Smart Contact Gas Limit
is the same as the block gas limit as the maximum gas limit for transactions deploying smart contacts.
### Transactional gas limit
running smart contacts that can consume a very small amount of gas than the block gas limit.

## Rationale

## Backwards Compatibility

## Test Cases

## Implementation

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
