---
sip: <to be assigned>
title: Keeper Synths
status: WIP
author: Kain Warwick (@kaiynne)
discussions-to: https://discord.gg/kPPKsPb

created: 2020-05-21
---

## Simple Summary
The current version of the iSynths (inverse priced Synths) have price limits to protect the network, when these price limits are hit the Synth is frozen and must be restarted. Currently the protocolDAO is the only address that can call these functions. This results in delays and frustration for users. By making these functions public and paying a fee in SNX for anyone who resets an iSynth we can signficantly improve the user experience.

## Abstract
This SIP will change the iSynths purge and update pricing functions to be public and incentivised. The first person to call each function will be paid SNX as an incentive.

## Motivation
While the iSynths are extremely useful and somewhat differentiated among DeFi assets, they have significant friction for users as the price bands required to prevent them becoming over or under leveraged mean that they regularly freze and must be reset. This reset process also requires that all holders of the Synth are purged into sUSD. 

The reason the price bands are required is that if the price of the underlying Synth doubles the price of the iSynth will go to 0. As the price of the iSynth tends to 0 the amount of leverage increases. For example if an ETH iSynth was instantated at $200 and ETH went to $399 then the iSynth would go to $1, so you would get $1 of price movement for each $1 spent on iETH versus $1 of price movement for every $400 spent on sETH. This property reverses in the other direction such that as the price of ETH drops you must buy significantly more iETH to get the same level of price movement. 

These properties neccesitate tight price bands and increasing or removing them would add significant risk to the network. The solution proposed in this SIP therefore leaves the bands as is and instead improves the purging and reset process by incentivising anyone to call public functions to manage iSynth freezing. 

## Specification
<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
-->

# Overview
There are three core functions required to reset an iSynth.
1. FreezeSynth
2. Purge
3. ResetPrice

FreeSynth - Currently the oracle is responsible for freezing the iSynth when the price limits are hit, as an aside this is also problematic for our transition to chainlink as the CL oracles do not have the ability to call freeze based on a price limit being hit. Rather than relying on a centralised service to freeze a synth we will instead open this up to be a public function that any address can call. This function will require that the current price of the underlying Synth is outside the defined price bands. If it is the synth will be frozen, if not the call will fail. The fee in SNX for freezing an iSynth will initially be set to 50 SNX. This fee is deliberately set high to ensure there are sufficient incentives for bots to operate on these Synths.

Purge - Currently once a Synth is frozen the pDAO must call purge on all the addresses that hold this iSynth. This will also be made a public function and any address will be able to pass an array of addresses holding these Synths and they will be purged into sUSD. 

There are three attack vectors that this incentive opens however, the first is that it is currently possible to trade into a frozen synth. This means an attacker could repeatedly trade into a frozen iSynth and purge themselves providing the payment was higher than the gas cost to purge the address. The solution to this to introduce a check on exchange to disallow trading into a frozen iSynth. The second attack vector is pre-exchanging into iSynths with a low value into a number of accounts and then purging them to get the SNX incentive. If there is no limit on the size of the holding and the SNX incentive was sufficiently large it could be profitable to exchange into thousands of accounts as long as the marginal cost of the roundtrip exchnage fees and gas costs of trade into and purge out of each wallet was less than the incentive paid. 
There is third factor to this incentive which is that if accounts with small values are ignored completely an attack is possible by sybil attacking the system and moving into many accounts with small balances that in sum are sufficiently large to be meaningful. To illustrate the issue, imagine we allow any wallet with less than $1 of an iSynth to not be purged, then we instantiate iETH when ETH is @ $200 if ETH hits $300 iETH will be @ $100 and frozen, if someone were to exchange $50k worth of sUSD into iETH and then split this into 50,001 wallets they would be below the threshold set of $1 and we would not purge them and all of their iETH would triple in price when iETH was reset to $300. Clearly we must have a global limit on the amount of a Synth before the price can be reset, and if it is not below this level the Synth price cannot be reset. The issue is we are now at a stalemate where there is a significant balance of iSynths spread across many wallets and the cost to purge would significantly exceed the SNX incentive. There is too much value in total to reprice and there is too high a cost to purge each wallet.
To define the boundaries of this problem, the current cost of a purge of 12 addresses at 10 gwei is around $25. The cost of a transfer of a synth is about 1/4 the cost of an exchange, so you can pay one exchange fee and then split your balance into three wallets even with a large balance create a significant burden on the system. So let's say I trade $120k sUSD into iETH at the limit, and then transfer the iSynths into 120 wallets. I have paid $360 in exchange fees and ~ $125 in gas. The cost to purge these addresses will be $250 in gas. So the attack will be a net loss for the attacker, but if the attacker splits the wallets into 1200 x $100 wallets the cost will be $360 in exchange fees and $1250 in gas. But the cost to purge these accounts will be $2500. While this is unlikely to be executed it is possible. It also illustrates a larger issue which is scalability. if the network grows to the point where there are thousands of holders of an iSynth purging into sUSD will simply be cost prohibitive. An alternative solution is to apply an alternative version of fee reclation that checks when a Synth is exchange whether it was frozen after the last exchange and applies fee reclamation to reset the balance. This is the proposed soltution for a later upgrade of iSynths which are constantly rebalancing and do not require freezing but instead use FR to continuously track the daily repricing events in a cumulative fashion. But that solution is outside the scope of this SIP.

ResetPrice - Once all balances above the threshold have been purged and the total value in the iSynth is below the threshold, resetpricing can be called. This will read from the underlying asset aggregrator contract and then apply the new pricing and price bands.

# Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Move the attack vector and risk mitigations above into this section.

The Purgeincentive will thus be set at 30 SNX per purge cycle, with a maximum of $1 in total value allowed in an iSynth before resetPrice can be called. By blocking trading into a frozen Synth we reduce the attack vector significantly and ensure that there is significant risk that an attacker paying to seed many smal accounts may lose the gas costs of this attack to a faster keeper who can afford to pay higher gas costs due to their lower net cost of the total transaction cycle.

We considered paying an incentive based on the total value of the purge but this introduces a situtation where the final purge cycle may not be profitbale but the total value across holders too high to allow repricing to be called.

# Technical Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones. 

# Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
MinBalance - This is the minimum value measured in sUSD that can be purged (1c)
MaxValue - This is the maximum total value across all unpurged holders before resetPricing can be called ($1)
FreezeIncentive - The amount of SNX paid to the caller of FreezeSynth
PurgeIncentive - The amount of SNX paid to the caller of each purge cycle

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
