---
eip: 7825
title: Transaction Gas Limit Cap
description: Introduce a protocol-level cap on the maximum gas used by a transaction to 16,777,216 (2^24).
author: Giulio Rebuffo (@Giulio2002), Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/eip-7825-transaction-gas-limit-cap/21848
status: Final
type: Standards Track
category: Core
created: 2024-11-23
---

## Abstract

This proposal introduces a protocol-level cap on the maximum gas usage per transaction to 16,777,216 (2^24) gas. By implementing this limit, Ethereum can enhance its resilience against certain DoS vectors, improve network stability, and provide more predictability to transaction processing costs, especially in the context of increasing the gas limit.

## Motivation

Currently, transactions can theoretically consume up to the entire block gas limit, which poses several risks:

1. **DoS Attacks**: A single transaction consuming most or all of the block gas can result in uneven load distribution and impact network stability.  
2. **State Bloat Risks**: High-gas transactions often result in larger state changes, increasing the burden on nodes and exacerbating the Ethereum state growth problem.  
3. **Validation Overhead**: High-gas transactions can lead to longer block verification times, negatively impacting user experience and network decentralization.

By limiting individual transactions to a maximum of 16,777,216 gas, we aim to:

- Reduce the risks of single-transaction DoS attacks.  
- Promote fairer gas allocation across transactions within a block.  
- Ensure better synchronization among nodes by mitigating extreme block validation times.

## Specification

### Gas Cap

- Enforce a protocol-level maximum of **16,777,216 gas (2^24)** for any single transaction.  
- This cap applies regardless of the block gas limit set by miners or validators.  
- Transactions specifying gas limits higher than 16,777,216 gas will be rejected with an appropriate error code (e.g., `MAX_GAS_LIMIT_EXCEEDED`).  

### Changes to EVM Behavior

1. **Txpool Validation**: During transaction validation, if the `gasLimit` specified by the sender exceeds 16,777,216, the transaction is invalidated (not included in the txpool). 
2. **Block Validation**: As part of block validation before processing, any block having a transaction with `gasLimit` > 16,777,216 is deemed invalid and rejected.

### Protocol Adjustment

- The `GAS_LIMIT` parameter for transactions will be capped in client implementations at 16,777,216.  
- This cap is **independent** of the block gas limit, which exceeds this value.  

## Rationale

### Why 16,777,216 (2^24)?

The proposed cap of 16,777,216 gas (2^24) provides a clean power-of-two boundary that simplifies implementation while still being large enough to accommodate most complex transactions, including contract deployments and advanced DeFi interactions. This value represents approximately half of typical block sizes (30-40 million gas), ensuring multiple transactions can fit within each block.

### Compatibility with Current Gas Dynamics

- **Backward Compatibility**: Transactions with gas usage below 16,777,216 remain unaffected. Existing tooling and dApps need only minor updates to enforce the new cap.
- **Impact on Validators**: Validators can continue to process blocks with a gas limit exceeding 16,777,216, provided individual transactions adhere to the cap.

## Backwards Compatibility

This change is **not backward-compatible** with transactions that specify gas limits exceeding 16,777,216. Transactions with such high limits will need to be split into smaller operations. This adjustment is expected to impact a minimal number of users and dApps, as most transactions today fall well below the proposed cap.

An [empirical analysis](../assets/eip-7825/analysis.md) has been conducted to assess the potential impact of this change.

## Security Considerations

1. **DoS Mitigation**: A fixed cap reduces the risk of DoS attacks caused by excessively high-gas transactions.  
2. **Block Verification Stability**: By capping individual transactions, the validation of blocks becomes more predictable and uniform.  
3. **Edge Cases**: Certain highly complex transactions, such as large contract deployments, may require re-architecting to fit within the 16,777,216 gas cap.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).  
