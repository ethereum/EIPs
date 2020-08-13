---
sip: 77
title: StakingRewards bug fix's and Pausable stake()
status: Proposed
author: Clinton Ennis (@hav-noms), Anton Jurisevic (@zyzek)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-08-06
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

`stake()` needs to be pausable for completed incentives and two bug fixes. 

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Enhancements include:

- Inheriting `Pausable` contract and add `notPaused` modifer to `stake()` to prevent staking into deprecated pools
- Fix a potential overflow bug in the reward notification function reported by samcsun
- Fix to `setRewardsDuration` to allow `rewardsDuration` to be updated after the initial setting

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is inaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

### Pause stake when rewards completed

When a `StakingRewards` campaign has completed the contract needs to prevent anyone from staking into it. The staker will not accrue any rewards and can cause blocking issues with inverse Synths that need to be purged so that they can be relanced.
Adding `Pausable.sol` and modifier `notPaused` to `stake()` will allow the admin to set `paused` to `true` preventing anyone from staking. `SelfDestructible` has not been implemented and given the amount of value in these contracts probably best not to implement.

### Potential overflow bug fix

#### Summary

There is a multiplication overflow that can occur inside the rewardPerToken function, on [line 66](https://github.com/Synthetixio/synthetix/blob/c4dd4413cbbd3c0b40dfee2f9119af2dcb6a82e5/contracts/StakingRewards.sol#L66):

```
lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
```

An overflow occurs whenever `rewardRate >= 2^256 / (10^18 * (lastTimeRewardApplicable() - lastUpdateTime))`.

This can happen when the updateReward modifier is invoked, which will cause the following functions to revert:

- `earned`
- `stake`
- `withdraw`
- `getReward`
- `exit`
- `notifyRewardAmount`

The reward rate is set inside `notifyRewardAmount`, if a value that is too large is provided to the function.
Of particular note is that `notifyRewardAmount` is itself affected by this problem, which means that if the provided
reward is incorrect, then the problem is unrecoverable.

#### Solution

The `notifyRewardAmount` transaction should be reverted if a value greater than `2^256 / 10^18` is provided.
As an additional safety mechanism, this value will be required to be no greater than the remaining
balance of the rewards token in the contract. This will both prevent the overflow, and also provide an additional check
that the reward rate is being set to a value in the appropriate range (for example, no extra/missing zeroes).

#### Details

Specifically, this problem occurs when `rewardRate` is too high; it is set inside the `notifyRewardAmount` function on
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

### Fix to setRewardsDuration to allow updates after the initial setting

`setRewardsDuration` was intended to allow the `rewardsDuration` to be set after the duration had completed. However a flaw in the require meant it could be changed after the initial setting.

Current code

```
require(periodFinish == 0 || block.timestamp > periodFinish);
```

Proposed change

```
require(block.timestamp > periodFinish);
```

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

- Inherit the `Pausable.sol` contract and add modifier `notPaused` to `stake()`
- Revert the `notifyRewardAmount` transaction if the computer reward rate would pay out more than the balance of the contract over the reward period.
- Change the `require` in `setRewardsDuration` to only check the period has finished

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

- Pausable
  - should revert when stake is called when paused is true
  - should allow a call to stake to succeed when paused is false
- Overflow bugfix
  - should revert `notifyRewardAmount` if reward is greater than the contract balance
  - should revert `notifyRewardAmount` if reward plus any leftover from the previous period is greater than the contract balance
  - should not revert `notifyRewardAmount` if reward is equal to the contract balance
- setRewardsDuration bug fix
  - should revert when setting setRewardsDuration before the period has finished
  - should update rewardsDuration when calling setRewardsDuration after the rewards period has finished

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
