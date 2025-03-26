---
eip: 7918
title: Blob base fee bounded by execution cost
description: Imposes that the price for TARGET_BLOB_GAS_PER_BLOCK is greater than the price for TX_BASE_COST
author: Anders Elowsson (@anderselowsson)
discussions-to: https://ethereum-magicians.org/t/eip-blob-base-fee-bounded-by-price-of-blob-carrying-transaction/23271
status: Draft
type: Standards Track
category: Core
created: 2025-03-25
requires: 4844
---

## Abstract

This EIP imposes that the price of the targeted number blobs `TARGET_BLOB_GAS_PER_BLOCK * base_fee_per_blob_gas` stays above the price of a simple blob-carrying transaction `TX_BASE_COST * base_fee_per_gas`. This ensures that the blob fee auction can function properly, because the equilibrium always forms relative to the fee that carries the price signal. The proposed `if` statement to check fee parity in `calc_excess_blob_gas()` represents a neutral, simple, and future-proof resolution to current blob fee auction idiosyncrasies.

## Motivation

Ethereum deploys a dynamic pricing auction to set the blob base fee, lowering the fee if less gas is consumed than `TARGET_BLOB_GAS_PER_BLOCK` and raising the fee if more gas is consumed. Such an auction can function well when the blob base fee represents the price signal, allowing the mechanism to control the real price facing the consumer. However, when the cost of execution gas in the blob-carrying transaction dominates, the price signal is lost. The blob base fee no longer represents the actual cost facing the consumer, and the protocol cannot adjust the blob base fee to regulate the equilibrium quantity of blobs consumed. Under these circumstances, the current mechanism will continue lowering the blob base fee until it eventually settles at 1 wei. Whenever demand picks up, a sustained succession of near-full blocks is required to restore equilibrium, with the mechanism intermittently resorting to a first-price auction, considered a worse UX by blob consumers. The resulting spikiness in resource consumption is suboptimal for scaling blobspace. 

This proposal ensures that an equilibrium always forms relative to the fee that carries the price signal, thus alleviating spikiness while remaining neutral and future-proof. This is achieved with a simple `if` statement in the excess gas update function. The effect is illustrated in Figure 1.

![Figure 1](../assets/eip-7918/1.png)

**Figure 1.** Proposed restriction imposed on the blob base fee to ensure desirable equilibrium formation. When the blob fee is the primary price signal (green area), equilibrium forms just as today. When the execution fee is the primary price signal (red area), the demand curve becomes too inelastic, and the blob base fee is imposed to rise to the green area. The black line indicates fee parity between 6 blobs and a simple blob-carrying transaction.

## Specification

The function `calc_excess_blob_gas()` from [EIP-4844](./eip-4844.md) is changed to not subtract `TARGET_BLOB_GAS_PER_BLOCK` when updating the `excess_blob_gas`, if the price of `TARGET_BLOB_GAS_PER_BLOCK` is below the price of `TX_BASE_COST`.

```python
def calc_excess_blob_gas(parent: Header) -> int:
    if parent.excess_blob_gas + parent.blob_gas_used < TARGET_BLOB_GAS_PER_BLOCK:
        return 0

    if TX_BASE_COST * parent.base_fee_per_gas > TARGET_BLOB_GAS_PER_BLOCK * get_base_fee_per_blob_gas(parent):
        return parent.excess_blob_gas + parent.blob_gas_used
    else:
        return parent.excess_blob_gas + parent.blob_gas_used - TARGET_BLOB_GAS_PER_BLOCK
```

## Rationale

### Fee-inelasticity

This proposal alleviates idiosyncrasies in the blob base fee auction. At a fundamental level, the issue is that the demand curve becomes fee-inelastic as the cost of blob data falls relative to the cost of the blob-carrying transaction. When the execution cost dominates, it does not matter to the blob consumer how the blob fee evolves—it is ultimately the execution cost that contributes to equilibrium formation. Given that the protocol stipulates a perfectly inelastic supply curve, the blob base fee will simply fall to the boundary of 1 wei whenever the execution cost is too high for an equilibrium to form at `TARGET_BLOB_GAS_PER_BLOCK`. Thus, in the regime where execution fees dominate, the demand curve is *blob fee-inelastic*, and whenever the blob fees dominate, the demand curve is *execution fee-inelastic*. By ensuring that an equilibrium always forms relative to the fee that carries the price signal, spikiness in fee and resource consumption is alleviated.

