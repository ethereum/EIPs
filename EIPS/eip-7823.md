---
eip: 7823
title: Set upper bounds for MODEXP
description: Each input field is restricted to a maximum of 8192 bits
author: Alex Beregszaszi (@axic), Radoslaw Zagorowicz (@rodiazet)
discussions-to: https://ethereum-magicians.org/t/eip-7823-set-upper-bounds-for-modexp/21798
status: Draft
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

1. RSA verification with up to 8192 bit keys. Commonly used ones are 1024/2048/4196 bits.
2. Elliptic curve related use cases are usually less than 384 bits.

### EVMMAX

Replacing the precompile with EVM code using an instruction set like EVMMAX would be made simpler with this limit: Common cases (256, 381, 1024, 2048) could be implemented in special fast paths, while a slow fallback could be provided for the rest. Or even special, frequently used, moduli could have their own paths.

Furthermore one could consider limiting the lengths to certain inputs only.

## Backwards Compatibility

<!-- TODO -->

This is a backwards incompatible change. Needs thorough check of transaction history to see if this would have caused failures.

## Security Considerations

<!-- TODO -->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
