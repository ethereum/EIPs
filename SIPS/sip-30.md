---
sip: 30
title: Deprecate ERC223 from SNX and all Synths.
status: Implemented
author: Clinton Ennis (@hav-noms)
discussions-to: (https://discordapp.com/invite/CDTvjHY)

created: 2019-11-26
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Deprecate [ERC223](https://github.com/ethereum/EIPs/issues/223) from SNX and all Synths to save gas on dex exchanges and no transaction errors.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

The UX for [Mintr](https://mintr.synthetix.io) drove the implementation of ERC223 to reduce the number of transactions a user(minter) had to execute to deposit their sUSD into the Depot FIFO queue to be sold for ETH from 2 to 1 by only eliminating the ERC20 approve transaction prior to calling a ERC20 transferFrom. While this has been a nice UX for mintr users with the [Depot](https://contracts.synthetix.io/Depot) the benefits of ERC223 transfer have not outweighed the cons on contract to contract transfers;

- Bloated gas estimations [Issue 243](https://github.com/Synthetixio/synthetix/issues/243)
- Causing gas loss [Issue 243](https://github.com/Synthetixio/synthetix/issues/243)
- Perceived errors in SNX and Synth Transfers [etherscan](https://etherscan.io/address/0xe9cf7887b93150d4f2da7dfc6d502b216438f244)
  ![Although one or more Error Occurred Reverted Contract Execution Completed](https://user-images.githubusercontent.com/799038/69776252-943b6d80-11ef-11ea-97b5-d01f849cff8b.png)

There is a lot of Dex activity happening now with SNX on [uniswap](https://uniswap.info/token/0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f), [Kyber](https://tracker.kyber.network/#/tokens/0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f), sUSD [uniswap](https://uniswap.info/token/0x57ab1ec28d129707052df4df418d58a2d46d5f51), [Kyber](https://tracker.kyber.network/#/tokens/0x57ab1ec28d129707052df4df418d58a2d46d5f51) and sETH [uniswap](https://uniswap.info/token/0x5e74c9036fb86bd7ecdcb084a0673efc32ea31cb).
The ERC223 implementation is causing a significant cumulative gas loss trading these tokens. We aim to reduce the total gas lost / consumed trading Synthetix tokens.

This will also enable better (cheaper) composability as teams integrate Synths to build Defi products. 

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

- Removing all ERC223 is a simple code change to `ExternStateToken.sol` which is inherited by `Synthetix.sol` and `Synth.sol`
- It will require all Synths & SNX to be redeployed but no proxy addresses will change keeping all existing token addresses.
- The current [Depot](https://contracts.synthetix.io/Depot) will no longer be able to accept sUSD deposits effectivly putting it to its end of life.
- A new Depot will be required which will go back to using the original ERC20 approve, transferFrom workflow. This could be an opportunity to makes some additional improvements to the Depot such as making it upgradable. Putting it behind a proxy and giving it an external state contract so its logic can be upgraded.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

- Removing ERC223 will no longer show the transfer errors in contract to contract transfers. [Uniswap sETH exchange](https://etherscan.io/address/0xe9cf7887b93150d4f2da7dfc6d502b216438f244)
- This will also save 200K gas per contract to contract transfer. [github code reference](https://github.com/Synthetixio/synthetix/blob/v2.14.0/contracts/TokenFallbackCaller.sol#L52)
- Reclaim byte code space for SNX contract deployment by removing the ERC223 implementation in `ExternStateToken.sol`.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

- The current Depot will no longer be able to accept sUSD deposits but withdrawals and buying sUSD with ETH will still work as expected. It could stay until it is drained of sUSD supply.
- A new Depot version will need to be deployed to allow sUSD deposits. The Dapps will need to switch over to using this Depot for sUSD purchases with ETH when the FiFo queue is drained.
- Mintr will need to be updated to include an approve transaction for the Depot to call transferFrom to transfer the minters sUSD from their wallet to itself and create a deposit entry.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
