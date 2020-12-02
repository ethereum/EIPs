---
sccp: 60
title: Suspend sBCH and iBCH synths until after BCH hard fork
author: Jackson Chan (@jacko125)
status: Implemented
discussions-to: https://research.synthetix.io/
created: 2020-11-14

---

## Simple Summary

Suspend sBCH and iBCH synths until after BCH hard fork on November 15, 2020 at approximately 4:00 AM PT (12:00 PM UTC).

## Abstract

<!--A short (~200 word) description of the variable change proposed.-->

Bitcoin Cash (BCH) will be undergoing a network protocol upgrade on November 15, 2020 at approximately 4:00 AM PT (12:00 PM UTC).

In connection to the protocol upgrade, there has been a proposed chain-split between the two main BCH clients, Bitcoin Cash ABC (BCHA) and Bitcoin Cash Node (BCHN), making this a hard fork that may result in a chain split and additional token.

sBCH and iBCH synths will be resumed when the price feed is stable and safe after the hard fork.

## Motivation

- Upcoming hard fork of BCH could affect the BCH ticker's underlying prices which require the synths based on BCH to be suspended.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
