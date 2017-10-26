```
EIP: <to be assigned>
Title: SIMD Operations for the EVM
Author: Greg Colvin, greg@colvin.org
Type: Standard Track
Category: Core
Status: Draft
Created: 2017-04-25
```

## ABSTRACT

A proposal to provide Single Instruction Multiple Data types and operations for the Ethereum Virtual Machine, making full use of the 256-bit wide EVM stack items, and offering substantial performance gains for both vector and scalar operations.

## MOTIVATION

Most all modern CPUs include SIMD hardware that operates on wide registers of data, applying a Single Instruction to Multiple Data lanes in parallel, where lanes divide a register into a vector of scalar elements of equal size.  This model is an excellent fit for the wide stack items of the EVM, offering substantial performance boosts for operations that can be expressed as parallel operations on vectors of scalars.  For some examples, a brief literature search finds SIMD speedups of
* up to 7X for [SHA-512](http://keccak.noekeon.org/sw_performance.html)
* 4X for [elliptic curve scalar multiplication](http://link.springer.com/chapter/10.1007/3-540-45439-X_16)
* 3X to 4X for [BLAKE2b](http://github.com/minio/blake2b-simd)
* up to 3X for [OpenSSL](https://software.intel.com/en-us/articles/improving-openssl-performance)
* 2X to 3X for [elliptic curve modular multiplication](http://ieee-hpec.org/2013/index_htm_files/24-Simd-acceleration-Pabbuleti-2886999.pdf)
* 1.7X to 1.9X for [SHA-256](https://github.com/minio/sha256-simd)
* 1.3X for [RSA encryption](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.738.1218&rep=rep1&type=pdf)

## SPECIFICATION

### Encoding

We propose a simple encoding of SIMD operations as extended two-byte codes.  The first byte is the opcode, and the second byte is the SIMD type: scalar type, lane width, and number of elements. 

 N bits | Field
-|-
8 | opcode
1 | scalar type: 0 = unsigned integer, 1 = IEEE float
1 | reserved: 0
2 | lane width: log base 2 of the number of bytes, as an MSB first integer
1 | reserved: 0
3 | element count: log base 2 of the number of lanes, as an MSB first integer

Thus we can specify SIMD types with unsigned integer lanes from 8 to 64 bits in vectors of 32 to 2 lanes, respectively.  Floating point lanes however support only 32- and 64-bit IEEE floating point.  And a type of _0x7F_ represents a normal 256-bit EVM integer.

_Note that when the element count is one the operation is on one scalar, so this specification also provides for native operations on single scalars of native sizes._

_Note that floating point operations are **not** proposed for inclusion in the initial release, but we considered it important to reserve code space for possible future expansion._

### Semantics

We define the following extended versions of the EVM's arithmetic, logic, and comparison operations.  As with the normal versions, they consume their arguments from the stack and place their results on the stack, except that their arguments are vectors rather than scalars. 

lo\hi |	B             | C
-|-|-
0|                     | XLT
1| XADD           | XGT
2| XMUL          | XSLT
3| XSUB           | XSGT
4| XDIV            | XEQ
5| XSDIV          | XISZERO
6| XMOD          | XAND
7| XSMOD        | XOR
8|                      | XXOR
9|                       | XNOT
A|                       | XINDEX
B|                       | XSHL
C|                       | XSHR
D|                       | XSAR
E| XCAST           | XROL
F| XSHUFFLE      | XROR

Except for XSHUFFLE, XCAST, and XINDEX all the extended operations on unsigned integer values have the same semantics as the corresponding operations for codes 01 through 1F, except that the modulus varies by scalar type and the operations are applied pair-wise to the elements of the source operands to compute the destination elements.  _The source operands must have the same element type and number of elements._  E.g.
```
PUSH uint8[1, 2, 3]
PUSH uint8[4, 5, 6]
XADD
```
leaves
```
uint8[5, 7, 9]
```
on the stack.

XSHUFFLE takes two vectors on the stack: a vector to permute and a permutation mask.  E.g. 
```
PUSH uint64[4, 5, 6, 0]
PUSH uint8[2, 0, 1, 3]
SHUFFLE
```
leaves 
```
uint64[6, 4, 5 , 0]
```
on the stack. The mask must have integral type, and the same number of elements as the source vector.

The second byte of the XCAST opcode is applied to the item on the stack to create a new vector of the specified type.  Elements are converted according to the usual C conventions, missing elements are set to zero, and extra elements are discarded.  If the stack item is not a vector it is converted to a vector by taking its bits least-significant-bit first and copying them into the corresponding bits of each element, least-significant-element first.  Again, excess data is truncated and missing data is 0-filled.  Vectors are converted to 256-bit EVM integers via the reverse process., with elements that are floating point NANs normalized to all bits on.

_Note that MLOAD and MSTORE are valid only on 256-bit EVM integers.  For SIMD vectors an XCAST is needed after a load and before a store to convert vectors to and from 256-bit integers._

XINDEX has the same semantics as BYTE, except that individual elements of the vector are indexed.

Floating point values follow IEEE 754 semantics.  Since those are not defined for shifting and rotating those operations are defined here as having no effect.

Extended operations other than XSHUFFLE and XCAST are only valid on vectors of the same SIMD type.  This can be validated at contract creation time, or else checked at runtime.

### Subroutines

If [EIP 187](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-187.md) is accepted a typpe-safe syntax for declaring subroutines taking vector arguments will be needed.

* `BEGINSUBX n_args, arg_types... n_results, result_types...`
marks the **single** entry to a subroutine.  `n_args` items are taken off of the stack at entry to, and `n_results` items are placed on the stack at return from the subroutine. `n_args` and `n_results` are given as one immediate byte each.  The `arg_types` and `result_types` are given in the same encoding as second byte of the SIMD opcodes, and must match the values on the stack.  The bytecode for a subroutine ends at the next `BEGINSUB`, `BEGINSUBX` or `BEGINDATA` instruction or at the end of the bytecode.

## RATIONALE

Currently, the lowest common denominator for SIMD hardware (e.g. Intel SSE2 and ARM Neon) is 16-byte registers supporting integer lanes of 1, 2, 4, and 8 bytes, and floating point lanes of 4 and 8 bytes.  More recent SIMD hardware (e.g. Intel AVX) supports 32-byte registers, and EVM stack items are also 32 bytes wide.  The limits above derive from these numbers, assuring that EVM code is within the bounds of available hardware - and the reserved bits provide room for growth. 

For most modern languages (including Rust, Python, Go, Java, and C++) compilers can do a good job of generating SIMD code for parallelizable loops, and/or there are intrinsics or libraries available for explicit access to SIMD hardware.  So a portable software implementation will likely provide good use of the hardware on most platforms, and intrinsics or libraries can be used as available and needed.  Thus we can expect these operations to take about the same (or for 256-bit vectors on 128-bit hardware up to twice) the time to execute regardless of element size or number of elements.

### Gas

One motivation for these operations, besides taking full advantage of the hardware, is assigning lower gas costs for operations on smaller scalars.

On a machine with 64-bit registers the standard algorithms from Knuth's [Art of Computer Programming](http://library.aceondo.net/ebooks/Computer_Science/algorithm-the_art_of_computer_programming-knuth.pdf) require 32-bit digits, using the upper half of a register for overflows, so for 256-bit values N=8 digits are needed, and for 64-bit values N=2 digits are needed.  The cycle counts for these algorithms are:

operation | cycles | N = 2 | N = 4 | N = 8
-|-|-|-|-
add | 10 _N_ + 6 | 26 | 46 | 86
subtract | 12 _N_ + 3 |27 | 51 | 99
multiply | 28 _N_**2 + 11 _N_ + 3 | 137 | 495 |1883
divide | 30 _N_**2 + 119 _N_ + 111 | 469 | 1067 | 2983

The remaining operations are of about the same complexity as addition and subtraction, or less. Given that JUMPDEST is a no-op, and is assigned a gas price of 1, this can be taken as the overhead of the interpreter.  All of the arithmetic operations are assigned the same gas price of 5, for a remaining runtime of 4.  The interpreter loop itself takes about 6 to 8 C instructions, so ADD and SUB are reasonably priced, but MUL is some 5 to 21 times slower than ADD or SUB, and DIV is some 18 to 35 times slower, so they are clearly mispriced.

By comparison, on most [Intel](https://software.intel.com/sites/landingpage/IntrinsicsGuide) and [ARM](https://developer.arm.com/docs/100166_0001/latest/programmers-model/instruction-set-summary/table-of-processor-instructions) SIMD units instructions take approximately the following cycle counts, independent of register width.

operation | Intel cycles | ARM cycles | gas
-|-|-|-
add | .5 | 1 | 1
subtract | .5 | 1 | 1
multiply | 2 | 1 | 1
divide | 10 | 12 | 2

Since all but the divide operation take fewer cycles than the interpreter overhead they are assigned the minimal cost of 1.  Division takes slightly more, and is assigned a cost of 2.
