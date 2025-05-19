---
eip: xxxx
title: Sorted Key-Value Store with Iteration for the EVM
description: Enable smart contracts to efficiently store, retrieve, and iterate over ordered key-value pairs by exposing the underlying key-value database functionality of Ethereum clients through a precompiled contract.
author: Keyvan Kambakhsh (@keyvank), Nobitex Labs (@nobitex) <labs@nobitex.ir>
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-sorted-key-value-store-with-iteration-for-the-evm/24267
status: Draft
type: Standards Track
category: Core
created: 2025-05-19
---

## Simple Summary

This EIP proposes the introduction of a native Key-Value (KV) store in the EVM that would allow contracts to efficiently store, access, and ***iterate*** over key-value pairs in a ***sorted*** manner. This would enhance the capabilities of smart contracts by allowing better data management, particularly for use cases that involve ordered data, such as ranking systems or order-books.

## Abstract

Currently, the EVM provides basic storage functionalities for smart contracts, primarily in the form of mappings (key-value pairs). However, mappings are unordered, and there is no built-in support for iterating over them in a sorted order. This proposal suggests adding a new functionality to the EVM to support a sorted KV store, enabling smart contracts to:

1. **Store key-value pairs in a persistent and ordered manner**.
2. **Efficiently iterate over stored keys in ascending or descending order**.
3. **Improve contract execution and state management for applications like rankings, order-books and lists**.

This will reduce the need for external libraries or off-chain computations to sort and manage data, improving efficiency and reducing gas costs.

## Motivation

Many decentralized applications (dApps) rely on ordered data for various use cases, such as:

- **Ranking systems** (e.g., leaderboards or voting systems).
- **Efficient data storage** for applications needing quick access to the most recent or highest priority items (e.g., token voting, auctions).

Currently, to implement such ordered key-value pair storage, smart contracts must implement complex sorting logic or rely on external services (e.g., off-chain indexing). These approaches are often gas-inefficient and require extra off-chain infrastructure. By natively supporting sorted KV stores, smart contracts can perform these tasks more efficiently and cost-effectively.

## Specification

This EIP introduces a **native Sorted Key-Value Store** in the EVM, accessed through a **precompiled contract**. The store supports lexicographically ordered key-value pairs with full CRUD functionality and cursor-based iteration.

```solidity=
interface ISortedKVStore {
    /// Inserts or updates a key-value pair
    function set(bytes calldata key, bytes calldata value) external;

    /// Retrieves the value associated with a given key
    function get(bytes calldata key) external view returns (bytes memory value);

    /// Removes a key-value pair from the store
    function remove(bytes calldata key) external;
    
    /// Initializes an iterator starting at the first key >= `prefix`
    function begin(bytes calldata prefix) external view returns (bytes32 iterator);

    /// Advances the iterator and returns the next key-value pair
    function next(bytes32 iterator) external view returns (
        bytes32 newIterator,
        bytes memory key,
        bytes memory value
    );
}
```

### Notes

* **Lexicographical Sorting**: Keys are sorted using byte-wise lexicographical order.
* **Gas Efficiency**: All operations are designed to be efficient. The underlying Ethereum database (e.g., LevelDB or RocksDB) natively supports key iteration and sorted access.


## Rationale

The implementation of this feature is straightforward because the database backend of Ethereum, which underpins the EVM's storage mechanism, is already a **persistent Key-Value (KV) store**. Ethereum uses **LevelDB** or **RocksDB** as its default database engines, both of which inherently support efficient storage and retrieval of key-value pairs.

These databases are designed to handle key-value storage in a way that is optimized for performance, and they already facilitate sorting and iteration through key-value pairs. Specifically, they allow for **iterating over pairs using a key-prefix**, which means that keys can be retrieved in lexicographical order (ascending or descending) with minimal computational overhead. This is a core feature of the underlying database engines, and it is used extensively in Ethereum's own state management (e.g., account balances, contract storage).

Given that Ethereum’s database backend already supports sorted key-value storage and iteration, adding native support for a sorted KV store in the EVM is trivial from an implementation standpoint. Ethereum contracts would be able to interact with this underlying functionality by leveraging the existing database capabilities for iterating over keys in sorted order.

### Use Cases

- **Ranking Systems**: Automatically maintain a leaderboard where scores or ranks are updated in real-time and can be iterated in sorted order.
- **Auctions**: Maintain and iterate over auction bids in ascending or descending order.
- **Voting Systems**: Efficiently track and iterate over votes or other metrics in sorted order.
- **Order books**: Manage and iterate over buy and sell orders in price order for decentralized exchanges or markets.

### Potential Alternatives

- **Off-Chain Solutions**: Currently, many developers use off-chain solutions, such as oracles or indexing services, to maintain sorted data. However, these solutions increase complexity and reliance on external infrastructure.
- **Custom Sorting Logic**: Developers could manually implement sorting within contracts, but this requires complex logic and would be costly in terms of gas fees. The native support for sorted KV stores would streamline this process.

## Backwards Compatibility

The new functionality would not break existing smart contracts but would add a new method of managing key-value pairs. It is fully compatible with the existing Ethereum Virtual Machine (EVM) and can coexist with current storage models such as mappings.

## Security Considerations

If correctly implemented, this EIP does not introduce any new critical security vulnerabilities to the EVM. The proposed functionality leverages the existing capabilities of Ethereum’s underlying key-value storage engines (e.g., LevelDB or RocksDB), which are already designed to handle ordered data safely and efficiently.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
