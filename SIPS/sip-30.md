---
sip: 30
title: Deprecate ERC223 from SNX and all Synths.
status: Proposed
author: Clinton Ennis (@hav-noms)
discussions-to: (https://discordapp.com/invite/CDTvjHY)

created: 2019-11-26
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Deprecate [ERC223](https://github.com/ethereum/EIPs/issues/223) from SNX and all Synths.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

The UX for [Mintr](https://mintr.synthetix.io) drove the implementation of ERC223 to reduce the number of transactions a user(minter) had to execute to Deposit their sUSD into the Depot FIFO queue to be sold for ETH from 2 to 1 by only eliminating the ERC20 approve transaction prior to calling a ERC20 transferFrom. While this has been a nice UX for mintr users with the [Depot](https://contracts.synthetix.io/Depot)

The benefits of ERC223 transfer have not outweighted the cons on contract to contract calls;

- Bloated gas estimations
- Causing gas loss
- Perceived errors in SNX and Synth Transfers 'Although one or more Error Occurred [Reverted] Contract Execution Completed'

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

- Removing ERC223 will no longer show the transfer errors in contract to contract transfers.
- This will also save 200K gas per contract to contract transfer.
- Reclaim bytcode space for SNX contract deployment

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
