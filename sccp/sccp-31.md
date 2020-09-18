---
sccp: 31
title: Increase Commodity Fees
author: Kaleb Keny (@kaleb-keny)
status: Implemented
discussions-to: <https://discord.gg/XzQjCf>
created: 2020-06-26
---

## Simple Summary
Increase the fees on commodities to 30 bp in order to make front-running less likely.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
As per [sip-56](https://github.com/Synthetixio/SIPs/blob/master/SIPS/sip-56.md) each synth can now have its own fee levels. This SCCP suggest to raise the fees on commodity synths back to 30 bp.

## Motivation
Fees were configured recently in [sccp-24](https://sips.synthetix.io/sccp/sccp-24) however analysis of the data showed that front-running opportunities were more accessible. Increasing fees to 30 bp, should decrease the chance of front-running  until [sip-52](https://sips.synthetix.io/sips/sip-52) is implemented.

Thank you `brian` for helping out the community and pointing it out.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
