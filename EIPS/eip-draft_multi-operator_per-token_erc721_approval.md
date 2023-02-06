---
title: Multi-operator, per-token ERC721 approval.
description: Extends the ERC721 standard to allow token owners to approve multiple operators to control their assets on a per-token basis.
author: Simon Fremaux (@dievardump), Cristian Espinoza (@crisgarner), David Huber (@cxkoda), 0xInuarashi (@0xInuarashi), Kartik Patel (@Slokh) and Arran Schlosberg (@aschlosberg)
discussions-to: https://ethereum-magicians.org/t/fine-grained-erc721-approval-for-multiple-operators/12796
status: Draft
type: ERC
created: 2023-02-02
requires: 165, 721
---

## Abstract

Extends ERC721 to introduce fine-grained approval of one or more operators to control one or more tokens on behalf of an owner. Without this EIP, the only way to approve `>1` operators for a given token is via `setApprovalForAll()`, which affords the approved operator control over all assets and creates an unnecessarily broad security risk. This EIP introduces a mechanism for per-token control of grants, and rapid revocation of all approvals on a per-owner or per-token basis.

## Motivation

The NFT standard defined in [EIP-721](./eip-721.md) allows token owners to "approve" arbitrary addresses to control their tokens—the approved addresses are known as "operators". Two types of approval are supported:

1. `approve(address,uint256)` provides a mechanism for only a single operator to be approved for a given `tokenId`; and
2. `setApprovalForAll(address,bool)` toggles whether an operator is approved for *every* token owned by `msg.sender`.

With the introduction of multiple NFT marketplaces, the ability to specify `>1` operators for a particular token is necessary if sellers wish to approve each marketplace to transfer a token upon sale. There is, however, no mechanism for achieving this without using `setApprovalForAll()`. This is in conflict with the principle of least privilege and creates an attack vector that is exploited by phishing for malicious (i.e. zero-cost) sell-side signatures that are executed by legitimate marketplace contracts.

This EIP therefore defines a fine-grained approach for approving multiple operators but scoped to specific token(s).

### Goals

1. Ease of adoption for marketplaces; requires minimal changes to existing workflows.
2. Ease of adoption for off-chain approval-indexing services.
3. Simplified revocation of approvals.

### Non-goals

1. Security measures for protecting NFTs other than through limiting the scope of operator approvals.
2. Compatibility with [EIP-1155](./eip-1155.md) semi-fungible tokens. However we note that the mechanisms described herein also apply to approval for an operator to control the entire balance of an ERC1155 token *type* without requiring approval for all tokens, regardless of type.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

To comply with this EIP, a contract MUST implement `IERCTBD` (defined herein) and the `ERC165` and `ERC721` interfaces; see [EIP-165](./eip-165.md) and [EIP-721](./eip-721.md) respectively.

