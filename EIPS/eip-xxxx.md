---
eip:
title: EVM Modular Arithmetic Extensions
description: Expanded-width modular arithmetic operations for the EVM
author(s):
discussions-to:
status: Draft
type: Standards Track
category: Core
created: 2024-10-07
requires:
---

## Abstract

This EIP proposes new EVM modular arithmetic opcodes which support operations on odd or power-of-two moduli between 3 and 2**768-1

## Motivation

## Specification

### Constants
| Name | Value | Description |
| ---- | ---- | ---- |
| `COST_SETMODX_BASE` | 1 | Base cost for the `SETMODX` opcode |

### Conventions

1. The use of `assert` implies that if the assertion fails, the current call frame will consume all call gas and terminate call execution in an exceptional state.
2. Unless otherwise stated, sizes are specified in number of bytes.

### Overview

The execution state of an EVM call frame is modified to include a mapping of `id` (a number 0-256) to "field context".  A field context comprises a modulus and an allocated space of virtual registers to perform operations on.

An executing contract uses a new instruction `SETMODX` to set the active field context, allocating a new one in the mapping if it does not already exist for `id`.

New arithmetic opcodes perform modular addition, subtraction and multiplication with inputs/outputs from virtual registers of the active field context.

New load/store opcodes copy values to and from EVM memory and the value space of the active field context.

### New Opcodes

#### `SETMODX(0xc0)`

**Input**: `<top of stack> id modulus_offset modulus_size alloc_count`.

**Output**: none

#### Execution

Assume `cost_setmodx_precompute_odd(modulus) -> int` is defined.

Charge `COST_SETMODX_BASE`.
Assert `0 <= id <= 256`.

If a field context for `id` exists in this call scope:
* Set it as the active one.

Otherwise:

* Assert `modulus_size <= 96`.
* Assert that the byte range`[modulus_offset, modulus_offset+modulus_size]` falls within EVM memory.
* Load the byte range from EVM memory, interpreting it as a big endian `modulus`.
* Assert `modulus` is odd or is a power of two.
* Assert `3 <= modulus <= 2**768 - 1`.
* Assert `0 < alloc_count <= 256`.
* Define the size of elements stored in virtual registers: `element_size` as the size needed to represent the modulus padded to be a multiple of 8 bytes.  Implementations will align individual virtual register values along system-word lines (mostly/all 64 bit).
* assert that the new size of all virtual registers allocated in the current call-context does not exceed 25 kilobytes.
* Charge EVM memory expansion cost to expand memory by `alloc_count * element_size` bytes:.
* if the modulus is odd:
    * charge `cost_setmodx_precompute_odd(modulus)`, which charges a constant value based on the size of the modulus.  See the rationale section for some explanation of why this is needed.
* Allocate the new field context with `alloc_count` initially-zeroed registers. Associate it with `id` in the mapping.
* The new field context is set as active.

#### Arithmetic Opcodes

Opcodes `ADDMODX(0xc3)`, `SUBMODX(0xc4)`, `MULMODX(0xc5)` take a 7 byte immediate interpreted as byte values `out_idx`, `out_stride`, `x_idx`, `x_stride`, `y_idx`, `y_stride`, `count`.

Assume, `arith_op_cost(op: string, modulus: int, count: int) -> int` is defined (TBD: see rationale).

Execution asserts:
* all accessed values fall within bounds: `max([out_idx + (out_stride * count), x_idx + (x_stride * count), y_idx + (y_stride * count)]) < len(field_context.registers)`
* `out_stride != 0`
* `count != 0`
* an active field context `active_ctx` is set.

Then, charge `arith_op_cost(op_name, active_ctx.modulus, count)` and compute:
```
for i in range(count):
    active_ctx.registers[out_idx+i*out_stride] = op(active_ctx.registers[x_idx+i*x_stride], active_ctx.registers[y_idx+i*y_stride])
```

Where `op` computes modular addition, subtraction or multiplication.

Note: Inputs/outputs can overlap. `active_ctx.registers` is not modified until all operations in the loop have completed.

--- 

### Data Transfer Opcodes

Note: serialization format for values in EVM memory: big-endian padded to `active_ctx.element_size` bytes.

#### `LOADX(0xc1)`

**Stack in**: `(top of stack) dest source count`

**Stack out**: none

**Description**: copies values from registers in the currently-active field context to EVM memory.

##### Execution

