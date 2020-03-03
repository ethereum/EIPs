---
sip: 46
title: Address Resolver Gas Improvements
status: Proposed
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-03-02
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Cache addresses from resolver inside contracts to reduce gas usage.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Ensure that each contract relying on addresses from the `AddressResolver` caches its own copy of these addresses, thereby reducing the gas usage for users when executing regular transactions like `issue`, `burn`, `claim` and `exchange`. The cache however must be refreshed on each and every deployment.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

In our Achernar release (v2.19.8), we introduced [SIP-43](./sip-43.md) - an address lookup contract into the `FeePool`, `Synthetix`, `Exchanger`, `Issuer` and all `Synth` contracts, among others. The impact to gas on common user functions like `FeePool.claim`, `Synthetix.exchange` and `Synthetix.issueSynths` was signficant.

Prior to Achernar

| Contract  | Function       | Gas Used |
| --------- | -------------- | -------- |
| FeePool   | claimFees      | 322,641  |
| Synthetix | burnSynths     | 352,748  |
| Synthetix | exchange       | 226,041  |
| Synthetix | issueMaxSynths | 342,547  |
| Synthetix | issueSynths    | 361,070  |

> from https://github.com/Synthetixio/synthetix/runs/353850454

After Achernar

| Contract  | Function       | Gas Used | Diff     | %     |
| --------- | -------------- | -------- | -------- | ----- |
| FeePool   | claimFees      | 497,550  | +174,909 | +54%  |
| Synthetix | burnSynths     | 547,257  | +193,145 | +55%  |
| Synthetix | exchange       | 565,260  | +339,218 | +150% |
| Synthetix | issueMaxSynths | 503,953  | +161,406 | +47%  |
| Synthetix | issueSynths    | 531,401  | +168,223 | +46%  |

> from https://github.com/Synthetixio/synthetix/runs/457383033

The biggest impact is to `exchange()` however that was primarily due to [SIP-37](./sip-37.md) (Fee Reclamation) that was also released in Achernar.

By caching the various required addresses, we can reduce these down and not worry about having to write code in each function to limit how often we lookup the addresses required.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

1. Introduce a local `mapping(bytes32 => address)` cache into `MixinResolver` - the functionality included in all contracts that need to communicate via the address resolver
2. Ensure `MixinResolver` is instantiated with a list of `bytes32` addresses that the contract needs to know about
3. Expose a function in `MixinResolver.setResolverAndSyncCache()` to sync the cache. This is to be called each deployment whenever any new contracts are added.

Preliminary investigations after Caching and other improvements (such as SIP-41):

| Contract  | Function       | Gas Used | Diff from pre-Achenar | %     |
| --------- | -------------- | -------- | --------------------- | ----- |
| FeePool   | claimFees      | 422,852  | +100,211              | +24%  |
| Synthetix | burnSynths     | 329,877  | -22,871               | -7%   |
| Synthetix | exchange       | 473,954  | +247,913              | +110% |
| Synthetix | issueMaxSynths | 437,013  | +94,466               | +28%  |
| Synthetix | issueSynths    | 394,636  | +33,566               | +9%   |

> from https://github.com/Synthetixio/synthetix/pull/434/checks?check_run_id=480906529

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

1. A local mapping in each `MixinResolver` will prevent unnecssary CALL opcodes from being used (approximately 1518 gas)
2. Having the list of required address names in each `MixinResolver` will allow automated checks each deployment to know what needs updating in the AddressResolver
3. After each deployment, determine which `MixinResolver` contracts need to be resynced based on the list in #2 above

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

https://github.com/Synthetixio/synthetix/blob/resolver-gas-improvements/test/contracts/MixinResolver.js

https://github.com/Synthetixio/synthetix/blob/resolver-gas-improvements/test/publish/index.js#L944-L1073

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

[@Synthetixio/synthetix#434](https://github.com/Synthetixio/synthetix/pull/434)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
