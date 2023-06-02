---
title: Decrease TLOAD/TSTORE pricing for common cases
description: Improve the efficiency of TLOAD/TSTORE by introducing a quadratic(?) pricing model.
author: @charles-cooper, @prestwich, ...(?)
discussions-to: none yet
status: Draft
type: Standards Track
category: Core
created: tbd
requires: 1153
---

## Abstract

Increase the efficiency of TLOAD/TSTORE for common use cases, while providing a quadratic pricing model to prevent DoS vectors.

## Motivation

EIP-1153 introduces a new storage region, termed "transient storage", which behaves like storage in the sense that it is word-addressed and persists between call frames, but unlike storage in the sense that it is wiped at the end of each transaction. During development of the 1153 specification, it was decided to match the pricing to be the same as warm storage loads and stores. This was for two reasons: conceptual simplicity of the EIP, and it also addressed concerns about two related DoS vectors: being able to allocate too much transient storage, and the cost of rolling back state in the case of reverts.

One of the most important use cases that EIP-1153 enables is cheap reentrancy protection. In fact, if transient storage is cheap enough for the first few slots, reentrancy protection can be enabled by default at the language level without too much burden to users, while simultaneously preventing the largest - and most expensive! - class of smart contract vulnerabilities.

Furthermore, it seems that transient storage is fundamentally overpriced. Its pricing does not interact with refunds, it only requires a new allocation on contract load (as opposed to memory, which requires a fresh allocation on every call), and has no interaction with database journaling.

This EIP proposes a quadratic pricing model, which is cheaper for common cases (fewer than 33 slots are written per contract), while making DoS using transient storage prohibitively expensive.

XXX: probably go with 9 gas per tload and 15 gas per tstore.
Does that make transient storage easier to memory dos than warm storage?


## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The gas cost for TLOAD is proposed to be 3 gas. The gas cost for TSTORE is proposed to be 3 gas + `expansion_cost`, where expansion cost is calculated as 3x the number of transient slots allocated for this contract.

The maximum number of transient slots which can be allocated on a single contract given 30m gas is approximately 4,471 (solution to `x(x-1)/2*3 + 3*x = 30_000_000`), which totals 143KB.

The maximum number of transient slots which can be allocated in a transaction if you use the strategy of calling a new contract (also designed to maximize transient storage allocation) once the cost of TSTORE is more than the cost of calling a cold contract (2600 gas) is roughly 23,068, which totals 722KB.

## Rationale

TBD

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

## Reference Implementation

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