* Assert that a field context is set as active in the current call frame.
* Assert that the range `[source, source + count]` falls within the active field context value space.
* Assert that the range `[dest, dest + count * active_ctx.element_size]` falls entirely within EVM memory.
* If modulus is a power of two:
    * charge `cost_mem_copy(count * active_ctx.element_size)` (TBD: deliberately didn't choose `mcopy` gas model to see if this can consider a cheaper one).
* If modulus is odd:
    * charge gas `arith_op_cost("MULMODX", active_ctx.modulus, count)`.  This accounts for the conversion of elements in the range from Montgomery to canonical form.  See the section in the appendix for more details.
* copy register values `[source, source + count]` to memory `[dest, dest + count * active_ctx.element_size]`.

#### `STOREX(0xc2)`

**Stack in**: `dest source count`

**Stack out**: none

**Description**: copies values from EVM memory into registers of the currently-active field context.

##### Execution

* Assert that a field context is set as active in the current call frame.
* Assert `dest + count` is less than or equal to the number of the active field context's registers.
* Assert that `[source, source + count * active_context.element_size]` falls entirely within EVM memory.  Interpret it as `count` number of values, asserting that each is less than the modulus and storing them in the registers `[dest, dest + count]`.

### EVM Memory Expansion Cost Modification

When expanding EVM memory, expansion cost will now consider the size of all allocated virtual registers in the current call frame.

## Rationale
### Separation of EVM Memory and Virtual Register Space

This allows optimized implementation/platform-specific value representations to be used without making them observable to the EVM.  An example is Montgomery representation which enables optimized modular multiplication over odd moduli.

### Total Virtual Register Allocation Cap

25kb is chosen as a tentative limit with the goal of ensuring that the virtual register space can be contained in the L1 CPU data cache of most machines (with room to spare), in order that arithmetic operation costs do not have to account for memory access latency.

### Spec TODOs

#### `arith_op_cost`

Previous spec iterations have proposed cost models for modular add/sub/mul and `SETMODX` for odd moduli.  For even moduli, the implementation and reasoning about costs should be much more simple.

The modification of adapting the arithmetic opcodes to support vector arguments opens the way for exploration of optimization via concurrency/SIMD as a next step for completion of this spec.

#### `cost_setmodx_precompute_odd`

For odd moduli, the spec assumes clients will use Montgomery modular multiplication algorithm for optimization.  This requires precomputing two values specific to the chosen modulus:
1. a system-word-sized constant used in the modular multiplication algorithm.  Most performant algorithms use `mont_const = pow(-mod, -1, 2**SYSTEM_WORD_SIZE_BITS)`.
2. a bigint value used for conversion from canonical to Montgomery form.  most commonly-used value is `R**2 % mod` where `R` is a value larger than modulus and a power of two.

The first value can be computed in constant-time regardless of the modulus size, while the second can be computed with a modular reduction.  It is assumed that the worst-case inputs have a linear cost model.

#### Padding for small modulus width

If modulus width is smaller than 64 bits, is it wasteful to assume that values occupy 64 bits of memory (for the purposes of the memory expansion function, `LOADX`, `STOREX`)?

## Test Cases

## Security Considerations

## Appendix

### Montgomery Modular Multiplication

For a value `A`, an odd modulus `M` and a value `R` (must be coprime and greater than `M`, chosen as a power of two for efficient performance), the Montgomery representation is `A * R % M`.

Define the Montgomery modular multiplication of two values `A` and `B`: `mulmont(A, B, M): A * B * R**-1 % M` where `R**-1 % M` is the modular inverse of `R` with respect to `M`.  There is various literature and algorithms for computing `mulmont` which have been published since 1985, and the operation is used ubiquitously where execution is bottlenecked by operations over odd moduli.

Note that normal modular addition and subtraction algorithms work for Montgomery form values.

##### Conversion of Canonical to Montgomery Representation

`mulmont(canon_val, R**2 % M, M) = mont_val`

##### Conversion from Montgomery to Canonical representation

`mulmont(mont_val, 1, M) = canon_val`

#### Implementation

```
# Basic Montgomery Multiplication
#   x, y, mod (int) - x < mod and y < mod
#   mod (int) - an odd modulus
#   R (int) -  a power of two, and greater than mod
#   mont_const (int) - pow(-mod, -1, R), precomputed
# output:
#  (x * y * pow(R, -1, mod)) % mod
#
def mulmont(x: int, y: int, mod: int, monst_const: int, R: int) -> int:
    t = x * y
    m = ((t % R) * mont_const) % R
    t = t + m * mod
    t /= R
    if t >= mod:
        t -= mod
    return t
```

There are various optimized algorithms for computing Montgomery Multiplication of bigint numbers expressed as arrays of system words.

These all use a different precomputed constant `mont_const = pow(-mod, -1, 2**SYSTEM_WORD_SIZE_BITS)`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
