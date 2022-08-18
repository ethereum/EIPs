// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERCX.sol";

/**
 * @dev Implementation of ---proposal_link--- with OpenZeppelin ERC721 version.
 */
contract ERCX is IERCX, ERC721 {
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
     * @dev See {IERCX-setUser}.
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool isBorrowed
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERCX: set user caller is not token owner or approved"
        );
        require(user != address(0), "ERCX: set user to zero address");

        UserInfo storage info = _users[tokenId];
        require(
            !info.isBorrowed || info.expires < block.timestamp,
            "ERCX: token is borrowed"
        );
        info.user = user;
        info.expires = expires;
        info.isBorrowed = isBorrowed;
        emit UpdateUser(tokenId, user, expires, isBorrowed);
    }

    /**
     * @dev See {IERCX-userOf}.
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
            "ERCX: user does not exist for this token"
        );
        return _users[tokenId].user;
    }

    /**
     * @dev See {IERCX-userExpires}.
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
     * @dev See {IERCX-isBorrowed}.
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
            interfaceId == type(IERCX).interfaceId ||
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
