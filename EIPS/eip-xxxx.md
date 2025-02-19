---
title: General Repricing
description: Gas Cost Repricing to reflect computational complexity and transaction throughput increase
author: Jacek Glen (@JacekGlen), Lukasz Glen (@lukasz-glen)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-02-05
requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

## Abstract

This EIP proposes a significant overhaul of the gas cost schedule, encompassing opcodes, precompiles, and other costs. The term "radical" indicates that a substantial number of opcodes and operations are modified concurrently, rather than through incremental adjustments. The focus is on computational complexity, agnostic to specific implementations and technologies, to a reasonable extent. This EIP does not account for network costs, such as the long-term cost of state changes persistence. Consequently, the gas cost schedule becomes more accurate, and Ethereum Network throughput is enhanced.

## Motivation

Gas costs encompass opcodes (including arguments and factors expressed in formulas), precompiles, and other operations such as memory expansion and access to cold or warm addresses. Gas costs are comprised of two components: network cost and computation cost. Network cost pertains to the effort required by the blockchain to maintain its state, including storage, logs, calldata, transactions, and receipts. These are data elements that need to be persisted by network nodes. Computation cost refers to the non-durable processing effort of smart contracts. Although several EIPs have addressed gas costs related to network costs, there has been minimal focus on computational costs (see EIP-160, EIP-1884). However, it is methodologically more feasible to estimate computational costs by measuring execution time.

The computational cost component of gas costs has remained largely unchanged since the inception of Ethereum. With multiple independent EVM implementations now optimized and stable, and the availability of appropriate technical and methodological tools, it is possible to evaluate how well the conventional gas cost schedule aligns with hardware workload profiles.

Measurements and estimations depend on various factors, including hardware, OS, virtualization, memory management, EVM, and more. The execution of a single opcode impacts or depends on caching, block preparation, block finalization, garbage collectors, code analysis, parsing etc. Consequently, the individual computational cost is a sum of multiple factors spread over the software stack. Despite this complexity, examinations have shown a general pattern. The computational cost outline is consistent across EVM implementations, technology stacks, and contexts. For example, the aggregated execution cost of one opcode can be twice as long as another opcode in most EVM clients. This illustrates computational complexity, determined experimentally rather than theoretically. The gas cost schedule should, therefore, accurately reflect computational complexity.

Observation 1.

The current gas cost schedule differs in many places from the experimentally determined computational complexity. Many significant outliers have been identified, indicating a need for rebalancing. Many others are reasonable candidates to be rebalanced. In particular, precompiles generally are significantly underestimated. The unbalanced gas cost schedule can: expose a risk to the network, open an attack vector, lead to false optimization, and break the principle that gas is the abstract unit of transaction execution effort.

Observation 2.

The gas cost schedule is inherently relative, meaning it can be modified as long as the proportions are correct. Generally, it is safer to decrease a gas cost than to increase it. A substantial reduction in gas costs associated with computational effort has two significant effects: it increases network throughput in terms of transactions per block, and it increases the weight of network costs.

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Parameters

| Constant                          | Value                |
|-----------------------------------|----------------------|
| `WARM_STORAGE_READ_COST`          | `5`                  |
| `BASE_OPCODE_COST`                | `1`                  |
| `FAST_OPCODE_COST`                | `2`                  |
| `MID_OPCODE_COST`                 | `3`                  |
| `EXP_BASE_COST`                   | `2`                  |
| `EXP_PER_BYTE_COST`               | `4`                  |
| `KECCAK_BASE_COST`                | `10`                 |
| `KECCAK_PER_WORD_COST`            | `6`                  |
| `COPY_PER_WORD_COST`              | `1`                  |
| `LOG_BASE_COST`                   | `7`                  |
| `LOG_PER_TOPIC_COST`              | `7`                  |
| `LOG_PER_BYTE_COST`               | `8`                  |

### Cost formulas

