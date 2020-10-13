---
eip: <to be assigned>
title: Add basefee in eth_getBlockByHash response
author: Abdelhamid Bakhta (@abdelhamidbakhta)
discussions-to:
status: Draft
type: Standards Track
category : Interface
created: 2020-10-13
requires: 1559
---

## Simple Summary
Add basefee field in `eth_getBlockByHash` RPC endpoint response.

## Abstract
[EIP-1559](/EIPS/eip-1559) introduces a base fee per gas in protocol.
This value is maintained under consensus as a new field in the block header structure.

## Motivation
Users may need value of the base fee at a given block. Base fee value is important to make gas price predictions more accurate.

## Specification

### eth_getBlockByHash

#### Description

Returns information about a block specified by hash.

#### Parameters

Parameters remain unchanged.

#### Returns
Add a new JSON field in the `result` object for block headers containing a base fee (post [EIP-1559](/EIPS/eip-1559) fork block).

- {[`Quantity`](#quantity)} `baseFee` - base fee for this block

## Backwards Compatibility
Backwards compatible. Calls related to block prior to [EIP-1559](/EIPS/eip-1559) fork block will omit the base fee field in the response.


## Implementation

### Besu
Available in master branch: https://github.com/hyperledger/besu


## Security Considerations
The added field (`baseFee`) is informational and does not introduce technical security issues.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
