---
sip: 2
title: Remove Fee Penalty Tiers
status: Approved
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125)
discussions-to: https://discord.gg/CDTvjHY

created: 2019-06-10
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This SIP proposes to remove the current fee penalty tiers and instead to block fee claims if the user falls below the target c ratio by a specified percentage.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The fee tiers were implemented to encourage SNX holders to return thier wallets to the target C ratio, in practice at the current yield no user is willingly incurring any level of fee penalty, so the penalities past 25% are unneccesary. Removing the tiers and blocking fee claims if the ratio falls below a configurable threshold will be simpler and more user friendly as a fee claim will now revert if the ratio changes while the transaction is confirming. This has happened on several occasions already and is neccesitating users paying higher gas fees to ensure fast confirmation times to avoid the risk of a penalty.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
Reducing the complexity of the fee claims process and lowering the required gas for claims transactions will be a net positive for users. The fee tiers were an attempt to implement the fee penalty curve as specified in the original white paper, but empirical evidence suggest this may not have had the intended effect on user behaviour. Users are highly avoidant of fee penalties and so any non-zero fee penalty is likely to result in complete avoidance of claims until the penalty is removed. This change implements this observed behaviour into the system to reduce the risk of lost fees due to long confirmation times and other issues.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->

### Solidity

``` /**
     * @notice Check if a particular address is able to claim fees right now
     * @param account The address you want to query for
     */
    function feesClaimable(address account)
        public
        view
        returns (bool)
    {
        // Penalty is calculated from ratio % above the target ratio (issuanceRatio).
        //  0  <  10%:   0% reduction in fees
        // 10% > above:  100% reduction in fees
        uint ratio = synthetix.collateralisationRatio(account);
        uint targetRatio = synthetix.synthetixState().issuanceRatio();

        // no penalty if collateral ratio below target ratio
        if (ratio < targetRatio) {
            return true;
        }

        // Calculate the threshold for collateral ratio before penalty applies
        uint ratio_threshold = targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(PENALTY_THRESHOLD));

        // Collateral ratio above threshold attracts max penalty
        if (ratio > ratio_threshold) {
            return false;
        }

        return true;
    }
```

And reverting the transaction if the currentPenalty is larger than 0 (Minters will have to fix their C-ratio to be above the penalty threshold to claim fees)

```     function _claimFees(address claimingAddress, bytes4 currencyKey)
        internal
        returns (bool)
    {
        require(feesClaimable(claimingAddress), "C-Ratio below penalty threshold");

        uint availableFees;
        uint availableRewards;
        (availableFees, availableRewards) = feesAvailable(claimingAddress, "XDR");

        require(availableFees > 0 || availableRewards > 0, "No fees or rewards available for period, or fees already claimed");

        _setLastFeeWithdrawal(claimingAddress, recentFeePeriods[1].feePeriodId);

        if (availableFees > 0) {
            // Record the fee payment in our recentFeePeriods
            uint feesPaid = _recordFeePayment(availableFees);

            // Send them their fees
            _payFees(claimingAddress, feesPaid, currencyKey);

            emitFeesClaimed(claimingAddress, feesPaid);
        }

        if (availableRewards > 0) {
            // Record the reward payment in our recentFeePeriods
            uint rewardPaid = _recordRewardPayment(availableRewards);

            // Send them their rewards
            _payRewards(claimingAddress, rewardPaid);

            emitRewardsClaimed(claimingAddress, rewardPaid);
        }

        return true;
    }
```

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Implementing a penalty threshold allows for the Collateralisation ratio to fluctuate between a certain percentage below the target issuance Ratio without the transaction reverting.

If the collateralisation ratio for the minter does fall below the threshold, then it can be fixed by burning sUSD debt before attempting to claim fees again.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
