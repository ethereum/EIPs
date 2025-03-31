---
title: History Expiry Meta
description: Meta EIP for History Expiry changes happening in conjunction with Pectra
author: Piper Merriam (@pipermerriam)
discussions-to: <URL>
status: Draft
type: Meta
created: 2025-03-28
requires: 4444
---

## Abstract



<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->
This Meta-EIP is meant to document the activation process and plan for history expiry. TODO: what else should be here

## Motivation

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

[EIP-4444](https://eips.ethereum.org/EIPS/eip-4444) documents the motivation for history expiry itself.

This EIP exists to document the process through which history expiry will be activated on mainnet, including the testnet activation on Sepolia.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.


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


## Backwards Compatibility

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

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
