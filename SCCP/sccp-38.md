---
sccp: 38
title: Increase Fees on Silver and Gold to 100 bp
author: Kaleb Keny (@kaleb-keny)
status: Approved
discussions-to: https://research.synthetix.io/t/increase-fees-on-silver-and-gold-to-100-bp/168
created: 2020-08-05

---

## Simple Summary

Increase fees on trades into sXAG and sXAU to 100 bp.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

As per [sip-56](https://github.com/Synthetixio/SIPs/blob/master/SIPS/sip-56.md) each synth can now have its own fee levels. This SCCP suggests to raise fees on sXAG and sXAU to 100 bp.

## Motivation

Analysis of on-chain data showed that front-running opportunities were more accessible for commodities. Increasing fees to 100 bp should make front-running quasi-impossible because of the update frequency of the chainlink oracles. That said when [sip-52](https://sips.synthetix.io/sips/sip-52) is implemented we should be able to lower these fees back to previous levels.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
