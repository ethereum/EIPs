---
eip: <to be assigned>
title: Retrieval of EIP-712 domain
description: A way to describe and retrieve an EIP-712 domain to securely integrate EIP-712 signatures.
author: Francisco Giordano (@frangio)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-07-14
requires: 712
---

## Abstract

This EIP complements [EIP-712] by standardizing how contracts should publish the fields and values that describe their domain. This enables user-agents to retrieve this description and generate appropriate domain separators in a general way, and thus integrate EIP-712 signatures securely and scalably.

## Motivation

EIP-712 is a signature scheme for complex structured messages. In order to avoid replay attacks and mitigate phishing, the scheme includes a "domain separator" that makes the resulting signature unique to a specific domain (e.g., a specific contract) and allows user-agents to inform end users the details of what is being signed and how it may be used. A domain is defined by a data structure with predefined fields, all of which are optional. Notably, EIP-712 does not specify any way for contracts to publish which of these fields they use or with what values. This has likely limited adoption of EIP-712, as it is not possible to develop general integrations, and instead applications find that they need to build custom support for each EIP-712 domain. A prime example of this is [EIP-2612] (permit), which has not been widely adopted by applications even though it is understood to be a valuable improvement to the user experience. This EIP defines an interface that can be used by user-agents to retrieve a definition of the domain that a contract uses to verify EIP-712 signatures.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

Compliant contracts MUST define `eip712Domain` exactly as declared below. All specified values MUST be returned even if they are not used, to ensure proper decoding on the client side.

```solidity
function eip712Domain() external view returns (
    bytes1 fields,
    string name,
    string version,
    uint256 chainId,
    address verifyingContract,
    bytes32 salt,
    uint256[] extensions
);
```

The return values of this function MUST describe the domain separator that is used for verification of EIP-712 signatures in the contract. They describe both the form of the `EIP712Domain` struct (i.e., which of the optional fields and extensions are present) and the value of each field, as follows.

- `fields`: A bit map where bit $$i$$ is set to 1 if and only if field $$i$$ is present ($$i \in [0, 4]$$). Bits are read from least significant to most significant, and fields are indexed in the order that is specified by EIP-712, identical to the order in which they are listead in the function type.
- `name`, `version`, `chainId`, `verifyingContract`, `salt`: The value of the corresponding field in `EIP712Domain`, if present according to `fields`. If the field is not present, the value is unspecified. The semantics of each field is defined in EIP-712.
- `extensions`: A list of EIP numbers that specify additional fields in the domain. Their inclusion in this list means they are part of the domain, and the value of `fields` does not change that.

## Rationale

A notable application of EIP-712 signatures is found in EIP-2612 (permit), which specifies a `DOMAIN_SEPARATOR` function that returns a `bytes32` value (the actual domain separator, i.e., the result of `hashStruct(eip712Domain)`). This value does not suffice for the purposes of integrating with EIP-712, as the RPC methods defined there receive an object describing the domain and not just the separator in hash form. Note that this is not a flaw of the RPC methods, it is indeed part of the security proposition that the domain should be validated and informed to the user as part of the signing process. The present EIP fills this gap in both EIP-712 and EIP-2612.

## Backwards Compatibility

This is an optional extension to EIP-712 that does not introduce backwards compatibility issues.

Upgradeable contracts that make use of EIP-712 signatures MAY be upgraded to implement this EIP.

User-agents or applications that implement this EIP SHOULD additionally support those contracts that due to their immutability cannot be upgraded to implement this EIP, by hardcoding their domain based on contract address and chain id.

## Reference Implementation

```solidity
pragma solidity 0.8.0;

function eip712Domain() external view returns (
    bytes1 fields,
    string memory name,
    string memory version,
    uint256 chainId,
    address verifyingContract,
    bytes32 salt,
    uint256[] memory extensions
) {
    return (
        hex"0d", // 01101
        "A name",
        "",
        block.chainid,
        address(this),
        bytes32(0),
        new uint[](0)
    );
}
```

```javascript
const fieldNames = ['name', 'version', 'chainId', 'verifyingContract', 'salt'];

/** Builds a domain object based on the values obtained by calling `eip712Domain()` in a contract. */
function buildDomain(fields, name, version, chainId, verifyingContract, salt, extensions) {
  if (extensions.length > 0) {
    throw Error("extensions not implemented");
  }

  const domain = { name, version, chainId, verifyingContract, salt };

  for (const [i, field] of fieldNames.entries()) {
    if (!(fields & (1 << i))) {
      delete domain[field];
    }
  }

  return domain;
}
```

## Security Considerations

While this EIP allows a contract to specify a `verifyingContract` other than itself, as well as a `chainId` other than that of the current chain, user-agents and applications should in general validate that these do match the contract and chain before requesting any user signatures for the domain. This may not always be a valid assumption.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

[EIP-712]: https://eips.ethereum.org/EIPS/eip-712
[EIP-2612]: https://eips.ethereum.org/EIPS/eip-2612
