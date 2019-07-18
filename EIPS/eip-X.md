---
eip: <to be assigned>
title: Rebalance net-metered SSTORE gas cost with consideration of SLOAD gas cost change
author: Wei Tang (@sorpaas)
discussions-to: https://github.com/sorpaas/EIPs/issues/1
status: Draft
type: Standards Track
category: Core
created: 2019-07-18
requires: 1283, 1706, 1884
---

## Simple Summary

A repricing efforts for several trie-size-dependent opcodes are being
carried out. This EIP also reprices net-metered SSTORE opcode.

## Abstract

Change the intermediate write and no-op write of SSTORE to always have
the same gas cost of SLOAD. Change the refund of resetting after
setting for SSTORE to take consideration of gas cost of SLOAD.

## Motivation

Net gas metering for SSTORE was priced according to SLOAD values. For
consistency, when SLOAD is repriced, SSTORE should be as well.

## Specification

Define variables `SLOAD_GAS`, `SSTORE_SET_GAS`, `SSTORE_RESET_GAS` and
`SSTORE_CLEARS_SCHEDULE`. The old and new values for those variables are:

* `SLOAD_GAS`: changed from `200` to `800`.
* `SSTORE_SET_GAS`: `20000`, not changed.
* `SSTORE_RESET_GAS`: `5000`, not changed.
* `SSTORE_CLEARS_SCHEDULE`: `15000`, not changed.

Change the definition of EIP-1283 using those variables. The new
specification, combining EIP-1283 and EIP-1706, will look like
below. The terms *original value*, *current value* and *new value* are
defined in EIP-1283. 

Replace SSTORE opcode gas cost calculation (including refunds) with
the following logic:

* If *current value* equals *new value* (this is a no-op), `SLOAD_GAS`
  is deducted.
* If *current value* does not equal *new value*
  * If *original value* equals *current value* (this storage slot has
    not been changed by the current execution context)
    * If *original value* is 0, `SSTORE_SET_GAS` is deducted.
    * Otherwise, `SSTORE_RESET_GAS` gas is deducted. If *new value* is
      0, add `SSTORE_CLEARS_SCHEDULE` gas to refund counter.
  * If *original value* does not equal *current value* (this storage
    slot is dirty), `SLOAD_GAS` gas is deducted. Apply both of the
    following clauses.
    * If *original value* is not 0
      * If *current value* is 0 (also means that *new value* is not
        0), remove `SSTORE_CLEARS_SCHEDULE` gas from refund
        counter. We can prove that refund counter will never go below
        0.
      * If *new value* is 0 (also means that *current value* is not
        0), add `SSTORE_CLEARS_SCHEDULE` gas to refund counter.
    * If *original value* equals *new value* (this storage slot is
      reset)
      * If *original value* is 0, add `SSTORE_SET_GAS - SLOAD_GAS` to
        refund counter.
      * Otherwise, add `SSTORE_RESET_GAS - SLOAD_GAS` gas to refund
        counter.
* If *gasleft* is less than or equal to 2300, fail the current call
  frame with 'out of gas' exception.

An implementation should also note EIP-1283's refund counter
implementation details, in the *Specification* section.

## Rationale

The same as EIP-1283's rationale.

## Backwards Compatibility

This EIP has the same backward compatibility property of EIP-1283 and EIP-1706.

## Test Cases

To be added.

## Implementation

To be added.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
