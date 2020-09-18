---
sip: 57
title: Permanent Read-only Proxy for Address Resolver
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-05-08
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

A permanent read-only proxy to the latest AddressResolver instance.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Create and maintain a read-only proxy to the latest `AddressResolver` instance. Third party contracts can then reference this proxy in their code and rest assured that thier code will work with future versions of the `AddressResolver`.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Synthetix is a protocol that iterates fairly frequently. Yet we want to provide an immutable avenue for that third party contracts to connect with our infrastructure, even after upgrades.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

To create a minimal version of `Proxy`, called `ReadProxy`, that forwards non-mutable calls to the underlying `target` and returns its results (transacting to mutated functions will fail).

The owner of this `ReadProxy` will be the `ProtocolDAO` and is the only one that can change the `target` of this proxy. The `target` will change only when a new version of the contract is released.

The `ReadProxy` will conform to the current [`IAddressResolver` interface](https://github.com/Synthetixio/synthetix/blob/v2.21.13/contracts/interfaces/IAddressResolver.sol), which is:

```solidity
interface IAddressResolver {

    function getAddress(bytes32 name) external view returns (address);

    // Note ⚠️⚠️⚠️: This is coming in the Altair (v2.22) release of Synthetix
    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);

}
```

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

While we could simply reuse the `Proxy` contract, it's much more powerful than is necessary here, so we propose a simpler and safer read-only version of the proxy for this instance.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- When any view function from `AddressResolver` is invoked on this `ReadProxy` instance, it forwards the request to the `AddressResolver` and returns its response
- When any mutative function call (other than what is in the `ReadProxy`'s ABI directly) is attempted, the transaction will fail
- When the `target` of `ReadProxy` changes, it emits a `TargetUpdated` event.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

See commit [b015b8f5](https://github.com/Synthetixio/synthetix/commit/b015b8f576be630b16dfbb9b978de671878d4917) and corresponding PR [#512](https://github.com/Synthetixio/synthetix/pull/512)

## Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

(None)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
