## Preamble

    EIP: 20
    Title: ERC-20 Token Standard
    Author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
    Type: Standard
    Category: ERC
    Status: Accepted
    Created: 2015-11-19


## Simple Summary

A standard interface for tokens.


## Abstract

The following standard allows for the implementation of a standard API for tokens within smart contracts.
This standard provides basic functionality to transfer tokens, as well as allow tokens to be approved so they can be spent by another on-chain third party.


## Motivation

A standard interface allows any tokens on Ethereum to be re-used by other applications: from wallets to decentralized exchanges.


## Specification

## Token
### Methods

**NOTE**: Callers should handle `false` from `returns (bool success)`.  Callers should not assume that `false` is never returned!

#### name

Returns the name of the token - e.g. `"MyToken"`

``` js
function name() constant returns (string name)
```


#### symbol

Returns the symbol of the token. E.g. "MYT"

``` js
function symbol() constant returns (string symbol)
```



#### decimals

Returns the number of decimals the token uses - e.g. `8`, means to divide the token amount by `100000000` to get its user representation.

``` js
function decimals() constant returns (uint8 decimals)
```


#### totalSupply

Returns the total token supply.

``` js
function totalSupply() constant returns (uint256 totalSupply)
```



#### balanceOf

Returns the account balance of another account with address `_owner`.

``` js
function balanceOf(address _owner) constant returns (uint256 balance)
```



#### transfer

Transfers `_value` amount of tokens to address `_to`.
The command should `throw` if the `_from` account balance has not enough tokens to spend.


``` js
function transfer(address _to, uint256 _value) returns (bool success)
```



#### transferFrom

Transfers `_value` amount of tokens from address `_from` to address `_to`.

The `transferFrom` method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
The command should `throw` unless the `_from` account has deliberately authorized the sender of the message via some mechanism.

``` js
function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
```



#### approve

Allows `_spender` to withdraw from your account multiple times, up to the `_value` amount. If this function is called again it overwrites the current allowance with `_value`.

**NOTE**: To prevent attack vectors like the one [described here](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/) and discussed [here](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729),
make sure to force users set the allowance to `0` before setting it to another value for the same spender.

``` js
function approve(address _spender, uint256 _value) returns (bool success)
```


#### allowance

Returns the amount which `_spender` is still allowed to withdraw from `_owner`.

``` js
function allowance(address _owner, address _spender) constant returns (uint256 remaining)
```



### Events


#### Transfer

Triggered when tokens are transferred.

``` js
event Transfer(address indexed _from, address indexed _to, uint256 _value)
```



#### Approval

Triggered when `approve(address _spender, uint256 _value)` is called.

``` js
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
```



## Implementation

There are already plenty of ERC20-compliant tokens deployed on the Ethereum network.
Different implementations have been written by various teams that have different trade-offs: from gas saving to improved security.

#### Example implementations are available at
- https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/StandardToken.sol
- https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/StandardToken.sol

#### Implementation of adding the force to 0 before calling "approve" again:
- https://github.com/Giveth/minime/blob/master/contracts/MiniMeToken.sol

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
