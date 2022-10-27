// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5501.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-5501 with OpenZeppelin ERC721 version.
 */
contract ERC5501 is IERC5501, ERC721 {
    /**
     * @dev Structure to hold user information.
     * @notice If isBorrowed is true, UserInfo cannot be modified before it expires.
     */
    struct UserInfo {
        address user; // Address of user role
        uint64 expires; // Unix timestamp, user expires on
        bool isBorrowed; // Borrowed flag
    }

    // Mapping from token ID to UserInfo
    mapping(uint256 => UserInfo) internal _users;

    /**
     * @dev Initializes the contract by setting a name and a symbol to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * @dev See {IERC5501-setUser}.
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool isBorrowed
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC5501: set user caller is not token owner or approved"
        );
        require(user != address(0), "ERC5501: set user to zero address");

        UserInfo storage info = _users[tokenId];
        require(
            !info.isBorrowed || info.expires < block.timestamp,
            "ERC5501: token is borrowed"
        );
        info.user = user;
        info.expires = expires;
        info.isBorrowed = isBorrowed;
        emit UpdateUser(tokenId, user, expires, isBorrowed);
    }

    /**
     * @dev See {IERC5501-userOf}.
     */
    function userOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            uint256(_users[tokenId].expires) >= block.timestamp,
            "ERC5501: user does not exist for this token"
        );
        return _users[tokenId].user;
    }

    /**
     * @dev See {IERC5501-userExpires}.
     */
    function userExpires(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint64)
    {
        return _users[tokenId].expires;
    }

    /**
     * @dev See {IERC5501-isBorrowed}.
     */
    function userIsBorrowed(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _users[tokenId].isBorrowed;
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
            interfaceId == type(IERC5501).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called after any token transfer.
     * If user is set and token is not borrowed, reset user.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        if (
            from != to &&
            !_users[tokenId].isBorrowed &&
            _users[tokenId].user != address(0)
        ) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0, false);
        }
    }
}
