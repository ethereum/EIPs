---
sip: 34
title: Disable sMKR and iMKR
status: Implemented
author: Spreek (@Spreek)
discussions-to: (https://discord.gg/x88nPs)
created: 2019-12-25
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
Disable the sMKR and iMKR synths to prevent traders from profiting by manipulating the price feed.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The sMKR and iMKR synths are under attack by price feed manipulators. See [this reddit thread](https://www.reddit.com/r/ethfinance/comments/eexbfa/daily_general_discussion_december_24_2019/fby3i6n/) for a description of the attack. The illiquidity of the underlying allows users to profitably move the price feed in order to profit from their synth positions. In order to stop this attack, sMKR and iMKR should be disabled.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
The synthetix system relies on an efficient, liquid market to form its price feed. It cannot support being a larger market than the underlying (at least without substantial changes to the protocol). An oracle change by itself therefore cannot mitigate this attack, nor can any of the front running protections. The problem is that it is profitable to forcibly move the market while holding synths. I see few other recourses other than removing a synth that is exposed to such a risk.

The attackers are currently trading large volumes (24 million daily volume at time of writing) and making large profits at the expense of minters. Some estimates in the discord server put the rate of growth in their account at about $7000 per hour.

The utility of a synthetic version of an ERC20 token available at nearly every DEX is also quite questionable and it has had limited interest besides among people exploiting its lack of liquidity. So there seems to be little downside in disabling it for the time being, as it is not a big driver of non-toxic volume or interest in the SNX exchange.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
Disable sMKR and iMKR, allowing current holders to exit at the fixed oracle price, but no further buys to be made.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
There seems to be wide support and little dissent for removing these synths as seen by the response to @samantha and @brian who have both previously suggested this in the discord. The major objections to this propsal are likely that 1) this is an inelegant solution, and 2) this attack will draw more liquidity to the MKR pairs and eventually make itself unprofitable. While inelegant, we currently do not have another good lever to pull to stop this attack (at some point, we can consider using dynamic fees if we ever choose to implement that, but that is a much larger project). While you could (and we already are seeing) more liquidity being drawn in to MKR/ETH pairs on a variety of exchanges, there is also danger of copycat traders watching for synth distribution changes and following the manipulators trades. This could amplify the costs to minters/traders over the next few days/weeks until it is a much larger threat.

There has also been a great deal of consternation about this attack on twitter and reddit, which negatively affects the system. A quick and effective response to stop this attack should reassure many of these concerns.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
TBD

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
In order to implement this quickly given the priority of the issue, we are proposing to temporarily freeze the oracle price feed at the current price until a longer term solution can be found and the community reaches consensus on the future status ok sMKR and iMKR.

## Update (April 8, 2020): 
We have removed s/iMKR from the system, and purged anyone who held those Synths into sUSD. 

`sMKR` frozen at `443.3180`, `iMKR` frozen at `656.6820` in https://etherscan.io/tx/0x0069d23e7461c8c474fb388845428d480be8f087f5b934ad7d11a3b1a9b5e7d6.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
