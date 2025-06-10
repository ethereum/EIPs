---
eip: XXXX
title: Increase Maximum Contract Size to 48KB
status: Draft
author: Giulio Rebuffo (@Giulio2002), Ben Adams (@badams)
discussions-to: <URL or platform for discussion>
type: Core
category: Core
created: 2025-06-09
requires: 1
---

## Abstract

This EIP proposes to raise the maximum allowed size for contract code deployed on Ethereum from 24,576 bytes (24KB) to 48,768 bytes (48KB).

## Motivation

The current 24KB contract size limit can be restrictive for complex contracts and applications. Increasing the limit to 48KB allows for more feature-rich contracts while maintaining reasonable constraints on block and state growth.

## Specification

- The maximum size of contract code and initcode is 48,768 bytes.
- All other rules and checks remain unchanged.

## Rationale

- **Developer Flexibility:** Enables more complex contracts and features.
- **Backward Compatibility:** Existing contracts are unaffected.
- **Simplicity:** Only the size limit is changed, with no other protocol modifications.

## Backwards Compatibility

This change is not backwards compatible and must be activated via a network upgrade (hard fork). Contracts larger than 24KB but up to 48KB will be deployable after activation.

## Security Considerations

A higher contract size limit may marginally increase the risk of denial-of-service attacks via large contracts, but the new limit remains conservative.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
