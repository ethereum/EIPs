---
sip: 17
title: Bytes4 to Bytes32 currencyKeys
status: Approved
author: Jackson Chan (@wacko-jacko), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/CDTvjHY
created: 2019-08-29
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Upgrade type of currencyKeys from Bytes4 to Bytes32.


## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->
Synthetix wants to create new synths with symbols longer than 4 chars. i.e sATOM, sDEFI This is currently not possible
with currencyKeys type defined as Bytes4.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The system was originally built with currencyKeys as Bytes4 to save storage space. However the system requirements have changed to require Symbols longer than 4 charactors for Synths like the DeFI index token sDEFI. 

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->
Change all instances of Bytes4 to Bytes32 in Synth.sol and Synthetix.sol.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
https://github.com/Synthetixio/synthetix/commit/908028f492187bb85dd519db4435d9c1964f8b4c

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
https://github.com/Synthetixio/synthetix/commit/908028f492187bb85dd519db4435d9c1964f8b4c


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
