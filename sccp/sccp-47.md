---
sccp: 47
title: Raise Fees on Crypto Synths to 50 bp
author: Kaleb Keny (@kaleb-keny)
status: Implemented
discussions-to: https://research.synthetix.io/
created: 2020-09-14
---

## Simple Summary

Raise fees on synths sXTZ, sXRP, sLTC, sADA, sBCH, sBNB, sLINK, sETH and sBTC and their respective inverses to 50 bp from 30 bp.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increase fees to 50 bp on synths which are pushed with a 1% deviation threshold.

## Motivation

Analysis of on-chain data showed that front-running opportunities still exist with post migration to chainlink price oracles.
Increasing fees to 50 bp on synths with a 1% deviation threshold push should help close this window while waiting for further changes to the oracle.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
