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
    Counters.Counter private _soulsCount;

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
        address soul,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        if (_indexedTokenIds[soul].length() == 0) {
            _soulsCount.increment();
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
        address soul,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        _indexedTokenIds[soul].add(tokenId);
        if (valid) {
            _numberOfValidTokens[soul] += 1;
        }
        //unused variables
        issuer;
        value;
        slot;
        valid;
    }

    function _mint(
        address soul,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256 tokenId) {
        tokenId = _emittedCount.current();
        _mintUnsafe(soul, tokenId, value, slot, true);
        emit Minted(soul, tokenId, value);
        _emittedCount.increment();
    }

    function _mint(
        address issuer,
        address soul,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256 tokenId) {
        tokenId = _emittedCount.current();
        _mintUnsafe(issuer, soul, tokenId, value, slot, true);
        emit Minted(soul, tokenId, value);
        _emittedCount.increment();
    }

    function _mintBatch(
        address[] memory souls,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](souls.length);
        for (uint256 i = 0; i < souls.length; i++) {
            tokenIds[i] = _mint(souls[i], value, slot);
        }
    }

    function _afterTokenRevoke(uint256 tokenId) internal virtual override {
        assert(_numberOfValidTokens[_getTokenOrRevert(tokenId).soul] > 0);
        _numberOfValidTokens[_getTokenOrRevert(tokenId).soul] -= 1;
    }

    function _beforeTokenDestroy(uint256 tokenId) internal virtual override {
        address soul = soulOf(tokenId);

        if (_getTokenOrRevert(tokenId).valid) {
            assert(_numberOfValidTokens[soul] > 0);
            _numberOfValidTokens[soul] -= 1;
        }
        EnumerableSet.remove(_indexedTokenIds[soul], tokenId);
        if (EnumerableSet.length(_indexedTokenIds[soul]) == 0) {
            assert(_soulsCount.current() > 0);
            _soulsCount.decrement();
        }
    }

    function _increaseEmittedCount() internal {
        _emittedCount.increment();
    }

    function _tokensOfSoul(address soul)
        internal
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _indexedTokenIds[soul].values();
        require(tokenIds.length != 0, "ERC5727: the soul has no token");
    }

    function emittedCount() public view virtual override returns (uint256) {
        return _emittedCount.current();
    }

    function soulsCount() public view virtual override returns (uint256) {
        return _soulsCount.current();
    }

    function balanceOf(address soul)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _indexedTokenIds[soul].length();
    }

    function hasValid(address soul)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _numberOfValidTokens[soul] > 0;
    }

    function tokenOfSoulByIndex(address soul, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        EnumerableSet.UintSet storage ids = _indexedTokenIds[soul];
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
