// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERCXBalance.sol";
import "./IERCXEnumerable.sol";

/**
 * @dev Implementation of Enumerable extension of ---proposal_link--- with OpenZeppelin ERC721 version.
 */
contract ERCXEnumerable is IERCXEnumerable, ERCXBalance {
    /**
     * @dev Initializes the contract by setting a name and a symbol to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        ERCXBalance(name_, symbol_)
    {}

    /**
     * @dev See {IERCX-tokenOfUserByIndex}.
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
            "ERCXEnumerable: address zero is not a valid owner"
        );
        uint256[] memory balance = _userBalances[user];
        require(
            balance.length > 0 && index < balance.length,
            "ERCXEnumerable: owner index out of bounds"
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
        revert("ERCXEnumerable: owner index out of bounds");
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
            interfaceId == type(IERCXEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
