// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC165.sol";

/**
 * @title ERC-7410 Update Allowance By Spender Extension
 * Note: the ERC-165 identifier for this interface is 0x2d474b5c
 */
interface IERC20ApproveBySpender is IERC20, IERC165 {

    /**
     * @notice Updates any allowance by `owner` address for caller.
     * Emits an {IERC20-Approval} event.
     *
     * Requirements:
     * - `owner` cannot be the caller.
     * - `amount` should be less than or equal to current allowance of `owner` for caller.
     */
    function approveBySpender(address owner, uint256 amount) external;

}
