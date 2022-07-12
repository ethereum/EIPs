// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title ERC-1155 Approval By Amount Extension
 * Note: the ERC-165 identifier for this interface is 0x1be07d74
 */
interface IERC1155ApprovalByAmount is IERC1155 {

    /**
     * @notice Emmited when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `id` and with an amount: `amount`.
     */
    event ApprovalByAmount(address indexed account, address indexed operator, uint256 id, uint256 amount);

    /**
     * @notice Grants permision to `operator` to transfer the caller's tokens, according to `id`, and an amount: `amount`.
     * Emits an {ApprovalByAmount} event.
     *
     * Requirements:
     * - `operator` cannot be the caller.
     */
    function approve(address operator, uint256 id, uint256 amount) external;

    /**
     * @notice Returns the amount allocated to `operator` approved to transfer ``account``'s tokens, according to `id`.
     */
    function allowance(address account, address operator, uint256 id) external view returns (uint256);
    
}