| Name | Formula | Description |
| ------------- | ------------- | ------------- |
| data_size | len(data) | The size of the data expressed as number of bytes |
| data_word_size | (len(data) + 31) / 32 | The size of the data expressed as number of words |
| exponent_byte_size | len(exponent) | The size in bytes of the exponent in the EXP opcode. |
| topic_count | len(topics) | The number of topics in the LOGx opcode. |
| sets_count | len(data) / 192 | The number of pair sets in the ECPAIRING precompile. |
| memory_expansion_cost | memory_cost(current_word_size) - memory_cost(previous_word_size)  | The cost of expanding memory to `current_word_size` words from `previous_word_size` words. In a single context memory cannot contract, so the formula is always non-negative |
| memory_cost | (memory_word_size ** 2) / 512  | The cost of memory for `data_word_size` words. |
| memory_word_size | (memory_size + 31) / 32 | The size of the allocated memory expressed as number of words |
| address_access_cost | 5 (warm) \| 2600 (cold)  | The cost of accessing warm and cold address data. |

### Opcode Costs

| Opcode | Name | Pre-change Gas | Gas Cost |
| ------------- | ------------- | -------------: | -------------: |
| 01 | ADD | 3 | BASE_OPCODE_COST |
| 02 | MUL | 5 | BASE_OPCODE_COST |
| 03 | SUB | 3 | BASE_OPCODE_COST |
| 04 | DIV | 5 | BASE_OPCODE_COST |
| 05 | SDIV | 5 | BASE_OPCODE_COST |
| 06 | MOD | 5 | BASE_OPCODE_COST |
| 07 | SMOD | 5 | BASE_OPCODE_COST |
| 08 | ADDMOD | 8 | FAST_OPCODE_COST |
| 09 | MULMOD | 8 | MID_OPCODE_COST |
| 0A | EXP | 10 + 50 * exponent_byte_size | EXP_BASE_COST + EXP_PER_BYTE_COST * exponent_byte_size |
| 0B | SIGNEXTEND | 5 | BASE_OPCODE_COST |
| 10 | LT | 3 | BASE_OPCODE_COST |
| 11 | GT | 3 | BASE_OPCODE_COST |
| 12 | SLT | 3 | BASE_OPCODE_COST |
| 13 | SGT | 3 | BASE_OPCODE_COST |
| 14 | EQ | 3 | BASE_OPCODE_COST |
| 15 | ISZERO | 3 | BASE_OPCODE_COST |
| 16 | AND | 3 | BASE_OPCODE_COST |
| 17 | OR | 3 | BASE_OPCODE_COST |
| 18 | XOR | 3 | BASE_OPCODE_COST |
| 19 | NOT | 3 | BASE_OPCODE_COST |
| 1A | BYTE | 3 | BASE_OPCODE_COST |
| 1B | SHL | 3 | BASE_OPCODE_COST |
| 1C | SHR | 3 | BASE_OPCODE_COST |
| 1D | SAR | 3 | BASE_OPCODE_COST |
| 20 | KECCAK256 | 30 + 6 * data_word_size + memory_expansion_cost | KECCAK_BASE_COST + KECCAK_PER_WORD_COST * data_word_size + memory_expansion_cost |
| 30 | ADDRESS | 2 | BASE_OPCODE_COST |
| 32 | ORIGIN | 2 | BASE_OPCODE_COST |
| 33 | CALLER | 2 | BASE_OPCODE_COST |
| 34 | CALLVALUE | 2 | BASE_OPCODE_COST |
| 35 | CALLDATALOAD | 3 | BASE_OPCODE_COST |
| 36 | CALLDATASIZE | 2 | BASE_OPCODE_COST |
| 37 | CALLDATACOPY | 3 + 3 * data_word_size + memory_expansion_cost | BASE_OPCODE_COST + COPY_PER_WORD_COST * data_word_size + memory_expansion_cost |
| 38 | CODESIZE | 2 | BASE_OPCODE_COST |
| 39 | CODECOPY | 3 + 3 * data_word_size + memory_expansion_cost | BASE_OPCODE_COST + COPY_PER_WORD_COST * data_word_size + memory_expansion_cost |
| 3A | GASPRICE | 2 | BASE_OPCODE_COST |
| 3B | EXTCODESIZE | address_access_cost | address_access_cost |
| 3C | EXTCODECOPY | 0 + 3 * data_word_size + memory_expansion_cost + address_access_cost | COPY_PER_WORD_COST * data_word_size + memory_expansion_cost + address_access_cost |
| 3D | RETURNDATASIZE | 2 | BASE_OPCODE_COST |
| 3E | RETURNDATACOPY | 3 + 3 * data_word_size + memory_expansion_cost | BASE_OPCODE_COST + COPY_PER_WORD_COST * data_word_size + memory_expansion_cost |
| 3F | EXTCODEHASH | address_access_cost | address_access_cost |
| 41 | COINBASE | 2 | BASE_OPCODE_COST |
| 42 | TIMESTAMP | 2 | BASE_OPCODE_COST |
| 43 | NUMBER | 2 | BASE_OPCODE_COST |
| 45 | GASLIMIT | 2 |  BASE_OPCODE_COST |
| 46 | CHAINID | 2 | BASE_OPCODE_COST |
| 47 | SELFBALANCE | 5 | BASE_OPCODE_COST |
| 50 | POP | 2 | BASE_OPCODE_COST |
| 51 | MLOAD | 3 | BASE_OPCODE_COST |
| 52 | MSTORE | 3 + memory_expansion_cost | BASE_OPCODE_COST + memory_expansion_cost |
| 53 | MSTORE8 | 3 + memory_expansion_cost | BASE_OPCODE_COST + memory_expansion_cost |
| 56 | JUMP | 8 | BASE_OPCODE_COST |
| 57 | JUMPI | 10 | BASE_OPCODE_COST |
| 58 | PC | 2 | BASE_OPCODE_COST |
| 59 | MSIZE | 2 | BASE_OPCODE_COST |
| 5A | GAS | 2 | BASE_OPCODE_COST |
| 5C | TLOAD | 100 | WARM_STORAGE_READ_COST |
| 5D | TSTORE | 100 | WARM_STORAGE_READ_COST |
| 5B | JUMPDEST | 1 | BASE_OPCODE_COST |
| 5E | MCOPY | 3 + 3 * data_word_size + memory_expansion_cost | BASE_OPCODE_COST + COPY_PER_WORD_COST * data_word_size + memory_expansion_cost |
| 5F | PUSH0 | 2 | BASE_OPCODE_COST |
| 60 - 7F | PUSHx | 3 | BASE_OPCODE_COST |
| 80 - 8F | DUPx | 3 | BASE_OPCODE_COST |
| 90 - 9F | SWAPx | 3 | BASE_OPCODE_COST |
| A0 - A4 | LOGx | 375 + 375 \* topic_count + 8 \* data_size + memory_expansion_cost | LOG_BASE_COST + LOG_PER_TOPIC_COST \* topic_count + LOG_PER_BYTE_COST \* data_size + memory_expansion_cost |

