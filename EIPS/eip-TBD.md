---
title: NFT royalties with on-chain, decentralized enforcement
description: TBD
author: David Huber (@cxkoda) and Arran Schlosberg (@aschlosberg)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-09-25
requires: 165, 721, 2981
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

We describe a mechanism for which, upon sale of a Non-Fungible Token (NFT), the dominant strategy of the buyer is to truthfully report their valuation of the token and pay a creator-specified royalty computed from said valuation.

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

## Motivation

While [ERC-2981](./eip-2981.md) introduced a standard for contracts to signal a royalty amount to be paid upon sale of an NFT, it doesn't describe a means of enforcement. It goes so far as to state that "payment must be voluntary, as transfer mechanisms… \[do\] not always imply a sale occurred". Successful enforcement therefore requires token owners themselves to truthfully reveal both the occurrence and value of sales.

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

For each `tokenId`, we introduce a set of addresses, members of which MAY transfer token ownership to themselves, without payment. The set MUST be initially empty. For every action requiring logging of an ERC-721 `Transfer` event, *except* for initial mint, the set for the logged `tokenId` MUST be appended with the logged `from` address; i.e. upon each transfer, the set is appended with the previous owner. If an address in this set transfers the token to themselves under this specification, it is referred to as a *take-back*.

Royalty payment is accepted by the contract implementing ERC-721 and receipt of royalties MUST empty the take-back set (i.e. transfer permissions collapse back to standard ERC-721 rules). After each token transfer, a grace period SHOULD be allowed during which take-backs are disabled and the new owner decides whether to pay the royalty or allow the take-back set to grow.

In addition to clearing of the take-back set, receipt of royalties MUST begin a temporary window during which *any* address MAY purchase the token for a price that is a function of the royalty received—this is referred to as *auto-listing* and is not limited to addresses in the take-back set. The function determining this auto-listing price SHOULD be the inverse of the `royaltyInfo()` function of ERC-2981. Implementations MAY specify the duration of the auto-listing window at their discretion but it MUST be finite and, after expiration, transfer permissions MUST collapse back to standard ERC-721 rules.

```solidity
interface IERCTBD {
  // TBD
}
```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD 

TODO: a yellow paper with proofs of strategy dominance will be included in the assets; this is being finalised.

Summary rationale for the draft: the risk of take-back in the event of no royalty being paid is only a rational decision if the same entity controls both addresses; i.e. a change in beneficial owner of the token results in a payment but transfer between one's own addresses doesn't require royalty payment. The auto-listing window ensures *truthful* revelation of the value of the token.

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
