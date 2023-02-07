// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0;

// TODO: use actual interfaces for 165 and 721.

interface IERC165 {

}

interface IERC721 is IERC165 {}

/**
 * @notice Extends ERC-721 to include per-token approval for multiple operators.
 * @dev Implementers concerned about the interplay between explicit approvals and the standard `ERC721` mechanisms MAY
 * choose to revert on all calls to `ERC721.setApprovalForAll(…)` to reduce risk exposure and make it easier to reason
 * about approvals. Off-chain indexers of approvals SHOULD assume that an operator is approved if either of
 * `ERC721.Approval(…)` or `ERC721.ApprovalForAll(…, true)` events are witnessed without the corresponding
 * revocation(s), even if an `ExplicitApprovalFor(…, false)` is emitted.
 * @dev TODO: the ERC-165 identifier for this interface is TBD.
 */
interface IERCTBD is IERC721 {
    /**
     * @notice Emitted when approval is explicitly granted or revoked for a token.
     */
    event ExplicitApprovalFor(
        address indexed operator,
        uint256 indexed tokenId,
        bool approved
    );

    /**
     * @notice Emitted when all explicit approvals, as granted by either `setExplicitApprovalFor()` function, are
     * revoked for all tokens.
     * @dev MUST be emitted upon calls to `revokeAllExplicitApprovals()`.
     */
    event AllExplicitApprovalsRevoked(address indexed owner);

    /**
     * @notice Emitted when all explicit approvals, as granted by either `setExplicitApprovalFor()` function, are
     * revoked for the specific token.
     * @dev MUST be emitted upon token transfer and calls to `revokeAllExplicitApprovals(tokenId)`.
     * @param owner MUST be `ownerOf(tokenId)` as per ERC721; in the case of revocation due to transfer, this MUST be
     * the `from` address expected to be emitted in the respective `ERC721.Transfer()` event.
     */
    event AllExplicitApprovalsRevoked(
        address indexed owner,
        uint256 indexed tokenId
    );

    /**
     * @notice Approves the operator to manage the asset on behalf of its owner.
     * @dev Throws if msg.sender is not the current NFT owner.
     * @dev Approvals set via this method MUST be cleared upon transfer of the token to a new owner; akin to calling
     * `revokeAllExplicitApprovals(tokenId)`, including associated events.
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
     * @notice Revokes all explicit approvals granted by `msg.sender`.
     * @dev MUST emit `AllExplicitApprovalsRevoked(msg.sender)`.
     */
    function revokeAllExplicitApprovals() external;

    /**
     * @notice Revokes all excplicit approvals granted by `msg.sender` for the specified token.
     * @dev Throws if `msg.sender` is not the current NFT owner.
     * @dev MUST emit `AllExplicitApprovalsRevoked(msg.sender, tokenId)`.
     */
    function revokeAllExplicitApprovals(uint256 tokenId) external;

    /**
     * @notice Returns true if (a) `operator` was approved via either `setExplicitApprovalFor()` function on `tokenId`;
     * and (b) the token has not since been transferred.
     * @dev Criterion (b) is important as an owner MUST NOT need to revoke approvals if receiving a token that they
     * previously owned.
     */
    function isExplicitlyApprovedFor(address operator, uint256 tokenId)
        external
        view
        returns (bool);
}

interface IERCTBDAnyApproval is IERC165 {
    /**
     * @notice Returns true if any of the following criteria are met:
     * 1. `isExplicitlyApprovedFor(operator, tokenId) == true`; OR
     * 2. `isApprovedForAll(ownerOf(tokenId), operator) == true`; OR
     * 3. `getApproved(tokenId) == operator`.
     * @dev The criteria MUST be extended if other mechanism(s) for approving operators are introduced. The criteria
     * MUST include all approval approaches.
     */
    function isApprovedFor(address operator, uint256 tokenId)
        external
        view
        returns (bool);
}
