---
sip: 63
title: Trading Incentives
status: WIP
author: Kain Warwick (@kaiynne)
discussions-to: TBC

created: 2020-05-28
---

## Simple Summary

This SIP proposes to track and record the fees paid by each address during each fee period to enable the distribution of trading incentives from a pool of SNX.

## Abstract
The feepool contract will be updated to write to a Trading Incentives contract after each succesful exchange. Feepool will read the current trading fees paid in that period by the address and add the trading fees paid in that exchange. The trading incentives contract will be a modified version of the LPRewards contract, each time fees are paid the balance of fees paid will be added to the Trading Incentives contract. SNX will bde deposited manually each fee period into this contract and traders will earn a portion of this SNX as they pay trading fees. 

## Motivation
There is currently no way to track trading fees paid on-chain, so it is not possible to reward traders who pay more fees on the exchange. Paying fee rebates is a very powerful way of reducing friction and switching costs for new traders. However, where CEX's can identify users and pay onboarding fees and other incentives a DEX does not have this ability so using a pooled mechanism rather than a direct rebate per user ensures the total fee incentive does not exceed a specified amount and cannot be sybil attacked. The pooled mechanism also ensures that traders who trade earlier are rewarded more than later traders incentivising traders to test out the exchange sooner. While the sX trading experience has improved significantly, there is still friction due to latency and other limitations. While we fully expect these limitations to be reduced or eliminated entirely in the near future, attracting new traders is critical to the growth of the platform. The trading experience is now sufficiently differentiated that the experience is likely to be positive relative to other DEX's particularly with respect to slippage and fees. This pooled mechanism also introduce the ability to add referal incentives and other mechanism if the base incentive proves successful. 

## Specification
<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview
Feepool will be modified to write to a Trading Incentive contract each time a trade is completed. The function will check the total fees paid in that fee period and add the additional fees paid in that exchange to this balance.

This fee balance will be used to calculate the distribution of the SNX during that period. At the end of the period the balance will need to be reset for each address and fees will begin to accumulate again. Balances will be zeroed when the new SNX is deposited from the inflationary supply or manually during the trial period.

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
We considered a number of approaches to this problem, including minting fee tokens and paying incentives immediately on each trade. There are several benefits to this approach over the alternatives considered. The first is that the rewards are paid out on a form of bonding curve with higher rewards paid earlier when there are fewer fees accumulated in that period. The second is that users can accumulate as many fees as they want before claiming reducing gas costs and allowing even small traders to wait until they have sufficient fees to justify a withdrawal. The third is that this negates the requirement of handling fee period rollovers or unclaimed fees. Each week the balanance of fees paid is wiped when the new SNX deposit is made ensuring all traders start each fee period with an equal chance to earn fees.

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones. 

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
Please list all values configurable via SCCP under this implementation.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
