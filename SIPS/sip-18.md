---
sip: 18
title: Recover orphaned $2.9k sUSD from SNX fee address
author: Nocturnalsheet (@nocturnalsheet), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/CDTvjHY
status: Implemented
created: 2019-09-02
---


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This SIP proposes to recover the $2.9k sUSD that is currently unclaimable by minters in the SNX [fee address](https://etherscan.io/address/0xfeefeefeefeefeefeefeefeefeefeefeefeefeef)

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
There is currently ~$2.9K sUSD orphaned from the transfer fee era where each transfer of synths has to pay a transfer fee. After the upgrade to store fees in XDRs, the collected fees in sUSD were orphaned and minters are not being able to claim those fees.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The $2.9k sUSD ultimately belongs to minters who have staked and contributed to the SNX system and we should not deny their rightful claim to it, even if most of the current minters may not be aware or know about this issue. This $2.9k sUSD fee rewards is now only a small portion of the total fee rewards but it was the entire rewards for minters back in the day so we should work to resolve and recover this orphaned $2.9k sUSD       

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
2 possible options:
1) Exchange the $2.9K from sUSD into XDR and send it back to the 0xfeefeefee address and record it in FeePool.recentFeePeriods.feesToDistribute - allowing minters to claim as part of their weekly rewards
2) Fee pool owner to burn the $2.9k sUSD from 0xfeefeefee address, removing it from global debt

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The orphaned $2.9k sUSD may be a small amount but it still contributes to the global debt and being orhpaned also means that they are not able to go into synths supply circulation for usage. 
 
## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Replicate sending $3K sUSD on KOVAN to the 0xfeefee address and test the recoverFees() function

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Implement a FeePool.recoverTransferFees() public function. 
- It will burn the balance of sUSD at the 0xfeefee address 
- then issue the effective value of XDRs at the 0xfeefee address. Essentially the reverse of the _payFees() function.
- Call the feePaid(XDR, sUSDBalance) function to record the fees to distribute.

UPDATE: Here is the MAINNET transaction recovering lost sUSD fees to XDRs for claiming. 
https://etherscan.io/tx/0x54394af66ae7810f2114da8a02749d71b659a4409c7a98814644d1b04372edcb

The function FeePool.recoverTransferFees() can now be depricated from the codebase.




## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
