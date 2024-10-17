---
title: Dynamic target base fee
description: 
author: Marc Harvey-Hill (@Marchhill)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-10-15
requires: 7623, 7742, 7778
---

## Abstract

This EIP proposes to modify the EIP-1559 mechanism to make the target block gas and blob count adjust dynamically. This adjustment will target a constant price in ETH for a simple transfer on L1 (in the case of target block gas) and on L2 (in the case of target blob count).

## Motivation

Ethereum currently uses an arbitrary target of 50% capacity, with EIP-1559 smoothing out short term spikes. This means that the de facto capacity is much lower than the maxiumum capacity, as in practice gas prices would rise exponentially as the maximum capacity is reached. Instead of targeting an arbitrary capacity, dynamic targeting optimises for affordable and consistent transaction costs. A dynamic target adjusts to longer term changes in demand, which has benefits in two cases:
- When demand is high the target increases, allowing throughput to increase without exorbitant gas fees.
- When demand is low compared to maximum capacity (for example after a large increase in blob count), the target decreases so that the protocol can still receive revenue without undercharging for blockspace or blobspace.

## Specification

### Parameters

| Parameter | Value |
| - | - |
| `FORK_TIMESTAMP` | TBD |
| `TARGET_BLOCK_GAS_CHANGE_RATE` | TBD |
| `TARGET_BLOB_COUNT_CHANGE_RATE` | `1` |
| `L1_TX_COST_TARGET` | TBD |
| `L2_TX_COST_TARGET` | TBD |
| `L1_TX_COST_CHANGE_MARGIN` | TBD |
| `L2_TX_COST_CHANGE_MARGIN` | TBD |
| `L2_TX_COMPRESSED_SIZE` | `23` |

### Dynamic targeting

The target block gas and blob count change each epoch based on the mean transaction cost over the previous epoch. If the average tx cost exceeds the desired amount beyond some margin then the target is increased; likewise if it is below the desired amount by some margin the target will decrease. The cost of an L2 transaction can be estimated using the minimum theoretical compressed size of a basic transfer.

Calculating targets:

```python
L1_TX_SIZE = 21000
meanL1TxCost = average(gasCostsForTxsLastEpoch) * L1_TX_SIZE
l1TxCostDiff = meanL1TxCost - L1_TX_COST_TARGET
targetBlockGasDirection = -1 if l1TxCostDiff < -L1_TX_COST_CHANGE_MARGIN else (1 if l1TxCostDiff > L1_TX_COST_CHANGE_MARGIN else 0)
nextEpochTargetBlockGas = min(MAX_BLOCK_GAS, previousEpochTargetBlockGas + (targetBlockGasDirection * TARGET_BLOCK_GAS_CHANGE_RATE))

BLOB_SIZE = 125000
meanL2TxCost = average(blobCostsForLastEpoch) * L2_TX_COMPRESSED_SIZE / BLOB_SIZE
l2TxCostDiff = meanL2TxCost - L2_TX_COST_TARGET
targetBlobCountDirection = -1 if l2TxCostDiff < -L2_TX_COST_CHANGE_MARGIN else (1 if l2TxCostDiff > L2_TX_COST_CHANGE_MARGIN else 0)
nextEpochBlobCount = min(MAX_BLOB_COUNT, previousEpochTargetBlobCount + (targetBlobCountDirection * TARGET_BLOB_COUNT_CHANGE_RATE))
```

## Rationale

### Constant target tx cost

A constant transaction cost target can keep transaction costs for end users affordable. Volatility in the price of ETH would affect affordability, but is unlikely to be significant compared to normal fluctuations in gas costs due to spikes in activity. In future the costs could be adjusted in the case of changes in the order of magnitude of ETH price.

An alternative approach would be to track a target transaction cost in fiat, but chosing a specific fiat currency is not credibly neutral, and introducing exchange rate oracles into the protocol could be an attack vector. Yet another alternative could be to have validators vote on the target transaction cost, but they may have conflicts of interest (for example if they are blobspace consumers) so again this is not credibly neutral.

## Backwards Compatibility

todo

## Test Cases

todo

## Security Considerations

The average block size MAY increase up to the maximum. This is why [EIP-7623](./eip-7623.md) and [EIP-7778](./eip-7888.md) are required to reduce the maximum block size to a safe amount.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
