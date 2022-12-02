---
eip: TBD
title: Nonce management for signature-based operations powered on EIP-712
description: Extends EIP-712 and unifies EIP-2612 with many others
author: Anton Bukov (@k06a), Mikhail Melnik (@zumzoom)
discussions-to: TBD
status: Draft
type: Standards Track
category: ERC
created: 2022-12-02
requires: 712
---

## Abstract

This EIP defines interface allowing multiple other EIPs. This interface is designed to be used in the context of [EIP-712](./eip-712.md) and allows to define abstract operations that can be executed in behalf of signer.

## Motivation

Multiple EIPs define operations that can be executed in behalf of signer and sometime introduce method naming collision and other. For example, [EIP-2612](./eip-2612.md) defines both `permit` and `nonces` methods, but gives no clue that `nonces` is related to permit operation. In case of multiple same-level EIPs implemented within one smart contract (for example: permit, delegate, vote) it's obvious that they should use different nonces.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

- Smart contract implementing EIP-712 MUST also implement the folllowing interface:
    ```solidity
    interface EIP_TBD {
        /// @dev Returns next nonce for the signer in the context of the operation typehash
        /// @param signer The signer address
        /// @param typehash The operation typehash
        function operationNonces(address signer, bytes32 typehash) external view returns (uint256);

        /// @dev Increments nonce for the signer in the context of the operation typehash
        /// @param signer The signer address
        /// @param typehash The operation typehash
        function useOperationNonce(address owner, bytes32 typehash) external returns (uint256);
    }
    ```

## Rationale

TBD

## Backwards Compatibility

Fully backward compatibile with EIP-712.

## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
