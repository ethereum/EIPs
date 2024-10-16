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

This EIP proposes to modify the EIP-1559 mechanism to make the target block gas and blob count adjust dynamically. This adjustment will target a specific price for a simple transfer on L1 (in the case of target block gas) and on L2 (in the case of target blob count). The price target will be set each epoch through validators voting.

## Motivation

Ethereum currently uses an arbitrary target of 50% capacity, with EIP-1559 smoothing out short term spikes. This means that the de facto capacity is much lower than the maxiumum capacity, as in practice gas prices would rise exponentially as the maximum capacity is reached. A dynamic target adjusts to longer term changes in demand, which has benefits in two cases:
- When demand is high the target increases, allowing throughput to increase without exorbitant gas fees.
- When demand is low compared to maximum capacity (for example after a large increase in blob count), the target decreases so that the protocol can still receive revenue without undercharging for blockspace or blobspace.

## Specification

### Parameters

| Parameter | Value |
| - | - |
| `FORK_TIMESTAMP` | TBD |
| `TARGET_BLOCK_GAS_CHANGE_RATE` | TBD |
| `TARGET_BLOB_COUNT_CHANGE_RATE` | `1` |
| `L1_TX_COST_CHANGE_MARGIN` | TBD |
| `L2_TX_COST_CHANGE_MARGIN` | TBD |
| `L2_TX_COMPRESSED_SIZE` | `23` |

### Dynamic targeting

The target block gas and blob count change each epoch based on the mean transaction cost over the previous epoch. If the average tx cost exceeds the desired amount beyond some margin then the target is increased; likewise if it is below the desired amount by some margin the target will decrease. The cost of an L2 transaction can be estimated using the minimum theoretical compressed size of a basic transfer.

Calculating targets:

```python
L1_TX_SIZE = 21000
meanL1TxCost = average(gasCostsForTxsLastEpoch) * L1_TX_SIZE
l1TxCostDiff = meanL1TxCost - targetL1TxCost
targetBlockGasDirection = -1 if l1TxCostDiff < -L1_TX_COST_CHANGE_MARGIN else (1 if l1TxCostDiff > L1_TX_COST_CHANGE_MARGIN else 0)
nextEpochTargetBlockGas = min(MAX_BLOCK_GAS, previousEpochTargetBlockGas + (targetBlockGasDirection * TARGET_BLOCK_GAS_CHANGE_RATE))

BLOB_SIZE = 125000
meanL2TxCost = average(blobCostsForLastEpoch) * L2_TX_COMPRESSED_SIZE / BLOB_SIZE
l2TxCostDiff =  meanL2TxCost - targetL2TxCost
targetBlobCountDirection = -1 if l2TxCostDiff < -L2_TX_COST_CHANGE_MARGIN else (1 if l2TxCostDiff > L2_TX_COST_CHANGE_MARGIN else 0)
nextEpochBlobCount = min(MAX_BLOB_COUNT, previousEpochTargetBlobCount + (targetBlobCountDirection * TARGET_BLOB_COUNT_CHANGE_RATE))
```

### Voting

Each epoch, validators can submit a vote for the target L1 and L2 transaction costs that will be used in calculations for the next epoch. Votes can be hidden with ZK-proofs. The resulting target is the average of all votes weighted by relative stake. (todo: add details to this part).

## Rationale

### Voting

Validators voting on a target fee for transactions allows for a stable, neutral index to track. An alternative approach could be to target some arbitrary constant cost for a transaction in ETH, but this risks fees becoming too high in the event of an increase in the value of ETH. Yet another approach would be to track a target cost in fiat, but introducing ETH price oracles into the protocol could be an attack vector. In practice the community may reach rough consensus on a reasonable fiat cost to target, and validator votes would serve as a credibly neutral oracle.

## Backwards Compatibility

todo

## Test Cases

todo

## Security Considerations

The average block size MAY increase up to the maximum. This is why [EIP-7623](./eip-7623.md) and [EIP-7778](./eip-7888.md) are required to reduce the maximum block size to a safe amount.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
