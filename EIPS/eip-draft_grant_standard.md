---
eip: <to be assigned>
title: ERC888 Grant Standard
author: Arnaud Brousseau (@ArnaudBrousseau), James Fickel (@JFickel)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2019-04-30
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
This document outlines a standard interface to propose, vote on, and distribute grants.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
TODO

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
TODO:

* what kinds of solutions are out there already?
* why do we need a standard? (e.g. what's the problem with the current status quo?)
* how does having a standard for grants makes the situation better?

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
TODO: that's the meat of it really

* Interface definition with Solidity
* Reasoning on what to leave out of the standard vs what to bake in (what do we want to be immutable?)


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

* What other options did we leave out while designing the interface above?
* Why do we think the current interface is the best?
* Why do we think the parts we left out should be left out?

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->


## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
TODO: write a sample contract with test cases

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
TODO: deploy a contract utilizing the proposed grant mechanism. This is hard. Alternative: standardize on someone else's already-in-use contract. This is easier.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
