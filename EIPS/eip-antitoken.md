---
eip: <to be assigned>
title: Antitoken
author: hazae41 (@hazae41)
discussions-to: https://github.com/ethereum/EIPs/issues/3477
status: Draft
type: Standards Track
category: ERC
created: 2021-04-06
---

## Simple Summary
Representing debt in a token. Like an ERC-20 but with `receive` instead of `transfer`. Thus, the token has a negative value: the less you have, the better.

## Abstract
Imagine a anti-currency blockchain where, instead of signing the sending, you sign the receival. 

You cannot send the currency to an address, you can only receive it from the given address.

Thus, the incentive is to spend it, nobody wants it, the currency has a negative value.

This ERC uses a smart contract to emulate an anti-currency on the Ethereum ecosystem.

## Motivation
An antitoken can be used to represent debt, bad reputation, or anything negative in relation to its owner. 

The incentive is to spend it and to have a balance of zero.

## Specification
In a nutshell, the specification is the same as ERC-20, but with `receive` instead of `transfer`.

The balance MUST be a positive number, but its value MAY be displayed (e.g. on Dapps) with a negative sign.

Public functions `transfer` and `transferFrom` are replaced with `receive` and `receiveFrom`.

In public functions, `sender` is replaced by `recipient`, and `spender` is replaced by `receiver` (new name to be determined).

Function `receiveFrom` sees its parameters reverted:

`function transferFrom(address sender, address recipient, uint256 amount)`

-> `function receiveFrom(address recipient, address sender, uint256 amount)`

Internal functions and events DO NOT change.

## Rationale
The choice to stick to the ERC-20 specification is because it is roughly speaking a "negative" ERC-20.

The balance MUST remain positive to avoid security problems, and to be better compatible with existing applications.

## Reference Implementation
https://github.com/hazae41/ERC-Antitoken

## Security Considerations
An antitoken contract SHOULD NOT be compatible with ERC-20, otherwise it could be used on existing ERC-20 compatible applications (e.g. Decentralized exchanges).

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