### Designing for the future

The Fusaka update increases the target number of blobs, thus shifting the diagonal line in Figure 1 slightly downward. Such a shift is inherent by design and as intended. If blob consumers include many more blobs in their blob-carrying transactions, the execution gas may no longer carry the price signal at the same blob base fee, and the blob base fee should be able to settle relatively lower. This is also why fixed thresholds not relating to blob quantity or the execution fee may not be sustainable. In a scenario where Ethereum provides many orders of magnitude more blobs, the equilibrium blob base fee should ideally have a relatively lower floor. To understand why potential future blob scaling is important to account for when designing the mechanism, consider how the price of storing a fixed amount of data has fallen over the last 80 years.

However, as Ethereum scales, the number of blobs submitted in the average blob-carrying transaction, as a proportion of the `BLOBS_PER_BLOCK_TARGET`, will fall. Similarly, the number of blocks where `BLOBS_PER_BLOCK_TARGET` is submitted in a single blob-carrying transaction will also fall. The mechanism can be designed to account for this. A natural idea is to set fee parity between a blob-carrying transaction and the square root of the target number of blobs. If the target is 49 blobs per block, then fee parity is set to the cost of 7 blobs, etc. This means that the `if` statement would be altered by replacing `TARGET_BLOB_GAS_PER_BLOCK` with `integer_squareroot(BLOBS_PER_BLOCK_TARGET * GAS_PER_BLOB**2)`. If the target is 48 blobs for Fusaka, the black line in Figure 1 would apply. Further note that if blob-carrying transactions become restricted from including `BLOBS_PER_BLOCK_TARGET`, this should be accounted for.

### Delayed response during a quick rise in execution fees

When the `if` statement concludes that Ethereum operates in the execution-fee-led pricing regime, the blob base fee rises in accordance with `blob_gas_used`, without subtracting `TARGET_BLOB_GAS_PER_BLOCK`. This is an intuitive way to return to the blob-fee-led pricing regime. If the execution base fee rises quickly, there may however be a few blocks before the blob base fee catches up (during which `TARGET_BLOB_GAS_PER_BLOCK` will never be subtracted). This is arguably not an issue, and the smooth response in the blob base fee under these circumstances may even be seen as a benefit.

### Alternative specifications

The specification outlines the simplest way to achieve the desired goals and is therefore preferred. Here, two alternative variants are outlined. In the first, the fee-parity comparison is instead made on the current block's base fees, as derived from the parent block. The computation for the execution base fee is omitted and the variable instead provided as input. This would also require a change to the block validity `assert` statement (omitted here).

```python
def calc_excess_blob_gas(parent: Header, updated_base_fee_per_gas: (int)) -> int:
    if parent.excess_blob_gas + parent.blob_gas_used < TARGET_BLOB_GAS_PER_BLOCK:
        return 0
    
    # Compute the updated excess_blob_gas and the fee from the parent block as normal
    ret = parent.excess_blob_gas + parent.blob_gas_used - TARGET_BLOB_GAS_PER_BLOCK 
    blob_base_fee_per_gas = fake_exponential(MIN_BASE_FEE_PER_BLOB_GAS, ret, BLOB_BASE_FEE_UPDATE_FRACTION)

    # If the updated execution fee is higher, do not subtract TARGET_BLOB_GAS_PER_BLOCK
    if TX_BASE_COST * updated_base_fee_per_gas > blob_base_fee_per_gas:
        return parent.excess_blob_gas + parent.blob_gas_used
    else:
        return ret
```

Finally, the last function can be altered to strictly keep the blob base fee above fee parity (the black line in Figure 1). This would require the implementation of a `fake_log()`that inverts the  `fake_exponential()`.

```python
def calc_excess_blob_gas(parent: Header, updated_base_fee_per_gas: (int)) -> int:
    ...
    # If the updated execution fee is higher, return the associated excess_blob_gas
    if TX_BASE_COST * updated_base_fee_per_gas > blob_base_fee_per_gas:
        return fake_log(MIN_BASE_FEE_PER_BLOB_GAS, TX_BASE_COST * current_base_fee_per_gas, BLOB_BASE_FEE_UPDATE_FRACTION)
    else:
        return ret
```

Neither of these two alternatives would likely have a material impact on equilibrium formation.

## Security Considerations

The blob base fee will settle at a level where posting the target number of blobs costs at least as much as its blob-carrying transaction. To the best of the author's knowledge, there are no security risks associated with this.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
