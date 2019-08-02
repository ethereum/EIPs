---
sip: <to be assigned>
title: sETH Uniswap Pool Staking Incentives
status: WIP
author: Kain Warwick @kaiynne
discussions-to: https://discord.gg/2MmKtHb

created: 2019-08-02
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Ease of access to synethtix.exchange is critical to the success of the platform, this means new users must be able to convert ETH and other cryptocurrencies to Synths to begin trading on the exchange. Uniswap is the perfect on-ramp for synthetix.exchange as it is permisionless and open, but it requires liquidity providers to deposit both ETH and tokens. Providing liquidity on Uniswap is not risk free, so in order to encourage a deep liqidity pool and provide confidence in the on-ramp and off-ramp to the synthetix.exchange we have been incentivising LP's through SNX staking rewards. This SIP intends to formalise this mechanism at the protocol level. 

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
We are three weeks into the sETH pool staking trial and already there is almost 3k ETH of liuqidity in the Uniswap pool. In addition to the depth of the pool the peg has been restored providin even more confidence to new and existing users. By formalising thise mechanism at the protocol level liquidity providers should have even more incentive to participate as they will now have confidence that this pool will be incentivised longer term so the effort of establishing liquidiity will be worth it.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The trial has been successful but in order for this mechanism to work long term it must be formalised into the protocol.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
In order to increase the depth of the pool to 5k ETH+ the proposal is to divert 10% of SNX inflationary rewards to the pool, 50% of which will be locked for 1 year and 50% will be unlocked.

The distribution rules are as follows:
1. SNX tokens will be distributed based on each wallet's percentage of the liquidity tokens in the pool at the end of each fee period. 
2. You must be in the pool the entire week, no withdrawals are allowed. 
3. Only the opening LP token balance counts, you can add more liquidity but it will only be counted in following week.
4. The snapshot will occur two hours after each fee period closes @ ~6pm AEST.

The distribution will be managed by a smart contract, where the inflationary supply is minted each week, LP token holders will then need to claim their tokens after the close of each fee period.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
By implementing this mechanism at the contract level we remove the need for the foundation to calculate and distribute rewards, removing the need for an LP to trust that tokens will be distributed. 

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
We are proposing a Gitcoin bounty to write and deploy this contract, details will be provided soon, but a bounty of 30k SNX will be awarded for writing and deploying the contract. The foundation will pay for an audit of the contract before it is deployed. Because we expect this process to take 6-8 weeks we need an interim solution. The proposal is for the inflationary rewards to be diverted to a foundation controlled account until the automated mechanism is audited and deployed. This will require manual claculation and distribution until the contracts are ready.
## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
