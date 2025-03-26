---
eip: TBD
title: Skip `JUMPDEST` immediate argument check
status: Draft
type: Standards Track
category: Core
author: William Morriss <wjmelements@gmail.com>
created: 2025-03-26
---

## Abstract

Allow `JUMP` and `JUMPI` to arrive at any byte matching `JUMPDEST` (`0x5b`), even if that byte is an immediate argument.

## Motivation

Immediate arguments are opcode parameters supplied within the code rather than the stack.
Currently determining the validity of a `JUMPDEST` requires determining which bytes are immediate arguments to other opcodes, such as `PUSH1`.
This presents several problems:

1. Codesize is a linear DoS vector because code must be preprocessed to determine `JUMPDEST` validity.
2. New opcodes with immediate arguments cannot be safely adopted.

The rationale for this `JUMPDEST` validity check is to prevent unintended code execution.
However, almost all `JUMP` and `JUMPI` target constant destinations.
Removing this check allows larger programs and better opcodes.
Therefore, the cost of this safety check outweighs the benefit.

## Specification

When activated, all `0x5b` bytes are valid `JUMPDEST` for `JUMPI` and `JUMP` opcodes.

## Rationale

Removing the check solves several problems while reducing EVM complexity.

## Backwards Compatibility

Contracts utilizing

## Security Considerations

Current contracts performing dynamic jumps may gain new unintended functionality if it is possible to jump to an immediate argument containing `JUMPDEST`.
It is expected that very few contracts will become vulnerable in this way.
Most smart contract programming languages do not even allow dynamic jumps, so few contracts will become vulnerable, and for many of them the newly possible codepaths will be invalid.
A static analysis tool should be developed and made publicly available to test if a contract might become vulnerable, and the program should be run for all current contracts in order to notify projects about potential security issues.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
