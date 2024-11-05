---
eip: 7807
title: SSZ execution blocks
description: Migration of execution blocks to SSZ
author: Etan Kissling (@etan-status), Gajinder Singh (@g11tech)
discussions-to: https://ethereum-magicians.org/t/eip-7807-ssz-execution-blocks/21580
status: Draft
type: Standards Track
category: Core
created: 2024-10-28
requires: 6404, 6465, 6466, 7706, 7799
---

## Abstract

This EIP defines a migration process of execution blocks to [Simple Serialize (SSZ)](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/simple-serialize.md).

## Motivation

With [EIP-6404](./eip-6404.md) SSZ transactions, [EIP-6466](./eip-6466.md) SSZ receipts, and [EIP-6465](./eip-6465.md) SSZ withdrawals, all Merkle-Patricia Trie (MPT) besides the state trie are converted to SSZ. This enables the surrounding data structure, in this case, the execution block itself, to also convert to SSZ, achieving a unified block representation across both Consensus Layer and Execution Layer.

1. **Normalized block hash:** The Consensus Layer can compute the block hash autononomously, enabling it to process all consistency checks that currently require asynchronous communication with the Execution Layer ([`verify_and_notify_new_payload`](https://github.com/ethereum/consensus-specs/blob/9849fb39e75e6228ebd610ef0ad22f5b41543cd5/specs/electra/beacon-chain.md#modified-verify_and_notify_new_payload)). This allows early rejection of inconsistent blocks and dropping the requirement to wait for engine API interactions while syncing.

2. **Optimized engine API:** With all exchanged data supporting SSZ, the engine API can be changed from the textual JSON encoding to binary SSZ encoding, reducing exchanged data size by ~50% and significantly improving encoding/parsing efficiency.

3. **Proving support:** With SSZ, individual fields of the execution block header become provable without requiring full block headers to be present. With [EIP-7495](./eip-7495.md) SSZ `StableContainer`, proofs are forward compatible as long as underlying semantics of individual fields are unchanged, reducing maintenance requirements for smart contracts and verifying client applications.

4. **Cleanup opportunity:** The conversion to SSZ allows dropping historical fields from the PoW era and the inefficient logs bloom mechanism, and allows introducing the concept of [EIP-7706](./eip-7706.md) multi-dimensional gas.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### `ExecutionBlockHeader` container

Execution blocks are represented as a single, normalized SSZ container. The definition uses the `StableContainer[N]` SSZ type and `Optional[T]` as defined in [EIP-7495](./eip-7495.md).

| Name | Value | Description |
| - | - | - |
| `MAX_EXECUTION_BLOCK_FIELDS` | `uint64(2**6)` (= 64) | Maximum number of fields to which `StableExecutionBlock` can ever grow in the future |

```python
class StableGasAmounts(StableContainer[MAX_FEES_PER_GAS_FIELDS]):
    regular: Optional[GasAmount]
    blob: Optional[GasAmount]

class GasAmounts(Profile[StableGasAmounts]):
    regular: GasAmount
    blob: GasAmount

class StableExecutionBlockHeader(StableContainer[MAX_EXECUTION_BLOCK_FIELDS]):
    parent_hash: Optional[Root]
    miner: Optional[ExecutionAddress]
    state_root: Optional[Bytes32]
    transactions_root: Optional[Root]
    receipts_root: Optional[Root]
    number: Optional[uint64]
    gas_limits: Optional[StableGasAmounts]
    gas_used: Optional[StableGasAmounts]
    timestamp: Optional[uint64]
    extra_data: Optional[ByteList[MAX_EXTRA_DATA_BYTES]]
    mix_hash: Optional[Bytes32]
    base_fees_per_gas: Optional[FeesPerGas]
    withdrawals_root: Optional[Root]
    excess_gas: Optional[StableGasAmounts]
    parent_beacon_block_root: Optional[Root]
    requests_hash: Optional[Bytes32]
    system_logs_root: Optional[Root]

class ExecutionBlockHeader(Profile[StableExecutionBlockHeader]):
    parent_hash: Root
    miner: ExecutionAddress
    state_root: Bytes32
    transactions_root: Root  # EIP-6404 transactions.hash_tree_root()
    receipts_root: Root  # EIP-6466 receipts.hash_tree_root()
    number: uint64
    gas_limits: GasAmounts
    gas_used: GasAmounts
    timestamp: uint64
    extra_data: ByteList[MAX_EXTRA_DATA_BYTES]
    mix_hash: Bytes32
    base_fees_per_gas: BlobFeesPerGas
    withdrawals_root: Root  # EIP-6465 withdrawals.hash_tree_root()
    excess_gas: GasAmounts
    parent_beacon_block_root: Root
    requests_hash: Bytes32  # EIP-6110 `ExecutionRequests`.hash_tree_root()
    system_logs_root: Root
```

### Requests hash computation

`requests_hash` is changed to `ExecutionRequests.hash_tree_root()` using the same structure as in the Consensus Layer `BeaconBlockBody`.

### Execution block hash computation

The execution block hash is changed to be based on `hash_tree_root` in all contexts, including (1) the BLOCKHASH opcode, (2) engine API interactions (`blockHash` field), (3) JSON-RPC API interactions, (4) devp2p networking.

## Rationale

In the initial draft, only the requests hash and block hash are changed to be SSZ `hash_tree_root()` based. No Consensus Layer changes are required.

### Future

- With SSZ `Log`, the withdrawals mechanism and validator requests could be redefined to be based on logs (similar to deposits, originally, but without the delay), possibly removing the need for `withdrawals_root` and `requests_hash`.
  - The CL would insert the extra logs for minting ([EIP-7799](./eip-7799.md)) and could fetch the ones relevant for withdrawing (deposits, requests, consolidations). That mechanism would be more generic than [EIP-7685](./eip-7685.md) and would drop requiring the EL to special case requests, including `compute_requests_hash`.
  - For client applications and smart contracts, it would streamline transaction history verification based on [EIP-7792](./eip-7792.md).
  - The extra fee market for withdrawal and consolidation requests could be integrated into the multidimensional fee system, allowing to drop the extra queueing in the corresponding contract storage and reducing gas fees. The corresponding contracts may need to be updated with an irregular state transition or be replaced.

- Engine API should be updated with (1) possible withdrawals/requests refactoring as above, (2) dropping the `block_hash` field so that `ExecutionPayload` is replaced with to `ExecutionBlockHeader`, (3) binary encoding based on `ForkDigest`-context (through HTTP header or interleaved, similar to beacon-API). This reduces encoding overhead and also simplifies sharing data structures in combined CL/EL in-process implementations.

- Networking should be updated to be SSZ based, using similar format as [EIP-6404](./eip-6404.md#networking) with a type prefix followed by a potentially SSZ snappy compressed payload.

## Backwards Compatibility

This breaks compatibility of smart contracts that depend on the previous block header binary format, including for "generic" implementations that assume a common prefix and run the entire data through a linear keccak256 hash.

## Security Considerations

The SSZ block hash is based on SHA256 and shares the namespace with existing keccak256 based block hashes. As these hash algorithms are fundamentally different, no significant collision risk is expected.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
