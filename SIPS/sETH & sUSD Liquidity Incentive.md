---
sip: To be assigned
title: sETH & sUSD Liquidity Incentive
status: Proposed
author: Nocturnalsheet (@nocturnalsheet)
discussions-to: https://discord.gg/2MmKtHb

created: 2020-04-04
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Ease of access to synthetix.exchange is critical to the success of the platform, so this means new users must be able to convert ETH and other cryptocurrencies to Synths to begin trading on the exchange. For off ramp, users must be confidence in the stability of the sUSD peg at $1. A strong peg will provide confidence in both on and off ramp for trading in synthetix.exchange. 


## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This SIP formalises at the protocol level to divert 64,000 SNX from inflation into Curvepool to incentivise liquidity providers of the sUSD/USDT/DAI/USDC/TUSD pairing in Curve and reduce to 32,000 SNX from inflation into Unipool for the sETH/ETH pairing in Uniswap


## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The trial has been successful for Curve pool and to ensure this mechanism to work long term it must be formalised into the protocol. Reduction of SNX for Unipool is to ensure that debt pool is not over sETH bias and provides an added incentive for sETH/ETH liquidity providers to switch to sUSD liquidity provision.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
Workflow

- User adds liquidity to sETH uniswap exchange or sUSD Curve pool and receives LP tokens
- User then stakes the LP tokens at Unipool or Curvepool time staking contract respectively
- Anyone can call Synthetix.mint() to mint the inflationary supply. This will then be sent to the RewardsDistribution contract where it will send an amount of tokens to the Unipool and Curvepool contract.
- LP stakers will be assigned their % amount of SNX rewards based on their % of staked LP tokens against the pool of LP providers.
- LP stakers will need to come to the Unipool or Curvepool contract or use Mintr UI to claim their SNX rewards anytime.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
By implementing this distribution mechanism at the protocol level, liquidity providers can be assured that the incentives will exist long term so the effort of establishing liquidity will be worthwhile.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
TBD

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
TDB


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
