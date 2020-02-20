---
sccp: 12
title: Temporarily Deactivate Exploited Assets
author: Michael J. Cohen (@mjayceee)
discussions-to: TBC
status: Implemented
created: 2020-02-03
---

## Update (20/02/2020)
As part of the Achernar release, we are reactivating these assets. 

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
The vast majority of frontrunning activity is concentrated in three synth asset pairs: 
- sXTZ/iXTX 
- sLTC/iLTC
- sBNB/iBNB

As Kain pointed out in SCCP 11, the volume of frontrunning transactions is increasing again. With Fee Reclamation still several weeks away, there needs to be some sort of short term fix. This SCCP proposes that these three pairs are disabled immediately and enabled in the same release as Fee Reclamation.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
Disable these asset pairs immediately, but with the explicit intention to reactivate them in the same release as Fee Reclamation.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->
The suggestions to this point have been to either 1) raise fees system-wide to 100 bps, 2) slash frontrunner accounts, 3) or selectively disable assets.

Solution #1 may discourage frontrunners but will also harm good-faith stakers/hedgers and traders. It's also bad PR with traders who are potential future sX users. 

Solution #2 is overly aggressive, sets a dangerous precedent, is somewhat arbitrary and could be deployed arbitrarily in the future. It would discourage frontrunners but at a high cost from a PR perspective and future governance perspective.

Solution #3 seems kind of weak, but achieves the goal of removing the surface space for these attacks. It's a potential PR problem, but to preempt that narrative, this SCCP suggests that all disabled synths should be explicitly scheduled to be re-enabled in the same release as Fee Reclamation. More deliberate conversations should be had then about whether certain of these assets (especially XTX) should be listed at all.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
