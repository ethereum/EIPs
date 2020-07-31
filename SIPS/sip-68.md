---
sip: 68
title: Minor enhancements to StakingRewards.sol
status: Implemented
author: Clinton Ennis (@hav-noms), Anton Jurisevic (@zyzek)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-07-06
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

The `StakingRewards` contracts for liquidity mining need some minor enhancements.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Enhancements include:

- Recover airdropped rewards tokens from other protocols such as BAL & CRV
- Ability to update the rewards duration
- Remove the redundant `LPTokenWrapper`
- Refactor to set rewards and staking tokens via the constructor on deployment
- Adding `Pausable` and `notPaused` to stake() to prevent staking into deprecated pools
- Fix a potential overflow bug in the reward notification function

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is inaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

### Recover airdropped rewards tokens from other protocols such as BAL & CRV

When providing liquidity to [Balancer](https://pools.balancer.exchange/#/) or [Curve.fi](https://www.curve.fi/susdv2/deposit) and you stake your LP tokens in the Synthetix `StakingRewards` contract you will also be eligible for BAL and CRV Liquidity Mining rewards also and potentially other AMMs in the future.

This would include a `recoverERC20` function that is accessible by the owner only, the [protocolDAO](https://etherscan.io/address/protocoldao.snx.eth) and can recover any ERC20 except the staking and rewards tokens to protect the stakers that their LP tokens and their rewards tokens are not accessible by the owner. These additional LP rewards will then be distributed to the LP providers.

### Update the rewards duration

Synthetix often runs trials on Liquidity Mining. Right now the Rewards duration is 7 days hard coded. Allowing a configurable `rewardsDuration` means the sDAO can set the duration and supply the total duration rewards for the trial without having to send the rewards manually each week. i.e. the curve renBTC/sBTC/wBTC pool gets 10 BPT per week. Where the trial is 10 weeks we could have set the duration to 10 weeks and send all 100 BPT upfront and it will distribute for the full term of the trial.

When a trial is complete the contract can either be shut down or wired into the Synthetix Inflationary supply via the Rewards Distribution contract where the `rewardsDuration` can be set back to 7 days and automatically receive SNX weekly. Similar to current LP SNX rewards incentives.

### Remove the redundant LPToken Wrapper

The `LPTokenWrapper` added additional complexity to the code without adding any additional benefits. To simplify the code we propose to remove it.


### Refactor to set rewards and staking tokens via the constructor on deployment

The staking and rewards tokens were hard coded addresses in each contract. Now that there are many of these on MAINNET and deploying almost 1 a week, instead of having to edit the code directly it is prefered to send the staking and rewards tokens as arguments to the constructor on contract creation.

### Pause stake when rewards completed

When a `StakingRewards` campaign has completed the contract needs to prevent anyone from staking into it. They won't accrue rewards and can cause blocking issues with inverse Synths that need to be rebalanced which need to be purged.
Adding `Pausable.sol` and modifier `notPaused` to `stake()` will allow the admin to set `paused` to `true` preventing anyone from staking. `SelfDestructible` has not been implemented and given the amount of value in these contracts probably best not to implement. 

### Potential overflow bug fix

#### Summary

There is a multiplication overflow that can occur inside the rewardPerToken function, on [line 66](https://github.com/Synthetixio/synthetix/blob/c4dd4413cbbd3c0b40dfee2f9119af2dcb6a82e5/contracts/StakingRewards.sol#L66):

```
lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
```
    
An overflow occurs whenever `rewardRate >= 2^256 / (10^18 * (lastTimeRewardApplicable() - lastUpdateTime))`.

This can happen when the updateReward modifier is invoked, which will cause the following functions to revert:

  * `earned`
  * `stake`
  * `withdraw`
  * `getReward`
  * `exit`
  * `notifyRewardAmount`

The reward rate is set inside `notifyRewardAmount`, if a value that is too large is provided to the function.
Of particular note is that `notifyRewardAmount` is itself affected by this problem, which means that if the provided
reward is incorrect, then the problem is unrecoverable.

#### Solution

The `notifyRewardAmount` transaction should be reverted if a value greater than `2^256 / 10^18` is provided.
As an additional safety mechanism, this value will be required to be no greater than the remaining
balance of the rewards token in the contract. This will both prevent the overflow, and also provide an additional check
that the reward rate is being set to a value in the appropriate range (for example, no extra/missing zeroes).

#### Details

Specifically, this problem occurs when rewardRate is too high; it is set inside the `notifyRewardAmount` function on
lines [114](https://github.com/Synthetixio/synthetix/blob/c4dd4413cbbd3c0b40dfee2f9119af2dcb6a82e5/contracts/StakingRewards.sol#L114) and [118](https://github.com/Synthetixio/synthetix/blob/c4dd4413cbbd3c0b40dfee2f9119af2dcb6a82e5/contracts/StakingRewards.sol#L118).

```
rewardRate = floor(reward / rewardsDuration) = (reward - k) / rewardsDuration
```

for some `0 <= k < rewardsDuration`.

For the bug to occur, we need:

```
(reward - k) / rewardsDuration >= 2^256 / (10^18 * (lastTimeRewardApplicable - lastUpdateTime))
reward                         >= rewardsDuration * 2^256 / (10^18 * (lastTimeRewardApplicable - lastUpdateTime)) + k
```

Hence, we can ensure the bug does not occur if we force:

```
reward < rewardsDuration * 2^256 / (10^18 * (lastTimeRewardApplicable - lastUpdateTime))
```

So we should constrain `reward` to be less than the minimum value of the RHS.

The smallest possible value of `lastUpdateTime` is the block timestamp when `notifyRewardAmount` was last called. 
The largest possible value of `lastTimeRewardApplicable` is `periodFinish`,
and `periodFinish = notificationBlock.timestamp + rewardsDuration` ([line 121](https://github.com/Synthetixio/synthetix/blob/c4dd4413cbbd3c0b40dfee2f9119af2dcb6a82e5/contracts/StakingRewards.sol#L121)).
Putting these together we have:

```
(lastTimeRewardApplicable - lastUpdateTime) <= rewardsDuration
```

Ergo, we need:

```
reward < rewardsDuration * 2^256 / (10^18 * rewardsDuration)
	                     = 2^256 / 10^18
```

So the problem will not emerge whenever we require

```
    reward < uint(-1) / UNIT
```

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

* Add  `recoverERC20` and `setRewardsDuration` that have `onlyOwner` modifiers.
* `constructor` to take `_rewardsToken` & `_stakingToken` as arguments
* Refactor to remove the `LPTokenWrapper` contract. The original implementation to not include this.
* Revert the `notifyRewardAmount` transaction if the computer reward rate would pay out more than the balance of the contract over the reward period.
* Inherit the `Pausable.sol` contract and add modifier `notPaused` to `stake()` 


### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- External Rewards Recovery
  - only owner can call recoverERC20
  - should revert if recovering staking token
  - should revert if recovering rewards token (SNX)
  - should revert if recovering the SNX Proxy
  - should retrieve external token from StakingRewards and reduce contracts balance
  - should retrieve external token from StakingRewards and increase owners balance
  - should emit RewardsDurationUpdated event
- setRewardsDuration
  - should increase rewards duration
  - should emit Recovered event
  - Revert when setting setRewardsDuration before the period has finished
  - should distribute rewards
- Constructor & Settings
  - should set rewards token on constructor
  - should staking token on constructor
- Pausable
  - should revert when stake is called when paused is true
- Overflow bugfix
  - should revert `notifyRewardAmount` if reward is greater than the contract balance
  - should revert `notifyRewardAmount` if reward plus any leftover from the previous period is greater than the contract balance
  - should not revert `notifyRewardAmount` if reward is equal to the contract balance
  
### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
