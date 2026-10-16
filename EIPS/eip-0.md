---
eip: 0
title: Common Computational Gas Scaling Factor
description: Introduces CPCU, a common scaling factor for computational opcode gas costs, enabling collective repricing at hard fork boundaries
author: Helkomine (@Helkomine)
discussions-to: placeholder
status: Draft
type: Standards Track
category: Core
created: 2026-10-16
---

## Abstract

This EIP introduces a common scaling factor, `CPCU` (cost per computational unit), for pricing computational opcodes in the Ethereum Virtual Machine (EVM). The factor decouples the relative gas costs of computational operations from their absolute gas prices, allowing the latter to be adjusted collectively at hard fork boundaries without individually repricing each opcode.

At activation, `CPCU` is set to `1 gas/CU`, preserving the existing gas costs of the covered computational opcodes. Future EIPs MAY adjust `CPCU` to change their absolute costs while preserving their relative pricing. The factor remains fixed within each hard fork and does not automatically change in response to network conditions or changes to the block gas limit.

## Motivation

As the block gas limit increases, resources that do not scale sufficiently well with transaction throughput may need to be repriced to keep worst-case execution and validation costs bounded. Such repricing can introduce several challenges:

- **Compatibility:** Contracts that hardcode gas limits may fail because the available gas is no longer sufficient to execute their intended operations.
- **User experience:** Increasing absolute gas costs may increase transaction fees denominated in ETH, particularly during periods of network congestion.
- **Implementation complexity:** Different resources may have different scaling characteristics. If multiple resources require repricing as the block gas limit increases, coordinating these changes can complicate hard fork implementation and testing.

By introducing a common scaling factor for computational opcodes, this proposal provides several benefits:

- **Reduced implementation complexity:** A single parameter can be selected and updated at hard fork boundaries to adjust the prices of all covered computational opcodes. This is particularly useful when scaling efforts focus on computation, as it simplifies the process of adjusting computational prices across hard forks.
- **Avoidance of additional computational repricing costs:** Keeping computational gas prices unchanged or reducing them avoids introducing an additional increase in the gas required for computation, thereby preserving gas-sensitive contract compatibility and reducing upward pressure on transaction costs caused by computational repricing.
- **More scaling options:** Rather than relying exclusively on increasing the block gas limit, which may require increasing the prices of bottleneck resources, the protocol can also explore increasing computational capacity relative to gas by reducing computational gas costs. This provides an additional scaling option without requiring a corresponding increase in the block gas limit.
- **Consistency with common pricing parameters:** [EIP-8037](./eip-8037.md) introduces `CPSB` as a common parameter for pricing state creation costs. This proposal applies a similar approach to computational resources by introducing `CPCU`, allowing their relative prices to be preserved while their absolute gas costs are adjusted according to the network's scaling requirements.

## Specification

### Parameters

| Name | Value |
| --- | --- |
| `CPCU` | `1 gas/CU` |

At activation, `CPCU` MUST be set to `1 gas/CU`. Subsequent EIPs MAY specify a different value in accordance with the CPCU Adjustment Procedure defined below.

### Computational Units and Opcode Pricing

This EIP defines a computational unit (CU) as a protocol-defined unit for expressing the computational component of opcode costs. A CU is a pricing unit and does not represent a standardized amount of CPU time or a specific quantity of machine instructions.

For each covered opcode, this EIP assigns computational-unit coefficients corresponding to its existing computational gas cost coefficients. Static computational costs are expressed in CU. Dynamic computational cost coefficients are expressed in CU per unit of the relevant input metric. Existing rules for determining dynamic cost inputs MUST remain unchanged.

The computational gas cost of a covered opcode MUST be calculated as follows:

```text
computational_gas_cost = computational_unit_cost * CPCU
```

where `computational_unit_cost` is the sum of the opcode's static and dynamic computational costs, and `CPCU` is denominated in gas per CU.

At activation, `CPCU` MUST equal `1 gas/CU`, preserving the existing gas costs of the covered computational components.

This conversion applies only to the computational component of an operation. Other cost components, including memory expansion and state access, MUST continue to be calculated according to their respective pricing rules unless another EIP specifies otherwise.

