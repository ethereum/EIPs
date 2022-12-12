---
eip: <to be assigned>
title: Universal Router Contract
description: Universal router contract designed for token allowance that eliminates all `approve`` transactions in the future.
author: Zergity (zergity@gmail.com)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-12-12
requires: EIP20, EIP721, EIP1155
---

## Abstract

A universal router contract that executes transactions with a sequence of the following steps:
  * (optional) call a calculation contract to get the `amountIn` value, and ensure that this `amountIn` is no larger than an input `amountInMax`
  * transfer `amountIn` of a token from `msg.sender` to a `recipient`
  * call a contract to execute an action
  * (optional) verify the returning amount of a token must be no less than an input `amountOutMin`

## Motivation

Most of the Dapp router contract has the following pattern: Approve, (optional) calculation, transferFrom, action, and (optionally) verify the token output. This requires `n*m*k` `allow` (or `permit`) transactions, for `n` Dapps, `m` tokens and `k` user addresses. Even though user approves a contract to spend their tokens, it's the front-end code that they trust, not the contract itself. Anyone can create a front-end code and trick the users to sign a transaction to interact with the Uniswap Router contract and steal all their tokens that have been approved.

Universal Router separates token allowance logic from Dapp logic. Saves `(n-1)*m*k` approval transactions for old tokens and **ALL** approval transactions for new tokens. The Universal Router contract is designed to be simple and easy to verify and audit. It's counter-factually created using `CREATE2` so any new tokens can hardcode and skip the allowance check.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://ethereum.org/en/developers/docs/nodes-and-clients/)).

## Rationale

The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

## Backwards Compatibility

All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases

Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation

An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations

All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
