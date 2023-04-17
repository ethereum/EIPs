---
eip: NaN
title: Math checking in EVM
description: Check for math underflows overflows and division by zero at EVM level
author: Renan Rodrigues de Souza (@RenanSouza2)
discussions-to: https://ethereum-magicians.org/t/eip-math-checking/13846
status: Draft
type: Standards Track
category: Core
created: 2023-04-16
---

## Abstract

This EIP adds many math checking to EVM arithmetic. The list includes underflows, overflows, division by zero. A new opcode is added to get the flags and clean them.

## Motivation

The importance of math checking in smart contract projects is very clear. It was an openzeppelin library and then incorporated in solidity's default behavior. Bringing this to EVM level can combine both gas effiency and safety.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Starting from `BLOCK >= HARDFORK_BLOCK`

Two new flags are added to the EVM state: unsigned error (`uerr`) and signed overferror (`serr`).

From the point foward `a`, `b` and `c` references the two arguments in a math opeartion and `res` the output.

It is define two new flags `uerr` and `serr` and both start as zero.

The `uerr` flag "MUST" be set in the following circumstances:

 - When opcode is `ADD` (`0x01`) and `res < a`
 - When opcode is `SUB` (`0x03`) and `b > a`
 - When opcode is `MUL` (`0x02`) and `res / a != b`
 - When opcode is `DIV` (`0x04`) or `MOD` (`0x06`); and `b == 0`
 - When opcode is `ADDMOD` (`0x08`) and `c == 0 ∨ ((a + b) / (2 ** 256) > c)`
 - When opcode is `MULMOD` (`0x08`) and `c == 0 ∨ ((a * b) / (2 ** 256) > c)`
 - When opcode is `EXP` (`0x0A`) and ideal `a ** b > 2 **256`
 - When opcode is `SHL` (`0x1b`) and `res >> b != a`

The `serr` flag is "MUST" set in the following circumstances:

 - When opcode is `ADD` (`0x01`) and `sgn(a) == sgn(b) ^ sgn(a) != sgn(res)` 
 - When opcode is `SUB` (`0x03`) and `sgn(a) != sgn(b) ^ sgn(b) == sgn(res)`
 - When opcode is `MUL` (`0x02`) and `(a != 0 ^ abs(res) / abs(a) != abs(b)) ∨ (a == -1 ^ b == -(2**255)) ∨ (a == -(2**255) ^ b == -1)`
 - When opcode is `SDIV` (`0x05`)  or `SMOD` (`0x06`); and `b == 0 ∨ (a == -(2**255) ^ b == -1)`

A new opcode, `ARITHERR` (arithmetic error) is added, with number `0x0c`. This opcode takes 0 arguments from the stack. When executed, it pushes `2 * serr + err` and sets both flags to zero.

## Rationale

EVM uses two's complement for negative numbers. The opcodes listed above triggers one or two flags depending if they are used for signed and unsigned numbers.

The test for each opcode is made with implementation friendlyness in mind. The only exception is EXP as it is hard to give a concise test as most of the others relyed on the inverse operation and there is no native LOG

The flag being carryed to the stack is to make it possible to give control to the code implementation on how it will be utilized. It may perform an exceptional halting or any other behavior of it's choosing.

Using one operation for both flags is to save using two operations.

## Backwards Compatibility

This EIP introduces a new opcode and changes int EVM behavior. It requires to be included in a hard fork.

## Test Cases

TBD

## Reference Implementation

TBD

## Security Considerations

This is a new EVM beahavior but each code will decide how to interact with it.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
