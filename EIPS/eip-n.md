---
eip: 1234
title: Increase calldata pricing
description: Increase calldata price to decrease the maximum block size
author: Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/tbd/tbd
type: Standards Track
category: Core
status: Draft
created: 2024-02-12
---



## Abstract

The current calldata pricing allows for siginificantly large blocks of up to 2.7 MB while the average block size is much smaller at 125 KB. 
This EIP proposes an adjustment in the Ethereum calldata price to accommodate higher transaction throughput while reducing the current maximum block size. 
This is achieved through adjusting calldata pricing, particularly for nonzero bytes, aligning with emerging data storage practices in the network, especially in the context of EIP-4844.


## Motivation

The block gas hasn't been increased since EIP-1559, while the average size of blocks has continuously increased due to the growing number of rollups posting data to Layer 1. 
EIP-4844 introduces blobs as a preferred method for data availability, signaling a shift away from calldata-dependent strategies. 
This transition demands a reevaluation of calldata pricing, esspecially with regards to mitigating the inefficiency between the average block size in bytes and the maximum one possible.
By increasing the gas costs for nonzero calldata bytes for transactions that are mainly using Ethereum for Data Availability (DA), the proposal aims to balance the need for block space with the necessity of reducing the maximum block size to make room for adding more blobs. The move from using calldata for DA to blobs further strenghens the multidimensional fee market by incentivicing blob space.

Increasing calldata costs to 42.0 gas for transactions that do not spend more gas on EVM operations than a certain treshold, significantly reduces the maximum possible block size by lowering the number of huge, pure-DA transactons that fit into one block.
On the other hand the calldata price is kept at 16 gas per non-zero byte for those transactions that also spend enough on EVM computation, such that nothing changes for those users.



## Specification

| Parameter | Value |
| - | - |
| `LEGACY_CALLDATA_COSTS` | `16` |
| `NEW_CALLDATA_COSTS` | `42` |

The formula for determining the gas used per transaction is:

`tx.gasused = max(21000 + NEW_CALLDATA_COSTS * calldata, 21000 + LEGACY_CALLDATA_COSTS * calldata + evm_gas_used)`

## Rationale

The maximum block size currently stands at ~1.79 MB (`30_000_000/16`), increasing to ~2.54 MB with EIP-4844 going live. 
With the implentation of EIP-4844, calldata may stop being the best candidate for publishing data.
With this proposal, by repricing nonzero calldata bytes to 42 gas, we aim to reduce the maximum possible block size to approximately 1 MB or even lower.
This reduction makes room for increasing the number of blobs, while ensuring network security and efficiency. 
Importantly, regular users (sending ETH/tokens/NFTs, engaging in DeFi, social media, restaking) who do not use Ethereum exclusively for DA, may remain unaffected.



## Backwards Compatibility

This is a backwards incompatible gas repricing that requires a scheduled network upgrade.

Users will be able to continue operating with no changes.

## Security Considerations

As the maximum possible block size is reduced, no security concers were raised.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
 
