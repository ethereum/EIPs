---
eip: TBD
title: Delay Difficulty Bomb and Reduce Block Reward to 2.7
author: Peter Salanki (@salanki)
discussions-to: https://github.com/ethereum/EIPs/pull/1362
status: Draft
type: Standards Track
category: Core
created: 2018-08-29
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
This EIP proposes delaying the Difficulty Bomb by approximately 14 months and reducing the Block Reward to 2.7 ETH.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Starting with `CNSTNTNPL_FORK_BLKNUM` the client will calculate the difficulty based on a fake block number suggesting the client that the difficulty bomb is adjusting around 6 million blocks later than previously specified with the Homestead fork. 

The Block Reward will be reduced to 2.7 ETH and all Uncle Rewards will be adjusted proportionally.


## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
This EIP proposes a similar issuance reduction to [EIP-1295](https://github.com/ethereum/EIPs/pull/1295) without reducing the Uncle Reward structure, to give an alternative safer option.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
#### Relax Difficulty with Fake Block Number
For the purposes of `calc_difficulty`, simply replace the use of `block.number`, as used in the exponential ice age component, with the formula:

    fake_block_number = max(0, block.number - 6_000_000) if block.number >= CNSTNTNPL_FORK_BLKNUM else block.number
    
#### Adjust Block Reward

    new_block_reward = 2.7 ETH

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

This EIP provides a reduction to ETH issuance without impacting the current Uncle Reward structure. It reduces the risk of centralization to the mining network that could occur if Uncle Rewards are lowered. This EIP proposes 2.7 ETH per Block as the base reward recognizing the current economic costs to secure the network, and we believe is a good compromise of reducing issuance while maintaining network security.

In 2017 an issuance reduction occurred gradually over several months while the difficulty bomb was activating. The issuance reduction introduced in Metropolis did have a net positive effect on actual issuance at the time of the fork due to the bomb diffuse. A large overnight reduction has never been implemented before making it impossible to statistically quantify the risks of [EIP-858](https://github.com/ethereum/EIPs/pull/858) and [EIP-1234](https://github.com/ethereum/EIPs/pull/1234). By taking a gradual approach to issuance reduction the effects of such reduction can be measured and provide data for a future monetary policy without risking security of the network. We expect this EIP to be followed by additional reward reduction EIPs in future hardforks when safety of doing so has been quantified. 
## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This EIP is not forward compatible and introduces backwards incompatibilities in the difficulty calculation, as well as the block, uncle and nephew reward structure. Therefore, it should be included in a scheduled hardfork at a certain block number. It's suggested to include this EIP in the second Metropolis hard-fork, Constantinople.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
