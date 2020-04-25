---
eip: <to be assigned>
title: Non funglible property standard
author: Kohshi Shiba<kohshi.shiba@gmail.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category : ERC
created: 2020-04-25
requires (*optional): 165 721
---

## Simple Summary
Non fungible property standard enables rental or collateralized lending without escrow.
This is an advanced version of the widely accepted ERC721-Non fungible token standard.

## Abstract
The current ERC721 standard prospers where an item is unique such as digital collectibles or tokenized real world properties. 
Although the standard is showing adoption in the market, its specification, token can only deal with simple ownership in which the owner has full authority over its property and no others can transfer tokens, limits the variety of functions around tokens.

For example, collateralized loans or rental without escrow are activities which can be widely seen in the real world. 
However, these are unavailable with ERC721. 
This EIP proposes a novel token standard that realizes these kinds of utilities with other latest improvement proposals that also aim to improve ERC721. 


## Motivation
The main motivation for this proposal is to make rental and collateralizing possible without any escrow. 

With the current ERC721’s design, an owner of a digital item needs to escrow their token in order to use those services. 
This strain limits the user’s utility while escrow. for example, while escrow, users become unable to use most of the applications that grant some rights to users by reference to the mapping of ownership in the ERC721’s contract.

In the real world, people can take out a loan by collateralizing a house while using the house, or borrow cars while the ownership is still in others' hands. Of course, it is still possible to do those cases with ERC721 by adding additional functions on each application, but it is difficult  to gain interoperability because there is no common standard among the ecosystem, and thus such applications are not prevailing as of today. 

This EIP proposal intends to standardize those kinds of utilities as the non fungible property standard. 

## Specification
### Features
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
