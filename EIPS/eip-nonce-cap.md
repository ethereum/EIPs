---
eip: <to be assigned>
title: Nonce Cap
description: Caps the nonce at 2^64-2
author: Pandapip1 (@Pandapip1)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2022-12-20
requires: 2929
---

## Abstract

This EIP reserves a nonce for special contracts. It also caps the nonce at `2^64-2`.

## Motivation

This EIP is not terribly useful on its own, as it adds additional computation without any useful side effects. However, it can be used by other EIPs.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### `CREATE` and `CREATE2`

If a nonce would be incremented to `2^64-1` by `CREATE` or `CREATE2`, it is instead set to `2^64-2`. `2^64-1` is reserved for alias or other special contracts.

## Rationale

Capping a nonce allows for a special contract to be created. This special contract can be used to, for example, create aliases using [EIP-TBD](./eip-contract-alias.md). This EIP is not terribly useful on its own, but it can be used by other EIPs.

## Backwards Compatibility

This EIP requires a protocol upgrade, since it modifies consensus rules. The further restriction of nonce should not have an effect on accounts, as reaching a nonce of `2^64-2` is unfeasible.

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