The following table defines the computational-unit coefficients for the opcodes covered by this EIP. The old coefficients are expressed in gas-denominated units, while the new coefficients are expressed in CU-denominated units. Dynamic coefficients use the input metric defined by the existing pricing rule for the corresponding opcode.

| Name | Number | Old Static Cost (gas) | Old Dynamic Cost Coefficient | New Static Cost (CU) | New Dynamic Cost Coefficient (CU) |
| --- | --- | ---: | ---: | ---: | ---: |
| `ADD` | `0x01` | 3 | 0 | 3 | 0 |
| `MUL` | `0x02` | 5 | 0 | 5 | 0 |
| `SUB` | `0x03` | 3 | 0 | 3 | 0 |
| `DIV` | `0x04` | 5 | 0 | 5 | 0 |
| `SDIV` | `0x05` | 5 | 0 | 5 | 0 |
| `MOD` | `0x06` | 5 | 0 | 5 | 0 |
| `SMOD` | `0x07` | 5 | 0 | 5 | 0 |
| `ADDMOD` | `0x08` | 8 | 0 | 8 | 0 |
| `MULMOD` | `0x09` | 8 | 0 | 8 | 0 |
| `EXP` | `0x0A` | 10 | 50 gas per exponent byte | 10 | 50 CU per exponent byte |
| `SIGNEXTEND` | `0x0B` | 5 | 0 | 5 | 0 |
| `LT` | `0x10` | 3 | 0 | 3 | 0 |
| `GT` | `0x11` | 3 | 0 | 3 | 0 |
| `SLT` | `0x12` | 3 | 0 | 3 | 0 |
| `SGT` | `0x13` | 3 | 0 | 3 | 0 |
| `EQ` | `0x14` | 3 | 0 | 3 | 0 |
| `ISZERO` | `0x15` | 3 | 0 | 3 | 0 |
| `AND` | `0x16` | 3 | 0 | 3 | 0 |
| `OR` | `0x17` | 3 | 0 | 3 | 0 |
| `XOR` | `0x18` | 3 | 0 | 3 | 0 |
| `NOT` | `0x19` | 3 | 0 | 3 | 0 |
| `BYTE` | `0x1A` | 3 | 0 | 3 | 0 |
| `SHL` | `0x1B` | 3 | 0 | 3 | 0 |
| `SHR` | `0x1C` | 3 | 0 | 3 | 0 |
| `SAR` | `0x1D` | 3 | 0 | 3 | 0 |
| `CLZ` | `0x1E` | 5 | 0 | 5 | 0 |
| `KECCAK256` | `0x20` | 30 | 6 gas per word | 30 | 6 CU per word |

For `EXP`, the dynamic computational cost is determined by the number of bytes in the exponent, using the existing rule for calculating the exponent's byte length. For `KECCAK256`, the dynamic computational cost is determined by the number of words in the input data, using the existing rule for calculating the number of words.

The memory-expansion cost of `KECCAK256` is not part of the computational cost defined by this EIP and MUST continue to be calculated according to the existing memory-expansion rules.

### CPCU Adjustment Procedure

- At activation, `CPCU` MUST be set to `1 gas/CU`.
- `CPCU` MUST remain constant throughout each hard fork. It MUST NOT change dynamically in response to network conditions, including changes to the block gas limit.
- A subsequent EIP MAY specify a different `CPCU` value for a future hard fork. Such a change MUST be explicitly specified by that EIP and MUST account for the representability of all resulting computational gas costs in the protocol's gas accounting unit.

## Rationale

### Why Use a Common Scaling Factor?

One of the main challenges of reducing computational costs across multiple opcodes is the amount of work required to prepare and test such changes for each hard fork. Because computational opcodes are numerous, independently measuring and adjusting their prices can create a substantial implementation and coordination burden.

This burden may discourage clients from pursuing broad computational repricing, favoring increases to the block gas limit and repricing of bottleneck resources instead. These approaches can introduce the compatibility and transaction-cost concerns described in the Motivation section.

A common scaling factor allows the protocol to adjust the prices of covered computational opcodes collectively, reducing the amount of per-opcode repricing work required for subsequent hard forks. The initial implementation still requires careful specification, implementation, and testing of the new pricing model.

### What About Other Computational Operations?

