---
sip: 15
title: SNX liquidation mechanism
status: WIP
author: Jackson Chan (@jacko125), Kain Warwick (@kaiynne)
discussions-to:
created: 2019-08-20
---

## Simple Summary

This SIP proposes a liquidation mechanism for SNX collateral. Synths can be redeemed for staked SNX at a discount if the collateral ratio of a staker falls below the liquidation ratio for a two weeks.

## Abstract

Create a liquidation mechanism for under collateralised SNX Collateral to be redeemable with Synths at a discounted price (liquidation penalty fee).

Instead of instant liquidations for positions below the Liquidation ratio, a delay will be applied, so it will only be possible to liquidate SNX collateral if a staker's collateral ratio is not fixed by the time the delay expires.

## Motivation

In a crypto-backed stablecoin system such as Synthetix, the issued stablecoin (synths) tokens should represent a claims on the underlying collateral. The current design of the Synthetix system doesn't allow holders of synths to directly redeem the underlying collateral unless they are burning and unlocking their own SNX collateral. The value of the synths issued in the synthetix system is derived from incentivising minters to be over-collateralised on the debt they have issued and other economic incentives such as exchange fees and SNX rewards.

If a minter's collateral value falls below the required collateral ratio, there is no direct penalty for being under collateralised, even in the unlikely event where the value of their locked collateral (SNX) is less than the debt they owe. Stakers and synth holders should be able to liquidate undercollateralised minters at a discounted price to restore the network collateral ratio.

Liquidation encourages minters to remain above the required collateral ratio and creates strong economic incentives for stakers to burn synths to restore their collateral ratio if they are at risk of being liquidated.

Liquidation gives SNX holders and issuers of Synthetic synths these benefits:

1. Provides instrinsic value to Synths by enabling direct redemption into the underlying collateral (SNX).
2. Any Synth holder can ensure the stability of the system by liquidating stakers below the liquidation ratio restoring the network collateral ratio.
3. Incentivises a healthy network collateral ratio by providing a discount on the liquidated SNX collateral.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

### Liquidations Contract

Liquidations contract to mark an SNX staker for liquidation with a time delay to allow staker to fix collateral ratio.

**Parameters**

* `Liquidation Delay`: Time before liquidation of under collateralised collateral.
* `Liquidation Penalty`: % penalty on SNX collateral liquidated.
* `Liquidation Ratio`: Collateral ratio liquidation can be initiated.
* `Liquidation Target Ratio`: Target collateral ratio liquidations are capped at.

#### flagAccountForLiquidation(address account)

**Function signature**

`flagAccountForLiquidation(address account) external`

#### removeAccountInLiquidation(address account)

**Function signature**
`removeAccountInLiquidation(address account) external onlyInternalContract`

#### checkAndRemoveAccountInLiquidation(address account)

**Function signature**

`checkAndRemoveAccountInLiquidation(address account) external`

#### isOpenForLiquidation(address account)

**Function signature**

`isOpenForLiquidation(address account) external`

#### setLiquidationDelay(uint40 time)

**Function signature**

`setLiquidationDelay(uint40 time) onlyOwner`

#### setLiquidationRatio(uint ratio)

**Function signature**

`setLiquidationRatio(uint ratio) onlyOwner`

#### setLiquidationPenalty(uint penalty)

**Function signature**

`setLiquidationPenalty(uint penalty) onlyOwner`

#### setLiquidationTargetRatio(uint target)

**Function signature**

`setLiquidationTargetRatio(uint target) onlyOwner`


### Synthetix contract
---

#### liquidateSynthetix(address account, uint synthAmount)

**Function signature**

`liquidateSynthetix(address account, uint synthAmount) external`

Parameters

- `address account`: account to be liquidated
- `uint synthAmount`: amount of sUSD synth the redeemer wants to redeem against the account

### Escrowed SNX
---
Current escrowed SNX tokens in the RewardsEscrow will require a planned upgrade to the RewardsEscrow contract as per [SIP-60](./sip-60.md) to be included as part of the redeemable SNX when liquidating snx collateral. The escrowed snx tokens will be transferred to the liquidator and appended to the rewardsEscrow.

Mitigating this issue is the fact that in order to unlock all `transferrable` SNX a minter would have to repay all of their debt and re-issue debt at the issuance ratio (currently 800%).

## Rationale

The reasoning behind implementing a direct redemption liquidation mechanism with a delay function is to provide a mechanism to purge positions for which the primary incentives have failed. Under most circumstances we have observed that the majority of stakers maintain a healthy ratio to ensure they can claim staking rewards or in extreme cases they simply exit the system completely by burning all debt and selling ther SNX. Even in the case of a major price shock the majority of wallets have more collateral value than their Synth debt so the optimal strategy is to burn debt and recover the collateral. In the case where this does not happen a fallback incentive to remove these undercollateralised positions is required. However, given that these wallets are likely to be edge cases so long as the collateral ratio remains above 500% (currently 800%) it is important to not open an attack vector that would enable a malicious party to attempt to manipulate the price of SNX to liquidate positions. Due to the time delay implemented in the mechanism the cost of attack far exceeds the potential reward making it unlikely that a rational actor would pursue this strategy. The tension in this implementation is therefore between the time it takes to remove an undercollateralised position and the risk that liquidations are used as an attack vector against stakers. The default thresholds and delays implemented err on the side of protecting stakers and can therefore be reduced over time if liquidations are deemed too inefficient.

The rationale for these liquidation mechanisms are:

* **Time Delay:** A time delay increases the cost to a malicious actor who attempts to manipulate the SNX price to trigger liquidations and reduces the risk of black swan events.

* **Liquidation Penalty:** A liquidation penalty payable to the liquidator provides incentives for liquidators and minters to fix their collateral ratio. Liquidators can burn synths and claim SNX at a discounted rate.

* **Partial liquidations:** Partial liquidation of under collateralised SNX reduces the risk of minter's losing all their staked collateral from liquidation and allows a proportion of their debt to be paid back to fix their collateral ratio. Multiple liquidators can benefit from burning any amount of sUSD synth until the c-ratio is above the liquidation target ratio.

* **Liquidation target ratio:** A liquidation target ratio works alongside partial liquidations allowing a proportion of snx to be liquidated until the staker's collateral ratio reaches above the liquidation target ratio. At this ratio it would provide enough buffer in the collateral to back the debt issued.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
