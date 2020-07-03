---
sccp: 32
title: Increase Fees on Stock Synths
author: Kaleb Keny (@kaleb-keny)
status: WIP
discussions-to: <https://discord.gg/XzQjCf>
created: 2020-07-03
---

## Simple Summary
Increase the fees on trades into stock synths to 30 bp.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
As per [sip-56](https://github.com/Synthetixio/SIPs/blob/master/SIPS/sip-56.md) each synth can now have its own fee levels. This SCCP suggest to raise the fees on stocks synths (sFTSE and sNIKKEI) to 30 bp.

## Motivation
Fees were configured recently in [sccp-24](https://sips.synthetix.io/sccp/sccp-24) . However, analysis of recent on-chain data showed that front-running opportunities were more accessible for stock synths due to the low trading fees levied. Increasing these back to 30 bp should shrink that window significantly and bolster the protection until [sip-52](https://sips.synthetix.io/sips/sip-52) is implemented.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
