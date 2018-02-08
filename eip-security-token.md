
## Preamble

    EIP: <to be assigned>
    Title: Security Token
    Author: <list of authors' names and optionally, email addresses>
    Type: Standard Track 
    Category: ERC
    Status: Draft
    Created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
    Requires (*optional): <EIP number(s)>
    Replaces (*optional): <EIP number(s)>


## Simple Summary

Tokens can be used to represent ownership of regulated securities that require transfer restrictions.  We propose a common interface to support the case of security tokens allowing user interface designs and other smart contracts to become aware of these restrictions. 

## Abstract

  ...

## Motivation

Although token contracts that implement ERC20 (or other token standards) can implement restrictions by way of checks in the transfer function (throwing an error if they are not met), there is no agreed mechanism to communicate these restrictions.  In the current environment, a transfer would simply fail without reason, leading to ad-hoc mechanisms to communicate these restrictions to the user.  To enable a new economy of regulated security tokens, we need a standard mechanism for, say, an exchange to determine who is allowed to buy a particular token.  
    
## Specification
The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumj, ethereumjs, ...). 

## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.

## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
