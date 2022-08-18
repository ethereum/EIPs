// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @title IERC5501Enumerable
 * @dev See https://eips.ethereum.org/EIPS/eip-5501
 * This extension for ERC5501 adds the option to iterate over user tokens.
 * @notice the EIP-165 identifier for this interface is 0x1d350ef8.
 */
interface IERC5501Enumerable /* is IERC5501Balance, IERC5501 */ {
    /**
     * @notice Enumerate NFTs assigned to a user.
     * @dev Reverts if user is zero address or _index >= userBalanceOf(_owner).
     * @param _user an address to iterate over its tokens
     * @return uint256 the token ID for given index assigned to _user
     */
    function tokenOfUserByIndex(address _user, uint256 _index) external view returns (uint256);
}
