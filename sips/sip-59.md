---
sip: 59
title: Delegated Migrator
status: Proposed
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-05-11
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

The addition of the Delegated Migrator contract to add transparency and community voting on protocol upgrades.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

The introduction of the Delegated Migrator contract to perform upgrades on-chain in one or more steps. Migration scripts, once proposed and after a waiting period has elapsed, can be executed by the protocolDAO which will delegate ownership to the migration contract for the duration of the transaction. However, during the waiting period, the community can vote to reject any proposal.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Synthetix protocol upgrades are currently performed in a faily complex manner. Each release, the core contributors run through the [publisher script](https://docs.synthetix.io/contracts/publisher/) which determines which new contracts need deploying and which owner actions are required to connect them together. The system is suspended by the protocolDAO, the owner actions are staged and executed by the protocolDAO, and then the system is resumed.

There are a number of issues with this approach:

1. **Opaque**. The upgrade process is hard to reason about - when an upgrade is coming, the community cannot clearly see what on-chain changes are coming in the upcoming release.
2. **Centralised**. The protocolDAO dictates what changes are coming to the protocol, and the remainder of the community have no agency on-chain with which to approve or reject these changes.
3. **Slow**. Upgrades require numerous transactions to be performed by the protocolDAO. Not only is this time consuming for the protocolDAO members, it also means more downtime for the protocol itself.

As such, in an effort to fully decentralise the Synthetix protocol, this SIP proposes limiting the protocol upgrades to only those performed on-chain by a contract readable by anyone, and with a reasonable time delay for community participants to reject the proposal by on-chain vote.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

In principle the idea is as follows:

1. A contract is created, called the `DelegatedMigrator`, which is nominated and accepts ownership over all Synthetix contracts. It implements `IDelegatedMigrator` (interface below). The sole exception is the `SystemSettings` contract from [SIP-64](./sip-64.md), it will remain owned by the protocolDAO to continue to perform SCCP updates without requiring the use of the Delegated Migrator .
2. The owner of this `IDelegateMigrator` contract is the [protocolDAO](https://etherscan.io/address/protocoldao.snx.eth)
3. This migrator then allows the submission of proposals, in the form of a contract address. Each proposal must conform to `IMigration` (see below).
4. After a waiting period has expired for a proposal, `execute` may be invoked by the protocolDAO sequentially for each step in the migration.
5. If at any point during the waiting period a configurable percentage of token holders vote to veto the upgrade proposal via `reject` it will not proceed. The specific details of this voting process are TBD.

```solidity
interface IMigration {
    // Views
    function numOfScripts() external view returns (uint);

    // Mutative functions
    function migrate(IAddressResolver resolver, uint256 index) external;
}

interface IDelegatedMigrator {
    // Views
    function waitingPeriodSecs() external view returns (uint);

    // Mutative functions
    function propose(string version, IMigration target) external; // onlyOwner

    function reject(string version, IMigration target) external; // onlyTokenVote

    function execute(string version, IMigration target, uint index) external; // onlyOwner

    function setTokenVote(address tokenVote) external; // onlySelf (i.e. only via a migration script)

    function setWaitingPeriodSecs(uint secs) external; // onlySelf (i.e. only via a migration script)
}
```

#### Example Migration Contract

```solidity

import "synthetix/contracts/interfaces/IAddressResolver.sol";

// Example Migration script
contract AtlairUpgrade is IMigration {

    function numOfScripts() external view returns (uint) {
      return 1;
    }

    function migrate(IAddressResolver resolver, uint256 index) external {
      require(index < 1, "Invalid migration script index");

      migrate0(resolver);
    }

    function migrate0(IAddressResolver resolver) internal {
      Proxy synthetixProxy = resolver.getAddress("ProxySynthetix");
      synthetixProxy.setTarget(0x00000000000000000000000000000000000000000);

      Synthetix synthetix = resolver.getAddress("Synthetix");
      // etc.
    }

}
```

In order to integrate with the current Synthetix release process, the aforemented publisher script would be configured to output a migration contract, which would then be committed to mainnet, verified and submitted as a proposal.

> ### Future Improvements
>
> 1. For the initial phase of this migrator, the suggestion is to limit invocations of `execute()` to the `owner`. This is to prevent any confusions for the core contributors during partial upgrades (which take more than a single transaction). In the future however, we envisage that `execute()` will be callable by anyone.
> 2. Additionally, the eventual aim is to have `propose()` also callable by anyone. This would then require approval by vote rather than veto by vote as suggested above. This is something to look at in future iterations of the migrator.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

There will be a configurable time delay between when a proposal has been accepted and when execution can begin. This time delay exists to allow the network to review the proposed upgrade.

> Note: all migration contracts and any associated contracts must be verified on Etherscan _before_ proposing so that the community can review them appropriately once proposed.

If the holders do not agree with the upgrades, they may vote to reject the proposal. Morever, if the proposal is not verified on Etherscan (or some other verified source), then the community should simply reject the proposal.

The migration may take multiple steps (in the case where the migration requires more than the 10M block gas limit to complete, meaning in those cases that the migration isn't atomic).

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- When a proposal is added, if it does not conform to `IMigration`, then fail the transaction
- When a migration is executed, if there is no accompanying proposal, if the waiting period has not elapsed, or if it has been rejected by token vote, then fail the transaction
- When a migration step is executed, if there is no such index in the migration, fail the transaction
- When a migration step is executed, if its preceeding step has not been executed, fail the transaction
- When a migration step is executed, if it passes the preceeding checks, then execute the migration step via delegate call (thus as the owner of the Synthetix protocol)

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TBD

## Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

- The time delay between the addition of a proposal and it's potential execution: `IDelegatedMigrator.waitingPeriodSecs`

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
