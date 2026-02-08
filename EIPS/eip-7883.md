---
eip: 7883
title: ModExp Gas Cost Increase
description: Increases cost of ModExp precompile
author: Marcin Sobczak (@marcindsobczak), Marek Moraczyński (@MarekM25), Marcos Maceo (@stdevMac)
discussions-to: https://ethereum-magicians.org/t/eip-7883-modexp-gas-cost-increase/22841
status: Final
type: Standards Track
category: Core
created: 2025-02-11
requires: 2565
---

## Abstract

This EIP is modifying the `ModExp` precompile pricing algorithm introduced in [EIP-2565](./eip-2565.md).

## Motivation

Currently the `ModExp` precompile is underpriced in certain scenarios relative to its resource consumption. By adjusting the pricing formula, this EIP aims to address these discrepancies, making `ModExp` sufficiently efficient to enable potential increases in the block gas limit.

## Specification

Upon activation of this EIP, the gas cost of calling the precompile at address `0x0000000000000000000000000000000000000005` will be calculated as follows:

```
def calculate_multiplication_complexity(base_length, modulus_length):
    max_length = max(base_length, modulus_length)
    words = math.ceil(max_length / 8)
    multiplication_complexity = 16
    if max_length > 32: multiplication_complexity = 2 * words**2
    return multiplication_complexity

def calculate_iteration_count(exponent_length, exponent):
    iteration_count = 0
    if exponent_length <= 32 and exponent == 0: iteration_count = 0
    elif exponent_length <= 32: iteration_count = exponent.bit_length() - 1
    elif exponent_length > 32: iteration_count = (16 * (exponent_length - 32)) + ((exponent & (2**256 - 1)).bit_length() - 1)
    return max(iteration_count, 1)

def calculate_gas_cost(base_length, modulus_length, exponent_length, exponent):
    multiplication_complexity = calculate_multiplication_complexity(base_length, modulus_length)
    iteration_count = calculate_iteration_count(exponent_length, exponent)
    return max(500, math.floor(multiplication_complexity * iteration_count))
```

The specific changes from the algorithm defined in [EIP-2565](./eip-2565.md):

### 1. Increased minimal and general price

The gas cost calculation is modified from:

```
    return max(200, math.floor(multiplication_complexity * iteration_count / 3))
```

to:

```
    return max(500, math.floor(multiplication_complexity * iteration_count))
```

This change increases the minimum gas cost from 200 to 500 and triples the general cost by removing the division by 3.

### 2. Increase cost for exponents larger than 32 bytes

The gas cost calculation is modified from:

```
    elif exponent_length > 32: iteration_count = (8 * (exponent_length - 32)) + ((exponent & (2**256 - 1)).bit_length() - 1)
```

to:

```
    elif exponent_length > 32: iteration_count = (16 * (exponent_length - 32)) + ((exponent & (2**256 - 1)).bit_length() - 1)
```

The multiplier for exponents larger than 32 bytes is increased from 8 to 16, doubling its impact.

### 3. Assume the minimal base / modulus length to be 32 and increase the cost when it is larger than 32 bytes

The gas cost calculation is modified from:

```
def calculate_multiplication_complexity(base_length, modulus_length):
    max_length = max(base_length, modulus_length)
    words = math.ceil(max_length / 8)
    return words**2
```

to:

```
def calculate_multiplication_complexity(base_length, modulus_length):
    max_length = max(base_length, modulus_length)
    words = math.ceil(max_length / 8)
    multiplication_complexity = 16
    if max_length > 32: multiplication_complexity = 2 * words**2
    return multiplication_complexity
```

This change introduces a minimal multiplication complexity of 16 and doubles the complexity if the base or modulus length exceeds 32 bytes.

## Rationale

