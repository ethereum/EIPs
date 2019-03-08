---
eip: 877
title: Separating transaction signer from transaction deployer
author: Alex Van de Sande (@alexvandesande)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2018-02-09
---

## Simple Summary

Many contract developers run in the problem of allowing users to interact with their contracts without having ether. This has been addressed by proposed [account abstractions](https://github.com/ethereum/EIPs/issues/859) which would bring a lot of new features but also brings a lot of complexity. The latest proposed version by Vitalik, while still brings many benefits like quantum resistance, would still not, for example, to pay token transactions with the token themselves, an often requested feature.

This EIP proposes a simple way that enables this by simply separating the transaction ***signer*** (the person or entity authorizing the transaction) from the transacion ***deployer*** (the person or entity publishing that transaction to the chain and paying its gas). It is not meant to replace account abstraction and the other benefits it might bring.

## Abstract

Currently, ethereum transactions have the following fields: `nonce`, `gasPrice`, `gasLimit`, `value`, `to` and `data`. This EIP proposes creating a new class of transactions that are two encapsulated signed transactions. The outer one contains `nonce`, `gasPrice`, `gasLimit` and a new field alled `signedTransaction` that contains the inner transaction. The inner transaction is a standard ethereum transaction, except it doesn't have `gasPrice` or `gasLimit`. Both transactions have a `nonce` field.

Block validators/miners should treat the inner transaction as a standard one **except** that in the end, the gas costs (with an added extra cost for the work of checking the validity of the signature) is *deduced from the account of the outer transaction, which deploying to the chain*. Both nonces must be valid and both should be incremented.

In higher level languages like solidity, `from` (if present) would be the `msg.sender` as it would be compatible with current contracts, and a new special variable called `tx.sender` could be added to represent the deployer of the transaction (if the code wanted to create incentives).


## Motivation

Using signed messages instead of transactions as means to interact with contracts is an emergint pattern in the space and this is a paving the cow paths EIP. Aragon is implementing it on their organizations, some token standard improvements have been extended to it. But it requires functions to be specifically made to support them, it doubles the amount of code required and this EIP proposes to make it a standard transaction format.

**Alternatively** this could be also done without a hard fork by adding support for these on solidity, by adding a function property that on compilation creates a second set of functions that accept signed messages.

## Current Implementation examples

As said, we are paving a cow path, there are multiple projects that are trying to develop this on their own solidity code, and therefore it's a good candidate for being a native feature.

* [Status](https://github.com/status-im/ideas/issues/73) 
* [Swarm City](https://github.com/swarmcity/SCLabs-gasstation-service)
* [Aragon](https://github.com/aragonlabs/pay-protocol) (this might not be the best link to show their work in this area)
* [Token Standard Functions for Preauthorized Actions](https://github.com/ethereum/EIPs/issues/662)
* [Token Standard Extension 865](https://github.com/ethereum/EIPs/issues/865)
* [Transaction Relay](https://github.com/iurimatias/TransactionRelay)

## Backwards Compatibility

Any transaction that does not have the `from` field is treated as it was before.


## Usage examples

Notice that the cost of ether is paid by the transaction deployer at no gains, so each contract would have to work out their own incentivization mechanism, in or off chain. Some usage examples would include:

* A game company creates games with a traditional monthly subscription, either by credit card or platform specific microtransactions. Private keys never leave the device and keep no ether and only the public accounts are sent to the company. The game then signs transactions on the device, sends them to the game company which checks who is an active subscriber and batches all transactions and pays the ether themselves. If the company goes bankrupt, the gamers themselves can either add ether to their accounts and keep playing, or set up a similar system themselves. End result is a **ethereum based game in which gamers can play by spending apple, google or xbox credits**.

* A standard token is created that for every transaction, gives an optional x% of the tokens being transferred to the deployer of the transaction. A wallet is created that signs messages and send them via whisper to the network, where other nodes can compete to download the available transactions, check the current gas price, and select those who are paying enough tokens to cover the cost. **The result is a token that the end users never need to keep any ether and can pay fees in the token itself.**

* An DAO is created with a list of accounts of their employees. Employees never need to own ether, instead they sign messages, send them to whisper to a decentralized list of relayers which then deploy the transactions. The DAO contract then checks if the transaction is valid and sends a bit of ether to the deployers, based on some internal metric on the rank of the employee or the time it took for the transaction to be relayed. The result is that the users of the DAO don't need to keep ether, and **the contract ends up paying for it's own gas usage**.

The benefits are obvious: a long list of new things are possible by leaving incentivization layer to the contract.