```
/**
 * @dev Implementers concerned about the interplay between explicit approvals and the standard `ERC721` mechanisms MAY
 *      choose to revert on all calls to `ERC721.setApprovalForAll(…)` to reduce risk exposure and make it easier to
 *      reason about approvals. Off-chain indexers of approvals SHOULD assume that an operator is approved if either of
 *      `ERC721.Approval(…)` or `ERC721.ApprovalForAll(…, true)` events are witnessed without the corresponding
 *      revocation(s).
 */
interface IERCTBD {
    /**
     * @notice Emitted when an operator is explicitly enabled or disabled for a token.
     */
    event ExplicitApprovalFor(
        address indexed operator,
        uint256 indexed tokenId,
        bool approved
    );

    /**
     * @notice Emitted when all explicit approvals, as granted by either `setExplicitApprovalFor()` function, are
     *         revoked for all tokens.
     * @dev MUST be emitted upon calls to `revokeAllExplicitApprovals()`.
     */
    event AllExplicitApprovalsRevoked(address indexed owner);

    /**
     * @notice Emitted when all explicit approvals, as granted by either `setExplicitApprovalFor()` function, are
     *         revoked for the specific token.
     * @dev MUST be emitted upon token transfer and calls to `revokeAllExplicitApprovals(tokenId)`.
     * @dev Inclusion of an indexed owner address assists off-chain indexing of existing approvals.
     * @param owner MUST be `ownerOf(tokenId)` as per ERC721; in the case of revocation due to transfer, this MUST be
     *              the `from` address expected to be emitted in the respective `ERC721.Transfer()` event.
     */
    event AllExplicitApprovalsRevoked(
        address indexed owner,
        uint256 indexed tokenId
    );

    /**
     * @notice Approves the operator to manage the asset on behalf of its owner.
     * @dev Throws if msg.sender is not the current NFT owner.
     * @dev Approvals set via this method MUST be cleared upon transfer of the token to a new owner; akin to calling
     *      `revokeAllExplicitApprovals(tokenId)`, including associated events.
     * @dev MUST emit `ApprovalFor(operator, tokenId, approved)`.
     * @dev MUST NOT have an effect on any standard ERC721 approval setters / getters.
     */
    function setExplicitApproval(
        address operator,
        uint256 tokenId,
        bool approved
    ) external;

    /**
     * @notice Approves the operator to manage the token(s) on behalf of their owner.
     * @dev MUST be equivalent to calling `setExplicitApprovalFor(operator, tokenId, approved)` for each `tokenId` in
     * the array.
     */
    function setExplicitApproval(
        address operator,
        uint256[] memory tokenIds,
        bool approved
    ) external;

    /**
     * @notice Revokes all explicit approvals, for all tokens, i.e. those granted by `msg.sender` via either of the
     *         `setExplicitApprovalFor()` functions.
     * @dev MUST emit `AllExplicitApprovalsRevoked(msg.sender)`.
     */
    function revokeAllExplicitApprovals() external;

    /**
     * @notice Revokes all excplicit approvals, for the specified token, i.e. those granted by `msg.sender` via either
     *         of the `setExplicitApprovalFor()` functions.
     * @dev Throws if `msg.sender` is not the current NFT owner.
     * @dev MUST emit `AllExplicitApprovalsRevoked(msg.sender, tokenId)`.
     */
    function revokeAllExplicitApprovals(uint256 tokenId) external;

    /**
     * @notice Returns true if (a) `operator` was approved via either `setExplicitApprovalFor()` function on `tokenId`;
     *         and (b) the token has not since been transferred.
     * @dev Criterion (b) is important as an owner MUST NOT need to revoke approvals if receiving a token that they
     *      previously owned.
     */
    function isExplicitlyApprovedFor(address operator, uint256 tokenId)
        external
        view
        returns (bool);
}
```

Compliant contracts SHOULD also implement IERCTBDAnyApproval.

```
interface IERCTBDAnyApproval {
    /**
     * @notice Returns true if any of the following criteria are met:
     *         1. `isExplicitlyApprovedFor(operator, tokenId) == true`; OR
     *         2. `isApprovedForAll(ownerOf(tokenId), operator) == true`; OR
     *         3. `getApproved(tokenId) == operator`.
     * @dev The criteria MUST be extended if other mechanism(s) for approving operators are introduced. The criteria
     *      MUST include all approval approaches, joined by logical OR.
     */
    function isApprovedFor(address operator, uint256 tokenId)
        external
        view
        returns (bool);
}
```

## Rationale

### Notes to be expanded upon
1. Approvals granted via the newly introduced methods are called *explicit* as a means of easily distinguishing them from those granted via the standard `ERC721.approve()` and `ERC721.setApprovalForAll()` functions. They do *not*, however, function differently to other approvals.
2. Abstracting `isApprovedFor()` into IERCTBDAnyApproval interface, as against keeping it in `IERCTBD` allows for modularity of plain IERCTBD implementations while also standardising the interface for checking approvals when interfacing with specific implementations and any future approval EIPs.

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Reference Implementation

An [efficient mechanism for broad revocation of approvals](../assets/eip-TODO/) via incrementing nonces is included.

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

### Threat model

### Mitigations

### Other risks

TODO: Interplay with `setApprovalForAll()`.

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
