---
eip: 2602
title: Disable null hash message for ecrecover precompile
author: Wei Tang (@sorpaas)
discussions-to: https://github.com/sorpaas/EIPs/issues/10
status: Draft
type: Standards Track
category: Core 
created: 2020-04-15
---

## Simple summary

Disable null hash message `ecrecover` operation in the precompile, due to it being potentially unsafe.

## Abstract

In `ecrecover`, disable null hash message support by acting the same as the operation fails.

## Motivation

In secp256k1, null hash message verification is unsafe because an adversary can [forge the signature](https://crypto.stackexchange.com/questions/50279/how-should-ecdsa-handle-the-null-hash/50290#50290). Many libraries also by default disallow verification of null hash message. By disabling null hash message verification, we avoid potential misuse of the precompile.

## Specification

In the beginning of execution of `ecrecover` precompile, fetch the message and check if it is equal to null hash (`0x0000...0000`). If so, set output length to `0` and return.

## Rationale

This is a simple change that disables null hash message verification, by acting the same as when `ecrecover` fails.

## Backwards compatibility

EVM bahavior is only different if the provided user input to `ecrecover` contains null hash message. In this case, the previous behavior is unsafe. The new behavior will act the same as the verification fails. Backward incompatibility impact should be minimal given that the new behavior is a case that contracts already have to handle when calling the precompile.

## Test cases

To be added.

## Implementation

To be added.

## Security considerations

This EIP should improve network security as the unsafe null hash message verification is disabled.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
