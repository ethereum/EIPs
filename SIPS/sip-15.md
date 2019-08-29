---
sip: 15
title: Direct Redemption of SNX collateral
status: WIP
author: Jackson Chan (@jacko125)
discussions-to:
created: 2019-08-20
---

Direct Redemption of SNX collateral with Synths

## Simple Summary

This SIP proposes to introduce direct redemption mechanism for synthetix collateral. Holders of Synths would be able to redeem their Synths against synthetix collateral that are staked, if the minter is below the liquidation ratio, at a fair discounted value.

Direct redemption gives holders and issuers of Synthetic synths these benefits:

1. Allows holders of Synths to burn synth debt on behalf of minter and redeem underlying collateral.
2. Provides instrinsic value to synth debt for anyone who holds synths as backing it with synthetix collateral that can be redeemed at fair value.
3. Stakers above the collateral ratio can protect their value in the system by liquidating another staker's collateral that is below the liquidation ratio, to fix network's collateralisation ratio.
4. Incentive for users to keep network collateral ratio healthy by providing a discount on the liquidated synthetix collateral price.
5. Minters who are being liquidated, can either buy back the synths on market to fix their collateral ratio, or allow others to do so but at a penalty.

## Abstract

In a crypto-backed stablecoin system such as Synthetix, the issued stablecoin (synths) tokens should represent a claims on the underlying collateral. The current design of the Synthetix system doesn't allow holders of synths to directly redeem the underlying collateral unless they are burning and unlocking their own synthetix collateral. The value of the synths issued in the synthetix system is derived from incentivising minters to be over-collateralised on the debt they have issued and other economic incentives such as exchange fees and SNX rewards.

If a minter's collateral value falls below the required collateral ratio, there is no direct penalty for being under collateralised, even in the unlikely event where the value of their locked synthetix collateral is less than the synths debt they owe. Stakers and synth holders should be able to liquidate these minters at a discounted price to encourage a purchase of synths debt in order to close off the minter's position.

It would encourage minters to be above the required collateral ratio and creat economic incentive to buy-back synths on market to fix their collateral ratio if they are at risk of being liquidated.

## Motivation
As above.

## Specification

1. Provide a liquidation contract for synth holders to mark a SNX staker as being listed for liquidation but give time for them to fix collateral ratio / burn debt by purchasing on market.
2. Time delayed liquidation of under-collateralised collateral.
3. Prevents black swan events where malicious actor quickly dumps a sizeable amount of SNX on CEX’s / exchanges to push the price down suddenly and target liquidation, as there is a time delay for liquidation.
4. Liquidator able to burn synths in exchange for SNX collateral at discount rate (% of the current value) as a penalty for under-collateralised staker.
5. Liquidator pays off debt owed by a minter and minter gets balance of collateral returned minus a discount amount that is rewarded to liquidator.  
6. Other collateral asset types can have separate liquidation thresholds and time frames for redemption if under-collateralised.

## Rationale

Sets a mechanism for direct redemption of synthetix collateral by synth holders and a peanlty for minters who do not fix their collateralisation ratio.

Provides incentives and reward for holders of synths to burn the synthetic tokens in exchange for collateral.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
