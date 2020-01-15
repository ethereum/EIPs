---
sip: 32
title: Chainlink Oracles Phase 1 - Forex & Commodities
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: https://discord.gg/3uJ5rAy

created: 2019-12-02
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Phase one of migrating to decentralized oracles involves transitioning to Chainlink networks for our forex and commodity synths.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

As part of the migration towards [decentralized oracles with Chainlink](https://github.com/Synthetixio/synthetix/issues/293), we will implement the transition in phases. Phase 1 will involve migrating our forex and commodity synths to Chainlink pricing networks.

In the meantime the SNX centralized oracle will continue to supply the prices for the remaining crypto synths (including inverses and indexes).

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

As [discussed in this issue](https://github.com/Synthetixio/synthetix/issues/293), it is imperative that the Synthetix ecosystem move away from a centralized oracle to decentralized pricing networks.

It has also been established that Chainlink oracles could expose the Synthetix system to front-running as the deviation target for updates of `1%` is larger than the exchange fee.

Thus in order to achieve a safe and secure transition, and to minimize any potential front-running risks, we have selected migrating to the forex and commodity prices first, as these have much less volatility on average than crypto prices and as such are a minimal target for front-running.

In addition, we will keep the max gas solution in place ([SIP-12](https://sips.synthetix.io/sips/sip-12)) during this transition and work with the chainlink nodes to ensure their gwei settings exceed our exchange limits to prevent front-running.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

Our `ExchangeRates` contract (https://contracts.synthetix.io/ExchangeRates) will continue to be fed prices from the decentralized oracle. However, the logic for looking up prices will be extended with a mapping of Chainlink Aggregator contracts for each forex and commodity synth.

The synths are as follows:

1. `sAUD` Australian Dollars ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0x1b7ce2481149328c5e00efa6daa82de8e24f078b))
2. `sCHF` Swiss Francs ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0xcd80a8f6915c78b3e65d30f94468547e021ccf9b))
3. `sEUR` Euros ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0x152cfa5d0e11ab0355179cd812035c2c64d750bd))
4. `sGBP` Pound Sterling ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0x174754491a4ca333bf777387b0926bc8ecaf7f6e))
5. `sJPY` Japanese Yen ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0xe3153d946c958e334285f4aa93c6a3d8f5dfbff7))
6. `sXAG` Silver (ounce) ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0xc8bc999deab18feca1c5fbd6bffe9975ac396402))
7. `sXAU` Gold (ounce) ([see decentralized oracle network on ropsten](https://aggregator-staging.surge.sh/ropsten/0xf45a5bb73124907e8c391c6a1001896f62f8f290))

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

In order to have both the centralized oracle and decentralized oracles work in tandem, we will abstract away the logic in the `ExchangeRates` contract. Fortunately, the current architecture is such that this change is a fairly minimal impact to the Synthetix system.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

_To be added_

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

_To be added_

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
