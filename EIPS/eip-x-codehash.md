---
eip: <to be assigned>
title: CODEHASH opcode
author: Nick Johnson <arachnid@notdot.net>
discussions-to: <email address>
status: Draft
type: Standards Track
category: Core
created: 2018-05-02
---

## Abstract
This EIP specifies a new opcode, which returns the keccak256 hash of a contract's code.

## Motivation
Many contracts need to perform checks on a contract's bytecode, but do not necessarily need the bytecode itself. For instance, a contract may want to check if another contract's bytecode is one of a set of permitted implementations, or it may perform analyses on code and whitelist any contract with matching bytecode if the analysis passes.

Contracts can presently do this using the `CODECOPY` opcode, but this is expensive, especially for large contracts, in cases where only the hash is required. As a result, we propose a new opcode, `CODEHASH`, which returns the keccak256 hash of a contract's bytecode.

## Specification
A new opcode, `CODEHASH`, is introduced, with number 0x3D. `CODEHASH` takes one argument from the stack, and pushes the keccak256 hash of the code at that address to the stack.

## Rationale
As described in the motivation section, this opcode is widely useful, and saves on wasted gas in many cases.

## Backwards Compatibility
There are no backwards compatibility concerns.

## Test Cases
TBD

## Implementation
TBD

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
