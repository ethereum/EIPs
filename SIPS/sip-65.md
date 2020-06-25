---
sip: 65
title: Decentralized Circuit Breaker
status: Proposed
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-06-17
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Integrate a circuit breaker into each exchange, if the price of either Synth being exchanged has changed by more than a specific percentage the Synth will be suspended.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

When any exchange is attempted, prior to executing the exchange the protocol will check to see the price difference on both the source and destination synths since the last exchange of either. If the price difference on either is over a certain threshold (SCCP modifible), then the synth will be suspended (via [SIP-44](./sip-44.md)) and the exchange prevented. It will then be up to the `protocolDAO` to investigate the issue and to activate the synth once again after reviewing the incident.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Both of the major outages of the Synthetix protocol have been the result of an incorrect price being reported via an oracle. The first was the `KRW` case from the Synthetix oracle in June 2019 and was exploited by a bot. The second was the mispricing of silver (`XAG`) to gold (`XAU`) from the Chainlink pricing network in February 2020. Even with robust data integrity checking, both instances reflect situations where multiple failures occurred simultaneously and prices were published that were incorrect and exploitable.

Both of these should have immediately caused the synth to be suspended and unusable until the `protocolDAO` had time to investigate.

Because the debt pool is shared among all `SNX` stakers, and because of Synthetix's _infinite liquidity_ feature whereby 100% of any synth can be traded into the same USD value of any other synth, a mispriced synth could have catastropic consequences for the debt pool - inflating it to a point where the `SNX` collateral was not sufficient to back all outstanding debt.

This change will ensure that at the moment of exploit (trying to exchange one synth to another), a check is performed. Note that `sUSD` is fixed to `1` so by tackling this problem at the `exchange` action we capture the vast majority of the exploits (more on this below).

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

The `Exchanger` contract will be amended to include a new `priceDeviationThreshold` parameter (configurable by SCCP).

Every time an exchange occurs, we will check that both the source and destination synth prices have not changed by more than the threshold. We will then persist these rates as the `lastExchangedRate` for both synths. If there is not `lastExchangeRate` for either synth, the contract will lookup the last three price changes on chain (which is more gas intensive but is a rare edge-case).

The function to check and potentially suspend will be publicly available, so that anyone may invoke it without needing to attempt an `exchange`.

In addition, we need to handle the settlement of a trade (see [SIP-37](./sip-37.md) for more details on trade settlement). Because settlement is called to process some past event (i.e. how much is owed when the price of the oracle after the waiting period ends is taken into account) - we cannot nor would not want to do any suspension during settlement. However, we also cannot leave the trade in an unsettled state and block future user exchanges. As such, we propose to waive any reclaims or rebates in the event that the amount received deviates from the amount that should have been received by more than the `priceDeviationThreshold`.

> There is a remote possibility that an exchange gets in before a spike, fronrunning a real rate change, but by the time the waiting period expires `N` minutes later, a spike occurs, and the exchange is settled with no fee reclaim. As such, the `protocolDAO`, when investigating suspended synths via price spikes, must also look through the unsettled exchanges performed right before the spike and determine the necessary course of action before resuming the synth in question.

Finally, as the suspension is limited to the synth, even in a case of a false positive - where a synth is suspended when it shouldn't be - the only concern is increased downtime for any user to exchange or transfer that synth. It will be on the protocolDAO to investigate and resume the synth after a thorough investigation.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

A cleaner way to solve this problem would be to suspend the system on price updates, not on exchanges. However as Synthetix partially uses decentralized price feeds from Chainlink (and is planning to migrate to them fully in the near term with [SIP-36](./sip-36.md)), it cannot hook into actions from contracts it reads due to the limitations of smart contract interactions.

> Note: a future version of this will instead incorporate upcoming changes in Chainlink Aggregators to read circuit breaker switches from them, instead of having to rely on previous prices from exchanges.

In the meantime, checking at the moment of exchange is the optimal strategy. Unfortunately this means slightly more gas for the user, which in the current climate is a difficult decision, but necessary to prevent collapse of the system.

In order to reduce gas as much as possible, this SIP proposes to store a `lastExchangeRate` mapping locally on `Exchanger` and use that as the source of truth, rather than looking back through `ExchangeRates` for some amount of predetermined time to determine if an invalid price occurred.

### Caveats

1. Imposing the suspension on a user's `exchange` will incur slightly more gas cost per successful exchange (~5%). This is unfortunate in the current Ethereum gas climate but necessary.

2. If the suspension is hit, then the user who performs the action will pay the gas cost (which is much less than an exchange) and not have their exchange processed. However, this suspension action is expected to be a _very_ rare edge case, and adding extra development work to repay them for their efforts is not worth it given the unlikeliness of this being needed. Additionally we are investigating the implementation of a keeper network to ensure that actions like this are incentivised and do not fall onto the user.

