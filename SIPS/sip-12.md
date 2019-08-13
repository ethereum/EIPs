---
sip: 12
title: Max gas price for exchange transactions
status: Proposed
author: Bojan Kiculovic @kicul88
discussions-to: https://discordapp.com/invite/kPPKsPb
created: 2019-06-24
---

Max gas price for exchange transactions

## Simple Summary
This SIP proposes to introduce max gas price for transactions on synthetix exchange in order to prevent front running of price oracle.

## Abstract
Front running transactions on decentralized exchanges is well known problem and usually undertaken in order to gain profits by manipulation of transaction order in a block. 
In case of Synthetix, front running oracle transaction would allow front runner to gain instant profits without risk. There are some prerequisites, in terms of price dynamics, in order for those transactions to be profitable, but those prerequisites could be easily and very quickly calculated from data found in pending oracle update transaction. I won't go into details about those profitable calculations, but can give team some examples if they  need. With introduction of new synths, potentially profitable front running transactions will grow exponentially. This has happened on several occasions already and is necessitating a change that would set maximum gas price for every transaction taking place on synthetix exchange. Every transaction with gas price higher than max should be dropped by smart contract.


## Motivation
Current design of Synthetix price oracle system could be easily exploited by front running price update transactions. This “attack” allows anyone to gain instant profits without taking appropriate risk. This profit comes at the expense of minters, because their debt will rise with every profitable, front running transaction. Besides debt enlargement, another implication of front running is that, in order to cash out profits, front runner would need to exchange gained synths for BTC, ETH or USDT, thus creating very strong and constant pressure on the peg.


## Specification
The most important part is that this gas price limit is set below or equal the Gwei price at which oracle transaction is sent in order to ensure that oracle transaction is executed first in the Ethereum block.
There are at least 2 ways in which this change could be implemented :
Statical. This is simpler and more straightforward one, where there is some arbitrarily gas price set, for example 20-30 Gwei. 
 
Dynamical.  This is more complex and similar to what Bancor have created. It would need to take congestion on Ethereum into consideration.


## Rationale
By implementing maximum gas price on exchange transactions and setting it just below the gas price of oracle update transactions, would prevent front running.


## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
