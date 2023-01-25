---
eip: tbd
title: Remove The Blake2f Precompile
description:
author: @jwasinger
discussions-to:
status: Draft
type: Standards Track
category: Core
created: 2023-1-25
requires:
---

## Abstract

This EIP proposes the removal of the Blake2f precompile, reverting the behavior of the address at `0x09` to what it was before EIP-152

## Motivation

## Specification

The address `0x09` is no longer an entrypoint to the Blake2f precompile. It now behaves the same as any other non-contract account.

## Rationale

## Backwards Compatibility

It is assumed that there are no deployed contracts which make use of the Blake2f precompile (this will be verified by analyzing all EVM execution traces from chain history starting at the Berlin hard-fork).

## Security Considerations

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
