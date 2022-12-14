---
eip: 20
title: Token Standard
description: A standard interface for tokens
author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
discussions-to: https://github.com/ethereum/EIPs/issues/20
status: Final
type: Standards Track
category: ERC
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
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  /// @notice         Allows `_spender` to withdraw from your account multiple times, up to the `_value` amount.
  ///                 If this function is called again it overwrites the current allowance with `_value`.
  /// @dev            To prevent the re-approval attack vector described in the Security Considerations section, clients SHOULD make sure
  ///                 to create user interfaces in such a way that they set the allowance `0` before setting it to another value for the
  ///                 same spender. However, contracts SHOULD NOT enforce this, for backward compatibility with previously-deployed contracts.
  /// @param _spender The address to which the tokens are deposited
  /// @param _value   The number of tokens that are transferred
  /// @return success Whether the operation was successful or not
  function approve(address _spender, uint256 _value) external returns (bool success);
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

### The approve and transferFrom flow

`approve` and `transferFrom` can be used in conjunction with one another to allow smart contracts to take an action if and only if a transfer succeeds. This enables use cases such as decentralized exchanges, which can trustlessly swap one token for another.

### Decimals is optional

Some tokens might wish to use a base unit other than $10^{-18}$, and sometimes it doesn't make sense to have a fraction of a token. However, not every token might reasonably need to specify `decimals`. Thus, `decimals` is optional.

## Backwards Compatibility

Many existing tokens deployed on the Ethereum network already support this EIP.

## Security Considerations

### Re-approval

#### Description of re-approval attack

1. Alice approves Bob to transfer $N$ of Alice's tokens (where $N>0$) by calling the `approve(Bob, N)`
2. Later, Alice decides to set the approval from $N$ to $M$ ($M>0$), so she calls the `approve(Bob, M)`
3. Bob notices Alice's second transaction when it is submitted to the mempool
4. Before Alice's `approve(Bob, M)` transaction is included in a block, Bob sends a transaction calling `transferFrom(Alice, Bob, N)` with a higer priority fee than Alice's transaction, and a transaction calling `transferFrom(Alice, Bob, M)` with a lower priority fee than Alice's transaction
5. Bob's `transferFrom(Alice, Bob, N)` will be executed first, transfering $N$ tokens from Alice to Bob
6. Next, Alice's `approve(Bob, M)` will execute, allowing Bob to transfer an additonal $M$ tokens
7. Finally, Bob's `transferFrom(Alice, Bob, M)` will be executed first, transfering another $M$ tokens from Alice to Bob

Bob was able to transfer a total of $N+M$ tokens instead of a total of $M$.

(Written by Mikhail Vladimirov <mikhail.vladimirov@gmail.com> and Dmitry Khovratovich <khovratovich@gmail.com>, edited by Pandapip1 (@Pandapip1))

#### Mitigation of re-appproval attack

Frontends should be written such that if a non-zero approval is to be raised or lowered, the approval is first set to zero and the transaction included in a block.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
