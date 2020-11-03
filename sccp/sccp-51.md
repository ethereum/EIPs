---
sccp: 51
title: Update sDEFI index
status: Implemented
author: Farmwell (@farmwell), CryptoToit (@CryptoToit)
discussions-to: https://research.synthetix.io/
created: 2020-09-30
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
It is proposed to update the composition of the sDEFI index synth. The DeFi space moves quickly. The index tracking DeFi should reflect the rapid pace of innovation and development.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The proposal is to add YFI, UNI, wNXM and CRV to sDEFI while removing ZRX, REP, LRC and BNT. The community has voted on the following initial weightage of the index:
  
  % Weightage | Ticker | Units
  - 15.00% | YFI | 0.023
  - 15.00% | AAVE | 8.41
  - 15.00% | SNX | 109.93
  - 10.00% | UNI | 92.09
  - 7.50% | COMP | 1.88
  - 7.50% | MKR | 0.39
  - 5.00%	| WNXM | 4.53
  - 5.00%	| UMA | 19.47
  - 5.00%	| REN | 598.03
  - 5.00%	| KNC | 159.13
  - 5.00%	| BAL | 9.05
  - 5.00%	| CRV | 253.8
  
## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The purpose of the updated sDEFI index synth is to attract traders wishing to gain exposure to the burgeoning DeFi sector with one token. 

YFI, UNI, wNXM and CRV are tokens of projects advancing the capabilities of every user in the DeFi space. YFI enables industrialized liquidity mining farming and custom asset management strategies at scale. Uniswap is the most decentralized piece of software enabling trustless swaps of ERC20 tokens with Ether or other ERC20 tokens. Nexus Mutual writes insurance policies enabling users to hedge the risk of DeFi smart contract failures. Curve is the most liquid stablecoin swap venue, enabling users to convert sUSD, USDT, USDC or DAI to a different flavor of stablecoin. Each of these tokens represents a project at the cutting edge of what is possible in DeFi.

As the DeFi sector has iterated and innovated some assets from the previous version of sDEFI are removed. These assets are ZRX, REP, LRC, and BNT. These are all projects with potential to have a positive impact on the capabilities of DeFi laymen users and power users but it is our view they no longer are digital assets representing the very forefront of what is possible in decentralised finance. 

DEXs like ZRX and BNT are not quite as dominant in terms of platform volume and user engagement as UNI, for example, though SNX community member MJC has noted the next version of BNT could melt faces and surprise people to the upside. At this point, it's a speculation of what BNT can do more than what BNT can do right now. Similarly, LRC and REP have so far not shown themselves to be preferred protocols for many DeFi users. 

The goal of the index is to provide exposure to the most innovative projects in DeFi right now. As the DeFi space continues to move quickly it is quite possible for previously excluded assets to rejoin the Index. 


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
