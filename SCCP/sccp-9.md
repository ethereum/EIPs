---
sccp: 9
title: Redeploy iXTZ and iBNB
author: Garth Travers (@garthtravers)
discussions-to: https://discordapp.com/invite/AEdUHzt
status: Implemented
created: 2019-12/17
---

## Simple Summary
I propose re-enabling iXTZ (Inverse Tezos) and iBNB (Inverse Binance Coin) with new limits. 
(n.b. originally this SIP only proposed re-enabling iXTZ but was updated before the release as during that time, iBNB also froze)

## Abstract
iXTZ and iBNB allow traders to effectively take a short position on Tezos and Binance Coin respectively. Since they reached their limits as a result of Tezos appreciating and Binance Coin depreciating in price recently, they have both frozen. If people are to continue taking inverse positions on Tezos or Binance Coin, a new iXTZ and iBNB will need to be enabled. 

## Motivation
iXTZ and iBNB are two of our existing Synths, and our usual practice when an Inverse Synth gets frozen is to re-enable it in the next release. 

## Implementation
The iXTZ entry price is $1.57 and the limits will be $0.785 and $2.355. The iBNB entry price is $12.57 and the limits will be $6.29 and $18.86. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
