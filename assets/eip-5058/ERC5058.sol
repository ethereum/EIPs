// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./IERC5058.sol";

/**
 * @dev Implementation ERC721 Lockable Token
 */
abstract contract ERC5058 is ERC721, IERC5058 {
    // Mapping from token ID to unlock time
    mapping(uint256 => uint256) public lockedTokens;

    // Mapping from token ID to lock approved address
    mapping(uint256 => address) private _lockApprovals;

    // Mapping from owner to lock operator approvals
    mapping(address => mapping(address => bool)) private _lockOperatorApprovals;

    /**
     * @dev See {IERC5058-lockApprove}.
     */
    function lockApprove(address to, uint256 tokenId) public virtual override {
        require(!isLocked(tokenId), "ERC5058: token is locked");
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC5058: lock approval to current owner");

        require(
            _msgSender() == owner || isLockApprovedForAll(owner, _msgSender()),
            "ERC5058: lock approve caller is not owner nor approved for all"
        );

        _lockApprove(owner, to, tokenId);
    }

    /**
     * @dev See {IERC5058-getLockApproved}.
     */
    function getLockApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC5058: lock approved query for nonexistent token");

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC5058-lockerOf}.
     */
    function lockerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC5058: locker query for nonexistent token");
        require(isLocked(tokenId), "ERC5058: locker query for non-locked token");

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC5058-setLockApprovalForAll}.
     */
    function setLockApprovalForAll(address operator, bool approved) public virtual override {
        _setLockApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC5058-isLockApprovedForAll}.
     */
    function isLockApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _lockOperatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC5058-isLocked}.
     */
    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return lockedTokens[tokenId] > block.number;
    }

    /**
     * @dev See {IERC5058-lockExpiredTime}.
     */
    function lockExpiredTime(uint256 tokenId) public view virtual override returns (uint256) {
        return lockedTokens[tokenId];
    }

    /**
     * @dev See {IERC5058-lock}.
     */
    function lock(uint256 tokenId, uint256 expired) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isLockApprovedOrOwner(_msgSender(), tokenId), "ERC5058: lock caller is not owner nor approved");
        require(expired > block.number, "ERC5058: expired time must be greater than current block number");
        require(!isLocked(tokenId), "ERC5058: token is locked");

        _lock(_msgSender(), tokenId, expired);
    }

    /**
     * @dev See {IERC5058-unlock}.
     */
    function unlock(uint256 tokenId) public virtual override {
        require(lockerOf(tokenId) == _msgSender(), "ERC5058: unlock caller is not lock operator");

        address from = ERC721.ownerOf(tokenId);

        _beforeTokenLock(_msgSender(), from, tokenId, 0);

        delete lockedTokens[tokenId];

        emit Unlocked(_msgSender(), from, tokenId);

        _afterTokenLock(_msgSender(), from, tokenId, 0);
    }

    /**
     * @dev Locks `tokenId` from `from`  until `expired`.
     *
     * Requirements:
     *
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Locked} event.
     */
    function _lock(
        address operator,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenLock(operator, owner, tokenId, expired);

        lockedTokens[tokenId] = expired;
        _lockApprovals[tokenId] = operator;

        emit Locked(operator, owner, tokenId, expired);

        _afterTokenLock(operator, owner, tokenId, expired);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`, but the `tokenId` is locked and cannot be transferred.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     *
     * Emits {Locked} and {Transfer} event.
     */
    function _safeLockMint(
        address to,
        uint256 tokenId,
        uint256 expired,
        bytes memory _data
    ) internal virtual {
        require(expired > block.number, "ERC5058: lock mint for invalid lock block number");

        _safeMint(to, tokenId, _data);

        _lock(_msgSender(), tokenId, expired);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the lock approvals for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ERC721.ownerOf(tokenId);
        super._burn(tokenId);

        _beforeTokenLock(_msgSender(), owner, tokenId, 0);

        // clear lock approvals
        delete lockedTokens[tokenId];
        delete _lockApprovals[tokenId];

        _afterTokenLock(_msgSender(), owner, tokenId, 0);
    }

    /**
     * @dev Approve `to` to lock operate on `tokenId`
     *
     * Emits a {LockApproval} event.
     */
    function _lockApprove(
        address owner,
        address to,
        uint256 tokenId
    ) internal virtual {
        _lockApprovals[tokenId] = to;
        emit LockApproval(owner, to, tokenId);
    }

    /**
     * @dev Approve `operator` to lock operate on all of `owner` tokens
     *
     * Emits a {LockApprovalForAll} event.
     */
    function _setLockApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC5058: lock approve to caller");
        _lockOperatorApprovals[owner][operator] = approved;
        emit LockApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to lock `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isLockApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC5058: lock operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isLockApprovedForAll(owner, spender) || getLockApproved(tokenId) == spender);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the `tokenId` must not be locked.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!isLocked(tokenId), "ERC5058: token transfer while locked");
    }

    /**
     * @dev Hook that is called before any token lock/unlock.
     *
     * Calling conditions:
     *
     * - `owner` is non-zero.
     * - When `expired` is zero, `tokenId` will be unlock for `from`.
     * - When `expired` is non-zero, ``from``'s `tokenId` will be locked.
     *
     */
    function _beforeTokenLock(
        address operator,
        address owner,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {}

    /**
     * @dev Hook that is called after any lock/unlock of tokens.
     *
     * Calling conditions:
     *
     * - `owner` is non-zero.
     * - When `expired` is zero, `tokenId` will be unlock for `from`.
     * - When `expired` is non-zero, ``from``'s `tokenId` will be locked.
     *
     */
    function _afterTokenLock(
        address operator,
        address owner,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC5058).interfaceId || super.supportsInterface(interfaceId);
    }
}
