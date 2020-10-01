---
sccp: 50
title: Pause s/iDEFI ahead of LEND->AAVE migration
status: Proposed
author: Garth Travers (@garthtravers)
discussions-to: governance
created: 2020-10-01
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
This SCCP proposes to pause sDEFI and iDEFI ahead of the migration from LEND to AAVE. 

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
This SCCP proposes to pause s/iDEFI as soon as possible to prevent any issues with the possible ~100x price increase of LEND as it migrates to AAVE, with a contracted supply of 16m from 1300m (with 3m tokens added via inflation). It would then be relaunched after the migration with the new weighting determined by the community. 

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The AAVE protocol has [announced](https://medium.com/aave/september-update-governance-on-mainnet-first-aip-vote-token-migration-in-the-works-b5b8c6a67d46) that LEND is migrating to AAVE.
If it is accepted, and it is currently on the way to comfortable acceptance via community governance, then the migration will start on [block 10978863](https://etherscan.io/block/countdown/10978863) (ETA: Friday 2 October at 21:06:54 GMT+2).
The migration is not just a name change — the token supply is being reduced at a rate of 100:1.

![AAVE migration](https://miro.medium.com/max/1540/1*rXMTocoxhnub_EbXXvYMBw.png) 

The issue with this supply contraction is that it will likely have a major price impact — it is expected that on exchanges that honour the migration, the value of LEND will increase by ~100x as it is migrated to the AAVE token. 
This could have adverse impact on the s/iDEFI tokens, as it's not fully clear how exchanges will handle the migration. After consultation with Chainlink on behalf of its decentralised network of node operators, we've decided to propose pausing the s/iDEFI tokens ahead of the migration. A new s/iDEFI would then be launched next week after the migration has been carried out, using the new weighting (no. 1 in the picture below). 

![s/iDEFI proposed new weighting](https://cdn.discordapp.com/attachments/673764686134509568/758048892398076125/sDEFI-Rebalance-weights.png)

During the period of the Synth being paused, s/iDEFI holders would not be able to transfer or exchange their token, any they would not have any exposure to any shifts in the prices of the indexed assets within the basket during the paused period. When re-launched, the new s/iDEFI would have the same value as when it was paused. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
