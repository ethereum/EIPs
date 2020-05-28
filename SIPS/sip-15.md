---
sip: 15
title: SNX liquidation mechanism
status: WIP
author: Jackson Chan (@jacko125), Kain Warwick (@kaiynne)
discussions-to:
created: 2019-08-20
---

## Simple Summary

This SIP proposes a liquidation mechanism for SNX collateral. Synths can be redeemed for staked SNX at a discount if the collateral ratio of a staker falls below the liquidation ratio for two weeks.

## Abstract

Create a liquidation mechanism for under collateralised SNX Collateral to be redeemable with Synths at a discounted price (liquidation penalty fee).

Instead of instant liquidations for positions below the Liquidation ratio, a delay will be applied, so it will only be possible to liquidate SNX collateral if a staker's collateral ratio is not fixed by the time the delay expires.

## Motivation

In a crypto-backed stablecoin system such as Synthetix, the issued stablecoin (synths) tokens should represent claims on the underlying collateral. The current design of the Synthetix system doesn't allow holders of synths to directly redeem the underlying collateral unless they are burning and unlocking their own SNX collateral. The value of the synths issued in the synthetix system is derived from incentivising minters to be over-collateralised on the debt they have issued and other economic incentives such as exchange fees and SNX rewards.

If a minter's collateral value falls below the required collateral ratio, there is no direct penalty for being under collateralised, even in the unlikely event where the value of their locked collateral (SNX) is less than the debt they owe. Stakers and synth holders should be able to liquidate undercollateralised minters at a discounted price to restore the network collateral ratio.

Liquidation encourages minters to remain above the required collateral ratio and creates strong economic incentives for stakers to burn synths to restore their collateral ratio if they are at risk of being liquidated.

Liquidation gives SNX holders and issuers of Synthetic synths these benefits:

1. Provides instrinsic value to Synths by enabling direct redemption into the underlying collateral (SNX).
2. Any Synth holder can ensure the stability of the system by liquidating stakers below the liquidation ratio restoring the network collateral ratio.
3. Incentivises a healthy network collateral ratio by providing a discount on the liquidated SNX collateral.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->
**Liquidation Target Ratio**

Liquidations are capped at the Liquidation Target ratio which is the current Issuance Ratio. This is the ratio SNX collateral can issue debt to provide the system with sufficient capital to buffer price shocks and active stakers are required to maintain to claim fees and rewards.

Modeling shows that at a liquidation ratio of 200%, if liquidators were to repay and fix the staker's collateral ratio to 800%, then about 44% of the staker's SNX collateral will be liquidated to repair the undercollateralised position.

The amount of sUSD required to fix a staker's collateral to the target issuance ratio is calculated based on the formula:

- V = Value of SNX
- D = Debt Balance
- t = Target Collateral Ratio
- S = Amount of sUSD debt to burn
- P = Liquidation Penalty %

\\[
S = \frac{t * D - V}{t - (1 + P)}
\\]

**Liquidation Ratio**

The liquidation ratio to initiate the liquidation process will be set at `200%` initially and adjustable by an SCCP. This ensures there is sufficient buffer for the staker's collateral. The lower bound for the liquidation ratio would be `100% + any liquidation penalty` to pay for liquidations.

**Liquidation Penalty**

The liquidation penalty is paid to the liquidator and is paid as a bonus on top of the SNX amount being redeemed.

For example, given the liquidation penalty is 10%, when 100 SNX is liquidated, then `110 SNX` is transferred to the liquidator.

The maximum liquidation penalty will be capped at `50%`.

### Liquidations Contract

Liquidations contract to mark an SNX staker for liquidation with a time delay to allow staker to fix collateral ratio.

**Parameters**

- `Liquidation Delay`: Time before liquidation of under collateralised collateral.
- `Liquidation Penalty`: % penalty on SNX collateral liquidated.
- `Liquidation Ratio`: Collateral ratio liquidation can be initiated.

**Interface**

