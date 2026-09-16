---
eip: 7799
title: System logs
description: Per-block logs without associated transactions
author: Etan Kissling (@etan-status), Gajinder Singh (@g11tech)
discussions-to: https://ethereum-magicians.org/t/eip-7799-system-logs/21497
status: Draft
type: Standards Track
category: Core
created: 2024-10-29
requires: 4895, 6466, 7708, 7916, 8115
---

## Abstract

This EIP defines an extension for eth_getLogs to provide logs for events that are not associated with a given transaction, such as block rewards and withdrawals.

## Motivation

With [EIP-7708](./eip-7708.md) wallets gain the ability to use eth_getLogs to track changes to their ETH balance. However, the ETH balance may change without an explicit transaction, through block production and withdrawals. By having such operations emit block-level system logs, eth_getLogs provides a complete picture of ETH balance changes.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Fee payment logs

A log, identical to a LOG2, is issued for every transaction and appended after all other logs created by EVM execution. The fee amount incorporates the total fee charged during transaction execution, including the base fee, the priority fee, and potential blob fees.

| Field | Value |
| - | - |
| `address` | `0xfffffffffffffffffffffffffffffffffffffffe` ([`SYSTEM_ADDRESS`](./eip-4788.md)) |
| `topics[0]` | `0x7bd3aa7d673767f759ebf216e7f6c12844986c661ae6e0f1d988cf7eb7394d1d` (`keccak256('Fee(address,uint256)')`) |
| `topics[1]` | `from` address (zero prefixed to fill uint256) |
| `data` | `amount` in Wei (big endian uint256) |

### System logs list

A new list is introduced to track all block level logs emitted from system interactions. The definition uses the `Log` SSZ type from [EIP-6466](./eip-6466.md).

```python
system_logs = ProgressiveList[Log](
    log_0, log_1, log_2, ...)
```

### Priority fee processing

A log SHALL be appended to the system logs list when crediting the batched [EIP-8115](./eip-8115.md) priority fee.

| Field | Value |
| - | - |
| `address` | `0xfffffffffffffffffffffffffffffffffffffffe` ([`SYSTEM_ADDRESS`](./eip-4788.md)) |
| `topics[0]` | `0x5dfe9c0fd3043bb299f97cfece428f0396cf8b7890c525756e4ea5c0ff7d61b2` (`keccak256('PriorityRewards(address,uint256)')`) |
| `topics[1]` | `to` address (zero prefixed to fill uint256) |
| `data` | `amount` in Wei (big endian uint256) |

### Withdrawal processing

A log SHALL be appended to the system logs list on every [EIP-4895](./eip-4895.md) withdrawal.

| Field | Value |
| - | - |
| `address` | `0xfffffffffffffffffffffffffffffffffffffffe` ([`SYSTEM_ADDRESS`](./eip-4788.md)) |
| `topics[0]` | `0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65` (`keccak256('Withdrawal(address,uint256)')`) |
| `topics[1]` | `to` address (zero prefixed to fill uint256) |
| `data` | `amount` in Wei (big endian uint256) |

### Genesis processing

A log SHALL be appended to the system logs list when generating genesis blocks for networks that adopt this EIP from the beginning.

| Field | Value |
| - | - |
| `address` | `0xfffffffffffffffffffffffffffffffffffffffe` ([`SYSTEM_ADDRESS`](./eip-4788.md)) |
| `topics[0]` | `0xba2f6409ffd24dd4df8e06be958ed8c1706b128913be6e417989c74969b0b55a` (`keccak256('Genesis(address,uint256)')`) |
| `topics[1]` | `to` address (zero prefixed to fill uint256) |
| `data` | `amount` in Wei (big endian uint256) |

### Execution block header changes

The [execution block header](https://github.com/ethereum/devp2p/blob/5713591d0366da78a913a811c7502d9ca91d29a8/caps/eth.md#block-encoding-and-validity) is extended with a new field, `system-logs-root`.

```python
block_header.system_logs_root = system_logs.hash_tree_root()
```

### JSON-RPC API

Block header objects in the context of the JSON-RPC API are extended to include:

- `systemLogsRoot`: `DATA`, 32 Bytes

Log objects in the context of the JSON-RPC API are updated as follows:

- `logIndex`: `QUANTITY` - The additional system logs are indexed consecutively after the existing logs from transaction receipts
- `transactionIndex`: `QUANTITY` - `null` is also used for system logs; pending logs can still be identified by checking the `blockHash` for `null`
- `transactionHash`: DATA, 32 Bytes - `null` is also used for system logs

### Engine API

In the engine API, the `ExecutionPayload` for versions corresponding to forks adopting this EIP is extended to include:

- `systemLogsRoot`: `DATA`, 32 Bytes

As part of `engine_forkchoiceUpdated`, Execution Layer implementations SHALL verify that `systemLogsRoot` for each block matches the actual value computed from local processing. This extends on top of existing `receiptsRoot` validation.

### Consensus `ExecutionPayload` changes

The consensus `ExecutionPayload` type is extended with a new field to store the system logs root.

```python
class ExecutionPayload(...):
    ...
    system_logs_root: Root
```

## Rationale

Together with [EIP-7708](./eip-7708.md) this EIP provides the ability for wallets to compute the exact ETH balance from logs without requiring download of every single block header and all withdrawals.

The block reward from priority fees no longer has to be summed up by processing all receipts and can be obtained from the system logs root, making it efficiently provable.

### Alternatives / Future

- The information from withdrawals is now duplicated across both the `withdrawals` list and the system logs. Maybe the information could be massaged into the emitted `Withdrawal` log data, allowing the existing `withdrawals` list to be retired. The current list design requires the wallet to obtain all block headers and all withdrawals to ensure they obtained all data pertaining to the observed account. Allowing them to be queried using `eth_getLogs` is more in line with how deposits are being tracked.

- The log definitions themselves are subject to change. Aligning them with [ERC-20](./eip-20.md) for plain credits provides consistency. For withdrawals, the log data could match the form of deposit logs and [EIP-7685](./eip-7685.md) request logs.

## Backwards Compatibility

As a new field is added to the block header, applications assuming a specific block header layout may need updating.

## Security Considerations

The emitted logs use `SYSTEM_ADDRESS` as their `address` which cannot conflict with user controlled smart contracts.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
