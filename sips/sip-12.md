---
sip: 12
title: Max gas price for exchange transactions
status: Implemented
author: Bojan Kiculovic (@kicul88), Justin J Moses (@justinjmoses), Kain Warwick (@kaiynne)
discussions-to: https://discordapp.com/invite/kPPKsPb
created: 2019-06-24
---

Max gas price for exchange transactions

## Simple Summary

This SIP proposes to introduce max gas price for transactions on Synthetix exchanges in order to prevent front running of the price oracle.

## Abstract

Front running transactions on decentralized exchanges is well known problem and usually undertaken in order to gain profits by manipulation of transaction order in a block.

In case of Synthetix, front running occurs when a user or bot reads an incoming oracle update from the mempool and transmits an exchange with higher GWEI, taking advantage of a known price movement. This has happened on several occasions already, and while there is a locking mechanism now in place from [SIP-7](./sip-7.md), the time for the locks to commit is both slowing down oracle updates and hurting legitimate users. This necessitates a change that would set maximum gas price for every transaction taking place on Synthetix exchange. Every transaction with gas price higher than max should be dropped by the `Synthetix` smart contract.

## Motivation

The previous design of the Synthetix price oracle system was easily exploited by front running price update transactions. The “attack” allowed anyone to gain instant profits without taking appropriate risk. This profit comes at the expense of minters, because their debt would rise with every profitable front running transaction. Besides debt enlargement, another implication of front running is that, in order to cash out profits they would need to exchange gained synths for BTC, ETH or USDT, thus creating very strong and constant pressure on the peg.

This type of front running has since been mitigated by [SIP-7](./sip-7.md) with the introduction of trading locks. However the locks have two drawbacks:

1. They take some time to confirm on chain - from a few seconds to over a minute even with > `fastest` gas used during times of congestion; this has the potential of slowing down our oracle updates, causing our pricing to be off enough from the market for technical front running; and
2. Genuine users can get caught out with these locks if their timing is off.

As such, we believe that a max gas price solution is a good step forwards, negating the need for the lock. Ultimately however, it is just a step towards a complete solution, we won't solve front running completely until we change the way our exchanges are processed (stay tuned).

## Specification

The most important part is that this gas price limit is set below or equal the `Gwei` price at which oracle transaction is sent in order to ensure that oracle transaction is executed first in the Ethereum block.

There are at least 2 ways in which this change could be implemented:

1. **Static**: This is simpler and more straightforward one, where there is some arbitrarily gas price set, for example 20-30 Gwei.

2. **Dynamic**: This is more complex and similar to what Bancor have created. It would need to take congestion on Ethereum into consideration.

As can be seen lately, congestion is the new norm in Ethereum, so the Dynamic option is the only viable one.

The proposal for Dynamic gas pricing is as follows:

- To initially update our centralized oracle to track both `standard` and `fast` (roughly < 5 and < 2 min respectively to confirm) gas prices and calculate a gas limit from these. When this number deviates from some small percentage to the limit on-chain, it must update it;
- To update `Synthetix.sol`, adding prevention of using more gas than the gas price oracle allows above;
- To update our centralized oracle to always use substantially more than the gas price oracle. Moreover, the oracle is to no longer invoke the price update lock before each update.

> Initially the plan is to use the centralized SNX Oracle to update the gas limit on-chain, but there are plans in the works to move to a decentralized oracle in the near future.

## Rationale

Implementing a maximum gas price on exchange transactions and setting it just below the gas price of oracle update transactions will prevent front running and minimize disruption to legitimate exchanges (for normal users who don't need their exchange to be mined immediately and can wait a few blocks).

The example below illustrates how this mechanism will function:

1. An oracle (initially the SNX Oracle, moving to a decentralized oracle in the near term) reads and averages the current `standard` and `fast` gas prices using public APIs as `10`, `20` gwei respectively and sets the max limit to halway (adjustable) between `standard` and `fast` - i.e. at `15`.;
2. A frontrunning bot detects a spot market deviation of `>.3%` (assuming a fee of 30bps). It issues an exchange at the highest GWEI allowed by the `Synthetix` contract, which is `15` from above;
3. The SNX Oracle reads `fastest` and `fast` (which let's say have dropped to `12` and `10` say). It updates its gas price to `125%` (adjustable) of `Math.max(fastest, currentGasLimit)`. Which is `18.75` gwei;
4. Both txs are broadcast simultaneously, the exchange bot at `15` and the SNX Oracle rate update at `18.75` gwei;
5. The rate update confirms first ensuring that the frontrunning bot trades after the price update, ensuring it gets the current live rate from the spot market.

It is important to note that this mechanism relies on two components:

1. An oracle with accurate and timely estimates for gas prices in the network (this is non-trivial)
2. A real-time exchange rates oracle that can respond quickly to price deviations

It is possible, and even probable that this mechanism could still be frontrun, although with far less frequency than the current mechanims, if the gas price estimates are inaccurate and/or delayed and a sufficiently sophisticated frontrunning bot can reliably predict the likelihood of a spot rate change greater than 30bps faster than the oracle.

## Test Cases

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation

The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
