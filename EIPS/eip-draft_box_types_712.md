---
title: Box types for EIP-712 messages
description: A mechanism for EIP-712 messages to contain parameters of arbitrary type
author: Francisco Giordano <@frangio>
discussions-to: https://ethereum-magicians.org/t/eip-box-types-for-eip-712-messages/20092
status: Draft
type: Standards Track
category: Interface
created: 2024-05-23
requires: 712
---

## Abstract

A special type `box` is defined for EIP-712 messages. A `box` value is a value of an arbitrary struct type whose underlying type is encapsulated from the containing struct, but transparent and type-checkable by the wallet, and thus able to be fully inspected by the user prior to signing. A verifying contract can be made agnostic to the underlying type of a `box` value, but this type is not erased and can be verified on-chain if necessary.

## Motivation

[EIP-712](./eip-712.md) signatures have become a widely used primitive for users to express and authorize intents off-chain. Wide-ranging applications are able to define parameterized messages for users to sign in their wallet through a general-purpose interface that clearly surfaces the type, parameters, and domain of authorization. This crucially applies to hardware wallets as a last line of defense.

The general-purpose nature of EIP-712 is key to its success, but in addition wallets are able to develop special-purpose interfaces and capabilities for specific types of messages as they become more widely used. For example, [ERC-2612](./eip-2612.md) Permits are a well-known EIP-712 message that wallets display to the user in a special way that clearly surfaces the known implications and risks of signing.

Special-purpose interfaces improve usability and security for the user, but rely on standardized message types such as Permits. This EIP concerns the ability to standardize messages that contain within them parameters of arbitrary type.

A recent example is found in ERC-7683, which defines a struct with the following member:
```solidity
/// @dev Arbitrary implementation-specific data
/// Can be used to define tokens, amounts, destination chains, fees, settlement parameters,
/// or any other order-type specific information
bytes orderData;
```
Defining this parameter with type `bytes` enables the message to contain data of arbitrary type and is sufficient to bind the signature to implementation-specific data, but it amounts to type erasure. As a consequence, the user will be presented with an opaque bytestring in hexadecimal format in the wallet's signing interface. This negates the benefit of using EIP-712 signatures because the true contents of the parameter are invisible to the wallet's general-purpose interface.

Another example is found in recent efforts to make [ERC-1271](./eip-1271.md) signatures secure against replay. Achieving this without making the message contents opaque to the signer requires embedding an application's EIP-712 message inside an outer message that binds it to a specific account. The type of the outer message depends on the type of the inner message, and making the type reproducible by the smart contract account on-chain for verification requires an inefficient scheme to communicate the string-encoded type of the inner message as a part of the signature.

Both of these use cases would benefit from the ability to define EIP-712 struct parameters of arbitrary type in such a way that the verifying contract can be agnostic to the type of the parameter's value in a message while the wallet retains the ability to transparently display it to the user for inspection.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

EIP-712 is extended as follows:

### Typed structured data

A struct type may contain a *boxed member* by declaring it with type `box`. Example:

```
struct Envelope {
    address account;
    box contents;
}
```

A boxed member has an underlying *unboxed type*, which is an arbitrary struct type and may be different in each message.

### `encodeType`

A boxed member is encoded as `"box " || name`. For example, the above `Envelope` struct is encoded as `Envelope(address account,box contents)`.

### `encodeData`

A boxed value is encoded as its underlying *unboxed value*, i.e., `hashStruct(value) = keccak256(typeHash, encodeData(value))` where `typeHash` corresponds to the unboxed type and `encodeData` is operating on a value of that type.

### `signTypedData` schema

A signature request for an EIP-712 message that involves a boxed member shall include the unboxed type as a part of the message object. A boxed value must be an object with properties `value`, `primaryType`, and `types`. The `value` shall be type-checked and encoded according to `primaryType` and `types`, analogously to an EIP-712 message (though without the `\x19` prefix). The `types` defined in the message outside of the boxed value shall not be in scope for the encoding of a boxed value.

For example, a message for the `Envelope` type above may be represented as:

```js
{
    domain: ...,
    primaryType: 'Envelope',
    types: {
        Envelope: [
            { name: 'account', type: 'address' },
            { name: 'contents', type: 'box' }
        ]
    },
    message: {
        account: '0x...',
        contents: {
            primaryType: 'Mail',
            types: {
                Mail: [
                    { name: 'greeting', type: 'string' }
                ]
            },
            value: {
                greeting: 'Hello world'
            }
        },
    }
}
```

#### JSON Schema of a boxed value

```js
{
  type: 'object',
  properties: {
    value: {type: 'object'},
    primaryType: {type: 'string'},
    types: {
      type: 'object',
      additionalProperties: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            name: {type: 'string'},
            type: {type: 'string'}
          },
          required: ['name', 'type']
        }
      }
    }
  },
  required: ['value', 'primaryType', 'types']
}
```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
