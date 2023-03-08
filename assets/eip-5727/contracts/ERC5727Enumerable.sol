//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC5727.sol";
import "./interfaces/IERC5727Enumerable.sol";

abstract contract ERC5727Enumerable is ERC5727, IERC5727Enumerable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private _indexedTokenIds;
    mapping(address => uint256) private _numberOfValidTokens;

    Counters.Counter private _emittedCount;
    Counters.Counter private _ownersCount;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC5727)
        returns (bool)
    {
        return
            interfaceId == type(IERC5727Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenMint(
        address issuer,
        address owner,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        if (_indexedTokenIds[owner].length() == 0) {
            _ownersCount.increment();
        }
        //unused variables
        issuer;
        tokenId;
        value;
        slot;
        valid;
    }

    function _afterTokenMint(
        address issuer,
        address owner,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        _indexedTokenIds[owner].add(tokenId);
        if (valid) {
            _numberOfValidTokens[owner] += 1;
        }
        //unused variables
        issuer;
        value;
        slot;
        valid;
    }

    function _mint(
        address owner,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256 tokenId) {
        tokenId = _emittedCount.current();
        _mintUnsafe(owner, tokenId, value, slot, true);
        emit Minted(owner, tokenId, value);
        _emittedCount.increment();
    }

    function _mint(
        address issuer,
        address owner,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256 tokenId) {
        tokenId = _emittedCount.current();
        _mintUnsafe(issuer, owner, tokenId, value, slot, true);
        emit Minted(owner, tokenId, value);
        _emittedCount.increment();
    }

    function _mintBatch(
        address[] memory owners,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            tokenIds[i] = _mint(owners[i], value, slot);
        }
    }

    function _afterTokenRevoke(uint256 tokenId) internal virtual override {
        assert(_numberOfValidTokens[_getTokenOrRevert(tokenId).owner] > 0);
        _numberOfValidTokens[_getTokenOrRevert(tokenId).owner] -= 1;
    }

    function _beforeTokenDestroy(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        if (_getTokenOrRevert(tokenId).valid) {
            assert(_numberOfValidTokens[owner] > 0);
            _numberOfValidTokens[owner] -= 1;
        }
        EnumerableSet.remove(_indexedTokenIds[owner], tokenId);
        if (EnumerableSet.length(_indexedTokenIds[owner]) == 0) {
            assert(_ownersCount.current() > 0);
            _ownersCount.decrement();
        }
    }

    function _increaseEmittedCount() internal {
        _emittedCount.increment();
    }

    function _tokensOfOwner(address owner)
        internal
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _indexedTokenIds[owner].values();
        require(tokenIds.length != 0, "ERC5727: the owner has no token");
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _emittedCount.current();
    }

    function ownersCount() public view virtual override returns (uint256) {
        return _ownersCount.current();
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _indexedTokenIds[owner].length();
    }

    function hasValid(address owner)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _numberOfValidTokens[owner] > 0;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        EnumerableSet.UintSet storage ids = _indexedTokenIds[owner];
        require(
            index < EnumerableSet.length(ids),
            "ERC5727: Token does not exist"
        );
        return ids.at(index);
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return index;
    }
}
