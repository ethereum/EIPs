---
eip: <to be assigned>
title: Consensus Level
author: Kevin Owocki <kevin@gitcoin.co>
discussions-to: <TODO-ETHMagicians Thread>
status: Draft
type: <Informational>
category: N/A
created: 2019-04-04
requires: EIP-1
replaces (*optional): None
---


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This EIP adds a new field to the EIP template called 'Consensus', in which EIP authors can point to evidence that their EIP has achieved a level of consensus in the Ethereum community.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This EIP adds a new field to the EIP template called 'Consensus', in which EIP authors can point to evidence that their EIP has achieved a level of consensus in the Ethereum community.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
As the Ethereum community moves from simply discussing technical EIPs to a wider unvierse of EIPS, there will inevitably be debate as to whether EIPs are good for Ethereum.

The community is not very good at measuring consensus for EIPs that have achieved other than 100% consensus.  This EIP aims to correct that by putting the onus on EIP authors to measure consensus across as broad a swath of the community as possible, and to enter that information into the EIP.

As the old saying goes "If you can measure it you can manage it".  We believe that beginning to measure this signal will be an important step forward in Ethereum community's ability to self assemble.


## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
All new EIPs should now fill out the 'Consensus' field of the EIP template.  


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
I believe that this EIP is the minimum viable process for formalizing the measurement of consesnsus into the existing EIP process.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This EIP does not need backwards compatability.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
N/A

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
N/A

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
