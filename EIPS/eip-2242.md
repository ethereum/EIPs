---
eip: 2242
title: Transaction Postdata
author: John Adler (@adlerjohn)
discussions-to: https://ethereum-magicians.org/t/eip-2242-transaction-postdata/3557
status: Draft
type: Standards Track
category: Core
created: 2019-08-16
---

## Simple Summary
An additional, optional transaction field is added for "postdata," data that is posted on-chain but that cannot be read from the EVM.

## Abstract
A paradigm shift in how blockchains are used has been seen recently in Eth 2.0, with the rise of [_Execution Environments_](https://notes.ethereum.org/w1Pn2iMmSTqCmVUTGV4T5A?view) (EEs), and [_stateless clients_](https://ethresear.ch/t/the-stateless-client-concept/172). This shift involves blockchains serving as a secure data availability and arbitration layer, _i.e._, they provide a globally-accepted source of available data, and process fraud/validity and data availability proofs. This same paradigm can be applied on Eth 1.x, replacing EEs with [trust-minimized side chains](https://ethresear.ch/t/building-scalable-decentralized-payment-systems-request-for-feedback/5312).

## Motivation
While [EIP-2028](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2028.md) provides a reduction in gas cost of calldata, and is a step in the right direction of encouraging use of history rather than state, the EVM does not actually need to see all data that is posted on-chain. Following the principle of "don't pay for what you don't use," a distinct way of posting data on-chain, but without actually being usable within the EVM, is needed.

For [trust-minimized side chains with fraud proofs](https://ethresear.ch/t/minimal-viable-merged-consensus/5617), we simply need to ensure that the side chain block proposer has attested that _some_ data is available. Authentication can be performed as part of a fraud proof should that data end up invalid. Note that [trust-minimized side chains with validity proofs](https://ethresear.ch/t/on-chain-scaling-to-potentially-500-tx-sec-through-mass-tx-validation/3477) can't make use of the changes proposed in this EIP, as they required immediate authentication of the posted data. This will be [the topic of a future EIP](https://ethresear.ch/t/multi-threaded-data-availability-on-eth-1/5899).

## Specification
We propose a consensus modification, beginning at `FORK_BLKNUM`:

An additional optional field, `postdata`, is added to transactions. Serialized transactions now have the format:
```
"from": bytes20,
"to": bytes20,
"startGas": uint256,
"gasPrice": uint256,
"value": uint256,
"data": bytes,
"nonce": uint256,
["postdata": bytes],
```
with witnesses signing over the [RLP encoding](https://github.com/ethereum/wiki/wiki/RLP) of the above. `postdata` is data that is posted on-chain, for later historical retrieval by layer-2 systems.

`postdata` is an RLP-encoded twople `(version: uint64, data: bytes)`.
1. `version` is `0`.
1. `data` is an RLP-encoded list of binary data. This EIP does not interpret the data in any way, simply considering it as a binary blob, though future EIPs may introduce different interpretation schemes for different values of `version`.

The gas cost of the posted data is `1 gas per byte`. This cost is deducted from the `startGas`; if the remaining gas is non-positive the transaction immediately reverts with an out of gas exception.

## Rationale
The changes proposed are as minimal and non-disruptive to the existing EVM and transaction format as possible while also supporting possible [future extensions](https://ethresear.ch/t/multi-threaded-data-availability-on-eth-1/5899) through a version code.

## Backwards Compatibility
The new transaction format is backwards compatible, as the new `postdata` field is optionally appended to existing transactions.

The proposed changes are not forwards-compatible, and will require a hard fork.

## Test Cases
TODO

## Implementation
TODO

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