### Precompiles Costs

| Precompile | Name | Current Gas | Proposed Gas |
| ------------- | ------------- | -------------: |  -------------: |
| 02 | SHA2-256 | 60 + 12 * data_word_size | 10 + 4 * data_word_size |
| 03 | RIPEMD-160 | 600 + 120 * data_word_size | 60 + 40 * data_word_size |
| 07 | ECMUL | 6000 |  2700 |
| 08 | ECPAIRING | 45000 + 34000 * sets_count | 8000 + 7000 * sets_count |
| 0A | POINTEVAL | 50000 | 21000 |

The cost of 01 (ECRECOVER), 04 (IDENTITY), 05 (MODEXP) and 09 (BLAKE2F) precompiles remains unchanged. The calculated and rescaled cost of 06 (ECADD) is higher than the current cost. This is left unchanged to maintain compatibility with existing contracts.

Additionally, all precompiles benefit from the lowered cost of *CALL opcodes (see below).

### Other changes

The formula for these opcodes remains the same, but the total cost is affected by the memory_expansion_cost and address_access_cost changes.

| Opcode | Name | Affected formula component |
| ------------- | ------------- | ------------- |
| F0 | CREATE | memory_expansion_cost |
| F5 | CREATE2 | memory_expansion_cost |
| F1 | CALL | memory_expansion_cost, address_access_cost |
| FA | STATICCALL | memory_expansion_cost, address_access_cost |
| F4 | DELEGATECALL | memory_expansion_cost, address_access_cost |
| F3 | RETURN | memory_expansion_cost |
| FD | REVERT | memory_expansion_cost |

