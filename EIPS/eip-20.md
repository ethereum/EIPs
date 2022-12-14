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

## Token

### Methods

**NOTES**:
 - The following specifications use syntax from Solidity `0.4.17` (or above)
 - Callers MUST handle `false` from `returns (bool success)`.  Callers MUST NOT assume that `false` is never returned!

#### name

Returns the name of the token - e.g. `"MyToken"`.

OPTIONAL - This method can be used to improve usability,
but interfaces and other contracts MUST NOT expect these values to be present.

``` js
function name() public view returns (string)
```

#### symbol

Returns the symbol of the token. E.g. "HIX".

OPTIONAL - This method can be used to improve usability,
but interfaces and other contracts MUST NOT expect these values to be present.

``` js
function symbol() public view returns (string)
```

#### decimals

Returns the number of decimals the token uses - e.g. `8`, means to divide the token amount by `100000000` to get its user representation.

OPTIONAL - This method can be used to improve usability,
but interfaces and other contracts MUST NOT expect these values to be present.

``` js
function decimals() public view returns (uint8)
```

#### totalSupply

Returns the total token supply.

``` js
function totalSupply() public view returns (uint256)
```

#### balanceOf

Returns the account balance of another account with address `_owner`.

``` js
function balanceOf(address _owner) public view returns (uint256 balance)
```

#### transfer

Transfers `_value` amount of tokens to address `_to`, and MUST fire the `Transfer` event.
The function SHOULD `throw` if the message caller's account balance does not have enough tokens to spend.

*Note* Transfers of 0 values MUST be treated as normal transfers and fire the `Transfer` event.

``` js
function transfer(address _to, uint256 _value) public returns (bool success)
```

#### transferFrom

Transfers `_value` amount of tokens from address `_from` to address `_to`, and MUST fire the `Transfer` event.

The `transferFrom` method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
The function SHOULD `throw` unless the `_from` account has deliberately authorized the sender of the message via some mechanism.

*Note* Transfers of 0 values MUST be treated as normal transfers and fire the `Transfer` event.

``` js
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
```

#### approve

Allows `_spender` to withdraw from your account multiple times, up to the `_value` amount. If this function is called again it overwrites the current allowance with `_value`.

**NOTE**: Please read the [Security Considerations](#security-considerations) section for potential attack vectors.

``` js
function approve(address _spender, uint256 _value) public returns (bool success)
```

#### allowance

Returns the amount which `_spender` is still allowed to withdraw from `_owner`.

``` js
function allowance(address _owner, address _spender) public view returns (uint256 remaining)
```

### Events

#### Transfer

MUST trigger when tokens are transferred, including zero value transfers.

A token contract which creates new tokens SHOULD trigger a Transfer event with the `_from` address set to `0x0` when tokens are created.

``` js
event Transfer(address indexed _from, address indexed _to, uint256 _value)
```

#### Approval

MUST trigger on any successful call to `approve(address _spender, uint256 _value)`.

``` js
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
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
2. Later, Alice decides to set the approval from $N$ to $M$ ( $M>0$ ), so she calls the `approve(Bob, M)`
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
