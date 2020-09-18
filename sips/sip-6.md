---
sip: 6
title: Frontrunning protection
status: Implemented
author: Jackson Chan (@jacko125), Kain Warwick (@kaiynne), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/kPPKsPb
created: 2019-06-27
updated: 2019-07-09
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Frontrunning bots have been exploiting the oracle service to read the next update and insert a transaction ahead of the update to create essentially risk-free profits.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The oracle is currently vulnerable to front-running. There are several measures in place to ensure that profitability from this is as low as possible, but more sophisticated bots have been written recently that have a much higher probability of profiting. In order to protect the system, we have implemented a mechanism where if the oracle detects it is being front-run it will front-run the front-runner with a tx to change the exchange fee rate to 99%. This is a credible threat to attempts to front-run the system to ensure even if they are profitable for a period there is a high likelihood they lose everything if the oracle detects this activity. There is the potential for collateral damage if a genuine trader executes a trade in the same block, but we are implementing protections against this so that a user can specify a fee rate above which the tx will be rejected. We expect to have this implemented soon.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
In order for the system to remain viable, traders must not be able to frontrun the oracle. This feature ensures that there is a strong penalty for doing so that ought to discourage attempts to frontrun.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
The oracle code is currently closed source, so we will not be publishing the exact spec of the mechanism. But above certain thresholds, if a bot executes a tx at a higher gwei than the oracle in the same block, the oracle will escalate to push an even higher gwei transaction to raise the exchange fee to 99% then restore the exchange fee rate back to its original setting.

UPDATE: We have modified the specification and are putting this SIP back into Proposed status, the Oracle will now call a non-public function setProtectionCircuit which will burn the entire balance of the trade rather than sending it to the fee pool. This mechanism is far more robust and targeted and should reduce potential collateral damage as it specifically allows the oracle to flag a single transaction and implement this function against only that transaction.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
We have implemented several soft mechanisms to reduce the profitability of frontrunning over the last few months, and we plan to introduce more, but without a credible threat to profitability it is still the optimal strategy for bot developers to attempt to attack the system if the only penalty is reduced profits. If there is a risk of total loss of funds, this changes the strategic outlook for a potential bot developer significantly.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
N/A

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
N/A

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
