---
sip: 83
title: Total Issued Synths (Debt pool) Snapshots
status: Implemented
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125), Anton Jurisevic (@zyzek)
discussions-to: https://research.synthetix.io/t/sip-83-total-issued-synths-debt-pool-snapshots/190

created: 2020-08-31
requires: https://sips.synthetix.io/sips/sip-84
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

This SIP proposes to implement a mechanism to calculate and store a snapshot of the total issued synths
(total debt pool) value for minting, burning and claiming rewards to significantly reduce the cost of these transactions.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

We propose to add the ability to create a snapshot of the system's debt pool and total issued synths that can be
calculated on-chain, where the gas costs are paid by the invoking account, and used for subsequent minting, burning and
reward claiming. The recomputation of the system debt pool will be managed by three distinct processes:

1. Public functions to save or update a snapshot of the total system debt at current prices.
2. On each synth exchange, minting, or burning operation the debt snapshot will be updated with the debt deltas of the involved synths.
3. Periodic recomputation of the overall debt by minters rather than by keepers.

Together these will ensure that the on-chain total system debt does not diverge far from its true value without having
to expensively recompute total system debt on every mint, burn, or transfer.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

In order to enable minting, burning and claiming rewards the system needs to know the size of the debt pool and the
user's collateral ratio, calculating this value is expensive and contributes to the cost of each mint and burn transaction.
This is because each time the system must read the price and amount of every synth in the system, currently 40+.

The current size of the debt pool is calculated as:

\\[ Debt pool = \sum{Synths Total Supply * Synth Price}\\]

Not only does this cost increase linearly with the number of synths in the system, it also necessitates retrieving
the latest prices, timestamps, and total supplies of each synth from external contracts, rather than being able to read
them all from the current `ExchangeRates` contract.

In the current gas environment minting, burning and claiming costs can reach \$50 USD+ per tx or higher, with the
migration to external oracles this could rise by 50-100% (See [SIP 84](sip-84.md)).
The projected cost of reading all 40+ synth prices on-chain from external oracles to calculate the debt pool on each
transaction is `~800,000 gas` providing a huge reduction for stakers on Synthetix to issue, burn and claim rewards.

About 70% of the gas costs are spent in calculating the total size of the debt pool during minting, burning and claiming
rewards. Saving a snapshot of the debt pool allows subsequent minting and burning transactions to rely on
this precomputed value, saving the multiple contract calls and calculation.

This would reduce the bottleneck of increasing gas costs when new synths are added and allow Synthetix protocol to
onboard many more liquid synthetic assets such as sOIL and commodities in the future.

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

#### System Debt Caching

To solve the problem of requiring every minting, burning and claiming rewards transaction to read 40+ synth prices from
external oracles, the debt pool snapshot will allow the total system's issued synths value to be re-used for calculating
how much debt and the relative % shift someone is issuing / burning based on the debt pool snapshot.
As a system-wide value, the snapshot will be stored in the flexible storage contract described in [SIP 64](sip-64.md).

The debt pool snapshot captures the current synth prices and supplies at the time of the snapshot and removes the need
to retrieve latest data on every operation, relying on the fact that Synthetix exchanges involve repricing one synth
into another based on their respective USD prices.

We propose the addition of public functions that can be called to update the debt pool snapshot, with the caller
paying the gas to execute the on-chain cost of reading the latest synth prices from external oracles and updating the
debt pool snapshot value. By frequent calls to these functions, the debt pool snapshot can be kept arbitrarily accurate.
Although they could be expensive to execute by themselves, these functions will provide a great deal
of utility for subsequent minting and burning transactions that can read the cached value cheaply.

To ensure that the liveness of the debt pool snapshot, a view will be exposed that reports the current
`totalIssuedSynths` value and debt pool by reading the synth's prices and `synth.totalSupply` as occurs whenever the
system debt is currently computed. An acceptable deviation between this reported system debt and the cached value will
be established at an initial value of `2%`. It may be useful in the future to reward the caller of this function
if an invocation corrects a deviation that exceeded this bound.

This will be monitored by a keeper bot paying for the gas to update the snapshot whenever the cached value breaches
the acceptable deviation, up to a maximum update frequency. In order to save on gas, the keeper will have the option
of only updating the debt contributions of a minimal subset of synths that would bring the total system debt snapshot
back under the acceptable deviation, as there may be many synths whose contributions are negligible, and this facility
would be useful in the case that an individual synth price moves dramatically by itself.

The bot could also monitor the mempool for upcoming prices and pre-calculate the new `totalIssuedSynths` values to
detect if it needs to update the debt pool snapshot after.

#### Liveness

To ensure that the debt pool snapshot is not stale, there will be a staleness check on the last `timestamp` of when a
complete debt pool snapshot was last computed. Minting, burning and claiming rewards will revert if the debt pool
snapshot is stale until it has been updated.

The staleness period will be initially set to `60 minutes` and will be configurable via an SCCP.

An additional point is that Synthetix already tracks whether the rates being supplied to the system are individually
stale, or have been invalidated by chainlink warning flags (see [SIP 76](sip-76.md)). Currently, if any synth price is
invalid at the time of a system debt calculation, the operation that triggered it will fail. Therefore system debt
updates must also cache in flexible storage the validity of the debt snapshot in order to maintain this safety check.
As such any keeper bots performing the work of updating the system snapshot should monitor the validity of each
synth rate, and trigger a snaphot if any rate falls invalid, to protect the system. With moves towards a generalised
compensated keeper framework, triggering a snapshot when the system must be frozen may come with a reward.

