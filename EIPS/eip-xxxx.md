---
eip: eip-2628
title: Header in StatusMessage
author: Tomasz K. Stanczak (@tkstanczak)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2020-04-29
---

## Simple Summary

This document proposes to include the whole BlockHeader in the status message and change the way the header hash is calculated to decrease the required size of the StatusMessage in such scenario.

## Abstract

Remove number, bestHash, and genesisHash and include the full block header in the Eth62 StatusMessage. When calculating a header hash use Keccak(Bloom) instead of Bloom when serializing header.

## Motivation

Currently after a handshake with a new node, if the node has a better total difficulty block, then we need to ask for the block header to be able to verify the total difficulty claim.
With this change this will be no longer required which will make the network slightly more resilient to sybil attacks.

## Specification

Remove bestHash, genesisHash, number fields from the StatusMessage. Add Rlp_noBloom(BlockHeader) instead.
When calculating a block header hash use Keccak(Bloom) instead of Bloom before serializing the header to RLP (this is to decrease the Header size from ~512 bytes to ~288 bytes).
Furthermore with this change we can decrease the storage size of headers from genesis by ~3GB for nodes that do not require historical bodies and receipts if we also change the BlockHeaders message to only optionally require blooms.

## Rationale

It will be easier to quickly verify best branch claims from other nodes.
It may open ways to decrease the headers storage size (minor priority but it can improve stateless clients requirements)

## Backwards Compatibility

Not backward compatible. May require changes in tooling that is calculating / verifying header hashes.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
