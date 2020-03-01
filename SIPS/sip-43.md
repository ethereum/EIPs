---
sip: 43
title: Address Resolver
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: <Discord Channel>

created: 2020-02-28
---

## Simple Summary

Add a new `AddressResolver` contract for smart contract lookups.

## Abstract

Add an `AddressResolver` contract stores the addresses of all interoperable smart contracs within the Synthetix protocol, and provide access to this resolver in all smart contracts that need to communicate with the others.

## Motivation

The Synthetix protocol is supported by a fairly complicated network of smart contracts. However, due to the limits put on smart contracts sizes by the EVM (see [EIP-170](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-170.md)) only so much logic and state can fit into a single contract. Moreover, to reduce the need to upgrade key contracts and to provide better adherence to the single-responsiblity-principle, having more smaller, single-purpose contracts is preferable.

In order to facilitate this intercontract communication, a contract respository (based on the Service Locator pattern) is the most robust and bytecode efficient solution.

## Specification

The `AddressResolver` needs a mechanism with which to `import` mulitple addresses, and this needs to be restricted to the `owner`. This import should be mutative, such that any subsequent imports of the same `name` will simply overwrite previous versions.

It will be the responsibility of the deployment (and eventually migration contracts) to ensure that new addresses are imported after they are deployed.

The keys of this repository will be `bytes32` encoding of the existing contract names, which are all described in our [list of addresses](https://docs.synthetix.io/addresses/) in the documentation.

Every contract that wishes to use the `AddressResolver` will need to inherit from `MixinResolver` (by leveraging multiple inhertance, we an think of this functionality as being a mixed into the target contract).

## Rationale

We analyzed how others have approached this task - in particular Colony's implementation of an address lookup system. Ours is somewhat different in that it simply needs to store contract names and allow simple lookup. Seeing as we already have a system in place to uniquely identify contracts by a `string` name - converting these to `bytes32` seems the most straightforward and gas efficient.

## Test Cases

See https://github.com/Synthetixio/synthetix/pulls/383

## Implementation

See https://github.com/Synthetixio/synthetix/pulls/383

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
