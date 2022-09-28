//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC5727.sol";
import "./IERC5727Enumerable.sol";

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
        if (EnumerableSet.length(_indexedTokenIds[soul]) == 0) {
            Counters.increment(_soulsCount);
        }
    }

    function _afterTokenMint(
        address issuer,
        address soul,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        EnumerableSet.add(_indexedTokenIds[soul], tokenId);
        if (valid) {
            _numberOfValidTokens[soul] += 1;
        }
    }

    function _mint(
        address soul,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256 tokenId) {
        tokenId = Counters.current(_emittedCount);
        _mintUnsafe(soul, tokenId, value, slot, true);
        emit Minted(soul, tokenId, value);
        Counters.increment(_emittedCount);
    }

    function _mint(
        address issuer,
        address soul,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256 tokenId) {
        tokenId = Counters.current(_emittedCount);
        _mintUnsafe(issuer, soul, tokenId, value, slot, true);
        emit Minted(soul, tokenId, value);
        Counters.increment(_emittedCount);
    }

    function _mintBatch(
        address[] memory souls,
        uint256 value,
        uint256 slot
    ) internal virtual returns (uint256[] memory tokenIds) {
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
            assert(Counters.current(_soulsCount) > 0);
            Counters.decrement(_soulsCount);
        }
    }

    function _increaseEmittedCount() internal {
        Counters.increment(_emittedCount);
    }

    function _tokensOfSoul(address soul)
        internal
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = EnumerableSet.values(_indexedTokenIds[soul]);
        require(tokenIds.length != 0, "ERC5727: the soul has no token");
    }

    function emittedCount() public view virtual override returns (uint256) {
        return Counters.current(_emittedCount);
    }

    function soulsCount() public view virtual override returns (uint256) {
        return Counters.current(_soulsCount);
    }

    function balanceOf(address soul)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return EnumerableSet.length(_indexedTokenIds[soul]);
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
        return EnumerableSet.at(ids, index);
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
