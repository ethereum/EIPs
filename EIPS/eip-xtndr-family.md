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
Additionally, high-level blockchain and EVM policies (such as gas prices of operations) often concern tradeoffs between data size, network requirements for propagation and ease of execution. These changes would allow a greater range of space-time tradeoffs of smart contracts, through situationally allowing smaller contract sizes which are more complex to execute. This may allow greater flexibility in high-level policies and eventually network efficiency. An additional factor is to slightly increase the memory burden of the EVM in exchange for reduced storage requirements and disk wear.

This method aims to provide three features in such a way that they may be cohesively applied for maximal elegance, ease of implementation and ultimately efficiency of the protocol as a fundamental infrastructure layer which others build upon. The first and simplest feature is the declaration of prefix bytes to reserve sequences for future multi-byte opcodes.

The second of these three features is the introduction of variadic opcodes through two bytes preceeding a more conventional operation, in order to allow smaller bytecode footprints of highly structured repeated operations.

The third feature is a bytecode compression technique which substitutes multi-byte sequences (of the other two features) for specific single bytes previously declared within a contract, effectively holding a sequence of instructions in it's own memory. 

## Specification

The XTNDR opcode is found at 0xED. 

A sequence beginning with XTNDR is to signify a multi-byte opcode or otherwise an 'extended' operation. For example two-byte sequences starting with ED and followed by a non-numeric value is to be interpreted as a single opcode from 'extended space'.

A numeric value in-between ED (preceeding the numeric value) and a conventional opcode (which follows the numeric value) indicates a single multi-byte operation which is to be considered as a variadic version of the final opcode in the multi-byte sequence. The numeric value specifies the amount of operands that the conventional opcode is to operate over.

XTNDR introduces variadic opcodes (VOPs) which may be considered as a versioning of the fixed-adicity opcodes through address extension. Each opcode that has a suitable variadic extension that otherwise doesn't affect their functioning (e.g associative operations can be batched through 'joins') must have the suffix byte of it's extended version sequence identical to it's fixed-adicity address.

The extended version sequence is the sequence of bytes which specifies the operation to be performed.

Adicity is determined by the value immediately following the XTNDR opcode. Immediately after the adicity byte is the operation to be extended, which is followed by the operands. In some circumstances an operand may be 'fixed' and the adicity of the extended operation is reduced. This is similar to the notion of currying, or reducing a multivariate function to one of lower variety through fixing a variable as a constant.

An example of a variadic arithmetic sequence would be:

XTNDR 11 ADD 4 17 8 10 66 9 2 2 7 1 3 2

which performs addition over 11 values (in the usual order as if pairwise evaluated in sequential order), equivalent to 4 + 17 + 8 + 10 + 66 + 9 + 2 + 2 + 7 + 1 + 3 + 2. This returns a value of 131. 

This may be applied to a logical operation over more operands than currently supported. An example of the assembly for extending the greater-than operation (0x11) to a sequence of 6 numbers to check if it is a monotonically decreasing sequence is:

XTNDR 6 GT A B C D E F

This could be considered a compact equivalent to:

GT A B AND
GT B C AND 
GT C D AND
GT D E AND
GT E F

Any 'extended sequence' cannot contain JUMPs or stack manipulation opcodes, with the exception of potential usages to implement EIP-663.

## Rationale

Opcode address rational:
The E-series of opcodes is currently empty aside from 0xEF, which may be interpreted as standing for 'Ethereum (Object) Format'. The EE opcode is preferably reserved for future usages pertaining to 'Execution Environment'. 
The choice of EA could be interpreted as 'Extended Address'.
The 'macro memory' is preferred to be a contiguous portion of address (opcode) space, however this is not itself necessary.

Greatly increasing the amount of opcode space available will substantially reduce the consequences of adding niche, application-specific opcodes or those which are of speculative value. This may eventually allow replacing precompiles with multi-byte opcodes if this proves more efficient, or allowing parts of already implemented precompiles to be represented as multi-byte opcodes to allow for more modular cryptographic techniques.

This method is in some respects simpler than other proposals for improving the 'bytecode density' of the EVM ISA, whilst also being broadly compatible with those other proposals. 

Additionally, as gas accounting imposes a non-negligible overhead during execution, storing the gas costs of particular predictable sequences in their own (exclusive) area of memory may be more efficient.

## Backwards Compatibility

## Test Cases

## Reference Implementation

## Security Considerations

Due to the significant changes made to execution, the likelihood of mispricing small sequences of bytecode which require heavy operations ("EVM bombs") is high if not approached carefully. There are several methods of implementation, some of which may be considerably safer (in terms of memory requires and principally time of execution). 

These changes may have intense interactions with EIP-615 and EIP-2315, among others.

## Copyright

###### tags: `EIP`
