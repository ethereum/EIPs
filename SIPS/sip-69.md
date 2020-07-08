---
sip: 69
title: Update Index Synths
status: Approved
author: Daryl Lau (@daryllautk)
discussions-to: (https://discordapp.com/invite/CDTvjHY)

created: 2020-07-07
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Updating the current index tokens sDeFi and sCEX to include more assets to create a  more relevant composition reflecting the industry.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The current sDeFi and sCEX indexes need updating with the new token launches of several protocols. This SIP aims to create a more comprehensive index reflective of current times. With a recent market trend shifting to DeFi protocols, the new sDeFi V2 would attract newcomers to the Synthetix Ecosystem.
The current sDeFi implementation, misses out several prominent DeFi Tokens that have rose to fame in recent times such as AAVE, UMA, COMP and BAL
The current sCEX implementation does not have FTX Token included nor CRO.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
This SIP will update the assets included in sDeFi from SIP-22, in accordance with the weightages agreed upon in a poll to be created. This poll can be done via community votes on Twitter as per the previous rounds of proposals. 

### Update (Jul 8, 2020): 
Daryl has created a live [spreadsheet](https://docs.google.com/spreadsheets/d/1xfWPavj_T35qho7ppmdMdPiPpltI8jBb2QgoSJESIxE/edit#gid=0) featuring the weighting agreed upon by the community. 

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
We will follow the existing protocol and the implementations of the index tokens and only change the assets included and their corresponding weightages. 
These Synths will both be indices implemented in much the same way as the sCEX/iCEX Synths. iDEFI will have upper and lower thresholds which will be added to the SIP before deployment. 
For sDeFi;
The current Proposed V2 index comprises of COMP(Compound), MKR (Maker),  KNC (Kyber Network),SNX (Synthetix), ZRX (0x),REP (Augur), LEND (AAVE),  REN (Ren Protocol), UMA (UMA), LRC (Loopring), BNT (Bancor)
For sCEX;
The current proposed V2 Index comprises of BNB (Binance), CRO (Crypto.com), OKB (OKex), LEO (Bitfinex), HT (Huobi), FTT (FTX), KCS (Kucoin)


## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
s/iDeFi and s/iCEX already exists and are a clear example of how custom Synth indices can function successfully in the Synthetix protocol

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Announce the new index and weightages and migrate after a minimum 2 week period. Done by normalising the new price to the old price and restart the index contract.

Here are the weightings for the s/iDEFI Synths: 
1.06 of COMP (Compound), 
0.31 of MKR (Maker), 
63.23 of KNC (Kyber Network),
243.77 of ZRX (0x), 
37.70 of SNX (Synthetix), 
437.08 of LEND (AAVE), 
3.83 of REP (Augur), 
305.36 of REN (REN), 
415.03 of LRC (Loopring),
18.14 of UMA (UMA), 
23.00 of BNT (Bancor),
2.17 of BAL (Balancer).

Here are the weightings for the s/iCEX Synths: 
17.36 of BNB (Binance), 
1804.01 of CRO (Crypto.com), 
33.67 of OKB (OKex), 
107.35 of LEO (Bitfinex), 
28.35 of HT (Huobi), 
11.98 of FTX (FTX), 
9.82 of KCS (Kucoin).


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
