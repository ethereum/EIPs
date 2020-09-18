---
sip: 19
title: Deprecate Transfer Fee logic
author: Clinton Ennis (@hav-noms), Jackson Chan (@jacko125)
discussions-to: https://discord.gg/CDTvjHY
status: Implemented
created: 2019-09-23
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Remove all Synth token transfer fee logic from the Synthetix smart contracts.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Transfer fees on Synth transfers was removed in February 2019 by setting the transferFeeRate to 0. [See the announcement here] (https://blog.synthetix.io/q1-release-sbtc-and-more/)

This proposal is to remove all transfer fee code from the system to get back code size needed for new logic. It's safe to say transfer fees can be deprecated and the code removed.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Ethereum is limited to deploying smart contracts with compiled bytecode size of 1024kb. Any unused bytecode is taking up precious space so the motivation to remove the transfer fee logic as it is not being used anymore and and wont be re-introduced in the foreseeable future.

Synth transfer fees were initially implemented on the Synth sUSD as a fee for providing the utility of stability. It was found that the transfer fee was a) not generating sufficient revenue to the system and b) creating technical blockers integrating with 3rd party systems.

If a Synth Transfer fees become a requirement in the future, the code is in the github history and the feature could be restored with some code refactoring.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Removal of all transfer fee code, supplementing functions and events emitted from Synthetix.sol, Synth.sol, FeePool.sol

All tests updated to generate fees from exchanges and remove all tests generating fees from transfers.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

[https://github.com/Synthetixio/synthetix/pull/248/files]

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

[https://github.com/Synthetixio/synthetix/commit/05c42daefb282a49f791e7e626e10cf1f8352f36]

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
