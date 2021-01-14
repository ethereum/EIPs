---
sip: 60
title: New Escrow Contract & Migration
status: Approved
author: Clinton Ennis (@hav-noms), Jackson Chan (@jacko125)
discussions-to: <https://discord.gg/ShGSzny>

created: 2020-05-20
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Migrate to a new more flexible SNX escrow contract that supports arbitrary vesting entry lengths, L2 escrow migration and account merging. Allow users to migrate to the new contract and then deprecate the existing reward escrow contract.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

The current SNX [RewardEscrow](https://contracts.synthetix.io/RewardEscrow) contract is limited only allowing the [FeePool](https://contracts.synthetix.io/FeePool) to escrow SNX rewards from the inflationary supply.

It was not designed to be used as a general purpose escrow contract. New requirements include adding arbitary length escrow entries to be created by anyone as well as supporting the new terminal inflation and liquidation.

This will require a migration of all escrowed SNX and escrow entries from the current [RewardEscrow](https://contracts.synthetix.io/RewardEscrow) to new Reward Escrow V2 contract.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

### Current limitations of the `RewardEscrow` contract

1. Only escrows SNX for 12 months.
2. Only `FeePool` has the authority to create escrow entries.
3. The escrow table `checkAccountSchedule` only supports returning up to 5 years of escrow entries from the initial inflationary supply.

### Desired features for a general `SynthetixEscrow` contract

1. Ability to add arbitrary escrow periods. e.g. 3 months to 2 years.
2. Public escrowing. Allows any EOA or any contract to escrow SNX. Allowing SNX to be escrowed for protocol contributors, investors and funds or contracts that escrow some sort of incentive similar to the Staking Rewards.
3. Update `checkAccountSchedule` to allow for terminal inflation and an unlimited escrow navigation through paging.
4. Ability for account merging of escrowed tokens at specific time windows for people to merge their balances - [sip-13](https://sips.synthetix.io/sips/sip-13).
5. Ability to migrate escrowed SNX and vesting entries to L2 OVM. An internal contract (base:SynthetixBridgeToOptimism) to clear all entries for a user (during the initial deposit phase of L2 migration).
6. Enable passing of escrow entry ID to the escrow contract, to allow the Dapps to read escrow entries offline and manage vesting rather than iterating through each entry on-chain.


## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->


### Migration

1. Synthetix contract will need to be upgraded to migrate the SNX from the old escrow contract to the new contract on chain.

2. Claiming rewards and vesting on the new contract will be blocked for users with existing vesting entries who haven't migrated their previous vesting entries.

3. Users with existing vesting entries on the old rewards escrow will need to migrate their vesting entries across to the new contract. The migration will read from the address's existing entries and copy them from the old escrow contract.

4. The gas cost of writing all of these vesting entries to the new contract could be as high as 0.5 ETH per address, given this the proposal is for low SNX balances of less than 1,000 escrowed SNX all vesting entries are wiped and any escrowed SNX for these addresses is immediately available to vest. 

5. For balances over 1,000 SNX any vesting entries beyond 52 weeks will be rolled up into a single entry that is immediately available to be vested.

For the avoidance of doubt, there is no need to vest any escrowed SNX in order to migrate to the new escrow contract.

### L2 Escrow Migration

With the launch of L2 Staking for SNX on the OVM testnet, users will be able to migrate all their SNX and escrowed SNX to L2 for staking and rewards. The vesting entries will be copied onto the L2 reward escrow contract that mirrors the migration process.

1. The `SynthetixBridgeToOptimism.depositAndMigrateEscrow()` transaction will vest any escrowed SNX that can be vested and transfer the remaining `totalEscrowedAccountBalance` SNX amount from the Reward escrow contract into the deposit contract. The vesting entries on L1 reward escrow will be deleted for the address.

2. The L1 migration step is required for stakers to migrate to L2 their escrowed SNX (if they have escrowed SNX on the old escrow contract).

If the user has not migrated on L1 to the new escrow contract, the `SynthetixBridgeToOptimism.depositAndMigrateEscrow()` function will fail.

To prevent an address from migrating their SNX staking to L2 and then duplicating their vesting entries to the new Reward Escrow afterwards, `migrateVestingSchedule()` will fail if the address has already migrated to L2 first.

Fields migrated to L2 Reward Escrow:

```
    escrowedAccountBalance

    And

    struct VestingEntry {
        uint64 endTime;
        uint64 duration;
        uint64 lastVested;
        uint256 escrowAmount;
        uint256 remainingAmount;
    }
```

3. L2 migration is an irreversible action. Escrowed SNX on L2 will need to be vested on L2 first before withdrawing to L1.

### Account Merging

- Require all debt to be burned before account merging is open for a staker.
- Approve and record the recipient / destination address that will claim the new escrow SNX amount and vesting entries.
- The recipient address will sign a transaction to merge the escrowed SNX amount and add to their existing `totalEscrowedAccountBalance` balance and append the vesting entries to their `vestingSchedules`.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
