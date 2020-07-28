---
sip: 61
title: Keeper Synths
status: WIP
author: Kain Warwick (@kaiynne), Justin Moses (@justinjmoses)
discussions-to: https://discord.gg/kPPKsPb

created: 2020-05-21
---

## Simple Summary
The current version of the iSynths (inverse price Synths) have price limits to protect the network, when these price limits are hit the Synth is frozen and the price must be updated to the current price of the underlying asset. Currently the protocolDAO is the only address that can make these calls. This results in delays and frustration for users. By making these functions public and paying a fee in SNX for anyone who resets an iSynth we can signficantly improve the user experience.

## Abstract
This SIP will change the iSynths purge and update pricing functions to be public and incentivised. The first address to call freezeSynth will be paid SNX as an incentive.

## Motivation
While the iSynths are extremely useful and somewhat differentiated among DeFi assets, they have significant friction for users as the price bands required to prevent them becoming over or under leveraged mean they regularly freze and must be reset. This reset process also requires that all holders of the Synth are purged into sUSD first incurring high gas costs.

The reason the price bands are required is that if the price of the underlying Synth doubles the price of the iSynth will go to 0. As the price of the iSynth tends to 0 the amount of leverage increases. For example if an ETH iSynth was instantiated at $200 and ETH went to $399 then the iSynth would go to $1, so you would get $1 of price movement for each $1 spent on iETH versus $1 of price movement for every $400 spent on sETH. This property reverses in the other direction such that as the price of ETH drops you must buy significantly more iETH to get the same level of price movement as sETH.

This leverage neccesitates tight price bands and increasing or removing them would add significant risk to the network. The solution proposed in this SIP therefore leaves the bands as is and instead improves the purging and reset process by incentivising anyone to call public functions to manage iSynth freezing.

## Specification

# Overview
There are three core functions required to reset an iSynth.
1. FreezeSynth
2. Purge
3. ResetPrice

FreezeSynth - Currently the oracle is responsible for freezing the iSynth when the price limits are hit, as an aside this is also problematic for our transition to chainlink as the CL oracles do not have the ability to call FreezeSynth based on a price limit being hit. Rather than relying on a centralised service to freeze iSynths we will instead make this a public function any address can call. This function will require that the current price of the underlying Synth is outside the defined price bands. If it is the synth will be frozen, if not the call will fail. The fee in SNX for freezing an iSynth will initially be set to 50 SNX. This fee is deliberately set high to ensure there are sufficient incentives to ensure competition to quickly freeze iSynths. the address that calls FreezeSynth successfully will be stored and only this address will be able to purge and reset prices for a configurable period (initially 60 minutes) called the LockPeriod.

Purge - Currently once a Synth is frozen the pDAO must call purge on all the addresses that hold this iSynth. During the LockPeriod the address that called FreezeSynth will be able to purge by passing an array of addresses holding the iSynth purging them into sUSD. If the address that froze the synth fails to purge all addresses any address can call purge and it will then have excludive access to purging the iSynth for the next LockPeriod. Only addresses holding more than $0.01 can be purged, the reasoning behind this limitation is discussed in the rationale section below.

ResetPrice - ResetPrice can only be called once the total balance in the iSynth is below a configurable threshold called MaxValue (currently $10). Once the total value in the iSynth is below the threshold, ResetPrice can be called. This will read from the underlying Chainlink aggregrator contract and apply the new pricing and price bands. The SNX incentive for calling purge will be the number of purged addresses * PurgeIncentive a configurable value (currently 3 SNX).

# Rationale
There are three attack vectors this incentive opens:
1. Trading into an iSynth after it is frozen to capture incentives
2. Trading into an iSynth just before it freezes then splitting the iSynth across many wallets to capture the incentives
3. Moving into many accounts with small balances with the expectation of not being purged

The first attack is possible because you can currently trade into a frozen synth. An attacker could repeatedly trade into a frozen iSynth and purge themselves providing the payment was higher than the gas cost to purge the address. The solution to this to introduce a check on exchange to disallow trading into a frozen iSynth.

The second attack relies on exchanging into iSynths then splitting the value across a number of accounts and then purging them to capture the SNX incentive. If there is no limit on the size of an address that can be purged and the SNX incentive was sufficiently large it could be profitable to exchange into thousands of accounts with dust as long as the marginal cost of the roundtrip exchange fees and gas costs of trade into and purge out of each wallet was less than the incentive. The current MinPurgeAmount is configurable (currently $0.01). It could still be profitable to split into addresses with values above $0.01 however this requires more funds at risk as another keeper could capture the incentive.

***UPDATE***
Kaleb on discord has pointed out that a form of colusion could undermine the incentives preventing this attack. Where the address that calls FreezeSynth could offer to buy frozen iSynths and then split them into many addresses to maximise the yield. Meaning that it would be optimal for any address that wins the race to call FreezeSynth to open a trustless escrow offer to buy as many of the frozen synth as possible and split them into many wallets. There are several potential mitigations to this type of collusion including preventing transfers. However, @justinjmoses is of the belief that the best approach is to instead apply a form of fe reclamation as discussed below. We will therefore review and revise this SIP before resubmitting.

The third attack relies on small values being excluded from purging making it possible to move into many accounts with small balances that in sum are sufficiently large to be meaningful. To illustrate the issue, imagine we did not check the total Synth balance before ResetPrice is called. If we instantiate iETH when ETH is @ $200 if ETH hits $300 iETH will be $100 and frozen, if someone were to exchange $5k worth of sUSD into iETH and then split this into 5,000 wallets their iETH would triple in price when iETH was reset to $300. Clearly we must have a global limit on the total value of a Synth before the price can be reset MaxValue ensures this attack is not successful.

Blocking trading into a frozen Synth reduces this attack vector significantly and ensuring there is significant risk that an attacker paying to seed many small accounts may lose the gas cost and eschange fees of this attack to a faster keeper who can afford to pay higher gas costs to call FreezeSynth due to their lower net cost.

If this theoretical griefing attack or scalability become problematic there is an alternative solution which is to apply a new type of fee reclation ResetPriceReclaim. Rather than purging a keeper would call a function that would iterate over all wallets and apply ResetPriceReclaim or ResetPriceRebate then call Resetprice. This would mean that a reclaim or rebate entry would be registered against each address that would cover the change in price of the Synth after ResetPrice was called.

This is similar to the proposed solution for a later upgrade of iSynths which rebalance daily and do not require freezing but instead use Fee Reclamation to track the daily repricing events in a cumulative fashion. That solution is outside the scope of this SIP.

# Technical Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.

# Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Configurable Values (Via SCCP)
MinBalance - This is the minimum value measured in sUSD that can be purged (1c)

MaxValue - This is the maximum total value across all unpurged holders before resetPricing can be called ($10)

FreezeIncentive - The amount of SNX paid to the caller of FreezeSynth

PurgeIncentive - The amount of SNX paid to the caller of purge cycle

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
