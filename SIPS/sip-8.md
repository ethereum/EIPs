---
sip: 8
title: sETH Uniswap Pool Staking Incentives
status: Implemented
author: Kain Warwick (@kaiynne)
discussions-to: https://discord.gg/2MmKtHb

created: 2019-08-02
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Ease of access to synethtix.exchange is critical to the success of the platform, so this means new users must be able to convert ETH and other cryptocurrencies to Synths to begin trading on the exchange. Uniswap is the perfect on-ramp and off-ramp for synthetix.exchange as it is permisionless and open, but it requires liquidity providers (LPs) to deposit both ETH and tokens. Providing liquidity on Uniswap is not risk free, so in order to encourage a deep liqidity pool and provide confidence in the on-ramp and off-ramp to the synthetix.exchange we have been incentivising LP's through SNX staking rewards. This SIP intends to formalise this mechanism at the protocol level. We are four weeks into the sETH pool staking trial and there is almost 3k ETH of liquidity in the Uniswap pool. In addition to the depth of the pool the peg has been restored, providing confidence to both new and existing users of sX. By formalising this mechanism at the protocol level, liquidity providers should have even more incentive to participate as they can be confident that this incentive will exist long term so the effort of establishing liquidiity will be worthwhile.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This SIP formalises at the protocol level to divert a portion of SNX inflation into a pool to incentivise liquidity providers of the sETH/ETH pair in Uniswap.


## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The trial has been successful but in order for this mechanism to work long term it must be formalised into the protocol.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
The implementation of this SIP will be phased in:

Phase One: trial period funded by the foundation, the trial period has now been extended to five weeks finishing on 2019-08-21
Phase Two: 5% inflation diverted to pool with all rewards unlocked (eight weeks 2019-08-21 to 2019-10-16)
Phase Three (pending community approval): 5% additional inflation locked for 1 year as per the existing inflationary rewards mechanism (2019-10-16 ongoing)

The distribution rules are as follows:
1. SNX tokens will be distributed by the percentage of liquidity tokens at the end of each period.
2. You must be in the pool the entire week, no withdrawals are allowed. 
3. Only the opening LP token balance counts, you can add more liquidity but it will only be counted in following week.
4. The snapshot will occur two hours after each fee period which closes @ Wednesday ~6pm AEST.
5. There is a minimum of 1 liquidity token required per provider. 

The distribution will be managed by an m/n multisig contract with signers selected from LP providers. 

The source of truth for distribution will be the open source script released by user @justwanttoknowathing on Discord, <insert link to code> 

1. Any signer runs the script by @justwanttoknowathing
2. Any signer posts results on Discord
3. All signers have 24 hours to review output
4. All signers discord handle + signing address are public
5. An LP that believes their rewards are incorrect can DM a signer to check their balance and vote incorrect
6. A single signer submits the distribution tx to the multisig and posts the payload to Discord
7. M/N signers sign the tx
8. If more than two signers do not sign the tx the distribution will not proceed
9. Failure to vote on a correct tx will result in removal and replacement of a signer(s)

*h/t @nocturnalsheet for the core signing process above.*

^Phase three requires some modifications to the fee pool contracts hence the delay and discussion required before implementing this change.

^There is still a kill-switch built into this mechanism whereby if the signers go rogue. The foundation (and eventually the community via decentralised proxies) can halt distribution of the inflationary rewards to this contract and deploy a new multisig with different signers.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
By implementing this distribution mechanism using a multisig, we prepare for the next phase of the project where the foundation can no longer modify distribution and other aspects of the system and begin to test aspects of decentralised goveranance.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
We are proposing to use the Gnosis multisig for signing of these transactions. This multisig will be the owner of the "airdropper" contract that is currently manually distributing this incentive.

As part of this implementation we have also enabled the abilility to manually send tokens into escrow, this functionality will support escrowing future OTC token sales from the foundation treasury.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