In addition to EVM opcodes, other operations consume computational resources, including precompiled contracts. This proposal does not adjust the prices of precompiles because they use distinct cost models and require separate benchmarking and calibration procedures.

A future EIP MAY apply a similar scaling approach to precompiles or other computational operations, provided that it defines the relevant cost model and adjustment procedure.

### Additional Repricing Options

By enabling collective adjustment of computational gas prices, this proposal gives clients and protocol developers additional options when balancing resource costs against block capacity.

For example, if state creation, state access, or calldata costs need to increase while the block gas limit also increases, computational prices could be reduced to offset some of the additional gas burden, subject to the protocol's gas accounting resolution and resource constraints. Conversely, if broad reductions in resource prices are undesirable, the protocol could increase the price of a particularly poorly scaling resource while increasing the block gas limit, leaving computational prices unchanged.

These are alternative calibration strategies rather than automatic behaviors of `CPCU`. Each strategy requires analysis of its effects on execution costs, validation requirements, and network capacity.

## Backwards Compatibility

This EIP requires a hard fork.

Execution clients MUST implement the new computational-unit pricing model for the covered opcodes. Wallets, transaction builders, and gas estimators SHOULD account for the applicable `CPCU` value when estimating execution costs.

At activation, `CPCU` is set to `1 gas/CU`, preserving the gas costs of the computational components covered by this EIP. Implementations MUST nevertheless verify that separating computational costs from other cost components does not inadvertently change total gas accounting.

A subsequent hard fork that changes `CPCU` MAY change the gas costs of covered computational opcodes and consequently affect gas estimation, transaction execution, and the compatibility of contracts that depend on specific gas costs.

## Security Considerations

### Implementation and Testing Complexity

This proposal changes how the computational components of multiple opcodes are priced. Implementations must ensure that all covered opcodes apply `CPCU` consistently and that non-computational cost components remain unaffected.

Comprehensive testing is required to verify the new accounting model, including static costs, dynamic costs, and interactions with other cost components. Although the initial implementation introduces this additional work, subsequent repricing can be simplified by changing a common parameter rather than independently adjusting numerous opcode prices.

### Limitations on Direct Cost Reductions

Under the current integer-valued gas accounting model, setting `CPCU` to a positive value below `1 gas/CU` is not directly representable if `CPCU` is restricted to integer gas-per-CU values. Setting `CPCU` to zero is not a viable alternative because it would remove the gas charge for covered computational operations and could introduce denial-of-service vectors.

Consequently, reducing computational gas costs below their initial values through this mechanism requires a finer-grained gas accounting unit or an equivalent representation that supports fractional gas-per-CU values. A future EIP could introduce such a mechanism, for example by using milli-gas or another sufficiently precise unit.

### Changes to Computational Work per Transaction and Block

[EIP-7825](./eip-7825.md) limits the maximum execution-gas budget of a transaction to \(2^{24}\) gas. [EIP-8037](./eip-8037.md) separates state-related and execution-related costs, with the [EIP-7825](./eip-7825.md) limit applying to the execution dimension.

Changing `CPCU` does not change the computational work performed by an individual opcode. It changes the amount of computational work that can be represented by a fixed execution-gas budget. Consequently, reducing `CPCU` can increase the maximum computational work permitted per transaction and, subject to the applicable block gas limit and other protocol constraints, per block.

This may affect transaction parallelization, block validation time, and worst-case execution latency. Any future EIP that changes `CPCU` MUST evaluate these effects and establish that the resulting execution workload remains within acceptable protocol limits.

At activation, `CPCU` is set to `1 gas/CU`, so this EIP does not change the gas costs of the covered computational components. Subsequent hard forks MAY adjust `CPCU`, in which case the computational workload represented by a fixed amount of gas will change accordingly.

### Limitations of a Common Scaling Factor

`CPCU` provides a mechanism for collectively adjusting computational gas prices; it does not itself change those prices beyond the initial conversion to CU-based accounting, nor does it automatically adapt to network conditions or scaling requirements.

Its usefulness depends on whether a common adjustment is appropriate for the covered computational operations. A common factor preserves their relative pricing and therefore cannot independently correct cases where the relative costs of individual opcodes no longer reflect their resource consumption. Such cases may still require opcode-specific repricing or a separate cost model.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
