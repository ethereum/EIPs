---
sip: 53
title: Binary Options
status: WIP
author: Anton Jurisevic (@zyzek)
discussions-to: https://discord.gg/kPPKsPb

created: 2020-04-23
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

This SIP proposes to allow the creation of new markets for trading binary option Synths.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

A binary option is a type of option contract which provides a fixed return based on a binary outcome in the future. These option Synths pay out on a certain date if the price of a chosen asset is above (or below) a level specified at the creation of the option. This allows users to take a position on the price of any asset known to the Synthetix system.
The proposed options use a parimutuel-style initial bidding period to set the price per option, and where one side of the market pays out the other side at maturity. This removes the necessity of matching counterparties for these options.

---

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Synthetix enhances whatever markets are implemented on top of it, as users can frictionlessly enter and exit in any currency they wish. This effectively allows any instruments to be denominated in any currency – but it requires integration with the Synthetix platform.

When it comes to actually setting up a market, stakers take on some of the risk of capitalising these markets, and in providing the infrastructure to allow them to operate: these responsibilities and the labour required to generate binary options markets should be compensated. This requires fees to be remitted to the pool, and hence integration with the protocol itself.

Finally, the maturity condition of a binary option requires integration with trustworthy price oracles, which Synthetix already provides.

---

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->

### Table of Contents

