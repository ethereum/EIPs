---
eip: 8096
title: Increase Gas Cost of Point Evaluation
description: Increases cost of point evaluation precompile
author: Marcin Sobczak (@marcindsobczak), Kamil Chodoła (@kamilchodola), Marek Moraczyński (@MarekM25)
discussions-to: https://ethereum-magicians.org/t/eip-8096-point-evaluation-precompile-gas-cost-increase/26867
status: Draft
type: Standards Track
category: Core
created: 2025-12-02
requires: 4844
---

## Abstract

This EIP modifies the gas cost of `point evaluation` precompile introduced in [EIP-4844](./eip-4844.md).

## Motivation

Currently the `point evaluation` precompile is underpriced relative to its resource consumption. This EIP aims to address these discrepancies by adjusting the gas cost and making `point evaluation` precompile sufficiently efficient to enable potential further increases in the block gas limit.

## Specification

Upon activation of this EIP, the gas cost of calling the precompile at address `0x000000000000000000000000000000000000000A` will be doubled from `50_000` gas to `100_000` gas.

## Rationale

Benchmarking the `point evaluation` precompile revealed that its gas cost is significantly underestimated. This modification aim to ensure that the `point evaluation` precompile's performance no longer impedes potential increases to the block gas limit.

## Backwards Compatibility

This EIP introduces a backwards-incompatible change. However, similar gas repricings have occurred multiple times in the Ethereum ecosystem, and their effects are well understood.

## Security Considerations

This EIP does not introduce any new functionality or make existing operations cheaper, therefore there are no direct security concerns related to new attack vectors or reduced cost.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
