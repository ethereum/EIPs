---
sip: 97
title: Multi-Collateral Loans
status: Proposed
author: Michael Spain (@mjs-12), Clinton Ennis (@hav-noms)
discussions-to: https://research.synthetix.io/
created: 2020-11-19 
requires: 
---

## Simple Summary

Allow users to borrow synthetic assets against ETH and ERC20 collateral.

## Abstract

By locking collateral into Synthetix, users can borrow synthetic assets (synths) against the value of their collateral. A borrower's debt is fixed at the time the loan is created. This is in contrast with the debt of an SNX staker, which fluctuates with the composition of the debt pool. Since borrowers assume no responsibility for maintenance of the debt pool they are ineligible to receive fees or rewards. Instead, they are charged interest in proportion with the risk that they introduce to the system, which is paid weekly to SNX stakers via the fee pool. 

Initially, the system will support borrowing sUSD/sETH against ETH and sUSD/sBTC against renBTC. We may also consider allowing sUSD to be borrowed against SNX as a fixed debt position.

## Motivation

As Synthetix grows, the limitations of a single collateral system are becoming apparent.

- SNX price volatility requires significant overcollateralisation, making the system relatively capital inefficient.
- It introduces friction by requiring prospective traders to either exchange their assets directly for synths or buy and stake SNX.

As the two largest and most liquid assets, BTC and ETH are considerably less volatile than SNX and therefore can be borrowed against at lower collateralisation levels. They are also the most widely held assets, representing a huge market of potential traders. Allowing these users to access Synthetix whilst maintaining their BTC/ETH exposure will make the system more enticing. Having already successfully trialed ETH as collateral, we would like the system to be positioned to capture the increasing amount of tokenised Bitcoin that is entering Ethereum.

An implementation that supports generic ERC20 collateral would also mean that additional collateral could be added without requiring technichal work.

## Specification

### Loans

A loan is a debt position taken out by a borrower and is denominated in a specific synth. To open a loan, the borrower must deposit collateral. Depending on the type of collateral deposited, the borrower will have a choice of different synths that can be borrowed. They may also choose the amount borrowed, subject to the constraint that the ratio of collateral value to synth value is greater than some minimum. 

The duration of the loan is at the discretion of the borrower. While open, the loan accrues interest according to a variable rate that will be discussed later. Repayments can be made at any time, by anyone, but only the borrower may close the loan. 

If the collateralisation ratio of the loan falls below the minimum, it will be eligible for liquidation. To increase the loan's collateralisation ratio, anyone can deposit collateral to an open loan. The borrower can also withdraw collateral as long as they do not violate the minimum collateralisation requirement.

A loan can be summarised by the following fields.

| Symbol | Description | Example |
| ------ | ----------- | ----- |
| \\(c\\) | Collateral locked | 1 ETH | 
| \\(p_c\\) | USD price of the collateral | $100 | 
| \\(s\\) | Synth borrowed | 10 sUSD |
| \\(p_s\\) | USD price of the synth | $1 | 
| \\(I\\) | Interest accrued on the loan | 5 sUSD| 

From these fields, we can determine the loan's collateralisation ratio.

\\( r \ := \frac{p_c \ c}{p_s \ (s + I)}\\) 

Each type of collateral is implemented by its own smart contract and is responsible for the issuance and management of all the loans associated with it. It is distinguished by several variables.

| Symbol | Description | Notes |
| ------ | ----------- | ----- |
| \\(S\\)  | Synths that can be issued | For example [sUSD, sETH] or [sUSD, sBTC] |
| \\(b\\)  | Base interest rate | A configurable parameter that reflects the risk profile of the collateral. |
| \\(ratio_{min}\\) | Minimum collateralisation ratio | This limits the maximum loan that can be issued for a certain amount of collateral. If a loan falls under this threshold, it is eligible for liquidation. |

### Debt pool and Interest

Each loan contributes to the size of the debt pool. When a loan is opened, the debt pool increases by the amount of the synth borrowed. While the debt of the borrower is fixed, they are free to exchange their synths. This means that the profit/loss from their trading activities is absorbed by the SNX stakers and increases in proportion with the ratio of non SNX debt to SNX debt. We call this utilisation ratio \(U\) and require that as it increases, the cost of borrowing increases with it, to compensate stakers for the increased risk. A simple linear funtion is sufficient for our needs.

\\(i \ := \ mU + b \\)

Utilisation changes anytime the debt pool composition changes. It is not feasible to update every loan whenever the debt pool changes. Instead, whenever a loan is interacted with, we check the utilisation and determine the total accrued interest per base currency unit, using the same approach described by [SIP 80](https://sips.synthetix.io/sips/sip-80#aggregate-debt-calculation). This means we can calculate the interest accrued on a particular loan in constant time. Interest is charged whenever a repayment is made, a liquidation occurs, or a loan is closed.

### Liquidations

When a loan's collateralisation ratio falls below the minimum collateralistion required, it is eligible for liquidation. Liquidation is a public function that may be performed by anyone. The liquidation mechanism is the same as described in [SIP 15](https://sips.synthetix.io/sips/sip-15). The liquidator pays an amount of the borrowed synth back, and receives an amount of the borrower's collateral equal to the liquidated amount plus a penalty.

## Rationale

### Interest considerations

In systems where borrowers access the collateral of other depositors, there is a tension between utilisation and liquidity risk. If all the deposited ETH is borrowed, depositors cannot access any liquidity, which is a highly undesirable state. So they use piecewise functions to rapidly increase the cost of borrowing beyond some utilisation threshold. In Synthetix, users do not borrow the collateral of other users, rather the borrowed assets are created at the time the loan is issued.

## Test cases

Included with the implementation.
