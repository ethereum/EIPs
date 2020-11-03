---
sccp: 53
title: Remove LEND Aggregator from ExchangeRates contract
status: Implemented
author: Jackson Chan (@jacko125)
discussions-to: https://research.synthetix.io/
created: 2020-10-21
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
This SCCP proposes to remove the LEND Aggregator from the ExchangeRates contract for the migration from LEND to AAVE.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
This SCCP proposes to remove the LEND Aggregator from the ExchangeRates contract as soon as possible to prevent any further Binary option markets to be created using the LEND currencykey.

LEND is being migrated to AAVE and Chainlink will be stopping their support for the LEND-USD aggregator at `0x4aB81192BB75474Cf203B56c36D6a13623270A67`.

A new aggregator for AAVE-USD prices will be added to ExchangeRates once available from Chainlink.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The AAVE protocol has [announced](https://medium.com/aave/september-update-governance-on-mainnet-first-aip-vote-token-migration-in-the-works-b5b8c6a67d46) that LEND is migrating to AAVE.

![AAVE migration](https://miro.medium.com/max/1540/1*rXMTocoxhnub_EbXXvYMBw.png)

The price of LEND has become less stable as liquidity drops and many exchanges have delisted LEND pairs.

Chainlink will be removing support for the LEND-USD aggregator in the near future.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
