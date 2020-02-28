---
sip: 42
title: Gas Optimisations on issueSynths and burnSynths
author: Jackson Chan (@jacko125), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/CDTvjHY
status: Proposed
created: 2020-02-28
---

## Simple Summary

Optimize the calls to issueSynths by ~35% & burnSynths by ~45%

## Abstract

After the removal of XDRs in [SIP-33](https://sips.synthetix.io/sips/sip-33) the ability to reduce the gas heavy operation of totalIssuedSynths() from 2 to 1 call became possible saving gas on;
- Synthetix.issueSynths (& issueMaxSynths)
- Synthetix.burnSynths

## Specification

By reducing the calls to totalIssuedSynths() from 2 to 1 call takes out redundant processing of the systems value in both sUSD and XDR's.
totalIssuedSynth() is so heavy as it iterates though every Synth in Synthetix and makes a cross contract call for its totalSupply() to be able to calculate the total debt of the system.

## Test Cases
https://github.com/Synthetixio/synthetix/blob/c5de5b0e568d80e64bdc45b32735dfeeb3c5a649/test/contracts/Issuer.js

### KOVAN test transactions

issueSynths - https://kovan.etherscan.io/tx/0x0ea4016a010618a1942ac82e04630a9b62b1685acc137d7cd5e8f4d1664255f8
burnSynths - https://kovan.etherscan.io/tx/0xc4ec1af424681b3aa83d1ad624b6008853c7e3b7722da015ef8155871e994f6d

## Implementation
https://github.com/Synthetixio/synthetix/pull/432


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
