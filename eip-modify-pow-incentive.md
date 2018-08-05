---
eip: <tbd>
title: Modify Ethereum PoW Incentive Structure and Diffuse Difficulty Bomb
author: <Brian Venturo (@atlanticcrypto)>
discussions-to: TBD
status: Draft
type: <Standards Track>
category: <Core>
created: <2018-08-05>
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Network security and overall ecosystem maturity warrants the continued incentivization of Proof of Work participation but allows for a reduction in ancillary ETH issuance and the removal of the Difficulty Bomb. This EIP proposes a reduction of Uncle and removal of Nephew rewards while diffusing and removing the Difficulty Bomb with the Constantinople hard fork.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Starting with CNSTNTNPL_FORK_BLKNUM the client will calculate the difficulty based on a fake block number suggesting the client that the difficulty bomb is adjusting around 6 million blocks later than previously specified with the Homestead fork. Furthermore, Uncle rewards will be adjusted and Nephew rewards will be removed to eliminate excess ancillary ETH issuance. The current ETH block reward of 3 ETH will remain constant.


## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Network scalability and security are at the forefront of risks to the Ethereum protocol. With great strides being made towards on and off chain scalability, the existence of an artificial throughput limiting device in the protocol is no longer warranted. Removing the risk of reducing throughput through the initialization of the Difficulty Bomb is "low-hanging-fruit" to ensure continued operation at a minimum of current throughput into the future.

The security layer of the Ethereum network is and should remain robust. Incentives for continued investment into the security of the growing ecosystem are paramount. At the same time, the ancillary issuance benefits of the Ethereum protocol can be adjusted to reduce the overall issuance profile. Aggressively adjusting Uncle and removing Nephew rewards will reduce the inflationary aspect of ETH issuance, while keeping the current block reward constant at 3 ETH will ensure top line incentives stay in place.


## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
#### Remove Difficulty Bomb
For the purposes of calc_difficulty, simply remove the exponential difficulty adjustment component, epsilon, i.e. the int(2**((block.number // 100000) - 2)).

#### Adjust Uncle and Nephew rewards
If an uncle is included in a block for `block.number >= CNSTNTNPL_FORK_BLKNUM` such that `block.number - uncle.number = k`, the uncle reward is

    new_uncle_reward = (3 - k) * new_block_reward / 8

This is the existing pre-Constantinople formula for uncle rewards, adjusted to reward 2 levels of Uncles at a reduced rate.

The nephew reward for `block.number >= CNSTNTNPL_FORK_BLKNUM` is

    new_nephew_reward = 0

This is a removal of all rewards for Nephew blocks.


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->


## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This EIP is not forward compatible and introduces backwards incompatibilities in the difficulty calculation, as well as the block, uncle and nephew reward structure. Therefore, it should be included in a scheduled hardfork at a certain block number. It's suggested to include this EIP in the second Metropolis hard-fork, Constantinople.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Test cases shall be created once the specification is to be accepted by the developers or implemented by the clients.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Forthcoming.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
