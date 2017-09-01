## Preamble

    EIP: <to be assigned>
    Title: <EIP standard deposit and withdraw functions>
    Author: <Gabriele Rigo, gab@rigoblock.com>
    Type: <Standard Track>
    Category (*only required for Standard Track): <Interface> 
    Status: Draft
    Created: <2017-09-01>
    Requires (*optional): <EIP number(s)>
    Replaces (*optional): <EIP number(s)>


## Simple Summary
define standard and abstracted deposit and withdraw interface functions for allowing interaction between contracts
## Abstract
lack of accepted standards makes it very difficult for smart contracts to communicate with each other. the standard deposit and withdraw functions are designed as abstracted, could potentially be furhter abstracted. They allow for deposits and withdrawal of Ether and ERC20 tokens and allow an external contract/application perform success test.

## Motivation
set a standard in defining these two very commonly used functions, help developers build intercommunicating applications.
## Specification
the solidity code:
```
function deposit(address _token, uint _amount) payable returns (bool success) {}
function withdraw(address _token, uint _amount) returns (bool success) {}
```
use: for ETH movements, address _token == 0

## Rationale
use less size in smart contracts and generalize, setting a universally valuable standard.
## Backwards Compatibility
no issue with backward compatibility
## Test Cases
NA
## Implementation
NA
## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
