# EIP: XTNDR opcode family

title: XTNDR family opcode
description: Opcodespace extension via prefix, variadic opcodes and bytecode compression through macros
author: Brayton Goodall, Mihir Faujdar
type: Standards Track
category: Core
created: 2021-11-30


## Table of Contents
- [Abstract](#Abstract)
- [Motivation](#Motivation)
- [Specification](#Specification)
- [Rationale](#Rationale)
- [Backwards Compatibility](#Backwards-Compatibility)
- [Test Cases](#Test-Cases)
- [Reference Implementation](#Reference-Implementation)
- [Security Considerations](#Security-Considerations)
- [Copyright](#Copyright)

## Abstract
Introduce XTNDR, a prefix opcode to specify the bytes that immediately follow are to be interpreted as a multi-byte opcode. Additionally single-byte opcodes can have their adicity adjusted, in effect allowing in-bytecode macros for more compact functions. A portion of single-byte opcodespace is reserved for 'loading' prespecified multi-byte opcodes such that their usage is not prohibitively expensive. 


## Motivation

All EVM opcodes are single-byte, which encourages careful choice when introducing new opcodes. 
Additionally, high-level blockchain and EVM policies (such as gas prices of operations) often concern tradeoffs between data size, network requirements for propagation and ease of execution. These changes would allow a greater range of space-time tradeoffs of smart contracts, through situationally allowing smaller contract sizes which are more complex to execute. This may allow greater flexibility in high-level policies and eventually network efficiency.

## Specification

The XTNDR opcode is at 0xED. 
ED followed by a numeric value is interpreted indicates a multi-byte variadic opcode.
Two-byte sequences starting with ED and followed by a non-numeric value is to be interpreted as a single opcode from 'extended space'.


XTNDR introduces variadic opcodes (VOPs) which may be considered as a versioning of the fixed-adicity opcodes through address extension. Each opcode that has a suitable variadic extension that otherwise doesn't affect their functioning (e.g associative operations can be batched through 'joins') must have the suffix byte of it's extended version sequence identical to it's fixed-adicity address.

The extended version sequence is the sequence of bytes which specifies the operation to be performed.

Adicity is determined by the value immediately following the XTNDR opcode. Immediately after the adicity byte is the operation to be extended, after which the operands are found. 

For example the assembly for extending the greater-than operation (0x11) to a sequence of 6 numbers to check if it is a monotonically decreasing sequence: 

XTNDR 6 GT A B C D E F

This could be considered a compact equivalent to:

GT A B AND
GT B C AND 
GT C D AND
GT D E AND
GT E F


[JUMPs, SUBs, etc: differences with 2315]


## Rationale




Opcode address rational:
The E-series of opcodes is currently empty aside from 0xEF, which may be interpreted as standing for 'Ethereum (Object) Format'. The EE opcode is preferably reserved for future usages pertaining to 'Execution Environment'. 
The choice of EA could be interpreted as 'Extended Address'.
The 'macro memory' is preferred to be a contiguous portion of address (opcode) space, however this is not itself necessary.

## Backwards Compatibility

## Test Cases

## Reference Implementation

## Security Considerations

## Copyright

###### tags: `EIP`
