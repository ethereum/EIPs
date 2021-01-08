---
sccp: 48
title: Raise Fees on Crypto Synths to 100 bp
author: Kaleb Keny (@kaleb-keny)
status: Implemented
discussions-to: https://research.synthetix.io/
created: 2020-09-16
---

## Simple Summary

Raise fees on synths sXTZ, sXRP, sLTC, sADA, sBCH, sBNB, sLINK, sETH and sBTC and their respective inverses to 100 bp from 50 bp.

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Increase fees to 100 bp on synths which are pushed with a 1% deviation threshold.

## Motivation

Analysis of on-chain data showed that front-running opportunities continue to persist even with fees at 50 bp.
Increasing fees to 100 bp on synths with a 1% deviation threshold push should help close that window significantly, while waiting for further changes to the oracle and L2 to be implemented.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
