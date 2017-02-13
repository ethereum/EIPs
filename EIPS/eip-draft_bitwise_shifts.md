## Preamble

    EIP: <to be assigned>
    Title: Bitwise shifting instructions in EVM
    Author: Alex Beregszaszi, Paweł Bylica
    Type: Standard Track
    Category Core
    Status: Draft
    Created: 2017-02-13


## Simple Summary

To provide native bitwise shifting with cost on par with other arithmetic operations.

## Abstract

Native bitwise shifting instructions are introduced, which are more efficient processing wise on the host and are cheaper to user by a contract.

## Motivation

EVM is lacking bitwise shifting operators, but supports other logical and arithmetic operators. Shift operations can be implemented via arithmetic operators, but that has a higher cost and requires more processing time from the host. Implementing `SHL` and `SHR` using arithmetics cost each 35 gas, while the proposed instructions take 3 gas.

## Specification

The following instructions are introduced:

### `0x1b`: `SHL` (shift left)

The `SHL` instruction (shift left) pops 2 values from the stack, `arg1` and `arg2`, and pushes on the stack the second popped value `arg2` shifted to the left by the number of bits in the first popped value `arg1`. The result is equal to

```
(arg2 * 2^arg1) mod 2^256
```

Notes:
- If the shift amount is greater or equal 256 the result is 0.

### `0x1c`: `SHR` (logical shift right)

The `SHR` instruction (logical shift right) pops 2 values from the stack, `arg1` and `arg2`, and pushes on the stack the second popped value `arg2` shifted to the right by the number of bits in the first popped value `arg1` with zero fill. The result is equal to

```
arg2 udiv 2^arg1
```

Notes:
- If the shift amount is greater or equal 256 the result is 0.

### `0x1d`: `SAR` (arithmetic shift right)

The `SAR` instruction (arithmetic shift right) pops 2 values from the stack, `arg1` and `arg2`, and pushes on the stack the second popped value `arg2` shifted to the right by the number of bits in the first popped value `arg1` with sign extension. The result is equal to

```
arg2 sdiv 2^arg1
```

Notes:
- `arg1` is interpreted as unsigned number.
- If the shift amount is greater or equal 256 the result is 0 if `arg2` is non-negative or -1 if `arg2` is negative.

### `0x1e`: `ROL` (rotate left)

The `ROL` instruction (rotate left) pops 2 values from the stack, `arg1` and `arg2`, and pushes on the stack the second popped value `arg2` circular shifted to the left by the number of bits in the first popped value `arg1`.

```
(arg1 shl arg2) or (arg1 shr (256 - arg2)
```

Notes:
- `arg2 rol arg1` is equivalent of `arg2 rol (arg1 mod 2^256)`

### `0x1f`: `ROR` (rotate right)

The `ROL` instruction (rotate right) pops 2 values from the stack, `arg1` and `arg2`, and pushes on the stack the second popped value `arg2` circular shifted to the right by the number of bits in the first popped value `arg1`.

```
(arg1 shr arg2) or (arg1 shl (256 - arg2)
```

Notes:
- `arg2 ror arg1` is equivalent of `arg2 ror (arg1 mod 2^256)`

The cost of the shift instructions is set at `verylow` tier (3 gas), while the rotations are 12 gas each.

## Rationale

Instruction operands were chosen to match the other logical and arithmetic instructions.

## Backwards Compatibility

The newly introduced instructions have no effect on bytecode created in the past.

## Test Cases

TBA

## Implementation

Client support:
TBA

Compiler support:
- Solidity: https://github.com/ethereum/solidity/tree/asm-bitshift

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