3. If we only check `exchange` actions, this does not prevent `SNX` stakers from issuing or burning `sUSD` while an invalid price is on-chain. However, the primary risk is that a staker can pay off their debt using the exploit. That is, that the debt pool has reduced and they now need to burn far less `sUSD` to unlock their `SNX`. This exploit is only possible if one or more prices are returned much lower than is accurate (otherwise the debt pool would expand rather than contract), and that those synths consist of a large enough proportion of the debt pool. Additionally, since sUSD is always fixed to `1`, the proportion of the debt pool denominated in `sUSD` will never change regardless of the other synths. As such, this extreme edge case does not seem worthy of also performing the check on `issue`, `burn` and `claim` actions given the additional gas costs per action.

4. Checking the last price from an exchange isn't a perfect solution, it may miss scenarios where the price fluctuates in and out of a reasonable band - but it's a acceptable compromise until such time as Chainlink have integrated circuit breakers onto all their Aggregators and we have migrated to Chainlink completely.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

`IExchanger` additions:

```solidity

// Views
function isSynthPricingInvalid(bytes32 currencyKey) external view returns (bool);

// Mutative functions
function suspendInvalidSynth(bytes32 currencyKey) external;
```

In order to save gas, each time a new `exchange` occurs, the price of both the `src` and `dest` synths will be stored locally in `Exchanger` (rather than looking back in `ExchangeRates` for some amount of time).

Additionally, `Exchanger.exchange` will be amended to perform `suspendInvalidSynth(currencyKey)` for either (or both) source or destination synth when `isSynthPricingInvalid(currencyKey)` is `true`.

### Workflow

- `Synthetix.exchange(onBehalf)?` invoked from synth `src` to `dest` by `user` for `amount`

  - For both `src` and `dest` synths:
    - _Is there a previous rate for the synth?_
      - Yes:
        - _Is the absolute % difference in rate now compared to the previous rate >= `priceDeviationThreshold`?_
          - Yes: ✅🔚 Settle any unsettled trades into `src` as per usual (if `src` was the breach, then settle with no reclaim or rebate - see below), then suspend the synth and return immediately.
          - No: Persist the current rate as the last
      - No:
        - For each of the last `3` rounds,
          - _Is the absolute % difference in rate now compared to the rate at current round >= `priceDeviationThreshold`?_
            - Yes: ✅🔚 Suspend the synth and return immediately.
            - No: Persist the current rate as the last
  - Then
    - ✅ Continue with exchange

- `Synthetix.settle` invoked on `dest` for `user`
  - For each unsettled exchange from some `synth` to `dest`:
    - _Is the absolute % difference in `amountReceived` compared `amountShouldHaveReceived` >= `priceDeviationThreshold`?_
      - Yes: Settle the exchange with `0` reclaim and `0` rebate
      - No: Settle the exchange as per usual

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

#### Preconditions

- Given the `priceDeviationThreshold` is set to `50%`
- And the `waitingPeriodSecs` is set to `180` (3 minutes)

#### Common cases

- Given there was previously an exchange for `sUSD` (or any synth) to `sETH`, recording the last sETH price as `200`
  - And the current market price of `sETH` is returning `500`
    - When a user attempts to exchange `sBTC` (or any other synth) into `sETH` (or from any synth into `sETH`)
      - Then as `500` is more than `50%` away from `200` (i.e. it's more than `300`), `sETH` will be suspended, and the exchange will be prevented.
  - And the current market price of `sETH` is returning `105`
    - When a user attempts to exchange `sBTC` (or any other synth) into `sETH`
      - Then as `105` is less than `50%` away from `200` (i.e. it's above `100`), then the exchange will continue, and `105` will be persisted as the last price.
        - When one minute elapses
        - And a new price for `sETH` is returned at `5`
        - And five minutes elapses (thus ending their waiting period)
        - And a new price for `sETH` is returned at `100`
        - And the `user` attempts to `exchange` `sETH` into any other synth
          - Then as the price of `5` (the price at three minutes after their exchange) is more than `50%` away from `105` (i.e. below `52.5`), then the settlement will process with no reclaim or rebate.

#### Edge cases

- Given there is no previous exchange recorded for `sETH`
  - And the protocol upgrades `Exchanger` contract
    - And there are 10 previous rates for `sETH` price, all within 1% of each other
      - When a user attempts to exchange `sETH` for `sUSD`,
        - Then the current rate will be within 1% of the previous three rates, and the exchange will continue, persisting the current rate
  - And the protocol upgrades `ExchangeRates` contract or a Chainlink `Aggregator` is replaced for a price
    - And there is no previous rates for `sETH`
      - Then the exchange will continue, persisting the current rate

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

- `priceDeviationThreshold` the absolute % amount that a price must deviate (from it's last exchange) to trigger the suspension.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
