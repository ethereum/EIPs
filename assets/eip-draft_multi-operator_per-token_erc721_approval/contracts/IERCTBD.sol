// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

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
