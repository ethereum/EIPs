---
eip: <to be assigned>
title: Reduced gas cost for call to self
author: Alex Beregszaszi (@axic), Jacques Wagener (@jacqueswww)
discussions-to: <TBA>
status: Draft
type: Standards Track
category: Core
created: 2018-08-31
requires: 150
---

## Abstract
Reduce the gas cost for call instructions, when the goal is to run a new instance of the currently loaded contract.

## Motivation
The current gas cost of 700 for all call types (`CALL`, `DELEGATECALL`, `CALLCODE` and `STATICCALL`) does not take into account that a call to a contract itself
does not need to perform additional I/O operations, because the current contract code has already been loaded into memory.

Reducing the call-to-self gas cost would greatly benefit smart contract languages, such as Solidity and Vyper, who would then be able to utilise `CALL` instead
of `JUMP` opcodes for internal function calls. While languages can already utilise `CALL` for internal function calls, they are discouraged to do so due to the
gas costs associated with it.

Using `JUMP` comes at a considerable cost in complexity to the implementation of a smart contract language and/or compiler. The context (including stack and memory)
must be swapped in and out of the calling functions context. A desired feature is having *pure* functions, which do not modify the state of memory, and realising
them through `JUMP` requires a bigger effort from the compiler as opposed to being able to use `CALL`s.

Using call-to-self provides the guarentee that when making an internal call the function can rely on a clear reset state of memory or context, benefiting both
contract writers and contract consumers against potentially undetetected edge cases were memory could poison the context of the internal function.

Because of the `JUMP` usage for internal functions a smart contract languages are also at risk of reaching the stack depth limit considerbly faster, if nested
function calls with many in and/or outputs are required.

Reducing the gas cost, and thereby incentivising of using call-to-self instead of `JUMP`s for the internal function implementation will also benefit static
analyzers and tracers.

## Specification
If `block.number >= FORK_BLKNUM`, then decrease the cost of `CALL`, `DELEGATECALL`, `CALLCODE` and `STATICCALL` from 700 to 40,
if and only if, the destination address of the call equals to the address of the caller.

## Rationale
EIP150 has increased the cost of these instructions from 40 to 700 to more fairly charge for loading new contracts from disk, e.g. to reflect the I/O charge more closely.
By assuming that 660 is the cost of loading a contract from disk, one can assume that the original 40 gas is a fair cost of creating a new VM instance of an already loaded contract code.

## Backwards Compatibility
This should pose no risk to backwards compatibility. Currently existing contracts should not notice the difference, just see cheaper execution.
With EIP150 contract (and language) developers had a lesson that relying on strict gas costs is not feasible as costs may change.
The impact of this EIP is even less that of EIP150 because the costs are changing downwards and not upwards.

## Test Cases
TBA

## Implementation
TBA

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
