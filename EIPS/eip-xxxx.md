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

## Abstract

Currently, the EVM provides basic storage functionality for smart contracts, primarily in the form of mappings (key-value pairs) using the `SSTORE` and `SLOAD` opcodes. However, there is no built-in support for iterating over it in a sorted manner. This EIP proposes the introduction of a **separate**, native key-value store in the EVM that would allow contracts to efficiently store, access, and iterate over key-value pairs in a sorted order. This would enhance the capabilities of smart contracts by enabling better data management, particularly for use cases involving ordered data, such as ranking systems or order books.

## Motivation

Many decentralized applications (dApps) rely on ordered data for various use cases, such as:

- **Order books** (to efficiently find matching orders)
- **Ranking systems** (e.g., leaderboards or voting systems)

Currently, to implement such ordered key-value pair storage, smart contracts must implement complex sorting logic or rely on external services (e.g., off-chain indexing). These approaches are often gas-inefficient and require extra off-chain infrastructure. By natively supporting sorted KV stores, smart contracts can perform these tasks more efficiently and cost-effectively.

Having a raw, iterable key-value store within contracts opens up opportunities for developers to build efficient and advanced data storage and querying libraries, enabling contract developers to fully leverage the underlying persistent key-value store of the Ethereum blockchain.

## Specification

For the purposes of this specification, we introduce a new storage system named ***Iterable Storage***, along with a set of dedicated opcodes to interact with it:

### `ISTORE key value`

Stores a key-value pair in the Iterable Storage. If the key already exists, its value is overwritten.

- **Input:**  
  - `key`: A 32-byte key (fixed-length, similar to standard storage keys)  
  - `value`: Arbitrary-length value (subject to gas and storage limits)

- **Behavior:**  
  - Inserts or updates the key-value pair in the iterable store.  
  - Maintains key ordering (lexicographic) for iteration purposes.

- **Gas cost:** TBD, a fixed gas cost, plus additional gas per byte of the value.


### `ILOAD key`

Loads the value associated with a given key from Iterable Storage.

- **Input:**  
  - `key`: A 32-byte key

- **Output:**  
  - The corresponding value if the key exists; otherwise, returns empty or zero.

- **Behavior:**  
  - Similar to `SLOAD` but accesses the separate Iterable Storage.

- **Gas cost:** TBD, a fixed gas-cost, plus 

### `IDELETE key`

Deletes a key-value pair from the Iterable Storage.

- **Input:**  
  - `key`: A 32-byte key

- **Behavior:**  
  - Removes the entry from the iterable store.

- **Gas cost:** TBD, a fixed gas cost (potentially including a refund similar to SSTORE when deleting a non-zero entry).


### `ISEEK prefix`

Initializes an iterator starting from the first key that is **lexicographically greater than or equal to** the given prefix.

- **Input:**  
  - `prefix`: A 32-byte value used to find the starting point

- **Behavior:**  
  - Resets the internal iterator to the first matching key.  
  - If no matching key exists, the iterator is set to an end-of-iteration state.

- **Gas cost:** TBD, a fixed gas-cost

### `INEXT`

Retrieves the next key-value pair from the current iterator position.

- **Output:**  
  - `(key, value)` pair if a next entry exists; otherwise, returns an end-of-iteration signal (e.g., zero).

- **Behavior:**  
  - Advances the iterator to the next lexicographically ordered key.  
  - Can be called repeatedly after `ISEEK` to traverse the storage.

- **Gas cost:** TBD, a fixed gas cost, plus additional gas consumed to store the pair in memory.

The keys in Iterable Storage are fixed at 32 bytes to enable efficient use of the Merkle-Patricia Trie. This fixed size ensures compatibility with Ethereum's existing storage mechanisms and simplifies trie construction, as each key is treated as a consistent and predictable length.

While the keys are fixed in size, the values associated with each key can have arbitrary size, allowing for flexible data storage. This flexibility ensures that the system can store diverse types of data, while maintaining efficient indexing and iteration of key-value pairs.

## Rationale

The implementation of this feature is straightforward because the database backend of Ethereum, which underpins the EVM's storage mechanism, is already a **persistent Key-Value store**. Ethereum uses **LevelDB** or **RocksDB** as its default database engines, both of which inherently support efficient storage and retrieval of key-value pairs.

These databases are designed to handle key-value storage in a way that is optimized for performance, and they already facilitate sorting and iteration through key-value pairs. Specifically, they allow for **iterating over pairs using a key-prefix**, which means that keys can be retrieved in lexicographical order (ascending or descending) with minimal computational overhead. This is a core feature of the underlying database engines, and it is used extensively in Ethereum's own state management (e.g., account balances, contract storage).

Given that Ethereum’s database backend already supports sorted key-value storage and iteration, adding native support for a sorted KV store in the EVM is trivial from an implementation standpoint. Ethereum contracts would be able to interact with this underlying functionality by leveraging the existing database capabilities for iterating over keys in sorted order.

Raw iterable key-value stores are fundamental building blocks of modern database systems. By introducing native support for a sorted KV store in the EVM, Ethereum contracts would be empowered to build sophisticated data management and querying libraries. These libraries could take full advantage of the underlying database features to support complex use cases. This would open up new possibilities for developers and increase the flexibility and efficiency of smart contract development.

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

Since the values in Iterable Storage can be of arbitrary size, a key associated with a large value could result in unexpectedly high gas costs when read. This could lead to the caller unintentionally paying excessive gas fees. To mitigate this risk, one solution would be to limit values to 32 bytes, similar to the fixed-size keys, ensuring more predictable gas costs and preventing excessive storage usage.

Other than the potential for excessive gas costs, this EIP does not introduce any new critical security vulnerabilities to the EVM, if correctly implemented. The proposed functionality leverages the existing capabilities of Ethereum’s underlying key-value storage engines (e.g., LevelDB or RocksDB), which are already designed to handle ordered data safely and efficiently.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
