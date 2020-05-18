---
sip: 55
title: Synth Circuit Breaker (Phase One)
status: Implemented
author: Jackson Chan (@jacko125), Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-04-24
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Automated system to prevent the exchange or transfer of individual synths if their prices shift by more than `25%` (crypto) or `10%` (traditional) in a single update.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Sythetix uses a mix of decentralised oracles from Chainlink networks (for traditional markets) along with our centralized SNX Oracle (for crypto markets - to be phased out in [SIP-36](./sip-36.md)). In order to protect the integrity of the system, large abnormal price shifts in price updates of a synth will trigger a circuit breaker so that the synth becomes suspended from exchanging and transferring until it is investigated. Upon investigation by the Protocol DAO, the synth will be resumed following any remediations required.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

The primary motivation is security of funds. There have been occasions where synths have needed to be disabled immediately, such as the chainlink oracle issue with [XAG-USD mispriced as XAU](https://blog.synthetix.io/update-on-xag-pricing-incident), causing sXAG to be mispriced and loss of funds. This gives the team and community time to investigate the situation and ensure that funds are not at risk.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Phase one will use a continuous process (an off-chain oracle) to monitor the prices of assets in both the Synthetix `ExchangeRates` contract and the associated `AggregatorInterface` contracts from Chainlink. This circuit breaker oracle will have the power to suspend any synth at any time via the `SystemStatus` contract which was implemented in [SIP-44](./sip-44.md)).

If crypto prices are detected to have moved between a single update of `25%` or more in either direction, the circuit-breaker oracle will set the synth as suspended using the `System.Status.suspendSynth()` function with an assigned `reasonCode`.

If traditional prices (forex, commodities, equities) on the associated `AggregatorInterface` contracts from Chainlink deviate from the off-chain oracle price sources by `10%` or more, the circuit-breaker oracle will set the synth as suspended. The lower threshold for traditional markets compared to crypto is based on the volatility of the `Forex, commodities and equities` synths currently on Chainlink compared to the volatility of `crypto` synths.

From SIP-44, synth pausing means that the synth in question:

- Cannot be exchanged into any other synth
- Cannot be settled
- Cannot be transferred

The price oracle will continue to publish the synth prices on chain to the `ExchangeRates` contract however users will not be able to exchange or transfer them until the price shock is investigated as legitimate before resuming. The behaviour would mimic decentralised chainlink oracles which continue updating prices onchain regardless of the status of the synth's traded on synthetix exchange.

Once paused, we have a number of systems in place to alert the protocol DAO in the scenario where the circuit breaker is tripped and requires investigation before the protocol DAO re-enables the synth.

**The synth cannot be resumed by the circuit-breaker oracle due to access control restrictions**.

Resumption of a synth that has been suspended by the circuit breaker will be possible only by the [Protocol DAO](https://contracts.synthetix.io/ProtocolDAO) (see Rationale below) after investigating the price shock and confirming oracle feeds are stable.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

This phased approach is designed to give us as much protection now as possible while we still have centralised services yet also planning for the next decentralized phase.

In order to decentralize the resuming of synths process, work is ongoing to connect an Aragon DAO contract (or similar token holder voting system) so that SNX stakers are able to vote to resume without the Protocol DAO's intervention (a separate SIP will address this).

The next phase of this circuit breaker will be performed on-chain by modifying the exchange functionality within Synthetix (also another SIP). This decentrazlied approach will alleviate the need for the circuit-breaker oracle altogether. Instead of an oracle, the check will performed on-chain via the `Synthetix.exchange()` function itself, so that an exchange from / into the synth will pause the synth if there has been a price update above the threshold. Once the decentralized circuit-breaker is implemented, the circuit-breaker oracle will be deactivated.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

1. When the underlying price of any crypto synth, tracked via the `ExchangeRates` contract, changes by more than `25%` up or down between a single update, then the `SystemStatus.suspendSynth(synth)` function will be automatically invoked by the circuit-breaker oracle.
2. When the underlying price of any traditional synth, tracked via a Chainlink `AggregatorInterface`, deviates by more than `10%` from the off-chain oracle price sources, then the `SystemStatus.suspendSynth(synth)` function will be automatically invoked by the circuit-breaker oracle.
3. When the `SystemStatus.resumeSynth(synth)` function is invoked by the circuit-breaker, it fails as it does not have access
4. When the `SystemStatus.resumeSynth(synth)` function is invoked by anyone other than the ProtocolDAO, it fails (until such time as a community vote via token holders can be implemented)
5. When the `SystemStatus.resumeSynth(synth)` function is invoked by the Protocol DAO, the synth is successfully re-enabled.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
