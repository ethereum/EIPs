// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Consensus Interface
 * @dev This extension allows minting and revocation of tokens by community voting.
 */
interface IERC5727Governance is IERC5727 {
    /**
     * @notice Get the voters of the contract.
     * @return The array of the voters
     */
    function voters() external view returns (address[] memory);

    /**
     * @notice Approve to mint the token described by the `approvalRequestId` to `owner`.
     * @dev MUST revert if the caller is not a voter.
     * @param owner The owner which the token to mint to
     * @param approvalRequestId The approval request describing the value and slot of the token to mint
     */
    function approveMint(address owner, uint256 approvalRequestId) external;

    /**
     * @notice Approve to revoke the `tokenId`.
     * @dev MUST revert if the `tokenId` does not exist.
     * @param tokenId The token to revert
     */
    function approveRevoke(uint256 tokenId) external;

    /**
     * @notice Create an approval request describing the `value` and `slot` of a token.
     * @dev MUST revert when `value` is zero.
     * @param value The value of the approval request to create
     */
    function createApprovalRequest(uint256 value, uint256 slot) external;

    /**
     * @notice Remove `approvalRequestId` approval request.
     * @dev MUST revert if the caller is not the creator of the approval request.
     * @param approvalRequestId The approval request to remove
     */
    function removeApprovalRequest(uint256 approvalRequestId) external;

    /**
     * @notice Add a new voter `newVoter`.
     * @dev MUST revert if the caller is not an administrator.
     *  MUST revert if `newVoter` is already a voter.
     * @param newVoter the new voter to add
     */
    function addVoter(address newVoter) external;

    /**
     * @notice Remove the `voter` from the contract.
     * @dev MUST revert if the caller is not an administrator.
     *  MUST revert if `voter` is not a voter.
     * @param voter the voter to remove
     */
    function removeVoter(address voter) external;
}
