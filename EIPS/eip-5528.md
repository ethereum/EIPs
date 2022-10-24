---
eip: 5528
title: Refundable Fungible Token
description: Allows refunds for EIP-20 tokens by escrow smart contract
author: StartfundInc (@StartfundInc)
discussions-to: https://ethereum-magicians.org/t/eip-5528-refundable-token-standard/10494
status: Review
type: Standards Track
category: ERC
created: 2022-08-16
requires: 20
---

## Abstract

This standard is an extension of [EIP-20](./eip-20.md). This specification defines a type of escrow service with the following flow:

- The seller issues tokens.
- The seller creates an escrow smart contract with detailed escrow information like contract addresses, lock period, exchange rate, additional escrow success conditions, etc.
- The seller funds seller tokens to the *Escrow Contract*.
- Buyers fund buyer tokens which are pre-defined in the *Escrow Contract*.
- When the escrow status meets success, the seller can withdraw buyer tokens, and buyers can withdraw seller tokens based on exchange rates.
- Buyers can withdraw (or refund) their funded token if the escrow process is failed or is in the middle of the escrow process.

## Motivation

Because of the pseudonymous nature of cryptocurrencies, there is no automatic recourse to recover funds that have already been paid.

In traditional finance, trusted escrow services solve this problem. In the world of decentralized cryptocurrency, however, it is possible to implement an escrow service without a third-party arbitrator. This standard defines an interface for smart contracts to act as an escrow service with a function where tokens are sent back to the original wallet if the escrow is not completed.

## Specification

There are two types of contract for the escrow process:

- *Payable Contract*: The sellers and buyers use this token to fund the *Escrow Contract*.
- *Escrow Contract*: Defines the escrow policies and holds *Payable Contract*'s token for a certain period.

This standard proposes interfaces on top of the [EIP-20](./eip-20.md) standard.

### Methods

#### constructor

The *Escrow Contract* MUST define the following policies:

- Seller token contract address
- Buyer token contract address

The *Escrow Contract* MAY define the following policies:

- Escrow period
- Maximum (or minimum) number of investors
- Maximum (or minimum) number of tokens to fund
- Exchange rates of seller/buyer token
- KYC verification of users

#### `escrowFund`

Funds `_value` amount of tokens to address `_to`.

In the case of *Escrow Contract*:

 - `_to` MUST be the user address.
 - `msg.sender` MUST be the *Payable Contract* address.
 - MUST check policy validations.

In the case of *Payable Contract*:

  - The address `_to` MUST be the *Escrow Contract* address.
  - MUST call EIP-20's `transfer` function.
  - Before calling `transfer` function, MUST call the same function of the *Escrow Contract* interface. The parameter `_to` MUST be `msg.sender` to recognize the user address in the *Escrow Contract*.

```solidity
function escrowFund(address _to, uint256 _value) public returns (bool)
```

#### `escrowRefund`

Refunds `_value` amount of tokens from address `_from`.

In the case of *Escrow Contract*:

 - `_from` MUST be the user address.
 - `msg.sender` MUST be the *Payable Contract* address.
 - MUST check policy validations.

In the case of *Payable Contract*:

  - The address `_from` MUST be the *Escrow Contract* address.
  - MUST call EIP-20's `_transfer` likely function.
  - Before calling `_transfer` function, MUST call the same function of the *Escrow Contract* interface. The parameter `_from` MUST be `msg.sender` to recognize the user address in the *Escrow Contract*.

```solidity
function escrowRefund(address _from, uint256 _value) public returns (bool)
```

#### `escrowWithdraw`

Withdraws funds from the escrow account.

In the case of *Escrow Contract*:
 - MUST check the escrow process is completed.
 - MUST send the remaining balance of seller and buyer tokens to `msg.sender`'s seller and buyer contract wallets.

In the case of *Payable Contract*, it is optional.

```solidity
function escrowWithdraw() public returns (bool)
```

### Example of interface

```solidity
pragma solidity ^0.4.20;

interface IERC5528 is ERC20 {

    function escrowFund(address _to, uint256 _value) public returns (bool);

    function escrowRefund(address to, uint256 amount) public returns (bool);

    function escrowWithdraw() public returns (bool);

}

```

## Rationale

The interfaces described in this EIP have been chosen to cover the refundable issue in the escrow operation.

The suggested 3 functions (`escrowFund`, `escrowRefund` and `escrowWithdraw`) are based on `transfer` function in EIP-20.

`escrowFund` send tokens to the *Escrow Contract*. The *Escrow Contract* can hold the contract in the escrow process or reject tokens if the policy does not meet.

`escrowRefund` can be invoked in the middle of the escrow process or when the escrow process is failed.

`escrowWithdraw` allows users (sellers and buyers) to transfer tokens from the escrow account. When the escrow process is completed, the seller can get the buyer's token, and the buyers can get the seller's token.

## Backwards Compatibility

This EIP is fully backward compatible with the [EIP-20](./eip-20.md) specification.

## Test Cases

[Unit test example by truffle](../assets/eip-5528/truffule-test.js).

This test case demonstrates the following conditions for exchanging seller/buyer tokens.
- The exchange rate is one-to-one.
- If the number of buyers reaches 2, the escrow process will be terminated(success).
- Otherwise (not meeting success condition yet), buyers can refund (or withdraw) their funded tokens.

## Security Considerations

Since the *Escrow Contract* controls seller and buyer rights, flaws within the *Escrow Contract* will directly lead to unexpected behavior and potential loss of funds.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
