---
sip: 26
title: Max Gas on token fallback
status: Implemented
author: Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/3uJ5rAy

created: 2019-10-29
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

<!--A short (~200 word) description of the technical issue being addressed.-->
A bug was reported https://github.com/Synthetixio/synthetix/issues/243
which the position of emit would reduce the gas estimation of trading SNX via uniswap down from 900K to 100K 

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
Solidity passes 63/64 of gas in subcalls and it is burning all this on a failed subcall. 

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Move the emitTransfer to before the callTokenFallbackIfNeeded.

In `ExternStateToken.sol`:
// Emit a standard ERC20 transfer event
emitTransfer(from, to, value);

// If the recipient is a contract, we need to call tokenFallback on it so they can do ERC223
// actions when receiving our tokens. Unlike the standard, however, we don't revert if the
// recipient contract doesn't implement tokenFallback.
callTokenFallbackIfNeeded(from, to, value, data);

Limit the gas to sub calls to either 200K or the amount of gas thats left if it is less than 200K

In `TokenFallbackCaller.sol`:
uint gasLimit = gasleft() < MAX_GAS_SUB_CALL ? gasleft() : MAX_GAS_SUB_CALL;
recipient.call.gas(gasLimit)(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", sender, amount, data));


## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
https://github.com/Synthetixio/synthetix/blob/v2.12.2/contracts/ExternStateToken.sol#L134
https://github.com/Synthetixio/synthetix/blob/v2.12.2/contracts/TokenFallbackCaller.sol#L52

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
