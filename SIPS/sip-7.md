---
sip: 7
title: Oracle Trading Locks
status: Implemented
author: Jackson Chan (@jacko125), Kain Warwick (@kaiynne), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/FHPnPk

created: 2019-07-09
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
SIP-6 was effective in removing several front-running bots, but these bots have rapidly adapted to the mechanism implemented in SIP-6. SIP-6 was always intended to be a short term deterrent. This SIP intends to be a longer term solution to front-running. It enables the oracle service to perform three functions:
1. Pause exchanges
2. Prevent trades while an oracle update is in progress
3. Removes the destination param in an exchange so that exchanges only go to the messageSender

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
There is an attack vector that allows front-running the oracle by observing exchange rate update transactions after they are broadcast, then attempting to trade into a currency that will shift in favour of the trade. This front-running attack is extremely effective if well constructed and provides almost risk free profits. This SIP will likely render this method ineffective, as it will halt trading when the oracle detects a change in price. Once the trading halt is in place the oracle will push a price update and re-enable trading. This means that a trade broadcast right as an oracle update occurs will likely be rejected and have to be resubmitted, which impacts usability but we are planning UI updates to prevent this from impacting users on Synthetix.Exchange.

Any trades / exchanges during the lock period will revert and no balances be affected. The balance of the gas paid for the transaction will be returned the wallet, about 90+ %. 

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The motivation for this change is the same as for SIP-6, it is critical that users of the exchange do not have the ability to exploit the latency of the blockchain to make profit at the expense of SNX holders. While we welcome trading bots using valid strategies we believe the network must be able to prevent and punish users attempting to exploit this latency.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
The oracle code is currently closed source, so we will not be publishing the exact spec of the mechanism. But before the Oracle submits an exchange rate transaction it will submit a flag to halt trading, and only remove this flag once the price update has been confirmed on-chain.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
While SIP-6 was a slashing condition to punish front-running, this SIP address the root cause of the attack which is the ability to submit a trade before the oracle can reset rates. A bot could attempt to avoid slashing using several methods that would have reduced the efficacy of SIP-6 over time. This SIP combined with SIP-6 should change the calculus for a bot owner because the likelihood of profitability has been significantly reduced while still incurring the risk of slashing via SIP-6.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
https://github.com/Synthetixio/synthetix/blob/master/test/ExchangeRates.js#L1027

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
https://github.com/Synthetixio/synthetix/blob/master/contracts/ExchangeRates.sol#L308

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
