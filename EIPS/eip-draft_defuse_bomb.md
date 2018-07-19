---
eip: <to be assigned>
title: Defuse Difficulty Bomb and Reset Block Reward
author: SmeargleUsedFly (@SmeargleUsedFly)
discussions-to: https://github.com/ethereum/EIPs/issues/1227
status: Draft
type: Standards Track
category: Core
created: 2018-07-18
requires: 649
---

## Simple Summary
This EIP proposes to permanently disable the "difficulty bomb" and reset the block reward to pre-Byzantium levels.

## Abstract
Starting with `FORK_BLKNUM` the client will calculate the difficulty without the additional exponential component. Furthermore, block rewards will be adjusted to a base of 5 ETH, uncle and nephew rewards will be adjusted accordingly.

## Motivation
Nick Johnson, the [de facto lead EIP editor](https://gitter.im/ethereum/AllCoreDevs?at=5b4e00d6fd1b3474a69834bc), has [stated unambiguously](https://old.reddit.com/r/ethereum/comments/8zk7l0/changes_are_being_made_to_the_eip_process_which/e2jl29o/) that the Ethereum user community's opinion on changes to the protocol may only be announced by running/not running node client software. This is also reflected in EIP [#1](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md), which includes no mention of community input over the EIP process. However, due to the "difficulty bomb" (also known as the "ice age"), introduced in EIP [#2](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2.md), an artificial exponential increase in difficulty until chain freeze, users may find it much more challenging to exercise one of those choices than the other&mdash;namely, remaining on the unforked chain after a controversial hard-fork.

This situation has in fact already been observed: during the Byzantium hard-fork users were given the "choice" of following the upgraded side of the chain or remaining on the original chain, the latter already experiencing block times greater than 30 seconds. In reality one will find that organizing a disperse and decentralized set of individuals to keep the original, soon-to-be-dead chain alive under such conditions impossible. This is exacerbated when a controversial change, such as EIP [#649](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-649.md), is merged in so close to the hard-fork date, as users cannot be organized to take an educated stance for or against the change on such short notice.

Ultimately, the difficulty bomb serves but a single purpose: make it more difficult to keep the original chain alive after a hard-fork. This is unacceptable if the only way the community can make their voice heard is running/not running client software, and not through the EIP process, since they effectively have no choice and therefore no power. This EIP proposes to completely eliminate the difficulty bomb, returning some measure of power over Ethereum's governance process to the users, to the community.

Given the controversy surrounding the directly relevant EIP [#649](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-649.md), the issuance should also be reset to pre-Byzantium levels. It may be reduced again at a later time via a new hard-fork, only this time users would actually have a meaningful choice in accepting the change or not. Note: the issuance reduction is not the focus of this proposal, and is optional; the defusing of the difficulty bomb is of primary concern.

## Specification
#### Remove Exponential Component of Difficulty Adjustment
For the purposes of `calc_difficulty`, simply remove the exponential difficulty adjustment component, `epsilon`, i.e. the `int(2**((block.number // 100000) - 2))`.

#### Reset Block, Uncle, and Nephew rewards
To ensure a constant Ether issuance, adjust the block reward to `new_block_reward`, where

    new_block_reward = 5_000_000_000_000_000_000 if block.number >= FORK_BLKNUM else block.reward

(5E18 wei, or 5,000,000,000,000,000,000 wei, or 5 ETH).

Analogue, if an uncle is included in a block for `block.number >= FORK_BLKNUM` such that `block.number - uncle.number = k`, the uncle reward is

    new_uncle_reward = (8 - k) * new_block_reward / 8

This is the existing pre-Byzantium formula for uncle rewards, simply adjusted with `new_block_reward`.

The nephew reward for `block.number >= FORK_BLKNUM` is

    new_nephew_reward = new_block_reward / 32

This is the existing pre-Byzantium formula for nephew rewards, simply adjusted with `new_block_reward`.

## Rationale
This will permanently, without further changes, disable the "ice age." It will also reset the block reward to pre-Byzantium levels. Both of these changes are specified similarly to EIP [#649](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-649.md), so they should require only minimal changes from client developers.

## Backwards Compatibility
This EIP is not forward compatible and introduces backwards incompatibilities in the difficulty calculation, as well as the block, uncle and nephew reward structure. However, it may be controversial in nature among different sections of the userbase&mdash;the very problem this EIP is made to address. Therefore, it should not be included in a scheduled hardfork at a certain block number. It is suggested to implement this EIP in an isolated hard-fork before the second of the two Metropolis hard-forks.

## Test Cases
Forthcoming.

## Implementation
Forthcoming.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
