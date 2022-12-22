---
eip: <to be assigned>
title: EOF - JUMPF instruction
description: Introduces instruction for chaining function calls.
author: Andrei Maiboroda (@gumb0), Alex Beregszaszi (@axic), Paweł Bylica (@chfast), Matt Garnett (@lightclient)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2022-12-21
requires: 4750, 5450
---

## Abstract

Allow tail call optimizations in [EOF functions](./eip-4750.md) by introducing a new instruction `JUMPF`, which jumps to a code sections without adding a new return stack frame.

## Motivation

It is common for function to make a call at the end of the routine only to then return. `JUMPF` optimizes this behavior by changing code sections without needing to update the return stack.

## Specification

a new instruction `JUMPF (0xb2)` is introduced.

### Execution Semantics
1. Has one immediate argument, `code_section_index`, encoded as a 16-bit unsigned big-endian value.
2. If data stack size exceeds `1024 - type[code_section_index].max_stack_height` (i.e. if the called function may exceed the global stack height limit), execution results in exceptional halt. This also guarantees that the stack height after the call is within the limits.
3. Charges 5 gas.
4. Pops nothing and pushes nothing to data stack.

### Code Validation
Let the definition of `type[i]` be inherited from [EIP-4750](./eip-4750.md) and define `stack_height` to be the height of the stack at a certain instruction during the instruction flow traversal if the data stack at the start of the function were equal to `type[i].inputs`.
* Immediate argument of `JUMPF` MUST be greater than or equal to the total number of code sections.
* Stack height at `JUMPF` MUST be greater than or equal to `type[code_section_index].inputs`.
* `type[current_section_index].outputs` MUST equal `stack_height - type[code_section_index].inputs + type[code_section_index].outputs`. This means that `code_section_index` can output less stack elements than the original code section called by the top element on the return stack if the `current_section_index` code section leaves the delta `type[current_section_index] - type[code_section_index]` element(s) on the stack.
* Extend [EIP-4200](./eip-4200) code validation to fail if any `RJUMP*` offset points to one of the two bytes directly following a `JUMPF` instruction.

## Rationale

### Allowing `JUMPF` to section with less outputs

As long as `JUMPF` prepares the delta `type[current_section_index] - type[code_section_index]` stack elements before changing code sections, it is possible to jump to a section with less outputs than was originally entered via `CALLF`. This will reduce duplicated code as it will allow compilers more flexibility during code generation such that certain helpers can be used generically by functions, regardless of their output values.

## Backwards Compatibility

This change is backward compatible as EOF does not allow undefined instructions to be used or deployed, meaning no contracts will be affected.

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
