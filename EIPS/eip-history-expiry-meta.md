---
title: History Expiry Meta
description: Meta EIP for History Expiry changes happening in conjunction with Pectra
author: Piper Merriam (@pipermerriam)
discussions-to: <URL> TODO: waiting for eth-magicians to return to the living.
status: Draft
type: Meta
created: 2025-03-28
requires: 4444
---

## Abstract


This Meta-EIP documents the activation process and plan for history expiry as well as providing links to other EIPs that are related.

## Motivation


[EIP-4444](https://eips.ethereum.org/EIPS/eip-4444) documents the motivation for history expiry itself.

This EIP exists to document the process through which history expiry will be activated on mainnet, the testnet activation on Sepolia, devnet testing and other information surrounding history expiry that doesn't fit cleanly in any of the supporting EIPs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Execution layer client MUST implement [EIP-7642](https://eips.ethereum.org/EIPS/eip-7642) to support the `eth/69` over DevP2P.

Execution layer clients MAY drop pre-merge history according to [EIP-7639](https://eips.ethereum.org/EIPS/eip-7639).

Consensus layer clients SHOULD NOT depend on Execution Layer clients having the deposit logs from pre-merge blocks and SHOULD implement [EIP-6110](https://eips.ethereum.org/EIPS/eip-6110).


### Mainnet Activation

Mainnet activation of history expiry will occur shortly (a few days or weeks) after the activation of the [Pectra](https://eips.ethereum.org/EIPS/eip-7600) hard fork. The short delay is to ensure that all deposit logs from before the fork have been processed before clients begin dropping history.

### Testnet Activation

Testing of history expiry will occur on the Sepolia testnet. Execution clients may begin dropping pre-merge Sepolia history on 2025-05-01.

### Devnet Activation

Execution clients may test dropping of history on devnets for all history prior to block `TODO-WHAT-BLOCK-NUMBER?`.


## Rationale

### Why wait for Pecra

Consensus Layer clients have a dependency on pre-merge deposit logs. [EIP-6110](https://eips.ethereum.org/EIPS/eip-6110) will remove this dependency when the Pectra fork is activated.

### Why drop Sepolia history

The Sepolia history drop is intended as a testing ground for the mainnet activation.

### Why drop Devnet history

The Devnet history drop is intended to test prior to Sepolia to avoid any breakage on the Sepolia network.

### Won't this break JSON-RPC

History Expiry doesn't require clients to remove this data. It only allows them to. Clients that wish to preserve this history in their client for JSON-RPC use cases are free to do so.


### Where will Pre-Merge history be stored

Pre-merge data is available in the [e2store archival format](https://github.com/eth-clients/e2store-format-specs). A public list of these archives can be found in the [eth-clients historical data endpoints](https://eth-clients.github.io/history-endpoints/)

The Portal network also implements a decentralized peer-to-peer solution for storage and retrieval of all of Ethereum's pre-merge block data.


## Backwards Compatibility

### DevP2P `eth` protocol

Clients of the DevP2P `eth` protocol will need to upgrade to the new `eth/69` version specified in [EIP-7642](https://eips.ethereum.org/EIPS/eip-7642)

### Pre-Merge Deposit Logs

Consensus Layer clients have had a historical dependency on the deposit logs from pre-merge blocks. Dropping history would make these logs inaccessible to the Consensus Layer client. This issue is mitigated by [EIP-6110](https://eips.ethereum.org/EIPS/eip-6110)

### Serving Pre-Merge JSON-RPC

Execution clients that choose to drop history will no longer be capable of serving JSON-RPC requests for pre-merge requests for the following endpoints without sourcing the data from an alternate data source.

- `eth_getBlockTransactionCountByHash`
- `eth_getBlockTransactionCountByNumber`
- `eth_getUncleCountByBlockHash`
- `eth_getUncleCountByBlockNumber`
- `eth_getBlockByHash`
- `eth_getBlockByNumber`
- `eth_getTransactionByHash`
- `eth_getTransactionByBlockHashAndIndex`
- `eth_getTransactionByBlockNumberAndIndex`
- `eth_getTransactionReceipt`
- `eth_getUncleByBlockHashAndIndex`
- `eth_getUncleByBlockNumberAndIndex`


## Security Considerations

### Full History Sync

Execution layer clients will no longer be able to implement a full historical sync of history from the DevP2P network.  Clients that wish to retain this functionality will need to source the pre-merge blocks from an alternate source.  Clients SHOULD ensure that they continue to correctly validate block data sourced from alternate locations.

### Partial History Sync

Execution layer clients that do a partial sync will need to adjust their syncing algorithms to only go back to the merge block as opposed to the previous behavior of tracing all the way back to genesis.  Clients SHOULD ensure that their sync algorithms and other functionality are able to handle this data no longer being locally available.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