Benchmarking the `ModExp` precompile revealed several scenarios where its gas cost was significantly underestimated. Pricing adjustments are designed to rectify underpriced edge cases by modifying the existing `ModExp` pricing formula parameters. Specifically, the minimum cost for `ModExp` will rise from 200 to 500 (a 150% increase), the general cost will triple (a 200% increase), a minimum base/modulus length of 32 bytes will be assumed and the cost will scale more aggressively when the base, modulus, or exponent exceed 32 bytes. These modifications aim to ensure that the `ModExp` precompile's performance, even in its most resource-intensive edge cases across all execution layer clients, no longer impedes potential increases to the block gas limit.

## Backwards Compatibility

This EIP introduces a backwards-incompatible change. However, similar gas repricings have occurred multiple times in the Ethereum ecosystem, and their effects are well understood.

An empirical analysis of this proposal is available [here](../assets/eip-7883/call_analysis.md), with a separate breakdown by affected entities provided [here](../assets/eip-7883/entity_analysis.md).

## Test Cases

The most common usages (approximately 99.69% of historical `Modexp` calls as of January 4th, 2025) will experience either a 150% increase (from 200 to 500 gas) or a 200% increase (tripling from approximately 1360 gas).
No changes are made to the underlying interface or arithmetic algorithms, allowing existing test vectors to be reused. The table below presents the updated gas costs for these test vectors:

| Test Case                    | [EIP-2565](./eip-2565.md) Pricing | EIP-7883 Pricing | Increase |
|------------------------------|-----|-----|----|
| modexp_nagydani_1_square     | 200 | 500 | 150% |
| modexp_nagydani_1_qube       | 200 | 500 | 150% |
| modexp_nagydani_1_pow0x10001 | 341 | 2048 | 501% |
| modexp_nagydani_2_square     | 200 | 512 | 156% |
| modexp_nagydani_2_qube       | 200 | 512 | 156% |
| modexp_nagydani_2_pow0x10001 | 1365 | 8192 | 501% |
| modexp_nagydani_3_square     | 341 | 2048 | 501% |
| modexp_nagydani_3_qube       | 341 | 2048 | 501% |
| modexp_nagydani_3_pow0x10001 | 5461 | 32768 | 500% |
| modexp_nagydani_4_square     | 1365 | 8192 | 501% |
| modexp_nagydani_4_qube       | 1365 | 8192 | 501% |
| modexp_nagydani_4_pow0x10001 | 21845 | 131072 | 500% |
| modexp_nagydani_5_square     | 5461 | 32768 | 500% |
| modexp_nagydani_5_qube       | 5461 | 32768 | 500% |
| modexp_nagydani_5_pow0x10001 | 87381 | 524288 | 500% |
| modexp_marius_1_even         | 2057 | 45296 | 2102% |
| modexp_guido_1_even          | 2298 | 51136 | 2125% |
| modexp_guido_2_even          | 2300 | 51152 | 2124% |
| modexp_guido_3_even          | 5400 | 32400 | 500% |
| modexp_guido_4_even          | 1026 | 94448 | 9105% |
| modexp_marcin_1_base_heavy   | 200 | 1152 | 476% |
| modexp_marcin_1_exp_heavy    | 215 | 16624 | 7632% |
| modexp_marcin_1_balanced     | 200 | 1200 | 500% |
| modexp_marcin_2_base_heavy   | 867 | 5202 | 500% |
| modexp_marcin_2_exp_heavy    | 852 | 16368 | 1821% |
| modexp_marcin_2_balanced     | 996 | 5978 | 500% |
| modexp_marcin_3_base_heavy   | 677 | 2032 | 200% |
| modexp_marcin_3_exp_heavy    | 765 | 4080 | 433% |
| modexp_marcin_3_balanced     | 1360 | 4080 | 200% |

## Security Considerations

This EIP does not introduce any new functionality or make existing operations cheaper, therefore there are no direct security concerns related to new attack vectors or reduced costs. The primary security consideration for this EIP is the potential for `ModExp` scenarios to be overpriced, though this is deemed a lesser risk compared to the current underpricing issues.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