```
pragma solidity >=0.4.24;

interface ILiquidations {
    // Views
    function isOpenForLiquidation(address account) external view returns (bool);

    // Mutative Functions
    function flagAccountForLiquidation(address account) external;

    // Restricted: used internally to Synthetix contracts
    function removeAccountInLiquidation(address account) external;

    function checkAndRemoveAccountInLiquidation(address account) external;

    // owner only
    function setLiquidationDelay(uint time) external;

    function setLiquidationRatio(uint liquidationRatio) external;

    function setLiquidationPenalty(uint penalty) external;
}
```
**Events**

 - `AccountFlaggedForLiquidation(address indexed account, uint deadline)`
 - `AccountRemovedFromLiqudation(address indexed account, uint time)`

### Synthetix contract

---

Updates to the Synthetix contract interface

```
pragma solidity >=0.4.24;

interface ISynthetix {
    // Mutative Functions
    function liquidateDelinquentAccount(address account, uint susdAmount) external returns (bool);
}
```

### Escrowed SNX

---

Current escrowed SNX tokens in the RewardsEscrow will require a planned upgrade to the RewardsEscrow contract as per [SIP-60](./sip-60.md) to be included as part of the redeemable SNX when liquidating snx collateral. The escrowed snx tokens will be transferred to the liquidator and appended to the rewardsEscrow.

Mitigating this issue is the fact that in order to unlock all `transferrable` SNX a minter would have to repay all of their debt and re-issue debt at the issuance ratio (currently 800%).

### Insurance fund for liquidations
---

In the scenario where a staker's Collateral ratio falls below 100% + liquidation penalty, ie (110%) then the staker's collateral will not fully cover the repayment of all their debt and the liquidation penalty. Liquidators should still be able to partially liquidate the debt until there is not enough collateral to repay all the remaining debt and also provide the liquidation penalty incentive.

In the next iteration of Synthetix's liquidation mechanism, an SNX insurance fund will be set up to cover under-collateralised liquidations where any shortfall in SNX collateral will come out of the insurance fund to pay liquidators. This would allow the liquidators to repay all the debt of stakers who have no remaining SNX collateral after being liquidated.

## Rationale

The reasoning behind implementing a direct redemption liquidation mechanism with a delay function is to provide a mechanism to purge positions for which the primary incentives have failed. Under most circumstances we have observed that the majority of stakers maintain a healthy ratio to ensure they can claim staking rewards or in extreme cases they exit the system by burning all debt and selling their SNX. Even in the case of a major price shock the majority of wallets have more collateral value than their Synth debt so the optimal strategy is stil to burn debt and recover the collateral. In the case where this does not happen a fallback incentive to remove these undercollateralised positions is required. However, given these wallets are likely to be edge cases so long as the collateral ratio remains above 500% (currently 800%) it is important to not open an attack vector that would enable a malicious party to attempt to manipulate the price of SNX to liquidate positions. Due to the time delay implemented in the mechanism the cost of attack far exceeds the potential reward making it unlikely a rational actor would pursue this strategy. The tension in this implementation is therefore between the time it takes to remove an undercollateralised position and the risk that liquidations are used as an attack vector against stakers. The default thresholds and delays implemented err on the side of protecting stakers and can therefore be reduced over time if liquidations are deemed too inefficient.

The rationale for these liquidation mechanisms are:

- **Time Delay:** A time delay increases the cost to a malicious actor who attempts to manipulate the SNX price to trigger liquidations and reduces the risk of black swan events.

- **Liquidation Penalty:** A liquidation penalty payable to the liquidator provides incentives for liquidators and minters to fix their collateral ratio. Liquidators can burn synths and claim SNX at a discounted rate.

- **Partial liquidations:** Partial liquidation of under collateralised SNX reduces the risk of minter's losing all their staked collateral from liquidation and allows a proportion of their debt to be paid back to fix their collateral ratio. Multiple liquidators can benefit from burning any amount of sUSD synth until the c-ratio is above the liquidation target ratio.

