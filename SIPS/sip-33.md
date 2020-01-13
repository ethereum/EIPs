---
sip: 33
title: Deprecate XDR synth from Synthetix.
status: WIP
author: Nocturnalsheet (@nocturnalsheet), Clinton Ennis (@hav-noms)
discussions-to: (https://discordapp.com/invite/CDTvjHY)

created: 2019-12-17
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Deprecate XDR synth from Synthetix to simplify representation and calculation of claimable fees in fee pool, Gas Optimisationsa and simplify the system mechanics. 

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

XDR has been used in Synthetix since the beginning as an unit of account, however most people are still not able to understand the purpose and calcuation of XDR and most importantly how the price of XDR is being derived.

With the implementation of ([SIP-29 - Issue, burn and claim only in sUSD] (https://sips.synthetix.io/sips/sip-29)), XDR is not required to be the unit of account anymore and sUSD can replace the role of XDR as the base unit of account.

- This will help new users in Synthetix ecosystem to easily understand how fees are collected and distributed
- Easier onchain checking and verification of current amount of fees claimable sitting inside fee pool
- Allows for easier integration of third party dashboards/data analysis as they do not have to call the XDR value to sUSD to represent the USD value
- No requirement for Chainlink decentraliized oracle to support.
- System optimizations, gas savings on removing XDR from system mechanics
- Reduce system complexity


## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

- sX fees will be collected in sUSD and stored as sUSD in fee pool.
- Debt Calculations will be in sUSD

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

- Reduce the burden of oracle to call and fetch prices for XDR rate
- Allows for full decentralised oracles in future as XDR price is a niche and likely to be unsupported by most oracles 

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Not required at this stage

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
