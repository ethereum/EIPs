// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC165.sol";

/**
 * @title ERC-7410 Update Allowance By Spender Extension
 * Note: the ERC-165 identifier for this interface is 0x12860fba
 */
interface IERC7410 is IERC20, IERC165 {

    /**
     * @notice Decreases any allowance by `owner` address for caller.
     * Emits an {IERC20-Approval} event.
     *
     * Requirements:
     * - when `subtractedValue` is equal or higher than current allowance of spender the new allowance is set to 0.
     * Nullification also MUST be reflected for current allowance being type(uint256).max.
     */
    function decreaseAllowanceBySpender(address owner, uint256 subtractedValue) external;

}
