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
requires: 7495, 7773, 7916
---

## Abstract

This EIP migrates the execution block to [Simple Serialize (SSZ)](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/ssz/simple-serialize.md), including the block hash, request hash, and the per-block tries. Notably, individual transaction, receipt, and withdrawal list elements as well as the state trie are not affected by this EIP.

## Motivation

The execution block and its per-block tries use Merkle-Patricia and RLP encoding, separate from the SSZ representation used by the Consensus Layer. Migrating the block to SSZ unifies the block representation across both layers and enables:

1. **Normalized block hash:** The Consensus Layer can autonomously check the execution block hash against the builder's commitment, enabling early consistency checks that otherwise require asynchronous communication with the Execution Layer.

2. **Optimized engine API:** With all exchanged data supporting SSZ, the engine API can be changed from the textual JSON encoding to binary SSZ encoding, reducing exchanged data size by ~50% and significantly improving encoding/parsing efficiency.

3. **Proving support:** With SSZ, individual fields of the execution block become provable without requiring the full block to be present. With [EIP-7495](./eip-7495.md) `ProgressiveContainer` and [EIP-7916](./eip-7916.md) `ProgressiveList`, proofs are forward compatible as long as underlying semantics of individual fields are unchanged, reducing maintenance requirements for smart contracts and verifying client applications.

4. **Cleanup opportunity:** The conversion to SSZ allows dropping historical fields from the PoW era and the inefficient logs bloom mechanism.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Existing definitions

Definitions from existing specifications that are used throughout this document are replicated here for reference.

| Name | SSZ equivalent |
| - | - |
| [`Root`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/phase0/beacon-chain.md#custom-types) | `Bytes32` |
| [`ExecutionAddress`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/bellatrix/beacon-chain.md#custom-types) | `Bytes20` |

### Gas amounts

The different kinds of gas amounts and fees are combined into a single structure.

| Name | SSZ equivalent | Description |
| - | - | - |
| `GasAmount` | `uint64` | Amount in units of gas |
| `FeePerGas` | `uint256` | Fee per unit of gas |

```python
class GasAmounts(ProgressiveContainer(active_fields=[1] * 2)):
    regular: GasAmount
    blob: GasAmount

class BlobFeesPerGas(ProgressiveContainer(active_fields=[1] * 2)):
    regular: FeePerGas
    blob: FeePerGas
```

### Execution block

New execution blocks use a normalized SSZ representation.

```python
class ExecutionPayload(ProgressiveContainer(active_fields=[1] * 18)):
    parent_hash: Root
    miner: ExecutionAddress
    state_root: Bytes32
    transactions: ProgressiveList[ProgressiveByteList]
    receipts_root: Root
    number: uint64
    gas_limits: GasAmounts
    gas_used: GasAmounts
    timestamp: uint64
    extra_data: ByteList[MAX_EXTRA_DATA_BYTES]
    mix_hash: Bytes32
    base_fees_per_gas: BlobFeesPerGas
    withdrawals: ProgressiveList[ProgressiveByteList]
    excess_gas: GasAmounts
    parent_beacon_block_root: Root
    requests_hash: Root
    block_access_list: ProgressiveByteList
    slot_number: uint64
```

- Transaction and receipt list elements retain their existing [EIP-2718](./eip-2718.md) typed-envelope representation; withdrawal list elements and the block access list retain their existing RLP representation
- `receipts_root` is `receipts.hash_tree_root()` over the block's `ProgressiveList[ProgressiveByteList]` of receipts
- `requests_hash` is `ExecutionRequests.hash_tree_root()`, matching the [`ExecutionRequests`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/electra/beacon-chain.md#executionrequests) root used by the Consensus Layer

An execution block header can be derived as an [SSZ summary](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/ssz/simple-serialize.md#summaries-and-expansions) of `ExecutionPayload` that replaces the `transactions`, `withdrawals`, and `block_access_list` fields with their corresponding `hash_tree_root`.

### Consensus `ExecutionPayload` changes

The `ExecutionPayload` definition replaces the Consensus Layer [`ExecutionPayload`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/gloas/beacon-chain.md#executionpayload), carried by the [`ExecutionPayloadEnvelope`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/gloas/beacon-chain.md#executionpayloadenvelope).

### Execution block hash computation

The execution block hash is computed as `ExecutionPayload.hash_tree_root()` in all contexts, including (1) the `BLOCKHASH` opcode, (2) JSON-RPC API interactions (`blockHash` field), (3) devp2p networking, and (4) Consensus Layer references in [`BeaconState.latest_block_hash`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/gloas/beacon-chain.md#beaconstate) / [`ExecutionPayloadBid.block_hash`](https://github.com/ethereum/consensus-specs/blob/4f1df00ff567ea1855fb7f37ec23bd324a96703b/specs/gloas/beacon-chain.md#executionpayloadbid).

### JSON-RPC

JSON-RPC block responses MUST set the `logsBloom` field to all `1` bits (256 bytes of `0xff`).

## Rationale

### Forward compatibility

`ExecutionPayload` uses [`ProgressiveContainer`](./eip-7495.md) and [`ProgressiveList`](./eip-7916.md): generalized indices remain stable as the block definition evolves, and the lists can grow without a hardcoded limit.

### Logs bloom

Using an all `1` bits value forces consumers to fall back to inspecting every receipt; all `0` bits would signal a definite absence and may cause missed logs.

### Engine API

The shared SSZ block hash lets the engine API drop the redundant `block_hash` field and adopt binary `ForkDigest`-context encoding. This reduces encoding overhead and simplifies sharing data structures in combined Consensus Layer / Execution Layer implementations.

## Backwards Compatibility

This breaks compatibility of smart contracts that depend on the previous block header binary format, including for "generic" implementations that assume a common prefix and run the entire data through a linear keccak256 hash.

JSON-RPC consumers that read `logsBloom` observe an all-`1` value for SSZ blocks, which is backwards compatible. The receipt `logsBloom` is unaffected by this EIP.

## Security Considerations

The SSZ block hash is based on SHA256 and shares the namespace with existing keccak256 based block hashes. As these hash algorithms are fundamentally different, no significant collision risk is expected.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
