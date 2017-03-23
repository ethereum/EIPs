## Preamble

    EIP: 140
    Title: REVERT instruction in the Ethereum Virtual Machine
    Author: Alex Beregszaszi, Nikolai Mushegian (nikolai@nexusdev.us)
    Type: Standard Track
    Category: Core
    Status: Draft
    Created: 2017-02-06

## Simple Summary

The `REVERT` instruction provides a way to stop execution and revert state changes, without consuming all provided gas and with the ability to return a reason.

## Abstract

The `REVERT` instruction will stop execution, roll back all state changes done so far and provide a pointer to a memory section, which can be interpreted as an error code or message. While doing so, it will not consume all the remaining gas.

## Motivation

Currently this is not possible. There are two practical ways to revert a transaction from within a contract: running out of gas or executing an invalid instruction. Both of these options will consume all remaining gas. Additionally, reverting a transaction means that all changes, including LOGs, are lost and there is no way to convey a reason for aborting a transaction.

## Specification

The `REVERT` instruction is introduced at `0xfd`. Execution is aborted and state changes are rolled back.

It expects two stack items, the top item is the `memory_length` followed by `memory_offset`. Both of these can equal to zero. The cost of the `REVERT` instruction equals to that of the `RETURN` instruction.

In case there is not enough gas left to cover the cost of `REVERT` or there is a stack underflow, the effect of the `REVERT` instruction will equal to that of a regular out of gas exception.

The content of the optionally provided memory section is not defined by this EIP, but is a candidate for another Informational EIP.

## Rationale

TBD

## Backwards Compatibility

This change has no effect on contracts created in the past.

## Test Cases

TBA

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
