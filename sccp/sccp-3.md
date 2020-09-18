---
sccp: 3
title: Raise exchange fee to 50 basis points for two weeks
author: Kain Warwick (@kaiynne)
discussions-to: https://discord.gg/kPPKsPb
status: Implemented
created: 2019-06-26
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
The existing exchange fee of 30 basis points is exposing the system to frontrunning due to the oracle threshold. We propose to increase the fee to 50 basis points for two weeks to observe the impact this has on bots operating within the system. We believe that the higher fee should reduce the ability to frontrun the oracle significantly.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Exchange fees are charged each time a Synth is converted, this fee is currently set to 30bps, which is enabling bots to frontrun the oracle transaction with a high likelihood of profitibality. By increasing the exchange fee, the round trip cost for a trade is increased to 1%, making it harder to profit from exploiting the oracle. We have other options to reduce the likelihood of successfully operating such a bot, but they will take longer to implement. We hope to have them implemented in time to reduce the fees back to 30bps wthin two weeks.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
While there is no issue with bots trading on synthetix.exchange, a bot that is attempting to observe the next oracle update in the mempool and send a transaction with a higher gwei to ensure it confirms earlier is exploiting the system. In order to protect the system from such exploits the cost of a transaction needs to be increased. This should reduce or eliminate profitibility from exploits like these while we implement more robust systems to reduce the attack surface.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