The debt snapshot function being public and unrestricted also means that, upon an invalid rate being fixed,
the debt snapshot can be immediately recalculated by any account in order to re-enable dependent operations.

#### Mint, Burn, & Exchange Debt Delta Adjustments

Utilising a debt pool snapshot could expose frontminting opportunities when there are large price shifts observed on the
debt pool's underlying synths such as the ETH / BTC prices moving.
It is worth noting that frontminting mitigation strategies were implemented in [SIP40](./sip-40.md) in the form of a
24-hours mint and burn lock. This value can be increased via an SCCP to `48+ hours` to further reduce the frontminting
opportunities until continuous rewards are implemented.

However, to ensure that such front-minting opportunities are minimised, and that the debt deviation keeper needs to
execute as infrequently as possible, the debt will also be adjusted whenever synth supplies change.

This is simple in the case of minting and burning; when these operations occur, the debt pool snapshot will be updated
with the amount of sUSD that is issued or burned as the issuance / burning of sUSD debt will change the
debt pool size but not require latest prices to be retrieved.

When exchanges between non-sUSD synths occur, the prices are already retrieved to
perform the exchange, but we will additionally retrieve the post-exchange total supplies of the involved non-sUSD
synths to compute their total sUSD-denominated value. The delta between these value and the previously-computed ones
will be applied to the total debt snapshot, and the new values cached to be used next time an exchange of those
synths occurs.

In this way the current debt snapshot will be responsive to the latest price updates of those synths which are most
frequently used, and the public keeper function will ideally only need to be invoked at times of extreme synth price
volatility or heavy network congestion. This system will assist in protecting against front minting attacks,
but if it proves to keep the debt snapshot accurate enough, then its constant-time execution cost implies
that an unbounded number of synths could be added to the system.

#### Phase 2: Amortised Minter Debt Recomputation Levy

The debt snapshot keeper is the least technically complex solution to the debt calculation problem posed in this
SIP, and is a useful safety mechanism for protocol participants to protect the system if required, but ideally
no keeper functions would be required to maintain the integrity of the Synthetix debt pool.

Therefore in a future phase of the implementation it will be expedient to allow a full debt snapshot to occur at periodic
heartbeats once every 15 minutes, for example.
These heartbeats could either be computed by a separate compensated keeper function, or at the first mint, burn, or
claim operations to be performed after a given heartbeat is due. However, given the extra expense involved, the gas cost
of the recalculation will be measured and rebated to the caller from a common pool of ether held in a manner similar to the
[deferred transaction gas tank](sip-79.md). This pool will be replenished by a small fee charged on the 
execution cost of each mint, burn, and claim operation, which will be less than the gas saved for these function calls
by eliminating continual system debt recomputations.
As the number of snapshot-dependent operations occurring greatly exceeds the number of heartbeats required per day even
at one heartbeat every 15 minutes, the size of the levy will be modest, still representing a great savings for
all participants in the system.
Since the number of heartbeats per day at a given frequency is constant, any increase in system usage
allows the gas charge to be decreased, or the heartbeat frequency to be increased.


### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The rationale of the debt pool snapshot value is the ability to capture a snapshot of all the synths prices and their
respective synth's totalSupply (collectively as the `totalIssuedSynths`) for the purposes of minting, burning and
claiming rewards.

The snapshot is updated when minting and burning sUSD synths as sUSD synths don't require a new price update but is a
basic addition / subtraction to the last snapshot value.

Having a public function that reads the latest prices and synth total supply on-chain and writes the new debt pool
snapshot also provides a decentralised mechanism for the snapshot value to be executed on chain.
Initially there will be no incentives to run this transaction to update the snapshot, future iterations of the debt pool
snapshot update could rely on funds contributed by SNX stakers on each minting and burning transaction as there is a
very high utility for them in gas savings.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

- `uint debtPoolSnapshot` Snapshot value of all the circulating `synths supply * synth prices` (in \$USD) at the last snapshot, taking into account the contributions from mint, burn, and exchange operations since the last snapshot. Wherever `Issuer._totalIssuedSynths` is currently used, the snapshot will be substituted instead of a freshly-computed value.

- `uint snapshotTimestamp` Timestamp of the debt pool snapshot: Updated when `Issuer.updateDebtPoolSnapshot()` is executed but not updated when mint, burn, or exchange transactions update the snapshot value.

- `bool debtPoolSnapshotIsInvalid` True if and only if any rate involved in the computation of the cached debt pool snapshot (and SNX) was reported as invalid at the time of the snapshot. `Issuer._totalIssuedSynths` currently reports this value freshly-recomputed at each invocation, the new implementation should return the cached value instead.

- `Issuer.updateDebtPoolSnapshot()` Public function that updates the `debtPoolSnapshot`, `snapshotTimestamp`, and `debtPoolSnapshotIsInvalid` to their latest values.

- `Issuer.updateDebtPoolSnapshotForCurrencies(bytes32[] currencyKeys)` Public function that operates like `Issuer.updateDebtPoolSnapshot()`, but only accounts for the contributions of the provided currency keys. This may set `debtPoolSnapshotIsInvalid` to true, but not set it back to false, which requires a full recomputation of the system debt snapshot.

- `Issuer.totalIssuedSynths()` Current view function to get latest total issued synths and debt pool size. Used by bot to view and calculate the % deviation between last snapshot and the current actual `totalIssuedSynths()`. Excludes any of the EtherCollateral backed synths generated as not backed by SNX collateral.

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

| Parameter | initial Value |
| --------- | ------------- |
| Debt snapshot stale time | 60 minutes |
| Debt snapshot max deviation | 2 percent |

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
