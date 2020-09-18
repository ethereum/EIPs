---
sccp: 5
title: Increase Arb Pool Distribution to 5%
author: Kain Warwick (@kaiynne)
discussions-to: https://discordapp.com/invite/aApjG26
status: Implemented
created: 2019-11-05
---

<!--You can leave these HTML comments in your merged SCCP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SCCPs. Note that an SCCP number will be assigned by an editor. When opening a pull request to submit your SCCP, please use an abbreviated title in the filename, `sccp-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
The [sETH arb pool](0xA6B5E74466eDc95D0b6e65c5CBFcA0a676d893a4) has been drained very quickly over the last few weeks. There are several reasons for this, the first is that some of the front-running bots are using it as a way of clearing out excess sETH profits they are holding. On the face of it this might seem like a less than ideal situation. But the reality is that the arb pool is absorbing excess supply directly that would otherwise be absorbed into the sETH pool itself impacting the peg. By increasing the supply to the arb contract we can more quickly absorb this excess supply of sETH and tighten the peg, in combination with proposal 1 to change the window where users can be undercollateralised without being penalised this should exert upward pressure on the peg.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The intent of the arb pool is to ensure the sETH/ETH peg remains above .99 recently there has been insufficient SNX supply in the pool to keep the peg aligned, the intent of this change is to provide additional SNX to attempt to restore the peg.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The current 2% supply has been insufficient to support the peg, by raising the supply to 5% the peg should remaining closer to .99 throughout each fee period and ideally leave a buffer that will build up over time.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
