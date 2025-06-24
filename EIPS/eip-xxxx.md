---
eip: xxxx
title: Transaction Gas Limit Cap at 2^24
description: Introduce a protocol-level cap on the maximum gas used by a transaction to 16.77 million.
author: Toni Wahrstätter (@nerolation), Vitalik Buterin (@vbuterin)
discussions-to: [Discussion URL]
status: Draft
type: Standards Track
category: Core
created: 2025-06-24
---

## Abstract

This proposal introduces a protocol-level cap on the maximum gas usage per transaction to 16.77 million gas (2^24). By implementing this limit, Ethereum can enhance its resilience against certain DoS vectors, improve network stability, and provide more predictability to transaction processing costs.

## Motivation

Currently, transactions can theoretically consume up to the entire block gas limit, which poses several risks:

1. **DoS Attacks**: A single transaction consuming most or all of the block gas can result in uneven load distribution and impact network stability.
2. **zkVM Compatibility**: Splitting large transactions into smaller chunks allows better participation in distributed proving systems.
3. **Parallel Execution**: Variable gas usage causes load imbalance across execution threads.

By limiting individual transactions to a maximum of 16.77 million gas, we aim to:

- Reduce the risks of single-transaction DoS attacks.
- Enable more predictable zkVM circuit design.
- Promote fairer gas allocation across transactions within a block.

## Specification

### Gas Cap

- Enforce a protocol-level maximum of **16.77 million gas** (2^24) for any single transaction.
- This cap applies regardless of the block gas limit set by miners or validators.
- Transactions specifying gas limits higher than 16.77 million gas will be rejected with an appropriate error code.

### Changes to EVM Behavior

1. **Txpool Validation**: During transaction validation, if the `gasLimit` specified by the sender exceeds 16.77 million, the transaction is invalidated (not included in the txpool).
2. **Block Validation**: As part of block validation before processing, any block having a transaction with `gasLimit` > 16.77 million is deemed invalid and rejected.

### Protocol Adjustment

- The `GAS_LIMIT` parameter for transactions will be capped in client implementations at 16.77 million.
- This cap is **independent** of the block gas limit, which can still exceed this value.

## Rationale

### Why 16.77 Million?

The proposed cap of 16.77 million gas (2^24) provides a balance between allowing complex transactions while maintaining predictable execution bounds. This value enables most current use cases including contract deployments and advanced DeFi interactions while ensuring consistent performance characteristics.

## Backwards Compatibility

This change is **not backward-compatible** with transactions that specify gas limits exceeding 16.77 million. Transactions with such high limits will need to be split into smaller operations. This adjustment is expected to impact a minimal number of users and dApps, as most transactions today fall well below the proposed cap.

## Security Considerations

1. **DoS Mitigation**: A fixed cap reduces the risk of DoS attacks caused by excessively high-gas transactions.
2. **Block Verification Stability**: By capping individual transactions, the validation of blocks becomes more predictable and uniform.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).