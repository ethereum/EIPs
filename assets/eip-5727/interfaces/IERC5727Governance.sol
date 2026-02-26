// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Governance Interface
 * @dev This extension allows issuing of tokens by community voting.
 */
interface IERC5727Governance is IERC5727 {
    enum ApprovalStatus {
        Pending,
        Approved,
        Rejected,
        Removed
    }

    /**
     * @notice Emitted when a token issuance approval is changed.
     * @param approvalId The id of the approval
     * @param creator The creator of the approval, zero address if the approval is removed
     * @param status The status of the approval
     */
    event ApprovalUpdate(
        uint256 indexed approvalId,
        address indexed creator,
        ApprovalStatus status
    );

    /**
     * @notice Emitted when a voter approves an approval.
     * @param voter The voter who approves the approval
     * @param approvalId The id of the approval
     */
    event Approve(
        address indexed voter,
        uint256 indexed approvalId,
        bool approve
    );

    /**
     * @notice Create an approval of issuing a token.
     * @dev MUST revert if the caller is not a voter.
     *      MUST revert if the `to` address is the zero address.
     * @param to The owner which the token to mint to
     * @param tokenId The id of the token to mint
     * @param amount The amount of the token to mint
     * @param slot The slot of the token to mint
     * @param burnAuth The burn authorization of the token to mint
     * @param data The additional data used to mint the token
     */
    function requestApproval(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 slot,
        BurnAuth burnAuth,
        address verifier,
        bytes calldata data
    ) external;

    /**
     * @notice Remove `approvalId` approval request.
     * @dev MUST revert if the caller is not the creator of the approval request.
     *      MUST revert if the approval request is already approved or rejected or non-existent.
     * @param approvalId The approval to remove
     */
    function removeApprovalRequest(uint256 approvalId) external;

    /**
     * @notice Approve `approvalId` approval request.
     * @dev MUST revert if the caller is not a voter.
     *     MUST revert if the approval request is already approved or rejected or non-existent.
     * @param approvalId The approval to approve
     * @param approve True if the approval is approved, false if the approval is rejected
     * @param data The additional data used to approve the approval (e.g. the signature, voting power)
     */
    function voteApproval(
        uint256 approvalId,
        bool approve,
        bytes calldata data
    ) external;

    /**
     * @notice Get the URI of the approval.
     * @dev MUST revert if the `approvalId` does not exist.
     * @param approvalId The approval whose URI is queried for
     * @return The URI of the approval
     */
    function approvalURI(
        uint256 approvalId
    ) external view returns (string memory);
}
