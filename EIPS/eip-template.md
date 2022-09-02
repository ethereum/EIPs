---
eip: <to be assigned>
title: Demonstration Proposal
description: Hello world
author: Pandapip1 (@Pandapip1)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-09-02
requires: 20
---

## Abstract

This EIP is not actually a real EIP. It was made as a demonstration to show how an EIP could be made. This fake EIP extends [EIP-20](./eip-20.md) to add a hello world function. This function will serve no purpose.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC20HelloWorld is IERC20 {
    // @notice This function MUST return "Hello World"
    function hello() external view returns (string memory);
}

```

## Rationale

`hello` was chosen as the function name instead of `helloWorld` for brevity.

## Backwards Compatibility

No backward compatibility issues were found.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
