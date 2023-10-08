---
title: New unit, The Generation
description: A Generation is a scale version of an epoch.
author: JKincorperated (@JKincorperated)
discussions-to: https://ethereum-magicians.org/t/another-eip-a-new-unit-the-generation/16024
status: Draft
type: Informational
created: 2023-10-08
---

## Abstract

This EIP proposes the introduction of a new terminology, a "generation" to be used alongside the existing "epoch" terminology in the Ethereum network. A generation will be defined as a period consisting of 64 epochs, with each epoch consisting of 32 slots. This terminology enhancement aims to provide a more granular way to describe time intervals within the Ethereum network.

e.g. Slot 7497186 is in the 234287th epoch which is in the 3660th generation.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

A generation is defined as a period of 64 epochs. Generations MAY be aligned with the beacon chain genesis, but can be used as a term to describe any sequential 64 epochs with any start epoch.

For measuring generations from genesis the start value MUST be 0. To determine the generation of a specific slot, you SHOULD divide the current slot by 2048 or you MAY devide the current epoch by 64, following this division you MUST round down the the lowest integer.


## Rationale

TBD

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
