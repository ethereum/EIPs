---
eip: 20
title: Token Standard
description: A standard interface for tokens
author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
discussions-to: https://github.com/ethereum/EIPs/issues/20
type: Standards Track
category: ERC
status: Final
created: 2015-11-19
---

## Abstract

This EIP standardizes an interface for fungible tokens within smart contracts.
The interface has basic transfer functionality, and allows tokens to be approved so they can be spent by another on-chain third party.

## Motivation

A standard interface allows any tokens on Ethereum to be re-used by other applications: from wallets to decentralized exchanges.

## Specification

All compliant tokens MUST implement the following interface:

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

interface ERC20 {
  /// @notice       MUST trigger when tokens are transferred, including zero value transfers.
  ///               A token contract which creates new tokens SHOULD trigger a Transfer event with the `_from` address set to `0x0` when tokens are created.
  /// @param _from  The address from which the tokens were transferred
  /// @param _to    The address to which the tokens were deposited
  /// @param _value The number of tokens that were transferred
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /// @notice         MUST trigger on any successful call to `approve(address _spender, uint256 _value)`.
  /// @param _owner   The address from which the tokens can be transferred
  /// @param _spender The address that can spend the tokens
  /// @param _value   The number of tokens that can be transferred
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /// @notice        Returns the total token supply.
  /// @return supply The supply of the token
  function totalSupply() external view returns (uint256 supply);
  
  /// @notice         Returns the balance of the account with address `_owner`.
  /// @param _owner   The account to query the balance of
  /// @return balance The balance of the account
  function balanceOf(address _owner) external view returns (uint256);

  /// @notice Returns the amount which `_spender` is still allowed to withdraw from `_owner`.
  /// @param _owner   The account which holds the tokens
  /// @param _spender The account that can spend the tokens
  /// @return remaining 
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  /// @notice        Transfers `_value` amount of tokens to address `_to`, and MUST fire the `Transfer` event.
  ///                The function SHOULD `throw` if the message caller's account balance does not have enough tokens to spend.
  /// @dev           Transfers of 0 values MUST be treated as normal transfers and fire the `Transfer` event.
  ///                Callers MUST handle `false` from `returns (bool success)`. Callers MUST NOT assume that `false` is never returned!
  /// @param _to     The address to which the tokens are deposited
  /// @param _value  The number of tokens that are transferred
  /// @return success Whether the operation was successful or not
  function transfer(address _to, uint256 _value) external returns (bool success);

  /// @notice        Transfers `_value` amount of tokens from address `_from` to address `_to`, and MUST fire the `Transfer` event.
  ///                The `transferFrom` method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
  ///                This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
  ///                The function SHOULD `throw` unless the `_from` account has deliberately authorized the sender of the message via some mechanism.
  /// @dev           Transfers of 0 values MUST be treated as normal transfers and fire the `Transfer` event.
  /// @param _from   The address from which the tokens are transferred
  /// @param _to     The address to which the tokens are deposited
  /// @param _value  The number of tokens that are transferred
  /// @return success Whether the operation was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  Allows `_spender` to withdraw from your account multiple times, up to the `_value` amount. If this function is called again it overwrites the current allowance with `_value`.

  **NOTE**: To prevent attack vectors like the one [described here](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/) and discussed [here](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729),
  clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to `0` before setting it to another value for the same spender.
  THOUGH The contract itself shouldn't enforce it, to allow backwards compatibility with contracts deployed before

  function approve(address _spender, uint256 _value) public returns (bool success)
}
```

In addition, the following RECOMMENDED interfaces MAY be implemented:

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

interface ERC20Name is ERC20 {
  /// @notice      Returns the name of the token - e.g. `"MyToken"`.
  /// @dev         OPTIONAL EXTENSION - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.
  /// @return      The name of the token
  function name() external view returns (string);
}

interface ERC20Symbol is ERC20 {
  /// @notice      Returns the symbol of the token - e.g. `"HIX"`.
  /// @dev         OPTIONAL EXTENSION - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.
  /// @return      The symbol of the token
  function symbol() external view returns (string);
}

interface ERC20Decimals is ERC20 {
  /// @notice      Returns the number of decimals the token uses - e.g. `8`, means to divide the token amount by `100000000` to get its user representation.
  /// @dev         OPTIONAL EXTENSION - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.
  /// @return      The decimals of the token
  function decimals() external view returns (uint8);
}
```

## Rationale

## Backwards Compatibility

Many existing tokens deployed on the Ethereum network already support this EIP.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
