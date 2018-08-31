---
eip: <to be assigned>
title: Reduced gas cost for call to self
author: Alex Beregszaszi (@axic)
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
TBA (there's a lot to write here)

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
