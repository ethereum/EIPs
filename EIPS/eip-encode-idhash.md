---
title: Encode chain id with transaction hash
description: A standard for encoding a chain ID and transaction hash into a unique string format
author: Lauri Peltonen (@microbecode)
discussions-to: https://ethereum-magicians.org/t/a-new-standard-for-encoding-chain-id-transaction-hash/23782
status: Draft
type: Standards Track
category: ERC
created: 2025-05-10
requires: 155
---

## Abstract

This standard proposes a way to encode the combination of a chain ID and a transaction hash into one string.

## Motivation

Looking up a transaction by its hash always requires the context of the chain - a transaction hash alone is not enough to identify the used chain. If the chain information is included in the string itself, finding the right chain for the transaction is easy.

Such strings can then be used, for example, in a forwarder service that forwards to the correct blockchain explorer.

## Specification

The encoded string has three components:
- A chain ID, denoted as `chainId`. The used chain id MUST be based on [EIP-155](./eip-155.md) and the chain ID repository stated in that EIP.
- A transaction hash, denoted as `txHash`. The hash MUST include the `0x` prefix.
- A static string `tx`, acting as a type identifier.

The syntax is: `chainId:txHash:tx`.

An example for a transaction with hash `0xc55e2b90168af6972193c1f86fa4d7d7b31a29c156665d15b9cd48618b5177ef` that was issued on chain ID `1` is: `1:0xc55e2b90168af6972193c1f86fa4d7d7b31a29c156665d15b9cd48618b5177ef:tx`.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

The chain ID is the most important detail when routing queries based on this standard and is therefore the first element in the string. The transaction hash is the second most important element.

The suffix `tx` is used to differentiate from, for example, addresses. Without the `tx` it would remain unclear whether an encoded string refers to an address, a transaction hash or something else.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
