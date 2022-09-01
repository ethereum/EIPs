// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERC5501Balance.sol";
import "./IERC5501Enumerable.sol";

/**
 * @dev Implementation of Enumerable extension of https://eips.ethereum.org/EIPS/eip-5501 with OpenZeppelin ERC721 version.
 */
contract ERC5501Enumerable is IERC5501Enumerable, ERC5501Balance {
    /**
     * @dev Initializes the contract by setting a name and a symbol to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        ERC5501Balance(name_, symbol_)
    {}

    /**
     * @dev See {IERC5501-tokenOfUserByIndex}.
     */
    function tokenOfUserByIndex(address user, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            user != address(0),
            "ERC5501Enumerable: address zero is not a valid owner"
        );
        uint256[] memory balance = _userBalances[user];
        require(
            balance.length > 0 && index < balance.length,
            "ERC5501Enumerable: owner index out of bounds"
        );
        uint256 counter;
        unchecked {
            for (uint256 i; i < balance.length; ++i) {
                if (
                    _users[balance[i]].expires >= block.timestamp &&
                    _users[balance[i]].user == user
                ) {
                    if (counter == index) {
                        return balance[i];
                    }
                    ++counter;
                }
            }
        }
        revert("ERC5501Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {EIP-165: Standard Interface Detection}.
     * https://eips.ethereum.org/EIPS/eip-165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC5501Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
