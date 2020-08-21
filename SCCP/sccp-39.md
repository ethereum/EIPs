---
sccp: 39
title: Increase Forex Fees
author: Spreek (@Spreek)
discussions-to: https://research.synthetix.io/t/sccp-increase-forex-fees/169
status: Implemented
created: <2020-08-01>

---

## Simple Summary

Increase the fees on trades into currency synths.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

As per [sip-56](https://github.com/Synthetixio/SIPs/blob/master/SIPS/sip-56.md) each synth can now have its own fee levels. This SCCP suggest to restore the fees on all currency synths (sUSD, sEUR sJPY, sAUD, sGBP, sCHF) to their old level of 0.3%

## Motivation

Analysis of data shows continued danger from frontrunning in traditional synths. When we introduced differential fees in SIP 56, we chose to reduce fees on traditional synths, thinking that the lower volatility synths would be less risky. However, due to lag from chainlink oracles, we see continued profitable trading in these pairs. Therefore, until a new solution, we should at least temporarily restore fees to their old level of 0.3%. 

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
