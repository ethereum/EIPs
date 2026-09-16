---
eip: 7961
title: EVM64 - EOF code section
description: Define "pure" EVM64 mode, as an EOF code section.
author: Wei Tang (@sorpaas)
discussions-to: https://ethereum-magicians.org/t/eip-series-evm64/23794
status: Draft
type: Standards Track
category: Core
created: 2025-05-28
requires: 3540, 4750, 7960
---

## Abstract

An EOF-only specification for EVM64 instruction set. This defines a separate "EVM64" type for EOF code section in addition to "regular EVM". The interpreter then enters EVM64 mode when entering the code section. This EIP is an alternative to [EIP-7937](./eip-7937.md).

## Motivation

EIP-7937 has maximum compatibility with existing EVM. It implements EVM64 simply as a group of additional opcodes (using a prefix opcode). This EIP defines an alternative method, using EOF container's code section. It has its pros and cons. The code size will obviously become shorter, due to not needing multibyte opcodes any more. On the other hand, interop with EVM system calls become more difficult because it cannot be done in an EVM64 code section. The advantages and disadvantages are discussed further in the Rationale section.

## Specification

Define `0x02` as an allowed `type` in `types_section`, as defined in EIP-7960. This denotes an EVM64 code section.

### EOF function execution

When entering an EOF code section (either at the beginning of the contract call, or through `CALLF`), it enters "pure EVM64 mode". Unless defined below, no other opcodes are allowed. Those opcodes all only operate on the least significant 64-bit, in little endian.

During EOF validation, the validation function should enforce that only allowed opcodes exist.

### Gas cost constants

We define the following gas cost constants:

* `G_BASE64`: 1
* `G_VERYLOW64`: 2
* `G_LOW64`: 3
* `G_MID64`: 5
* `G_HIGH64`: 7
* `G_EXP64_STATIC`: 5
* `G_EXP64_DYNAMIC`: 25
* `G_RJUMPIV64`: 3

### Arithmetic opcodes

The 64-bit mode arithmetic opcodes are defined the same as non-64-bit mode, except that they only operate on the least significant 64-bits. In the below definition, `a`, `b`, `N` is `a mod 2^64`, `b mod 2^64` and `N mod 2^64`.

* ADD (`01`) and SUB (`03`): `a op b mod 2^64`, gas cost `G_VERYLOW64`.
* MUL (`02`), DIV (`04`), SDIV (`05`), MOD (`06`), SMOD (`07`), SIGNEXTEND (`0B`): `a op b mod 2^64`, gas cost `G_LOW64`.
* ADDMOD (`08`), MULMOD (`09`): `a op b % N mod 2^64`, gas cost `G_MID64`.
* EXP (`0A`): `a EXP b mod 2^64`, gas cost `static_gas = G_EXP64_STATIC, dynamic_gas = G_EXP64_DYNAMIC * exponent_byte_size`.

### Comparison and bitwise opcodes

The 64-bit mode comparison and bitwise opcodes are defined the same as non-64-bit mode, except that they only operate on the least significant 64 bits.

* LT (`10`), GT (`11`), SLT (`12`), SGT (`13`), EQ (`14`), AND (`16`), OR (`17`), XOR (`18`): `a op b mod 2^64`, gas cost `G_VERYLOW64`
* ISZERO (`15`), NOT (`19`): `op a mod 2^64`, gas cost `G_VERYLOW64`
* SHL (`1B`), SHR (`1C`), SAR (`1D`): `a op N mod 2^64`, gas cost `G_VERYLOW64`
* BYTE (`1A`) is defined as `(x >> i * 8) & 0xFF`. Note that the definition is changed from big endian to little endian.

### Memory opcodes

`MLOAD64` (0x51) will load a 64-bits integer in little endian onto the stack. `MSTORE64` (0x52) will read an 64-bits integer from the stack, and store it to memory in little endian.

The gas cost for both opcodes is `G_VERYLOW64`. The memory resizing costs count as 8 bytes.

`MSTORE8` is available in EVM64 mode, and its gas cost is the same as in "normal" EVM.

### Stack opcodes

`PUSH0` (0x5f) to `PUSH8` (0x67) follows 0-byte to 8-byte literal. The literal is read little endian and pushed onto the stack. The gas cost for them is `G_VERYLOW64`.

`POP`, `SWAPn` and `DUPn` are available in EVM64 mode, and their gas costs are the same as in "normal" EVM.

### Other opcodes

Contract opcodes `RETURN`, `REVERT`, `INVALID` are available in EVM64 mode. Their behaviors, including gas costs, are unchanged. However, for all stack items, only the least significant 64 bits are read.

`CALLF`, `RETF`, `RJUMP` are available in EVM64 mode. Their behaviors, including gas costs, are unchanged.

For flow operations RJUMPI and RJUMPV, the 64-bit mode has following changes:

* For `RJUMPI64` (0xe1), the condition popped from stack is only read for the last 64 bits. Gas cost is `G_RJUMPIV64`.
* For `RJUMPV64` (0xe2), the case popped from stack is only read for the last 64 bits. Gas cost is `G_RJUMPIV64`.

## Rationale

### Stack behavior

"Pure" in "pure EVM64" refers to the fact that all opcodes in EVM64 mode only operate on the least significant 64 bits. In this specification, we don't specifically define 64-bit stack. As far as this EIP is concerned, stack is still 256-bit. However, because they only operate on the least significant 64 bits. The most significant 192 bits becomes unobservable as long as the interpreter is in an EVM64 code section. Thus an EVM interpreter can optimize EVM64 execution as follows:

* When entering EVM64 code section, truncate `inputs` to 64 bits.
* Use 64-bit stack during EVM64 execution.
* When exiting EVM64 code section, prepend `0` to `outputs` to make it 256 bits.

### Discussions

This alternative definition (compared with EIP-7937) has the advantage that the code size is now shorter (because no multibyte opcodes are needed). It however will only work with EOF contract but not "legacy" EVM. The interaction between EVM64 and "system calls" (those calls that read Ethereum block values, addresses, balances and storages) will be more difficult. It's not "seamless" like EIP-7937 where one can enter/exit 64-bit mode at ease. Depending on how the 64-bit optimization works out, this may be an advantage or a disadvantage.

The memory is, as usual, still shared during the entire execution. So in EVM64, the contract can always use the memory to push/fetch data.

## Backwards Compatibility

No backward compatibility issues found.

<!-- TODO: Add test cases and reference implementation -->

## Security Considerations

Needs discussion. <!-- TODO -->

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
