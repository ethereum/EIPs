---
eip: 1234
title: Increase block gas limit and increase nonzero calldata pricing
description: Increase gas limit while decreasing the maximum block size
author: Toni Wahrstätter (@nerolation), Ansgar Dietrichs (@adietrichs)
discussions-to: https://ethereum-magicians.org/t/tbd/tbd
type: Standards Track
category: Core
status: Draft
created: 2024-01-26
---



## Abstract

This EIP proposes an adjustment in the Ethereum calldata price to accommodate higher transaction throughput while maintaining the current maximum block size. 
This is achieved through adjusting calldata pricing, particularly for nonzero bytes, aligning with emerging data storage practices in the network, especially in the context of EIP-4844.


## Motivation

The block gas hasn't been increased since EIP-1559, while the average size of blocks has continuously increased due to the growing number of rollups posting data to Layer 1. 
EIP-4844 introduces blobs as a preferred method for data availability, signaling a shift away from calldata-dependent strategies. 
This transition demands a reevaluation of calldata pricing. 
By increasing the gas costs for nonzero calldata bytes, the proposal aims to balance the need for higher block gas limits with the necessity of reducing the maximum block size to make room for adding more blobs. The move from using calldata for data availability to blobs further strenghens the multidimensional fee market by incentivicing blob space.

Increasing calldata costs to 42.0 gas saves a maximum of ~0.75 MB, the equivalent of 6 blobs. Realistically, this figure is much smaller.



## Specification

| Parameter | Value |
| - | - |
| `NEW_CALLDATA_GAS_COST` | `42` |


## Rationale

The maximum block size currently stands at ~1.79 MB (`30_000_000/16`), increasing to ~2.54 MB with EIP-4844 going live.  
With the implentation of EIP-4844, calldata may stop being the best candidate for publishing data.
With this proposal, by repricing nonzero calldata bytes to 42 gas each, we aim to reduce the maximum possible block size to approximately 1 MB. 
This reduction makes room for increasing the number of blobs, while ensuring network security and efficiency. 

The proposed gas limit increase to `NEW_BLOCK_GAS_LIMIT` is justified as it does not compromise security due to the accompanying decrease in maximum block size, especially considering the ongoing advancements in hardware accessibility and cost-effectiveness. 
Therefore, the described approach is preferred over a naive gas limit increase.



## Backwards Compatibility

This is a backwards incompatible gas repricing that requires a scheduled network upgrade.

Users will be able to continue operating with no changes.

## Security Considerations

As the maximum possible block size is reduced, no security concers were raised.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
 
