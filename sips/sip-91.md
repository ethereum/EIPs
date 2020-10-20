---
sip: 91 
title: Debt Cache Contract
status: Proposed
author: Anton Jurisevic (@zyzek)
discussions-to: https://research.synthetix.io/t/sip-91-debt-cache-contract/213

created: 2020-10-20 
requires (*optional): 83
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Separates the debt snapshot logic out of `Issuer`, and into a new `DebtCache` contract.

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

This SIP proposes adding a new `DebtCache` contract, along with a `RealtimeDebtCache` implementation
inheriting `DebtCache`, which will be used on L2 where debt snapshots are not required.
All debt cache related functions that currently exist in `Issuer` will be moved into the new contracts.

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

The modifications applied in [SIP-83](sip-83.md) to cache the total system debt increased the size of the `Issuer`
contract to the point that its compiled bytecode was too large to be deployed on the L2 OVM. As the L2 
deployment of Synthetix has no execution costs, debt snapshots are unnecessary in this context.
By separating out the snapshot logic, the `Issuer` and `DebtCache` contracts will individually fit into the
contract size limit on L2, and the `DebtCache` itself can be individually replaced with a `RealtimeDebtCache`
version which does not require cache synchronisation.

This structure will also allow debt cache logic to be upgraded without modifying the `Issuer`, which when
redeployed requires a time-consuming process of re-adding all Synths to the system.

## Specification
<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Although in principle one could simply replace the entire `Issuer` contract with a different version for L2,
this would require modifying the internal structure of that contract, and entail multiple versions of the
core debt snapshot code to exist. This would increase the overhead of making contract modifications in the
future. By separating out the logic into a new contract, this overhead is reduced, and the Issuer contract's
size is brought down much further below the fundamental size limits imposed by the OVM, allowing more headroom
to extend its functionality.

Many functions will be renamed in this refactor; although in many cases no functionality will change, these
modifications to the interface are in service of making it clearer, more consistent, and more complete.

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

`Issuer` will no longer be responsible for maintaining the debt cache, but will instead pass this responsibility on to
the new `DebtCache` contract.

#### Interface Modifications

The following functions, and a number of supporting internal functions will be moved from the `Issuer` and into a
new contract called `DebtCache`. These functions will be renamed to clarify the resulting interface. Several new functions
will added to round out its functionality and simplify the implementation.

| `Issuer` Function | `DebtCache` Function | Description | 
| ----------------- | -------------------- | ----------- |
| `debtSnapshotStaleTime` | `debtSnapshotStaleTime` | Reports the current snapshot stale time. |
| `currentSNXIssuedDebtForCurrencies` | `currentSynthDebts` | Reports the debt values for a set of synths at current prices and supply. |
| `cachedSNXIssuedDebtForCurrencies` | `cachedSynthDebts` | Reports the cached debt values for a set of synths. |
| `currentSNXIssuedDebt` | `currentDebt` | Reports the current total system debt value across all synths. |
| `cachedSNXIssuedDebtInfo` | `cacheInfo` | Reports the cached system debt, when a snapshot was last taken, and the cache's invalidity and stale status |
| `cacheSNXIssuedDebt` | `takeDebtSnapshot` | Takes completely fresh debt snapshot, updating the cache, timestamp, and validity status. |
| `updateSNXIssuedDebtForCurrencies` | `updateCachedSynthDebts` | Modifies the cached debt value with the deltas from a specific set of synths. |
| `purgeDebtCacheForSynth` | `purgeCachedSynthDebt` | Admin function to purge the cached value of a specific Synth if it was not added/removed from the system properly after an upgrade. |
| `updateSNXIssuedDebtForSynth` | `updateCachedSynthDebtWithRate` |  Allows the issuer and exchanger contracts to update a synth's cached debt without refetching its price |
| `updateSNXIssuedDebtOnExchange` | Deleted | Exchange-specific logic will be moved into the `Exchanger` contract; the same functionality will be implemented with the new `updateCachedSynthDebtsWithRates` function. |
| None | `updateCachedSynthDebtsWithRates` | As `updateCachedSynthDebtWithRate`, but for a set of synths. |
| None | `updateDebtCacheValidity` | Allows the issuer to invalidate teh cache when adding or removing synths. |
| None | `cachedDebt` | Reports the cached system debt. |
| None | `cacheTimestamp` | The timestamp that the cache was last refreshed with a full snapshot. |
| None | `cacheInvalid` | True if the cache has been invalidated by, or since, the last full snapshot. |
| None | `cacheStale` | True if the cache timestamp is older than the stale time. |

The `DebtCacheSynchronised` event will be renamed to `DebtCacheSnapshotTaken`.

In addition, the issuer itself will also gain a new function, `Issuer.synthAddresses(bytes32[] memory currencyKeys) returns (ISynth[] memory)`,
which will be used by the debt cache to obtain several synth addresses in a single function call in order to fetch the
total supply of each.

#### Flexible Storage Removal

To simplify implementation, offset the gas cost of the additional function call, the cached debt values will be stored in
the debt cache contract itself rather than in flexible storage.
There is less of a necessity to persist this information since it no longer rides along with the issuer, but in addition
storing the cache in the contract will decrease gas consumption for any account calling
`takeDebtSnapshot`, which will improve gas costs for the snapshot keeper, which must run regularly to keep the
debt snapshot from going stale.

#### L2 Realtime Debt Cache

On L2 `DebtCache` will be replaced by `RealtimeDebtCache`, which is a drop-in replacement that shares an identical
interface; but its semantics will be altered as follows:

* `cacheInfo` will report realtime values from `currentDebt` for the debt and invalidity. The cache timestamp will always report as the current block timestamp, and the cache will never be stale.
* `cachedSynthDebts` will report realtime values from `currentSynthDebts`.
* All mutative functions in the interface such as `takeDebtSnapshot` will become no-ops.

#### Issuer Multiple Synth Addition/Removal 

While the `Issuer` is being modified, functions to add and remove multiple Synths at once will also be added,
which will speed up redeployments of the `Issuer` (among other operations) by batching Synth migrations rather
than performing them one by one.

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases are included with the implementation in [its pull request](https://github.com/Synthetixio/synthetix/pull/811).

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
