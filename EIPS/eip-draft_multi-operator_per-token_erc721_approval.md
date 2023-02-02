---
title: Multi-operator, per-token ERC721 approval.
description: Extends the ERC721 standard to allow token owners to approve multiple operators to control their assets on a per-token basis.
author: Simon Fremaux (@dievardump), … (@crisgarner), David Huber (@cxkoda), 0xInuarashi (@0xInuarashi), … (@Slokh) and Arran Schlosberg (@aschlosberg)
discussions-to: https://ethereum-magicians.org/t/fine-grained-erc721-approval-for-multiple-operators/12796
status: Draft
type: ERC
created: 2023-02-02
requires: 165, 721
---

## Abstract

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

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

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

To comply with this EIP, a contract MUST implement `IERCTBD` (defined herein) and the `ERC165` and `ERC721` interfaces; see [EIP-165](./eip-165.md) and [EIP-721](./eip-721.md) respectively.

```
interface IERCTBD {
    /**
     * @notice Emitted when an operator is enabled or disabled for a token.
     */
    event ApprovalFor(
        address indexed operator,
        uint256 indexed tokenId,
        bool approved
    );

    /**
     * @notice Emitted when all explicit approvals, as granted by either
     *         `setApprovalFor()` function, are revoked for all tokens.
     */
    event AllExplicitApprovalsRevoked(address indexed owner);

    /**
     * @notice Emitted when all explicit approvals, as granted by either
     *         `setApprovalFor()` function, are revoked for the specific token.
     * @dev Inclusion of an indexed owner assists off-chain indexing of
     *      existing approvals.
     * @param owner MUST be `ownerOf(tokenId)` as per ERC721.
     */
    event AllExplicitApprovalsRevoked(
        address indexed owner,
        uint256 indexed tokenId
    );

    /**
     * @notice Approves the operator to manage the asset on behalf of its owner.
     * @dev Throws if msg.sender is not the current NFT owner.
     * @dev Approvals set via this method MUST be cleared upon transfer of the
     *      token to a new owner.
     * @dev MUST emit `ApprovalFor(operator,tokenId,approved)`.
     */
    function setApprovalFor(
        address operator,
        uint256 tokenId,
        bool approved
    ) external;

    /**
     * @notice Approves the operator to manage the tokens on behalf of its owner.
     * @dev Throws if msg.sender is not the current NFT owner of any of the
     *      tokens.
     * @dev Approvals set via this method MUST be cleared upon transfer of the
     *      token to a new owner.
     * @dev MUST emit `ApprovalFor(operator,tokenId,approved)` for each tokenId.
     */
    function setApprovalFor(
        address operator,
        uint256[] calldata tokenIds,
        bool approved
    ) external;

    /**
     * @notice Revokes all approvals, for all tokens, previously granted by
     *         `msg.sender` via either of the `setApprovalFor()` functions.
     * @dev MUST emit `AllExplicitApprovalsRevoked(msg.sender)`.
     */
    function revokeAllExplicitApprovals() external;

    /**
     * @notice Revokes all approvals, for the specified token, previously
     *         granted by `msg.sender` via either of the `setApprovalFor()`
     *         functions.
     * @dev This functionality MUST be invoked upon token transfer.
     * @dev MUST emit `AllExplicitApprovalsRevoked(ownerOf(tokenId),tokenId)`.
     */
    function revokeAllExplicitApprovals(uint256 tokenId) external;

    /**
     * @notice Returns true if any of the following criteria are met:
     *         1. `operator` was approved via either `setApprovalFor()` function
     *            on `tokenId` and the token has not since been transferred; OR
     *         2. `isApprovedForAll(ownerOf(tokenId), operator) == true`; OR
     *         3. `getApproved(tokenId) == operator`.
     */
    function isApprovedFor(address operator, uint256 tokenId)
        external
        view
        returns (bool);
}
```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

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