## Rationale

Gas Cost Estimator project

Other projects

Conclusions, common conclusions from these projects, security considerations, precompiles

Fractional gas price, pros and cons.

Increase vs. Decrease gas cost, security considerations.

Why only computational complexity? Trying to be independent of EVM implementations, some estimation.

Expected transaction throughput increment.

Impact on the gas price, expected impact.

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Backwards Compatibility

The changes require a hardfork.

The changes have the following consequences:

- The gas cost of affected opcodes, precompiles and other operations are changed.
- It is almost certain that the gas cost of a transaction that calls a contract is changed.
- Contracts that use hard coded gas limits for subcalls are affected.

TODO further research is required to ensure that contracts that use hard coded limits are not broken.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->
### Test 1

Code:

```mnemonic
PUSH1 0x60
```

Gas cost: 1

### Test 2

Code:

```mnemonic
PUSH2 0x0202
PUSH2 0x1000
EXP
```

Gas cost: 1 + 1 + (2 + 4 * 2) = 12

### Test 3

Code:

```mnemonic
// Put the required value in memory
PUSH1 0xFF
PUSH1 0x00
MSTORE

// Call the opcode
PUSH1 0x20
PUSH1 0x00
KECCAK256
```

Gas cost: 1 + 1 + (1 + 0) + 1 + 1 + (10 + 6 * 1) = 21

## Reference Implementation

The reference implementation in Go-Ethereum provides new instruction set and new `memoryGasCost` function. Additionally it contains a set of overrides for specific gas elements. The actual implementation requires proper versioning of the overrides.

```golang
const (
  RepricedGasBaseStep         uint64 = 1
  RepricedGasFastStep         uint64 = 2
  RepricedGasMidStep          uint64 = 3

  //overrides
  WarmStorageReadCost uint64 = 100 // WARM_STORAGE_READ_COST
  ExpGas              uint64 = 2  // Once per EXP instruction
  ExpByteGas          uint64 = 4  // One per byte of the EXP exponent
  Keccak256Gas        uint64 = 10 // Once per KECCAK256 operation.
  Keccak256WordGas    uint64 = 6  // One per word of the KECCAK256 operation's data.
  CopyGas             uint64 = 1  // One per word of the copied code (CALLDATACOPY, CODECOPY, EXTCODECOPY, RETURNDATACOPY, MCOPY)
  LogGas              uint64 = 7  // Per LOG* operation.
  LogTopicGas         uint64 = 7  // Multiplied by the * of the LOG*, per LOG transaction. e.g. LOG0 incurs 0, LOG4 incurs 4
  LogDataGas          uint64 = 8  // Per byte in a LOG* operation's data.
)

func newRepricedInstructionSet() JumpTable {
  instructionSet := newPragueInstructionSet()

  for _, op := range instructionSet {
    if op.isPush || op.isDup || op.isSwap || op.constantGas == GasFastestStep || op.constantGas == GasFastStep {
      op.constantGas = RepricedGasBaseStep
    }
  }
  instructionSet[ADDMOD].constantGas = RepricedGasFastStep
  instructionSet[MULMOD].constantGas = RepricedGasMidStep
  instructionSet[TLOAD].constantGas = WarmStorageReadCost
  instructionSet[TSTORE].constantGas = WarmStorageReadCost

  validateAndFillMaxStack(&instructionSet)
 return instructionSet
}

func memoryGasCost(mem *Memory, newMemSize uint64) (uint64, error) {
 if newMemSize == 0 {
    return 0, nil
  }
  if newMemSize > 0x1FFFFFFFE0 {
    return 0, ErrGasUintOverflow
  }
  newMemSizeWords := ToWordSize(newMemSize)
  newMemSize = newMemSizeWords * 32

  if newMemSize > uint64(mem.Len()) {
    square := newMemSizeWords * newMemSizeWords
    newTotalFee := square / params.QuadCoeffDiv

    fee := newTotalFee - mem.lastGasCost
    mem.lastGasCost = newTotalFee

    return fee, nil
  }
  return 0, nil
}

```

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
