---
sip: 83
title: Total Issued Synths (Debt pool) Snapshots
status: WIP
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125)
discussions-to: https://research.synthetix.io/t/sip-83-total-issued-synths-debt-pool-snapshots/190

created: 2020-08-31
requires: TBC
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

This SIP proposes to implement a mechanism to calculate and store a snapshot of the total issued synths (total debt pool) value for minting, burning and claiming rewards to significantly reduce the cost of these transactions.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

We propose to add the ability to create a snapshot of the system's debt pool and total issued synths that can be calculated on-chain, where the gas costs are paid by the invoking account, and used for subsequent minting, burning and reward claiming.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

In order to enable minting, burning and claiming rewards the system needs to know the size of the debt pool and the user's collateral ratio, calculating this value is expensive and contributes to the cost of each mint and burn transaction. This is because each time the system must read the price and amount of every synth in the system, currently 40+.

In the current gas environment minting, burning and claiming costs can reach \$50 USD+ per tx or higher, with the migration to external oracles this could rise by 50-100% (See https://github.com/Synthetixio/SIPs/pull/232). This is due to the necessity of retrieving the latest prices and timestamp for each Synth from an external contract/s instead of reading all prices from our current `ExchangeRates` contract. About 70% of the gas costs are spent in calculating the total size of the debt pool during minting, burning and claiming rewards. Providing a snapshot of the total debt pool, calculated as:

\\[ Debt pool = \sum{Synths Total Supply * Synth Price}\\]

allows subsequent minting and burning transactions to rely on the calculated debt pool size value. This would reduce the bottleneck of increasing gas costs when new synths are added and allow Synthetix protocol to onboard many more liquid synthetic assets such as sOIL and commodities in the future.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview

<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

To solve the problem of requiring every minting, burning and claiming rewards transaction to read 40+ synth prices from external oracles, the debt pool snapshot will allow the total system's issued synths value to be re-used for calculating how much debt and the relative % shift someone is issuing / burning based on the debt pool snapshot.

The debt pool snapshot captures a snapshot of all the synths prices (excluding sUSD) at the time and mitigates the need to retrieve latest synth prices everytime, relying on the fact that Synthetix exchanges involve repricing one synths into another based on their respective USD prices.

The projected cost of reading all 40+ synth prices on-chain from external oracles to calculate the debt pool on each transaction is `~800,000 gas` providing a huge reduction for stakers on Synthetix to issue, burn and claim rewards.

The cumulative debt delta allows someone issuing and burning debt to update their % ratio of the debt pool afterwards based on the latest total debt pool snapshot. During a minting and burning transaction, the debt pool snapshot will be updated with the amount of sUSD debt that is issued or burned as the issuance / burning of sUSD debt will change the debt pool size but not require latest prices to be retrieved.

We propose a public function that can be called to update the `debt pool snapshot` and the caller will be paying the gas to execute the on-chain cost of reading the latest synth prices from external oracles and updating the total issued synths / debt pool snapshot value. This function would be monitored and managed by a keeper bot paying for the gas to update.

#### Frontminting mitigation

Utilising a debt pool snapshot could expose frontminting opportunities when there are large price shifts observed on the debt pool's underlying synths such as the ETH / BTC prices moving. Frontminting mitigation strategies was implemented in [SIP40](./sip-40.md) in the form of a 24 hours mint and burn lock. This value can be increased via an SCCP to `48+ hours` to further reduce the frontminting opportunities until continuous rewards is implemented.

#### Keeper Bot

The public function to update the `debt pool snapshot` will require a bot to pay for the gas to read and update the snapshot value on-chain. This function will be expensive to execute but provide a high level of utility for minting and burning transactions that subsequently rely on the snapshot of the synths prices and debt pool size.

As the gas savings are in the vicinity of `~800,000` gas for minting, burning and claiming rewards, it would be possible to have SNX stakers pay a small proportion of the gas when they are minting, burning and claiming rewards towards the incentives to manage the snapshots.

The keeper bot would aim to maintain the debt pool snapshot within a % threshold of current prices and synths total supply but balance the frequency of how often these debt pool snapshots are created.

To ensure that the liveness of the `debt pool snapshot`, the keeper bot would also benefit from having the ability to compute the `current` live `totalIssuedSynths` value and debt pool by reading the synth's prices and `synth.totalSupply` off-chain to determine the % deviation of the last snapshot from the current actual debt pool size (in sUSD terms), before submitting a transaction to update the snapshot.

The bot could also monitor the mempool for upcoming prices and pre-calculate the new `totalIssuedSynths` values to detect if it needs to update the debt pool snapshot after.

#### Liveness

To ensure that the debt pool snapshot is not stale, there will be a staleness check on the last `timestamp` of when the debt pool snapshot was updated. Minting, burning and claiming rewards will revert if the debt pool snapshot is stale until it has been updated.

The staleness period will be initially set to `30 minutes` and is configurable via an SCCP.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The rationale of the debt pool snapshot value is the ability to capture a snapshot of all the synths prices and their respective synth's totalSupply (collectively as the `totalIssuedSynths`) for the purposes of minting, burning and claiming rewards.

The snapshot is updated when minting and burning sUSD synths as sUSD synths don't require a new price update but is a basic addition / subtraction to the last snapshot value.

Having a public function that reads the latest prices and synth total supply on-chain and writes the new debt pool snapshot also provides a decentralised mechanims for the snapshot value to be executed on chain. Initially there will be no incentives to run this transaction to update the snapshot, future iterations of the debt pool snapshot update could rely on funds contributed by SNX stakers on each minting and burning transaction as there is a very high utility for them in gas savings.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

- `uint debtPoolSnapshot` Snapshot value of all the circulating `synths supply * synth prices` (in \$USD) at the last snapshot. Includes any extra sUSD minted or burned since the last snapshot as these are added directly to the total Issued Synths value and debt pool.

- `uint snapshotTimestamp` Timestamp of the debt pool snapshot: Updated when `Issuer.updateDebtPoolSnapshot()` is executed but not updated when minting and burning transactions udpate the snapshot value.

- `Issuer.updateDebtPoolSnapshot()` Public function that updates the debt pool snapshot to latest values

- `Issuer.totalIssuedSynths()` Current view function to get latest total issued synths and debt pool size. Used by bot to view and calculate the % deviation between last snapshot and the current actual `totalIssuedSynths()`. Excludes any of the EtherCollateral backed synths generated as not backed by SNX collateral.

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
