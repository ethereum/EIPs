---
sip: 13
title: Account Merging
status: WIP
author: Kain Warwick (@kaiynne)
discussions-to: https://discord.gg/CDTvjHY

created: 2019-08-14
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Staking rewards are currently locked for 52 weeks from the date the are claimed, despite being locked they can still be used as collateral. One of the consequences of this is that a staker who has earned rewards in a wallet is forced to continue to maintain this wallet. The purpose of locking these staking rewards was to ensure that they were not able to be transferred, however, this creates a problem if a wallet is compromised or if a user would like to cycle wallets. This SIP proposes a compromise where a staker can transfer the entire balance of their staking rewards to a different wallet.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
A user will be able to specifiy an address to reallocate their staking rewards to. In order to migrate staking rewards the wallet must have a c ratio high enough to allow the SNX to be moved, this is to ensure users to does not migrate escrowed rewards and issue additional debt against them.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
This functionality is important for several reasons, the first is simple user experience. Given the issues with maintaining wallets there are many reasons why a user may want to cycle wallets. The current system makes this impossible without forgoing the right to mint against escrowed SNX. This change will ensure that the SNX ultilisation remains high and that there are not pockets of SNX that are no longer staked because they are in escrowed wallets that are no longer maintained. The second reason is that without this functionality it will be impossible for staking pools to operate effeciently. In order for a staking pool to operate a user must be able to withdraw their SNX and their staking rewards, without this functionality if a staking pool manager stops administering their pool all of the staking rewards would be locked and idle for at least 52 weeks.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
A user will be able to sign a transaction assigning the SNX tokens in the Reward Escrow Contract from the signing wallet to a new wallet. The reassignment process will check to ensure that there is no debt against the SNX tokens being reassigned. Only the full amount of SNX in escrow will be able to be reassigned, partial reasignments will not be possible.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
We initially considered a more full featured tranfer mechanism that merged the total balances of two wallets, however, the effort to build this is significantly larger than the function specified in this SIP, so this method will allow us to implement the change much faster and will place the burden of transferring unlocked SNX onto the user.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The RewardEscrow contract state will need to be migrated to a new RewardEscrow with the added functionality of allowing users to reassign their escrowed SNX reward balance between wallets that they control. It's completley self service. 
1. Alice signs a transaction to reassign the Escrowed SNX token balance to a new wallet she ccontrols
2. Alice signs a transaction to accept the Escrowed SNX token balance reassignment at the new address.
(optional)3. Alice signs a transaction to confirm the Escrowed SNX token balance reassignment at the new address.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
