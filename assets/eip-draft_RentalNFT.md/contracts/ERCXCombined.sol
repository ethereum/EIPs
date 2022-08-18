// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERCX.sol";
import "./IERCXBalance.sol";
import "./IERCXEnumerable.sol";
import "./IERCXTerminable.sol";

/**
 * @dev Implementation of ERCX contract with all extensions ---proposal_link--- with OpenZeppelin ERC721 version.
 */
contract ERCXCombined is
    IERCX,
    IERCXBalance,
    IERCXTerminable,
    IERCXEnumerable,
    ERC721
{
    /**
     * @dev Structure to hold user information.
     * @notice If isBorrowed is true, UserInfo cannot be modified before it expires.
     */
    struct UserInfo {
        address user; // Address of user role
        uint64 expires; // Unix timestamp, user expires on
        bool isBorrowed; // Borrowed flag
    }

    /**
     * @dev Structure to hold agreements from both parties to terminate a borrow.
     * @notice If both parties agree, it is possible to modify UserInfo even before it expires.
     * In such case, isBorrowed status is reverted to false.
     */
    struct BorrowTerminationInfo {
        bool lenderAgreement;
        bool borrowerAgreement;
    }

    // Mapping from token ID to UserInfo
    mapping(uint256 => UserInfo) internal _users;

    // Mapping from address to userOf tokens
    mapping(address => uint256[]) internal _userBalances;

    // Mapping from token ID to BorrowTerminationInfo
    mapping(uint256 => BorrowTerminationInfo) internal _borrowTerminations;

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
        // Balance extension
        flushExpired(user);

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

        // Balance extension
        _userBalances[user].push(tokenId);
        // Terminable extension
        delete _borrowTerminations[tokenId];
        emit ResetTerminationAgreements(tokenId);
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
     * @dev See {IERCX-userBalanceOf}.
     */
    function userBalanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            user != address(0),
            "ERCXBalance: address zero is not a valid owner"
        );
        uint256 balance;
        uint256[] memory candidates = _userBalances[user];
        unchecked {
            for (uint256 i; i < candidates.length; ++i) {
                if (
                    _users[candidates[i]].expires >= block.timestamp &&
                    _users[candidates[i]].user == user
                ) {
                    ++balance;
                }
            }
        }
        return balance;
    }

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
     * @dev See {IERCXTerminable-getBorrowTermination}.
     */
    function getBorrowTermination(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool, bool)
    {
        return (
            _borrowTerminations[tokenId].lenderAgreement,
            _borrowTerminations[tokenId].borrowerAgreement
        );
    }

    /**
     * @dev See {IERCXTerminable-setBorrowTermination}.
     */
    function setBorrowTermination(uint256 tokenId) public virtual override {
        UserInfo storage userInfo = _users[tokenId];
        require(
            userInfo.expires >= block.timestamp && userInfo.isBorrowed,
            "ERCXTerminable: borrow not active"
        );

        BorrowTerminationInfo storage terminationInfo = _borrowTerminations[
            tokenId
        ];
        if (ownerOf(tokenId) == msg.sender) {
            terminationInfo.lenderAgreement = true;
            emit AgreeToTerminateBorrow(tokenId, msg.sender, true);
        }
        if (userInfo.user == msg.sender) {
            terminationInfo.borrowerAgreement = true;
            emit AgreeToTerminateBorrow(tokenId, msg.sender, false);
        }
    }

    /**
     * @dev See {IERCXTerminable-terminateBorrow}.
     */
    function terminateBorrow(uint256 tokenId) public virtual override {
        BorrowTerminationInfo storage info = _borrowTerminations[tokenId];
        require(
            info.lenderAgreement && info.borrowerAgreement,
            "ERCXTerminable: not agreed"
        );
        _users[tokenId].isBorrowed = false;
        delete _borrowTerminations[tokenId];
        emit ResetTerminationAgreements(tokenId);
        emit TerminateBorrow(
            tokenId,
            ownerOf(tokenId),
            _users[tokenId].user,
            msg.sender
        );
    }

    /**
     * @notice On setUser flush all expired userOf statuses.
     * @dev This function may revert out of gas if user borrows too many tokens at once.
     * There must be a way to prevent such behaviour (such as flushing by parts only).
     * @param user an address to flush
     */
    function flushExpired(address user) internal {
        uint256[] storage candidates = _userBalances[user];
        unchecked {
            for (uint256 i; i < candidates.length; ++i) {
                if (
                    _users[candidates[i]].user != user ||
                    _users[candidates[i]].expires < block.timestamp
                ) {
                    candidates[i] = candidates[candidates.length - 1];
                    candidates.pop();
                    --i; // test moved element
                }
            }
        }
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
            interfaceId == type(IERCXBalance).interfaceId ||
            interfaceId == type(IERCXEnumerable).interfaceId ||
            interfaceId == type(IERCXTerminable).interfaceId ||
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
        } else if (
            // Terminable extension
            from != to && _users[tokenId].isBorrowed
        ) {
            delete _borrowTerminations[tokenId];
            emit ResetTerminationAgreements(tokenId);
        }
    }
}
