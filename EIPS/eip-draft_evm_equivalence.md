---
eip:
title: Full EVM Equivalence
description: Canonicalise the definition of Full EVM Equivalence
author: Pascal Caversaccio (@pcaversaccio)
discussions-to: https://ethereum-magicians.org/t/evm-equivalence-and-ethereum-stack-compatibility-definition-future-informational-eip/10044
status: Draft
type: Informational
created: 2023-01-06
---

## Abstract

This EIP standardises the definition of "Full Ethereum Virtual Machine (EVM) Equivalence". Full EVM equivalence is **complete** compliance with the latest version of the [Ethereum Yellow Paper](https://github.com/ethereum/yellowpaper). This definition applies retroactively from the first release of the Ethereum Yellow Paper in April 2014.

## Motivation

In light of the recent zkEVM announcements by various projects and the ongoing discussion, confusion, and ambiguity about how **full** EVM equivalence is defined, we define a canonical definition to foster a common understanding of the term "Full EVM Equivalence".

## Specification

Any protocol, network, smart contract system, or similar that claims at time `t` full EVM equivalence MUST fully (=100%) comply with the latest [Ethereum Yellow Paper](https://github.com/ethereum/yellowpaper) version at time `t`.

## Rationale

A proper equivalence definition requires a common, publicly available reference that specifies the formal specification of the equivalence. The [Ethereum Yellow Paper](https://github.com/ethereum/yellowpaper) formulates the formal specification of the Ethereum protocol, which is publicly available and serves as a common reference for all protocols, networks, smart contract systems, or the like that aim to build similar implementations.

## Backwards Compatibility

This proposal is fully backward compatible until the first release of the Ethereum Yellow Paper in April 2014.

## Test Cases

### Example 1 ✅

_Assumption:_ A protocol `X` follows at time `t` all the specifications stated in the Ethereum Yellow Paper at time `t`.

> Protocol `X` is fully EVM equivalent.

### Example 2 ❌

_Assumption:_ A protocol `X` follows at time `t` all the specifications stated in the Ethereum Yellow Paper at time `t` _except_ using the similar pricing for zero and non-zero byte of data.

> Protocol `X` is **not** fully EVM equivalent.

### Example 3 ❌

_Assumption:_ A protocol `X` follows at time `t` all the specifications stated in the Ethereum Yellow Paper at time `t` _except_ that the opcode `SELFDESTRUCT` does not destroy any storage.

> Protocol `X` is **not** fully EVM equivalent.

## Security Considerations

There are no security considerations directly related to the definition of "Full EVM Equivalence".

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