- **Liquidation target ratio:** A liquidation target ratio works alongside partial liquidations allowing a proportion of snx to be liquidated until the staker's collateral ratio is above the liquidation target ratio. At this ratio it would provide enough buffer in the collateral to again fully back the debt issued.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Given Alice has issued synths with 800 SNX, with a debt balance of 533.33 sUSD and now has a collateralised ratio of 150% and Bob acts as a liquidator with sUSD,

Given the following preconditions:

- liquidation ratio is 200%
- liquidation cap is 300%
- liquidation penalty is 10%
- and liqudatiion delay is set to _2_ weeks.

***

When

- Bob flags Alice address for liquidation

Then

- ✅ It succeeds and adds an liquidation Entry for Alice as flagged
- ✅ It sets deadline as block.timestamp + liquidation delay of _2_ weeks.
- ✅ It emits an event accountFlaggedForLiquidation(account, deadline)

***

When

- Bob or anyone else tries to flag Alice address for liquidation again

Then

- ❌ It fails as Alice's address is already flagged

***

Given

- Alice does not fix her c ratio by burning sUSD back to the Liquidation Target ratio
- and two weeks have elapsed
- and SNX is priced at USD 1.00

When
- bob calls liquidateSynthetix and burns 100 sUSD to liquidate SNX

Then

- ✅ Bob's sUSD balance is reduced by 100 sUSD, and Alice's SNX is transferred to Bob's address. The amount of SNX transferred is:
- `100 sUSD / Price of SNX` = `100 sUSD / $1 = 100 SNX redeemed` + liquidation penalty `100 * 10% = 110 SNX` transferred to Bob.
- Alice debt is reduced by 100 sUSD to `433.33 sUSD` and she has `690 SNX` remaining.

***

Given

- After Bob's liquidating 100 sUSD worth of SNX, Alice collateral ratio at 158.77% is still below the liquidation target ratio.

When
- Chad tries to liquidate Alice's SNX collateral with 50 sUSD
- and the result Collateral ratio, after reducing by 50 sUSD, is less than the target issuance ratio

Then

- ✅ Chad's sUSD balance is reduced by the 50 sUSD
- `50 SNX + 10% SNX = 55 SNX` is transferred to Chad
- Alice's debt is reduced by a further 50 sUSD to `383.33 sUSD` and she has `635 SNX` remaining.

***

When

- Bob now tries liquidating a larger amount of sUSD (1000 sUSD) against Alice's debt.
- 1000 sUSD takes Alice's collateral ratio above the liquidation target ratio (300%)

Then

- ✅ Bob's liquidation transaction only partially liquidates the `1000 sUSD` to reach 800% target
- ✅ Alice's liquidation entry is removed and returns false
- ✅ An event is emitted that liquidation flag is removed for her address

---

When

- Alice has been flagged for liquidation
- and the price of SNX increases so her Collateral ratio is now above the liquidation target ratio
- and she calls checkAndRemoveAccountInLiquidation

Then

- ✅ Her account is removed from liquidation
- and the liquidation entry is removed

***

When

- Alice has been flagged for liquidation
- and the price of SNX doesn't change so she is still below the liquidation target ratio
- and she calls checkAndRemoveAccountInLiquidation

Then

- ❌ it fails

When

- Alice has not been flagged for liquidation
- and she calls checkAndRemoveAccountInLiquidation

Then

- ❌ it fails and reverts with error 'Account has no liquidation set'

***

When

- Alice has been flagged for liquidation
- and the liquidation deadline has passed
- and her collateral ratio is above the liquidation target ratio
- and Bob tries to liquidate Alice calling `liquidateSynthetix()`

Then

- ✅ Her account is removed from liquidation within liquidateSynthetix transaction
- and no sUSD or debt is burned by Bob
- and no SNX is liquidated and transferred to Bob.

---

When

- Alice has been flagged for liquidation
- and she burns sUSD debt to fix her collateral ratio above the liquidation target ratio

Then

- ✅ Her account is removed from liquidation within the burn synths transaction

---

## Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->
Please list all values configurable via SCCP under this implementation.

- liquidationDelay
- liquidationRatio
- liquidationPenalty

## Implementation

The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
