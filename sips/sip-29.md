---
sip: 29
title: Issue, burn and claim only in sUSD
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: (https://discord.gg/3uJ5rAy)

created: 2019-11-27
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

This SIP proposes to remove the on-chain functionality of issue, burn and claim in anything other than `sUSD`.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

Issuing, burning and claiming any synth is functionality the smart contracts have supported even though the dApps don't offer the functionality. It's [been highlighted already](https://github.com/Synthetixio/synthetix/issues/311) that by issuing, burning and claiming in any synth, the exchange fee can be avoided. Unfortunately, [a bot](https://etherscan.io/address/0xc0fb2a3be460a9a027ab55b947f8461402284f7d) has been detected that is leveraging this loophole to issue new debt, repay it instantly, and accuring profits at the expense of Synthetix debt holders. The bot issues into synths that have market movement (by reading the mempool and using higher gwei than our oracle), then immediately burns their debt, and thereby profiting from trade without paying any fees.

This loophole makes it pertinant we shut this backdoor into exchanging immediately.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

The proposal is to remove the `currencyKey` argument from `Synthetix.issueSynths`, `Synthetix.issueMaxSynths`, `Synthetix.burnSynths`, `FeePool.claimFees` and `FeePool.claimOnBehalf` and that they all use `sUSD`.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Instead of having a `require(currencyKey, "sUSD")`, removing the `currencyKey` argument altogether removes any possible confusion for the user.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

These fixes are for the imminent Vega release, targeted to address the current bot activity.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
