---
eip: 2997
title: IMPERSONATECALL Opcode
author: Sergio Demian Lerner (sergio.d.lerner@gmail.com)
category: Core
type: Standards Track
status: Draft
created: 2020-09-24
---

## Abstract

Add a new opcode, `IMPERSONATECALL` at `0xf6`, which is similar in idea to `CALL (0xF1)`, except that it impersonates a sender, i.e. the callee sees a sender different from the real caller. To prevent collisions with other deployed contract or externally owned accounts, the impersonated sender address is derived from the real caller address and a salt.

### Specification

`IMPERSONATECALL`: `0xf6`, takes 7 operands:

- `gas`: the amount of gas the code may use in order to execute;
- `to`: the destination address whose code is to be executed;
- `in_offset`: the offset into memory of the input;
- `in_size`: the size of the input in bytes;
- `out_offset`: the offset into memory of the output;
- `out_size`: the size of the scratch pad for the output.
- `salt` is a `32` bytes value (a stack item). 

#### Computation of impersonated sender

The impersonated sender address is computed as `keccak256( 0xff ++ address ++ salt ++ zeros32)[12:]`.

- `0xff` is a single byte, 
- `address` is always `20` bytes, and represents the address of the real caller contract.
- `salt` is always `32` bytes. 

- The field zeros32 corresponds to 32 zero bytes.

This scheme emulates `CREATE2` derivation but it cannot practically collude with the `CREATE2` address space.

#### Notes
- The opcode behaves exactly as `CALL` in terms of gas consumption.
- In the called context `CALLER (0x33)` returns the impersonated address.
- If value transfer is non-zero in the call, the value is transferred from the impersonated account, and not from the real caller. This can be used to transfer ether out of an impersonated account.

### Motivation

Many times a "sponsor" company wants to deploy non-custodial smart wallets for all its users. The sponsor does not want to pay the deployment cost of each user contract in advance. Counterfactual contract creation enables this, yet it forces the sponsor to create the smart wallet (or a proxy contract to it) when the user wants to transfer ether or tokens out of his/her account. The contract creation cost is approximately 42000 gas. This proposal avoids this extra cost, and enables the creation of multi-wallets (wallets that serve multiple users) that can be commanded by EIP-712 based messages.

### Rationale

Even if `IMPERSONATECALL` requires hashing 3 words, implying an additional cost of 180 gas, we think the benefit of accounting for hashing doesn't not compensate increasing the complexity of the implementation.

While the same functionality could be provided in a pre-compiled contract, we believe using a new opcode is a cleaner solution.


### Possible arguments against

* You can replicate this functionality with counterfactual contract creation. We argue that the there is an important benefit of avoiding the deployment cost in case the sponsor needs to serve thousands of users.

### Clarifications

- This EIP makes collisions possible, yet practically impossible.

- If a contract already exists with an impersonated address, the `IMPERSONATECALL` is executed in the same way, and the existing code will not be executed. It should  be noted that `SELFDESTRUCT` (`0xff`) cannot be executed directly with `IMPERSONATECALL` as no opcode is executed in the context of the impersonated account.

### Examples

We present 4 examples of impersonated address derivation:

Example 0

* address `0x0000000000000000000000000000000000000000`
* salt `0x0000000000000000000000000000000000000000000000000000000000000000`
* result: `0xFFC4F52F884A02BCD5716744CD622127366F2EDF`

Example 1
* address `0xdeadbeef00000000000000000000000000000000`
* salt `0x0000000000000000000000000000000000000000000000000000000000000000`
* result: `0x85F15E045E1244AC03289B48448249DC0A34AA30`

Example 2
* address `0xdeadbeef00000000000000000000000000000000`
* salt `0x000000000000000000000000feed000000000000000000000000000000000000`
* result: `0x2DB27D1D6BE32C9ABFA484BA3D591101881D4B9F`


Example 3
* address `0x00000000000000000000000000000000deadbeef`
* salt `0x00000000000000000000000000000000000000000000000000000000cafebabe`
* result: `0x5004E448F43EFE3C7BF32F94B83B843D03901457`

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
