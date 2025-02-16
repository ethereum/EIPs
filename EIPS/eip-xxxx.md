---
title: Radical Repricing
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

This EIP proposes a radical change to the gas cost schedule: opcodes, precompiles, other costs.
Radical means that a large number of opcodes and operations are modified at once instead of a series of fine grained adjustments.
It focuses on computational complexity agnostic to the implementation and technology to the reasonable extent.
This EIP does not take into account, and cannot take by its nature, the network costs e.g. the long term cost of state changes persistence.
As the result, the gas cost schedule is more accurate and the Ethereum Network throughput increases.

## Motivation

Motivation 1.

Motivation 2.

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

 5
<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

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
| A0 - A4 | LOGx | 375 + 375 * topic_count + 8 * data_size + memory_expansion_cost | LOG_BASE_COST + LOG_PER_TOPIC_COST * topic_count + LOG_PER_BYTE_COST * data_size + memory_expansion_cost |

### Precompiles Costs

### Cost formulas

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

## Reference Implementation

```golang
const (
  RepricedGasBaseStep         uint64 = 1
  RepricedGasFastStep         uint64 = 2
  RepricedGasMidStep          uint64 = 3
  RepricedWarmStorageReadCost uint64 = 100 // WARM_STORAGE_READ_COST

  //overrides
  ExpGas           uint64 = 2  // Once per EXP instruction
  ExpByteGas       uint64 = 4  // One per byte of the EXP exponent
  Keccak256Gas     uint64 = 10 // Once per KECCAK256 operation.
  Keccak256WordGas uint64 = 6  // One per word of the KECCAK256 operation's data.
  CopyGas          uint64 = 1  // One per word of the copied code (CALLDATACOPY, CODECOPY, EXTCODECOPY, RETURNDATACOPY, MCOPY)
  LogGas           uint64 = 7  // Per LOG* operation.
  LogTopicGas      uint64 = 7  // Multiplied by the * of the LOG*, per LOG transaction. e.g. LOG0 incurs 0, LOG4 incurs 4
  LogDataGas       uint64 = 8  // Per byte in a LOG* operation's data.
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
  instructionSet[TLOAD].constantGas = RepricedWarmStorageReadCost
  instructionSet[TSTORE].constantGas = RepricedWarmStorageReadCost

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
<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
