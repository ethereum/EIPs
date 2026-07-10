---
eip: 7823
title: Set upper bounds for MODEXP
description: Each input field is restricted to a maximum of 8192 bits
author: Alex Beregszaszi (@axic), Radoslaw Zagorowicz (@rodiazet)
discussions-to: https://ethereum-magicians.org/t/eip-7823-set-upper-bounds-for-modexp/21798
status: Final
type: Standards Track
category: Core
created: 2024-11-11
requires: 198
---

## Abstract

Introduce an upper bound on the inputs of the MODEXP precompile. This can reduce the number of potential bugs, because the testing surface is not infinite anymore, and makes it easier to be replaced using EVMMAX.

## Motivation

The MODEXP precompile has been a source of numerous consensus bugs. Many of them were due to specifically crafted cases using impractical input lengths.

Its pricing function is also quite complex given its nature of unbounded inputs. While we don't suggest to rework the pricing function, it may be possible in a future upgrade once the limits are in place.

Furthermore this limitation makes it more feasible to have the precompile replaced with EVM code through features like EVMMAX.

## Specification

Recap from [EIP-198](./eip-198.md):
> At address `0x00……05`, add a precompile that expects input in the following format:
> 
> `<length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>`

We introduce an upper bound to the inputs of the precompile, each of the length inputs (`length_of_BASE`, `length_of_EXPONENT` and `length_of_MODULUS`) MUST be less than or equal to 8192 bits (1024 bytes).

If any of these inputs are larger than the limit, the precompile execution stops, returns an error, and consumes all gas.
    
## Rationale

### Limit

This upper bound allows the existing use cases of MODEXP:

1. RSA verification with up to 8192 bit keys. Commonly used ones are 1024/2048/4096 bits.
2. Elliptic curve related use cases are usually less than 384 bits.

### EVMMAX

Replacing the precompile with EVM code using an instruction set like EVMMAX would be made simpler with this limit: Common cases (256, 381, 1024, 2048) could be implemented in special fast paths, while a slow fallback could be provided for the rest. Or even special, frequently used, moduli could have their own paths.

Furthermore one could consider limiting the lengths to certain inputs only.

### Analysis

Since MODEXP was introduced in the Byzantium hard fork, an analysis has been conducted between block 5472266 (April 20, 2018) and block 21550926 (January 4th, 2025). All lengths of inputs are expressed in bytes.

#### Base length occurrences

| `input_of_BASE` | count |
|-----------------|-------|
| 32	| 2439595 |
| 128	| 4167 |
| 256	| 2969 |
| 160	| 436 |
| 512	| 36 |
| 0	| 13 |
| 64	| 7 |
| 78	| 2 |
| 513	| 2 |
| 129	| 1 |
| 385	| 1 |

#### Exponent length occurrences

| `input_of_EXPONENT` | count |
|---------------------|-------|
| 32	| 2442255 |
| 3	| 4771 |
| 1	| 159 |
| 128	| 29 |
| 0	| 13 |
| 5	| 2 |

#### Modulo length occurrences

| `input_of_MODULUS` | count |
|--------------------|-------|
| 32	| 2439594 |
| 128	| 4167 |
| 256	| 2968 |
| 160	| 436 |
| 512	| 38 |
| 0	| 13 |
| 64	| 8 |
| 78	| 2 |
| 129	| 1 |
| 384	| 1 |
| 257	| 1 |

This shows that no past successful use case exceeded an input length of 513 bytes, and the majority uses 32/128/256 byte inputs.

Besides these, there were a few invocations with invalid inputs:

- Empty inputs
- Inputs consisting of only `0x9e5faafc` or `0x85474728`
- A large, but invalid input: `0x9e281a98000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021e19e0c9bab2400000`

## Backwards Compatibility

This is a backwards incompatible change. However, based on analysis until block 21550926 (see above), no past transaction would have behaved differently after this change.

## Security Considerations

Since only the accepted input range is reduced, no new security surface area is expected.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
