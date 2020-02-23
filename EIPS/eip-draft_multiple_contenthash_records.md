---
eip: <to be assigned>
title: Multiple contenthash records for ENS
author: Filip Štamcar (@filips123)
discussions-to: https://github.com/ethereum/EIPs/issues/2393
status: Draft
type: Standards Track
category: ERC
created: 2020-02-18
requires: 1577
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This EIP introduces support for multiple `contenthash` records for ENS. It allows hosting a website on multiple distributed systems and accessing it from the same ENS domain. It is an extension of the EIP 1577.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Many applications are resolving ENS names to content hosted on distributed systems. To do this, they use `contenthash` record from ENS domain to know how to resolve names and which distributed system should be used.

However, the domain can store only one `contenthash` record which means that the site owner needs to decide which hosting system to use. Because there are many ENS-compatible hosting systems available (IPFS, Swarm, recently Onion and ZeroNet), and there will probably be even more in the future, lack of support for multiple records could become problematic. Instead, domains should be able to store multiple `contenthash` records to allow applications to resolve to multiple hosting systems.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

A resolver SHOULD store `contenthash` records in `mapping`, containing `protoCode` as key and whole `contenthash` (including `protoCode`) as value. Default `contenthash` SHOULD be stored as empty `bytes` key. Alternatively, it MAY use other storage types, but public interface MUST be the same as described in this EIP.

Setting and getting functions MUST have the same public interface as specified in EIP 1577. Additionally, they MUST also have new public interfaces introduced by this EIP:

* For setting a `contenthash` record, the `setContenthash` MUST provide additional `proto` parameter and use it to save the `contenthash`. When `proto` is not provided, it MUST save the record as default record.

  ```solidity
  function setContenthash(bytes32 node, bytes calldata proto, bytes calldata hash) external authorised(node);
  ```

* For getting a `contenthash` record, the `contenthash` MUST provide additional `proto` parameter and use it to get the `contenthash` for requested type. When `proto` is not provided, it MUST return the default record.

  ```solidity
  function contenthash(bytes32 node, bytes calldata proto) external view returns (bytes memory);
  ```

* Resolver that supports multiple `contenthash` records MUST return `true` for `supportsInterface` with interface ID `0x6de03e07`.

Applications that are using ENS `contenthash` records SHOULD handle them in a specific way:

* If the application only supports one hosting system (like directly handling ENS from IPFS/Swarm gateways), it SHOULD request `contenthash` with a specific type. The contract MUST then return it and application SHOULD correctly handle it.

* If the application supports multiple hosting systems (like MetaMask), it SHOULD request `contenthash` without a specific type (like in EIP 1577). The contract MUST then return the default `contenthash` record.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The proposed implementation was chosen because it is simple to implement and supports all important requested features. However, it doesn't support multiple records for the same type and priority order, as they aren't so important and are harder to implement properly. To implement them, a different way of implementation would need to be used.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

The EIP is backwards-compatible with EIP 1577, the only difference is additional overloaded methods. Old applications will still be able to function correctly, as they will receive the default `contenthash` record.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

Automatic Truffle tests have also been written along with new contract code. However, additional manual tests are also needed.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

Implementation of the smart contract, as well as automatic tests, are written in [`ensdomains/resolvers#30`](https://github.com/ensdomains/resolvers/pull/30).

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->

There SHOULD NOT be any security problems with this EIP. However, it SHOULD still be audited to check for any possible issues with using `mapping` and `bytes` for storage, and overloading methods, as well as other implementation-related features.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
