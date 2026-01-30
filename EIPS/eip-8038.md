---
eip: 8038
title: State-access gas cost update
description: Increases the gas cost of state-access operations to reflect Ethereum’s larger state
author: Maria Silva (@misilva73), Wei Han Ng (@weiihann), Ansgar Dietrichs (@adietrichs)
discussions-to: https://ethereum-magicians.org/t/eip-8038-state-access-gas-cost-update/25693
status: Draft
type: Standards Track
category: Core
created: 2025-10-03
requires: 2926, 7928, 8032
---

## Abstract

This EIP updates the gas cost of state-access operations to reflect Ethereum's larger state and the consequent slowdown of these operations. It raises the base costs for `GAS_STORAGE_UPDATE`, `GAS_COLD_SLOAD`, and `GAS_COLD_ACCOUNT_ACCESS` and updates the access cost for `EXTCODESIZE` and `EXTCODECOPY`. The design coordinates with [EIP-8032](./eip-8032.md): before EIP-8032, parameters assume worst-case contract size; after EIP-8032, they assume worst-case up to `ACTIVATION_THRESHOLD`, with additional depth-based scaling beyond.

## Motivation

The gas price of accessing state has not been updated for quite some time. [EIP-2929](./eip-2929.md) was included in the Berlin fork in March 2021 and raised the costs of state-accessing opcodes. Yet, since then, Ethereum's state has grown significantly, thus deteriorating the performance of these operations. This proposal further raises state access costs to better align them with the current performance of state access operations, in relation to other operations.

Additionally, `EXTCODESIZE` and `EXTCODECOPY` have the same access cost as `BALANCE` and `EXTCODEHASH`. However, `EXTCODESIZE` and `EXTCODECOPY` require two database reads - first to load the account object (which includes the `nonce`, `balance`, `codeHash` and `storageRoot`), and second to collect the required information (the code size and bytecode respectively). Therefore, the access cost of `EXTCODESIZE` and `EXTCODECOPY` should be higher when compared with the other account read operations.

## Specification

### Parameters

Upon activation of this EIP, the following parameters of the gas model are renamed:

| **Parameter** | **New name** |
|:---:|:---:|
| `GAS_STORAGE_UPDATE` | `GAS_COLD_STORAGE_WRITE` |
| `GAS_COLD_SLOAD` | `GAS_COLD_STORAGE_ACCESS` |

The following parameters of the gas model are updated:

| **Parameter** | **Current value** | **New value** | **Increase** |**Operations affected** |
|:---:|:---:|:---:|:---:|:---:|
| `GAS_COLD_STORAGE_WRITE` | 5,000 | TBD | TBD | `SSTORE` |
| `GAS_COLD_STORAGE_ACCESS` | 2,100 | TBD | TBD | `SSTORE` and `SLOAD` |
| `GAS_COLD_ACCOUNT_ACCESS` | 2,600 | TBD | TBD | `*CALL` opcodes, `BALANCE`, `SELFDESTRUCT` and `EXT*` opcodes |
| `GAS_WARM_ACCESS` | 100 | TBD | TBD | `SSTORE`, `SLOAD`, `*CALL` opcodes, `BALANCE` and `EXT*` opcodes |
| `GAS_STORAGE_CLEAR_REFUND` | 4,800 | TBD | TBD | `SSTORE` |
| `ACCESS_LIST_STORAGE_KEY_COST` | 1,900 | TBD | TBD | `SSTORE` and `SLOAD`|
| `ACCESS_LIST_ADDRESS_COST` | 2,400 | TBD | TBD | `*CALL` opcodes, `BALANCE`, `SELFDESTRUCT` and `EXT*` opcodes |

<-- TODO -->

### `EXT*` family update

Besides these parameter changes, the gas cost formula for `EXTCODESIZE` and `EXTCODECOPY` is updated to include an additional `GAS_WARM_ACCESS`:

```python
if address in evm.accessed_addresses:
    access_gas_cost = GAS_WARM_ACCESS*2
else:
    evm.accessed_addresses.add(address)
    access_gas_cost = GAS_COLD_ACCOUNT_ACCESS + GAS_WARM_ACCESS
```

## Rationale

### Benchmarking

This proposal does not yet have finalized numbers. To achieve this, we require stateful benchmarks, which are currently in development. Once we collect that data, we will set the final numbers.

<-- TODO -->

### Special case for `EXTCODESIZE` and `EXTCODECOPY`

Differently from other account read operations, `EXTCODESIZE` and `EXTCODECOPY` make two reads to the database. The first read is the same, where the object of the target account is loaded. This object includes the account's `nonce`, `balance`, `codeHash` and `storageRoot`. Then, these operations do another read to collect either the code size or the bytecode of the account. This second read is to an already warmed account, and thus we propose to price it as `GAS_WARM_ACCESS` for consistency.

### Interaction with [EIP-8032](./eip-8032.md)

[EIP-8032](./eip-8032.md) proposes modifying the `SSTORE` cost formula to account for the storage size of a contract. This is a more accurate method for pricing storage writes. It allows writes to smaller contracts to be cheaper than writes to large contracts, which helps with scaling and is fairer to users. However, [EIP-8032](./eip-8032.md) is not yet scheduled for inclusion in a fork, and, as such, this proposal considers two cases for setting the values of `GAS_COLD_STORAGE_WRITE` and `GAS_COLD_STORAGE_ACCESS`:

1. Before [EIP-8032](./eip-8032.md). In this case, we set the parameters assuming a worst-case contract size, which makes state-accessing operations more expensive, independently of the contract size.
2. After [EIP-8032](./eip-8032.md). In this case, we set the parameters assuming the worst-case until `ACTIVATION_THRESHOLD`, which is the parameter in [EIP-8032](./eip-8032.md) that triggers the depth-based cost. This means that contract sizes below the threshold have the same access costs, while contracts above the threshold get exponentially more expensive with increasing size.

### Interaction with [EIP-2926](./eip-2926.md)

[EIP-2926](./eip-2926.md) proposes to change how code is store in the state trie. One of the changes of this proposal is to include the code size as a new field in the account object (`codeSize`). With this change, the code size can be directly accessed with a single read to the database and thus `EXTCODESIZE` should maintain its previous cost formula, without including the additional `GAS_WARM_ACCESS`.

### Interaction with [EIP-7928](./eip-7928.md)

[EIP-7928](./eip-7928.md) introduces Block-Level Access Lists, which enable parallel disk reads, parallel transaction validation, and executionless state updates through client optimizations. The initial benchmarks won't take into consideration these optimizations.

## Backwards Compatibility

This is a backwards-incompatible gas repricing that requires a scheduled network upgrade.

Wallet developers and node operators MUST update gas estimation handling to accommodate the new state access cost rules. Specifically:

- Wallets: Wallets using `eth_estimateGas` MUST be updated to ensure that they correctly account for the updated gas parameters. Failure to do so could result in underestimating gas, leading to failed transactions.
- Node Software: RPC methods such as `eth_estimateGas` MUST incorporate the updated formula for gas calculation with the new state access cost values.

Users can maintain their usual workflows without modification, as wallet and RPC updates will handle these changes.

## Security Considerations

Changing the cost of state access operations could impact the usability of certain applications. More analysis is needed to understand the potential effects on various dApps and user behaviors.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
