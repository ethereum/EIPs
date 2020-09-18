---
sccp: 4
title: Raise exchange fee to 50 basis points for two weeks
author: Kain Warwick (@kaiynne)
discussions-to: https://discord.gg/kPPKsPb
status: Implemented
created: 2019-08-24
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
We are again seeing significant volume from front running bots, while these bots are not frontrunning via the mempool, they are still taking advantage of oracle latency to generate low risk profits. While we work on proposing and implementing additional frontrunning protections we believe it is prudent to again raise the exchange fee to 50 basis points.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Exchange fees are charged each time a Synth is converted, this fee is currently set to 30bps, which is enabling bots to frontrun the oracle transaction with a reasonable likelihood of profitibality.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
While there is no issue with bots trading on synthetix.exchange, a bot that is attempting to predict the next oracle update and exploit oracle latency is a risk to the system. In order to protect the system from such attack vectors the cost of a transaction needs to be increased temporarily.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
