---
sip: 63
title: Trading Incentives
status: WIP
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125)
discussions-to: TBC

created: 2020-05-28
---

## Simple Summary

This SIP proposes to track and record the fees paid by each address during each fee period to enable the distribution of trading incentives from a pool of SNX.

## Abstract
The exchanger contract will be updated to write to a Trading Incentives contract after each succesful exchange. The trading incentives contract will be a modified version of the LPRewards contract, each time fees are paid the balance of fees paid will be added to the Trading Incentives contract. SNX will be deposited manually each fee period into this contract and traders will earn a portion of this SNX as they pay trading fees. 

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
Exchanger will be modified to write to a Trading Incentive contract each time a trade is completed. The function will check the total fees paid in that fee period and add the additional fees paid in that exchange to this balance.

This fee balance will be used to calculate the distribution of the SNX during that period. At the end of the period the balance will need to be reset for each address and fees will begin to accumulate again. Balances will be zeroed when the new SNX is deposited from the inflationary supply or manually during the trial period.

### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
We considered a number of approaches to this problem, including minting fee tokens and paying incentives immediately on each trade. There are several benefits to this approach over the alternatives considered. The first is that users can accumulate as many fees as they want before claiming reducing gas costs and allowing even small traders to wait until they have sufficient fees to justify a withdrawal. Secondly this negates the requirement of handling fee period rollovers or unclaimed fees as trading incentives are not dependent on feepool periods. Each week the balanance of fees paid is wiped when the new SNX deposit is made ensuring all traders start each fee period with an equal chance to earn fees.

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones. 

**Trading Incentive Contract**

When an exchange is made by a user on Synthetix Exchange, the amount of fees remitted (in sUSD) and user the funds are exchanged `from` will be recorded in the `Trading incentive contract`. Each `address` will accumulate the total of exchange fees that they generate for a period (tracked as a `periodID`) and the counter is reset when SNX for the incentives is deposited for the period and a user makes another trade. The total of the previous period will be stored on the next trade regardless of how long ago the last trade was.   

For exchanges occuring through integrations and exchange aggregators such as `1inch` there will be a function that allows an `address` to be passed through the exchange to be recorded against the originating address for the trading volume incentives. 

The `trading incentive` contract will track the `totalFeesInPeriod` for each period generated by exchanges, which will be used for calculating the % of the fees an account has generated in that period and hence the % of the SNX rewards they will be allocated. 

The snx rewards an account can claim for a period is calculated as:

\\[ reward = \frac{Account's Exchange Fees for period}{Total Exchange Fees for period} * SNX rewards for period 
\\]

The `totalFeesInPeriod` will be stored and kept for each period once the new SNX is deposited for that period and closes it, resetting the balances for the next period to accumulate. 

This allows the account's to claim their trading incentives in any period they want in the future and combining multiple periods to claim.

**Interface**

```
pragma solidity >=0.4.24;

interface ITradingIncentive {
  // Views
  function rewards(address account, uint periodID) external view; 
  
  function rewardForPeriods(address account, uint[] periodIDs) external view;
  
  // Mutative Functions
  function recordExchangeFee(uint amount, address account) external;
  
  function claimReward(uint periodID) external;
  
  function claimRewardForPeriods(uint[] periodIDs) external;
  
  // owner only
  function notifyRewardAmount(uint reward) external;
}
```

**Exchanger contract**

Remit exchange fees generated by an account to the `Trading incentive` contract, storing the total fees for each account in the contract. 

Referrals - A function to allow trading incentives to be recorded against any `address` instead of the `msg.sender` of the `synthetix.exchange()` event. The `address` will need to be the one claiming the rewards from the `trading incentive` contract.    

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
- When an exchange is made, the exchange fee in sUSD and the address the exchange `from` gets stored in the trading incentives contract and the `totalFeesInPeriod` is increased by the exchange fee amount.
- When a delegatedExchange is made, the exchange fee in sUSD and the address the exchange `from` gets stored in the trading incentives contract and the `totalFeesInPeriod` is increased by the exchange fee amount.
- When an exchange is made, the exchange fee is added to the `totalExchangeFees` for the account, a value accumulated for the period until it is closed. 
- When an exchange is made, if the account last made a trade in a previous period, it will store their `totalFeesInPeriod` for the previous period and reset the value for the current period.
- When an exchange is made, if an address is passed in to record the trading incentives for, then it will store the total fees against that address.
- Given a referral address is sent in an exchange, the referral address will be recorded on the trading incentives contract and the exchange fees attributed to it.

- When notifyRewards is called, if the SNX balance is already transferred to the contract, then it passes. The transaction will record the `totalFeesInPeriod` for the current period and reset it. It will also increment the `periodID`.

**Reward Claiming**

- When a user claim their rewards, their reward will be calculated as a proportion of the fees they generated against the total fees of that period and the period is marked claimed for the user.
- When a user claim their rewards, if the claim is successful, it will record the final `totalFeesInPeriod` for the last  reward period if the period is closed, and reset their current `totalFeesInPeriod`. 
- When a user claim their rewards, if the claim is successful, it will increase the `totalRewardsClaimed` amount which ensures the contract has enough SNX to pay the rewards (on notifyRewards it will check the contract balance less `totalRewardsClaimed`.   
- When a user claim their rewards, if the period they provide has no fees generated, then it will fail.
- When a user claim their rewards, if the period they provide is already claimed, then it will fail.
- When a user claim their rewards, if the period they claim for has not been finalised and closed then it will fail. 

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
Please list all values configurable via SCCP under this implementation.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
