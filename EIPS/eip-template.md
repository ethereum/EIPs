---
eip: <to be assigned>
title: EIP-2771 Account Abstraction
description: A variant of EIP-2771 that does not require forwarders to be trusted
author: Pandapip1 (@pandapip1)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-01-11
requires: 2771
---

## Abstract

[EIP-2771](./eip-2771.md) is a commonly-used standard for meta-transactions that uses one or more trusted forwarders. This EIP extends [EIP-2771](./eip-2771.md) to provide support for trustless account abstraction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The key words "Trusted Forwarder", and "Recipient" in this document are to be interpreted as described in [EIP-2771](./eip-2771.md).

### Forwarder Interface

```solidity
pragma solidity ^0.8.0;

interface IForwarder {
    function isForwardedTransaction() external view returns (bool)
}
```

### Extracting the Sender and Forwarder

When a function of a Recipient is called, the Recipient MUST staticcall the `isForwardedTransaction()` function of the caller. If this either reverts or returns the boolean value false, the transaction MUST be treated normally, with the sender being the caller, and the Forwarder set to the zero address. If this returns the boolean value true, the transaction MUST be considered a forwarded transaction with the sender being extracted as defined in [EIP-2771](./eip-2771.md), and the Forwarder set to the caller.

### Recipient Extensions

When a Recipient contract takes, as a parameter of a function, an address, the Recipient should include an overload of that function that takes two addresses there instead. The first address represents the Forwarder, and the second address represents the address under the control of that Forwarder. If more than one address parameter is taken (for example, [EIP-20](./eip-20.md)'s `transferFrom`), only the overload that takes two addresses for each address parameter is needed. The original function should have the same effect as the overloaded function with the forwarder addresses set to the zero address.

For example, [EIP-20](./eip-20.md) would be extended as follows:

```solidity
function transfer(address toForwarder, address toAddress, uint256 amount);
function approve(address spenderForwarder, address spenderAddress, uint256 amount);
```

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
