---
sccp: 7
title: Reduce exchange fee to 30 basis points for two weeks
author: Arthur, nocturnalsheet 
discussions-to: https://discord.gg/kPPKsPb
status: Implemented
created: 2019-11-15
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
The existing exchange fee of 50 basis points was implemented to reduce the front running risk by trading bots. We propose to redcue the fee to 30 basis points for two weeks to to make it more feasible to trade in this low volatility environment.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Exchange fees are charged each time a Synth is converted, this fee is currently set to 50bps. SIP 21 is already implemented which reduces the front running risk. Lower trading fees will encourage more traders to try out what synthetix.exchange has to offer. 

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
While there is no issue with bots trading on synthetix.exchange, we want to encourage a variety of traders such as scalpers and short term swing traders and a lower fees will encourage them to make more trades.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
