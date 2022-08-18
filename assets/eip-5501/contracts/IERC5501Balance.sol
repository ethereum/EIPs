// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @title IERC5501Balance
 * @dev See https://eips.ethereum.org/EIPS/eip-5501
 * Extension for ERC5501 which adds userBalanceOf to query how many tokens address is userOf.
 * @notice the EIP-165 identifier for this interface is 0x0cb22289.
 */
interface IERC5501Balance /* is IERC5501 */{
    /**
     * @notice Count of all NFTs assigned to a user.
     * @dev Reverts if user is zero address.
     * @param _user an address for which to query the balance
     * @return uint256 the number of NFTs the user has
     */
    function userBalanceOf(address _user) external view returns (uint256);
}
