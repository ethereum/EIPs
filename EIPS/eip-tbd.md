---
eip: <to be assigned>
title: A GraphQL interface for node data
author: Nick Johnson (@arachnid)
discussions-to: 
status: Draft
type: Standards Track
category: Interface
created: 2018-10-15
---

## Abstract
This EIP defines a GraphQL schema for accessing node data. This schema can be implemented by nodes, or by translation layers that fall back to the existing JSON-RPC interface for legacy nodes, and is intended to provide an efficient and easy to use interface to Ethereum node data.

## Motivation
The existing JSON-RPC interface supported by all nodes has several deficiencies:

 - RPCs do not always return all the data a caller needs, or return significant extraneous data. As a result, a significant amount of time is spent serializing and deserializing irrelevant data, as well as making multiple RPC calls to retrieve the required data.
 - The JSON-RPC interface is loosely documented, with some cruical behaviours left undocumented - for instance, `""` vs `"0x"` for an empty byte string, and `0x0` vs `0x00` for a hexadecimal integer 0. This leads to different behaviour across clients, and results in applications that do not work on nodes they were not tested on during development.
 - Several legacy API calls exist that need to be implemented by nodes, but are deprecated or rarely used (eg, `sha3`).
 - Some APIs, such as the accounts and filters API, require server-side state or private data, which prevents public nodes from being fully compatible with existing standards.

This EIP proposes a new GraphQL interface that remedies these issues, in particular the first one. The schema is straightforward and largely self-documenting. GraphQL client and server libraries exist across a large number of programming languages, easing implementation and in some cases eliminating the need for a custom client library at all.

On the author's computer, a common task - fetching all the receipts from a recent block - completes in 500 milliseconds using the existing JSON API with 32 parallel threads to call `eth_getTransactionReceipt`. A similar query using the GraphQL interface, in contrast, completes in just 18 milliseconds.

## Specification

## Rationale
This EIP specifies only operations concerned with read-only access to public data that all nodes can be expected to offer, with the exception of the `submitRawTransaction` mutation. Other APIs will be specified in separate EIPS - see Backwards Compatibility for details.

## Backwards Compatibility
This API is not backwards compatible with the JSON-RPC API. It is recommended that nodes wishing to implement this API expose it on a separate port or URL path, deprecating the JSON-RPC API for eventual removal.

The following table maps existing RPC calls under the `eth_` namespace to their GraphQL equivalents:
| RPC | Status | Description |
|-----|--------|-------------|
| eth_protocolVersion | TODO | |
| eth_syncing | TODO | |
| eth_coinbase | NOT IMPLEMENTED | Mining functionality to be defined separately. |
| eth_mining | NOT IMPLEMENTED | Mining functionality to be defined separately. |
| eth_hashRate | NOT IMPLEMENTED | Mining functionality to be defined separately. |
| eth_gasPrice | TODO | |
| eth_accounts | NOT IMPLEMENTED | Accounts functionality is not part of the core node API. |
| eth_blockNumber | IMPLEMENTED |  `block { number }` |
| eth_getBalance | IMPLEMENTED |  `account(address: "0x...") { balance }` |
| eth_getStorageAt | IMPLEMENTED |  `account(address: "0x...") { storage(slot: "0x...") }` |
| eth_getTransactionCount | IMPLEMENTED |  `account(address: "0x...") { nonce }` |
| eth_getBlockTransactionCountByHash | IMPLEMENTED |  `block(hash: "0x...") { transactionCount }` |
| eth_getBlockTransactionCountByNumber | IMPLEMENTED |  `block(number: x) { transactionCounnt }` |
| eth_getUncleCountByBlockHash | IMPLEMENTED |  `block(hash: "0x...") { ommerCount }` |
| eth_getUncleCountByBlockNumber | IMPLEMENTED |  `block(number: x) { ommerCount }` |
| eth_getCode | IMPLEMENTED |  `account(address: "0x...") { code }` |
| eth_sign | NOT IMPLEMENTED | Accounts functionality is not part of the core node API. |
| eth_sendTransaction | NOT IMPLEMENTED | Accounts functionality is not part of the core node API. |
| eth_sendRawTransaction |  TODO | |
| eth_call |  TODO | |
| eth_estimateGas |  TODO | |
| eth_getBlockByHash | IMPLEMENTED |  `block(hash: "0x...") { ... }` |
| eth_getBlockByNumber | IMPLEMENTED |  `block(number: 123) { ... }` |
| eth_getTransactionByHash | IMPLEMENTED |  `transaction(hash: "0x...") { ... }` |
| eth_getTransactionByBlockHashAndIndex |  TODO | |
| eth_getTransactionByBlockNumberAndIndex |  TODO | |
| eth_getTransactionReceipt | IMPLEMENTED |  `transaction(hash: "0x...") { receipt { ... } }` |
| eth_getUncleByBlockHashAndIndex | IMPLEMENTED |  `block(hash: "0x...") { ommers { ... } }` |
| eth_getUncleByBlockNumberAndIndex | IMPLEMENTED |  `block(number: "0x...") { ommers { ... } }` |
| eth_getCompilers | NOT IMPLEMENTED | Compiler functionality is deprecated in JSON-RPC. |
| eth_compileLLL | NOT IMPLEMENTED | Compiler functionality is deprecated in JSON-RPC. |
| eth_compileSolidity | NOT IMPLEMENTED | Compiler functionality is deprecated in JSON-RPC. |
| eth_compileSerpent | NOT IMPLEMENTED | Compiler functionality is deprecated in JSON-RPC. |
| eth_newFilter | NOT IMPLEMENTED | Filter functionality may be specified in a future EIP. |
| eth_newBlockFilter | NOT IMPLEMENTED | Filter functionality may be specified in a future EIP. |
| eth_newPendingTransactionFilter | NOT IMPLEMENTED | Filter functionality may be specified in a future EIP. |
| eth_uninstallFilter | NOT IMPLEMENTED | Filter functionality may be specified in a future EIP. |
| eth_getFilterChanges | NOT IMPLEMENTED | Filter functionality may be specified in a future EIP. |
| eth_getFilterLogs | NOT IMPLEMENTED | Filter functionality may be specified in a future EIP. |
| eth_getLogs |  TODO | |
| eth_getWork | NOT IMPLEMENTED | Mining functionality to be defined separately. |
| eth_submitWork | NOT IMPLEMENTED | Mining functionality to be defined separately. |
| eth_submitHashrate | NOT IMPLEMENTED | Mining functionality to be defined separately. |

Some node APIs are expected to be defined in related EIPs, or to be deprecated with the JSON-RPC API and eventually removed:

 - Mining related functionality under `eth`: Defined in a separate EIP (TBD).
 - The `personal_` namespace: Account operations (message and transaction signing) should be handled via a separate API that can be optionally implemented outside the node.
 - Compiler functionality: Deprecated in JSON-RPC, no implementation planned.
 - Filter functionality: Can be implemented in clients by fetching logs; a subscription interface may be defined later using GraphQL's subscribe functionality.

## Test Cases
TBD

## Implementation
A PoC for Geth implementing this interface is available [in this pull request](https://github.com/ethereum/go-ethereum/pull/17903).

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
