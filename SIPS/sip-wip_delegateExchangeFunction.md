---
sip: WIP
title: Allow delegation of Synthetix Exchange function to another address 
author: Jackson Chan (@jacko125), Clinton Ennis (@hav-noms)
discussions-to: https://discord.gg/DQ8ehX4
status: WIP
created: 2019-08-01
---


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This SIP proposes to allow a wallet to delegate permission for another wallet / address to make exchanges on their behalf. This would be restricted to only doing exchange transactions.

Allows a non-custodial wallet to make trades on behalf of the owner wallet.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Currently only the wallet that also owns the synths can sign synthetix exchange transactions and restricts different trading platforms /automated trading that employ trading strategies from being used on the exchange without exposing the private keys of the wallet that also have ownership of the synths.

Also allows hardware wallets to utilise an automated service to trade on synthetix exchange as they can delegate a temporary wallet to trade on behalf.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
Currently only the wallet that also owns the synths can sign synthetix exchange transactions and restricts different trading platforms / automated trading that employ trading strategies from being used on the exchange without exposing the private keys of the wallet that also have ownership of the synths.

Also allows hardware wallets to utilise an automated service to trade on synthetix exchange as they can delegate a temporary wallet to trade on behalf.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
Approve delegate address to trade on another wallet.
Remove any delegated address from approval list.
Only ability to call synthetix.exchange() for an approved wallet.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

- Improve the trading experience of Synthetix.exchange for professional and retail traders.
- Allow automated trading using a separate private key to sign exchange transactions.
- Allow hardware wallets to still trade with automated services.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Not required at this stage

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Not required at this stage

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
