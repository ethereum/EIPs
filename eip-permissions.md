This is the suggested template for new EIPs.

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

## Preamble

    EIP: <to be assigned>
    Title: Contract Permission Standard
    Author: <list of authors' names and optionally, email addresses>
    Type: Standard Track 
    Category: ERC
    Status: Draft
    Created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
    Requires (*optional): <EIP number(s)>
    Replaces (*optional): <EIP number(s)>


## Simple Summary
A standard service interface to communicate access restrictions on smart contracts. 

## Abstract
Provide a common interface that allows checks to be performed on transactions.  This can be used to build a permission contract that could manages access rights on other contracts. 

## Motivation
There are often many restrictions to smart contracts however there is no common interface to communicate those restrictions.  This leads to adhoc user interfaces being built to prevent users from attempting transactions that would otherwise fail with no explanation.  In the case of an exchange where trading of ERC20 tokens that have restrictions on transfer, the exchange would need to consider the restrictions on each token and display those to the user.  This leads to a bigger burden on the exchange to warn a user of potential restrictions otherwise users will encounter failed transfers.  A common interface on these restrictions could be used to determine if a particular contract call will be allowed.


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
