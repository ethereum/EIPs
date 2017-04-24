This is the suggested template for new EIPs.

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

## Preamble

    EIP: <to be assigned> (I Suggest 20)
    Title: <EIP title>
    Author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
    Type: Informational
    Category ERC
    Status: Draft
    Created: 2015-11-19


## Simple Summary

Token standard interface.


## Abstract

The following standard allows for people to implement a token standard API withing their smart contracts.

This standard provides basic functionality for sending and approving tokens to be spend by a third party.


## Motivation

Following the same standard interface allows those tokens to be used in many wallets and exchanges.


## Specification

## Token
### Methods

**NOTE**: An important point is that callers should handle `false` from `returns (bool success)`.  Callers should not assume that `false` is never returned!

#### totalSupply

``` js
function totalSupply() constant returns (uint256 totalSupply)
```

Get the total token supply


#### balanceOf

``` js
function balanceOf(address _owner) constant returns (uint256 balance)
```

Get the account balance of another account with address `_owner`


#### transfer

``` js
function transfer(address _to, uint256 _value) returns (bool success)
```

Send `_value` amount of tokens to address `_to`


#### transferFrom

``` js
function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
```

Send `_value` amount of tokens from address `_from` to address `_to`

The `transferFrom` method is used for a withdraw workflow, allowing contracts to send tokens on your behalf, for example to "deposit" to a contract address and/or to charge fees in sub-currencies; the command should fail unless the `_from` account has deliberately authorized the sender of the message via some mechanism; we propose these standardized APIs for approval:


#### approve

``` js
function approve(address _spender, uint256 _value) returns (bool success)
```

Allow _spender to withdraw from your account, multiple times, up to the _value amount. If this function is called again it overwrites the current allowance with _value.
To prevent attack vectors like described here: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/
make sure to set the allowance to 0 before setting it to another value for the same spender.


#### allowance

``` js
function allowance(address _owner, address _spender) constant returns (uint256 remaining)
```

Returns the amount which `_spender` is still allowed to withdraw from `_owner`


### Events


#### Transfer

``` js
event Transfer(address indexed _from, address indexed _to, uint256 _value)
```

Triggered when tokens are transferred.


#### Approval

``` js
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
```

Triggered whenever `approve(address _spender, uint256 _value)` is called.


## Implementation

Different implementations are available at
- https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/StandardToken.sol
- https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/StandardToken.sol

Implentation adding the force 0 before calling approve again:
- https://github.com/Giveth/minime/blob/master/MiniMeToken.sol

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
