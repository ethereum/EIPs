---
eip: <to be assigned>
title: Poisoning the Well
author: Piper Merriam <piper@pipermerriam.com>
discussions-to: <email address>
status: Draft
type: Standards Track
category Core
created: 2018-04-03
---


## Simple Summary

This EIP attempts to break ASIC miners specialized for the current ethhash
mining algorithm.


## Abstract

There are companies who currently have ASIC based ethereum miners in
production, and probabalistically actively mining.  This EIP aims to "Poison
the well" by modifying the block mining algorithm in a manner that
probabalistically *"breaks"* these ASIC miners.


## Motivation

ASIC based miners will have lower operational costs than GPU based miners which
will result in GPU based mining quickly becoming unprofitable.  Given that
production of ASIC based miners has a high barrier to entry, this will cause a
trend towards centralization of mining power.

This trend towards centralization has a negative effect on network security,
putting significant control of the network in the hands of only a few entities.


## Specification

TODO

## Rationale

This EIP is aimed at breaking existing ASIC miners via small changes to the
existing ethash algorithm.  We hope to accomplish the following:

1. Break existing ASIC based miners.
2. Demonstrate a willingness to fork in the event of future ASIC miner production.

Goal #1 is something that we can only do probabalistically without detailned
knowledge of existing ASIC miner design.  Our approach should balance the
inherent security risks involved with changing the mining algorithm with the
risk that the change we make does not break existing ASIC miners.  This EIP
leans towards minimizing the security risks by making minimal changes to the
algorithm accepting the risk that the change may not break existing ASIC
miners.

## Backwards Compatibility

This change implements a backwards incompatable change to proof of work based
block mining.  All existing miners will be required to update to clients which
implement this new algorithm.

## Test Cases

TODO: will need to generate test cases for `ethereum/tests` repository

## Implementation

TODO

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