* [Summary](#summary)
* [Smart Contracts](#smart-contracts)
* [Basic Dynamics](#basic-dynamics)
  * [Option Supply](#option-supply)
  * [Option Prices](#option-prices)
  * [Fees](#fees)
  * [Equilibrium Prices](#equilibrium-prices)
  * [Options As Synths](#options-as-synths)
* [Market Creation](#market-creation)
  * [Initial Capital](#initial-capital)
  * [Oracles](#oracles)
  * [Incentives](#incentives)
* [Bidding Period](#bidding-period)
  * [Bids](#bids)
  * [Refunds](#refunds)
* [Trading Period](#trading-period)
  * [Balances](#balances)
  * [Token Transfers](#token-transfers)
* [Maturity](#maturity)
  * [Oracle Snapshot](#oracle-snapshot)
  * [Exercising Options](#exercising-options)
  * [Cleanup](#cleanup)
  * [Oracle Failure](#oracle-failure)
* [Future Extensions](#future-extensions)
  * [Arbitrary Maturity Predicates](#arbitrary-maturity-predicates)
  * [Multimodal Options Markets](#multimodal-options-markets)
  * [Limit Bids](#limit-bids)
* [Summary of Definitions](#summary-of-definitions)

### Summary

Over its life cycle, a binary options market transitions through the following states:

#### 1. Market Creation

Each binary option market is created by a factory contract. At the time of creation, a number of parameters are fixed; particularly the target price, underlying asset, and maturity date. The resulting market has two sides, corresponding to the events that the price of the underlying asset is either higher or lower than the specified target price at the maturity date.
Ownership and transfer of options on either side of the market is managed by a pair of dedicated ERC20 token contracts.

#### 2. Bidding Period

In the bidding period, the initial price and supply of options on each side of the market are determined.
No transfer of options between wallets is possible at this stage.

In order to fix the option prices, users commit funds to either side of the market. At the termination of bidding the basic price of each option is fixed.
At this time, users are awarded a pro-rata quantity of options proportional with the size of their share of the bid on a given side of the market, and no more bids are accepted.

#### 3. Trading Period

In this period, the supply of options does not change, but the options are free to be traded between wallets.
In this way the market price of each option can still float freely as more information becomes apparent before maturity.

#### 4. Maturity

After the maturity date is reached, users may exercise the options they hold, which will destroy them. Each option pays out 1 token if its condition has been met (e.g. the underlying asset's price is higher than the target price), and nothing if its condition has not been met. These returns are paid from the total bids made on both sides during the bidding period. After a time, the market is destroyed.

---

### Smart Contracts

* `BinaryOptionMarketFactory`: Responsible for generating new `BinaryOptionMarket` instances, and maintaining a list of active instances.
* `BinaryOptionMarket`: Each instance of this contract is responsible for managing the market for a particular asset to be at a certain price on a given date. Many of these could exist simultaneously for different assets, with different target prices, maturity dates, and so on. All funds of the denominating asset will be held in this contract.
* `Option`: This is an ERC20 token contract which holds each user's quantity of an option. Two of these contracts exist per `BinaryOptionMarket` instance, one per side of the market, called `OptionL` and `OptionS`. The actual wallet balances will be held as a value of the denominating asset a user has bid, and the quantity of options computed from this.

The smart contract architecture is summarised in the following diagram.

![Architecture](assets/sip-53/smart-contract-architecture.svg)

---

### Basic Dynamics

#### Option Supply

If we query the price of an underlying asset $U$ from an oracle at the maturity date, its price at maturity $P_U$ is either above or below the target price $P_U^{target}$. Users bid on each outcome to receive options that pay out in case that event occurs, exchanging tokens with the `BinaryOptionMarket` contract. That is, then events are $L$ and $S$:

* $L$: The event that $P_U \geq P_U^{target}$, when the "long" side of the market pays out.
* $S$: The event that $P_U < P_U^{target}$, when the "short" side of the market pays out.

We will define $Q_L$ and $Q_S$ to be the quantity of tokens bid on the long and short sides respectively.

At maturity, the entire value of bids from both sides of the market is paid out to the winning side, minus a fee $\phi$ for the market creator and fee pool. One or the other side paying out are mutually exclusive events, with each side of the market awarded $Q$ options, where

\\[
Q := (1 - \phi) (Q_L + Q_S)
\\]

The total quantity of options minted is $2Q$, but only $Q$ pay out at maturity.

#### Option Prices

The market spent quantities $Q_L$ and $Q_S$ of tokens to exchange into $Q$ options per side, the overall option price is easily computed:

\\[
P_L := \frac{Q_L}{Q} = \frac{Q_L}{(1 - \phi) (Q_L + Q_S)}
\\]

\\[
P_S := \frac{Q_S}{Q} = \frac{Q_S}{(1 - \phi) (Q_L + Q_S)}
\\]

For example, assuming no fees, if $Q_L = Q_S = 100$, then $P_L = P_S = 0.5$. But if $50$ additional tokens are bid on $L$, then $P_L = 0.6$, while $P_S = 0.4$.
Thus increased demand for options on one side of the market increases the price on that side and reduces it on the other. Larger bids will shift the prices by correspondingly greater amounts.

It is only at the end of the bidding period that the price is finalised, and users receive a pro-rated quantity of options according to the size of their bid. That is, if a user had bid $d$ tokens of the denominating asset $D$ on $L$, they would receive $\frac{d}{P_L}$ options. The case that the user had bid on $S$ is similar.

#### Fees

At the maturity date, $Q_L + Q_S$ Synths will have been exchanged into options, but only $Q = (1 - \phi) (Q_L + Q_S)$ options pay out. The remaining quantity of $\phi (Q_L + Q_S)$ tokens is owed to stakers and the market creator as a service fee.

There are distinct fee rates for the fee pool ($\phi_{pool}$) and for the market creator ($\phi_{creator}$), which are set by the community. The overall fee rate is the sum of these quantities: $\phi := \phi_{pool} + \phi_{creator}$.

These fees should be transferred at maturity (upon invocation of a public function) rather than continuously, as it allows users to recover their full bids in case of an oracle interruption, as described in the Maturity section below.

#### Equilibrium Prices

Note that, neglecting fees, $P_L + P_S = 1$, reflecting the fact that $L$ and $S$ are complementary events.

Without fees, the prices can be read off directly as odds, and in fact if the probability of $L$ paying off is $p$, then long options yield an expected profit of $p - P_L$ each. Meanwhile the expected profit on the short side is the exact negative of this: $(1 - p) - P_S = P_L - p$. The expected profit of buying an option is positive whenever its price is lower than its event's probability, so the prices should approach the probabilities.

If the fee is nonzero, then $P_L + P_S = \frac{1}{1 - \phi}$, which somewhat higher than $1$. Under these conditions, it will only be rational for market participants to purchase options if they believe the market is mispriced by a margin larger than the fee rate.

#### Options As Synths

Options are themselves Synths, with some restrictions.

Bidding on a binary option market is a Synth exchange operation. Bidders convert Synths to a tentative quantity of options, which stabilises at the end of bidding. Refunded bids are just exchanges in the opposite direction, minus a fee. In this way, options are exchangeable during the bidding period. After maturity, the exercise of an option into Synths is also an exchange.

There may be many markets operating simultaneously, and each contributes a value of Synths to the debt pool. In order to ensure that it is still efficient to compute the value of the system debt, the total debt contributed by all binary options will be held in the `BinaryOptionMarketFactory` contact. This debt is equivalent to the sum of bids over all markets. Whenever value is moved in or out of a given `BinaryOptionMarket` contract, the contribution of this movement must be updated with the factory contract.

In this way the debt associated with binary option Synths is located in a single place, easily consulted at any time.

---

### Market Creation

A new options market is generated by the `BinaryOptionMarketFactory`; the contract creator must choose fixed values for:

* $D$: The denominating asset (sUSD for all markets at first);
* $O$: The price oracle for the underlying asset $U$, which implicitly sets $U$ as well;
* $t_b$: The end of the bidding period;
* $t_m$: The maturity date;
* $P_U^{target}$: the target price of $U$ at maturity;
* $Q_L$ / $Q_S$: the initial demand on each side of the market;

A new `BinaryOptionMarket` contract is instantiated with the specified parameters, and two child `Option` instances. ERC20 token transfer by these `Option` instances will initially be frozen, and it will not unlock until the trading period begins.

For discoverability purposes, the address of each new `BinaryOptionMarket` instance will be tracked in a list on the `BinaryOptionMarketFactory` contract until that market is destroyed at the end of its life.

#### Initial Capital

The market creation functionality of the `BinaryOptionMarketFactory` contract will be public; anyone at all will be able to create a market, provided they can meet the minimum capitalisation requirement $C$.
The initial capital requirement will dissuade users from creating low-liquidity markets flippantly.

Without initial positive values for $Q_L$ and $Q_S$, $P_L$ and $P_S$ are undefined. Therefore the market creator is required to contribute a minimum initial value of $C$ worth of tokens. No constraints are placed upon the initial division of funds between $Q_L$ and $Q_S$, which will determine the specific initial prices, but the sum $Q_L + Q_S$ must be worth more than $C$. The market creator will be awarded options for this initial capital, just like any other bidder.

Along with setting initial prices, a strong reason that it is necessary to provide this initial liquidity is to ensure that when bids come into a new market, they don't swing the prices too aggressively. In a very thin market, small bids can cause drastic and undesirable shifts in price.

The market creator should be able to remove their initial capital as long as the total bids in the market are worth more than $C$. Thus it is important for the author of a given market to carefully select its initial parameters. By selecting a combination of asset, timing, and target price that attracts demand, and by choosing initial prices that are reasonably fair, the market creator minimises their own risk by maximising the market's health.

#### Oracles

The price oracle must be selected from the approved set of data sources available on the Synthetix [`ExchangeRates`](https://docs.synthetix.io/contracts/exchangerates/) contract, which includes a number of [Chainlink Aggregators](https://github.com/smartcontractkit/chainlink/blob/5ab3cd2777590701007cc02941cb94179e79f3ba/evm/contracts/Aggregator.sol).

Oracles are initially constrained to a trusted set, otherwise there is the strong potential for malicious actors to supply manipulated data feeds, but this could be democratised in the future.

#### Incentives

Without a profit motive there is no reason to expect anyone to risk funds in the creation of these markets, and therefore a portion of the overall payout ($\phi_{creator}$) will go to the market creator at the maturity date. In the initial stages it may be necessary to subsidise the creation of these markets by means of inflationary rewards or other bounties. The implementation of such subsidies is an open question for the community to answer.

---

### Bidding Period

The bidding period commences immediately after the contract is created, terminating at time $t_b$, when the trading period begins.
During the bidding period, users may add or remove funds on either side of the market, allowing it to equilibrate, ultimately fixing the option prices from time $t_b$ onward.

The following addresses the long side $L$; the short $S$ case is symmetric.

#### Bids

Users may bid to receive options that will pay out if outcome $L$ occurs. In order to do this, wallet $w$ deposits $d$ tokens of the denominating Synth $D$ with the `BinaryOptionMarket` contract. $Q_L$ and the associated `OptionL` contract's balance for wallet $w$ are both incremented by $d$.

If the user elects to bid with a Synth other than $D$, then the system will perform an automatic conversion to $D$.

#### Refunds

If a user has already taken a position, they may refund it. A fee is charged for this to counteract toxic order flow and other manipulations available to actors with private information.

If the user with wallet $w$ has already bid long $d$ tokens (of the denominating asset $D$), then they may refund any quantity $q \leq d$, and will receive $q (1 - \phi_{refund})$ tokens. $Q_L$ and the associated `OptionL` contract's balance for wallet $w$ are decremented by $d$. The remaining $q \cdot \phi_{refund}$ tokens are then rebalanced between $Q_L$ and $Q_S$ so that the odds are unaffected, but the fee stays in the pot.

A bidder may wish to refund their position because they have gained new information, or the underlying market conditions have changed. However, recall that placing a bid shifts prices for all existing bidders, so they may also wish to refund their position because the option price has shifted too much or they believe the options are now mispriced.

When a bidder exits the market, the part of their bid that they leave behind compensates the market for the incorrect signal they previously transmitted, increasing the payoff for other users who stuck with their position.
Be aware, however, that although this fee disincentivises churn and market toxicity, it also slightly distorts the market, creating a friction that stands in the way of the most rapid possible price discovery.

If the bidder elects to refund into a Synth other than $D$, the system will perform an automatic conversion from $D$.

---

### Trading Period

At the commencement of the trading period, bidding is disabled and ERC20 token transfer is enabled. As the individual token prices have stabilised, the quantity of options each wallet is awarded can be computed, as it no longer changes.

### Balances

It may be apparent that the `Option` contracts underlying each option market do not store the actual option balances, but rather store total bid for each wallet. To compute the actual balance of options (for the long side, for example), the value must be divided by $P_L$ before it is returned.

In this way, no reallocation of options needs to occur at the transition between the bidding and trading period, and users can compute their tentative option balance at current prices even while bidding is still ongoing.

The same considerations apply to the computation of the total supply of options, which at all times will evaluate to $2Q$.

### Token Transfers

During the trading period, each `Option` contract offers full ERC20 functionality, including `transfer`, `approve`, and `transferFrom`, supporting trading tokens on secondary markets. Balances for this functionality should be computed according to the computations described above.

---

### Maturity

Once the maturity date is reached, the oracle must be consulted and the outstanding options resolved to pay out $1$ token of $D$ or nothing. At their discretion, any user with a positive balance of options can then exercise them to obtain whatever payout they are owed.

#### Oracle Snapshot

After the maturity date, any user should be able to instruct the options market contract to query the oracle for the latest price of the underlying asset. This function must have been inoperative before the maturity date. The price snapshot should occur in a timely fashion as whichever side is in the money at maturity has a strong incentive to take the snapshot as rapidly as possible. The options market contract should remember the result to allow users to exercise their options in the future.

This function should also transfer the collected market fees to the fee pool and market creator.

#### Exercising Options

At maturity, users may exercise the options they hold. The required funds will then be transferred from the `BinaryOptionMarket` contract to the user, and their balances in the underlying `Option` token contracts set to zero, destroying those options so that they cannot be exercised again.
ERC20 total supply calculations must also account for this.

Users should be able to exercise their options into any flavour of Synth they like, and the exchange should take place automatically. That is, matured options themselves behave like Synths whose value either is that of their denominating asset, or zero, and so that can be traded and exchanged just like any other Synth.

#### Cleanup

In order to combat the proliferation of defunct options contracts, `BinaryOptionMarket` instances should implement a self-destruct function which can be invoked a long enough duration after the maturity date. Once this function is invoked, the contract and its two subsidiary `Option` instances will self destruct, and the corresponding entry deleted from the list of markets on the `BinaryOptionMarketFactory` contract.

In order to incentivise this, the market creator must deposit $\gamma$ tokens into the new contract in addition to the initial capital. When the cleanup function is invoked by the contract creator, the contract will return the deposit along with any unclaimed tokens left in the contract.

Initially this function will only be available to the original author, but if after a short period the they do not act, then the deposit will be made available to any user willing to perform the labour of cleaning up.

#### Oracle Failure

If at the maturity date the oracle is not operating, the contract could arrive at a state where options cannot be exercised. In the absence of oracle data for a long enough duration, it should be possible for users to refund their bids without a fee.
Note the following: first, this duration must perforce be shorter than the contract destruction duration just mentioned; second this must be implemented carefully as it introduces an incentive for users on the losing side of the market to interfere with the oracle.

---

### Future Extensions

#### Arbitrary Maturity Predicates

At present these options are defined on a particular maturity condition, but there is no reason that the system couldn't be extended to a range of richer conditions.

If the inputs inputs are restricted to only to a single price, there are many useful predicates that can be defined on that price beyond the over-under condition proposed in this document. For example, the options could pay out depending on whether the underlying price at maturity is within a percentage of its initial value.
If inputs are not restricted to to a single price, comparisons can be made between several different oracle outputs. For example, options could pay out based on whether the Nikkei 225 grew by more than the FTSE 100.

In fact any predicate accepting inputs from Synthetix oracles could be used as a maturity condition for options.

#### Multimodal Options Markets

Although this structure has been defined for a binary outcome, it extends easily to any number of outcomes. In particular, if there are $n$ possible outcomes, then $n$ `Option` token contract instances are instantiated, one for each outcome.

If $\Omega$ is an exhaustive set of mutually exclusive outcomes, and $Q_o$ is the quantity bid towards outcome $o \in \Omega$, then $Q := (1 - \phi) \sum_{o \in \Omega}{Q_o}$ is the number of options awarded to each outcome; $n \cdot Q$ options issued altogether, of which $Q$ will pay out. Then the price for outcome $o$ is $P_o := \frac{Q_o}{Q}$.

The binary version is just a special case of this more general structure; notice for example that it posesses the same property that, neglecting fees, the sum of all prices is $1$. Further, it still holds that it is expected to be profitable to buy a particular option whenever its price is less than the probability of its associated event occurring. As a result the prices can still be interpreted as the market's prediction of the odds of each event.

These events could be any discrete set of outcomes, such as the results of political elections. Thus the multimodal parimutuel structure can function as a general prediction market, provided that good oracle sources for events of interest can be obtained.

With multimodal markets understood, continuous quantities are also handled by discretising their ranges into buckets. For example, it would be possible for users to participate in a market focusing on the Ethereum price, where the possible outcomes were $\\$140$ or less, $\\$140 - \\$150$, and $\\$150$ or more. In principle any degree of granularity for these buckets is possible.

#### Limit Bids

A slight issue with the system described is that it assumes an elasticity curve which may not reflect the true underlying demand on one or both sides of the market. The liquidity at any given price point is infinitesimal, so participants need to wait for the size of the market to step-ladder up to a desired level.

In order to serve demand at given prices without this step ladder effect, one could allow users to place limit orders on either side of the market. Then bids on the long and short sides of the market can be 'matched', i.e. they could both be filled so that the demand is satisfied only under the conditions that there is sufficient depth to allow the price not to shift too much.
On the other hand, participants may also want to take stop loss positions which would refund their bid if the market shifts too far underneath them for their preference.

In combination these mechanisms would provide users with the confidence to participate freely in these markets, enhancing the depth and liquidity of the binary options markets.

These systems could be implemented as a smart contract or as a front-end overlay on synthetix.exchange. A related proposal for triggered order contracts is discussed [here](https://github.com/Synthetixio/synthetix/issues/195).

---

### Summary of Definitions

| Symbol | Description |
| ------ | ----------- |
| $U$   | The underlying asset of this market. It is assumed we have a reliable oracle $O$ supplying its instantaneous price. |
| $D$   | The denominating Synth of a market. Options are priced in terms of $D$, hence bids, refunds, fees, etc. are computed as quantities of $D$. |
| $t_b$, $t_m$  | The timestamps for the end of bidding and maturity, respectively, of a given contract. $t_b$ must be later than the contract creation time, and $t_m$ must be later than $t_b$. |
| $P_U$, $P_U^{target}$ | $P_U$ is the price of $U$ queried from the oracle $O$ at the maturity date $t_m$. $P_U^{target}$ is the target price of $U$ at maturity, against which $P_U$ is compared to assess the maturity condition. |
| $\phi_{pool}$, $\phi_{creator}$ | The platform fee rate paid to the fee pool and to the market creator respectively. These fees are paid at maturity. |
| $\phi$ | The overall market fee, which is equal to $\phi_{pool} + \phi_{creator}$. $\phi$ must in the range $[0, 1]$. |
| $\phi_{refund}$  | The fee rate to refund a bid. Its value must be in the range $[0, 1]$. |
| $L$, $S$ | The possible outcomes at maturity. $L$ is the event that $P_U \geq P_U^{target}$; when the "long" side of the market pays out. $S$ is the event that $P_U < P_U^{target}$; when the "short" side of the market pays out. |
| $Q_L$, $Q_S$ | The total funds on the long and short sides of the market respectively. |
| $Q$ | The quantity of options awarded to each side of the market; this is equal to $(1 - \phi) (Q_L + Q_S)$. |
| $P_L$, $P_S$ | The price of long and short options respectively. Defined as $P_L := \frac{Q_L}{Q}$ and $P_S := \frac{Q_S}{Q}$. |
| $C$   | The minimum initial capitalisation of a new market. |
| $\gamma$   | The self-destruction deposit. |

---

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Binary options themselves represent an unsatisfied latent demand in the crypto/DeFi space; but the necessity of implementing them ultimately can only be proven by success or failure of an actual implementation.
Successfully implemented, however, a fully-integrated binary options market ecosystem would increase the demand for Synths and increase the diversity of instruments available to the market for hedging and other purposes.

The parimutuel structure in particular was selected for its simplicity, efficiency, and desirable risk characteristics.
As the aggregated participants in one side of the market pay out the aggregated participants on the other side, this structure is relatively computationally efficient.
In particular, there is no need for the complexity associated with traditional binary options, which require counterparties to be matched.

Since all parties only interact with a central pool of funds residing in a smart contract, and the prices behave in simple and rational way, the mechanism is completely transparent and trustworthy to all.
There is no questionable mathematical apparatus which implicitly attempts to predict actual supply and demand.
From the perspective of the staking pool, the risk incurred in creating these markets is minimised, since the actual market position the pool has to take is zero, outside of initial capitalisation. Yet these markets could represent a real driver of demand and fee generation, which will contribute to the overall health of the Synthetix ecosystem.

The design proposed also leverages the existing structures Synthetix has constructed, as it can use as its inputs any price feed already available, while being enhanced for free whenever new prices are introduced. Similarly, the mechanism itself can be readily extended to a much broader catalogue of financial instruments, prediction markets, and so on.

---

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

---

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

---

## Further Discussion Questions

There are a number of details which the community will need to decide on for the proposed markets to flourish. For example:

### Alternative Price Discovery Mechanism

There is a potential alternative model for finding the price of each option that would remove the bidding period.
In this design, options would be generated by a simple exchange of a single token for a pair of options.
Any binary option market would generate one long option and one short option in exchange for a token of its denominating asset plus a fee. This works because although the specific prices of each option are not known, it is known that together they will pay out a single token. Refunds would proceed similarly: a user would have to purchase one of each option to exchange back to other Synths.

Then price discovery would proceed by the user who just exchanged into an option pair selling the undesired
option on market.

Under this proposal, exchange and transfer functionality could happen at all times, and there would also be no constraint on the growth of the market, right up to the maturity date.

### Basic Market Parameters

It will be necessary to choose, via SCCP, the values of basic market parameters such as the minimum initial capitalisation $C$, the size of the self-destruction deposit $\gamma$, and the levels of the various fees.

It may also be the case that some of these parameters, such as the market creation fee, should be set by the market creators themselves, to allow competitive pricing of these services.

### Which Markets to Create

The community will drive which markets should actually be opened. Some experimentation will be needed to settle questions such as which assets to focus on, the appropriate relative lengths of bidding and trading periods, the overall time to maturity, initial odds and target prices.

### Market Lifecycle

It is not clear a priori what level of incentivisation is appropriate for the opening and cleanup of markets. Determining these levels, and what form the incentives take is particularly relevant if inflationary SNX rewards are to be used to subsidise market creation.

It may be the case that the transition between bidding and trading periods needs to be smoothed out, and observation of market dynamics close to the close of bidding will be needed.

### Oracle Selection

In the future, it may be desirable to extend the set of prices available to binary options.
It needs to be decided asset prices are appropriate to allow users to build binary options markets upon, and which are not. Further to this, it may be the case that oracle system needs to be extended beyond the existing Synthetix data feeds; which feeds (if it is a restricted set), and how to perform the extension are still open questions.

### External Integrations

It will be necessary to decide how to filter and display markets on dApps and other interfaces; whether integration with external platforms would be valuable, and which platforms, is another avenue that may be fruitful to investigate.

### Functional Extensions

Several potential extensions have been listed above. It should be determined which, if any, of these extensions should be pursued.

---

## Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->

| Symbol | Description |
| ------ | ----------- |
| $C$   | The minimum value of the initial capitalisation of a new binary option market. This is a value of USD. |
| $\gamma$   | The size of the self-destruction deposit. This is a value of the denominating asset $D$. |
| $\phi_{pool}$   | The platform fee rate paid to the fee pool. This is a decimal number in the range $[0, 1]$. |
| $\phi_{creator}$ | The fee rate paid to the creator of a market. This is a decimal number in the range $[0, 1]$. |
| $\phi_{refund}$   | The fee rate to refund a bid. This is a decimal number in the range $[0, 1]$. |

---

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
