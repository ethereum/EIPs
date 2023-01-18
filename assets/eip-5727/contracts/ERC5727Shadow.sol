//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC5727.sol";
import "./interfaces/IERC5727Shadow.sol";

abstract contract ERC5727Shadow is ERC5727, IERC5727Shadow {
    mapping(uint256 => bool) private _shadowed;

    modifier onlyManager(uint256 tokenId) {
        require(
            _msgSender() == _getTokenOrRevert(tokenId).owner ||
                _msgSender() == _getTokenOrRevert(tokenId).issuer,
            "ERC5727Shadow: You are not the manager"
        );
        _;
    }

    function _beforeView(uint256 tokenId) internal view virtual override {
        require(
            !_shadowed[tokenId] ||
                _msgSender() == _getTokenOrRevert(tokenId).owner ||
                _msgSender() == _getTokenOrRevert(tokenId).issuer,
            "ERC5727Shadow: the token is shadowed"
        );
    }

    function _shadow(uint256 tokenId) internal virtual {
        _getTokenOrRevert(tokenId);
        _shadowed[tokenId] = true;
    }

    function _unshadow(uint256 tokenId) internal virtual {
        _getTokenOrRevert(tokenId);
        _shadowed[tokenId] = false;
    }

    function _isShadowed(uint256 tokenId) internal view virtual returns (bool) {
        _getTokenOrRevert(tokenId);
        return _shadowed[tokenId];
    }

    function isShadowed(uint256 tokenId)
        public
        view
        virtual
        override
        onlyManager(tokenId)
        returns (bool)
    {
        _getTokenOrRevert(tokenId);
        return _shadowed[tokenId];
    }

    function shadow(uint256 tokenId)
        public
        virtual
        override
        onlyManager(tokenId)
    {
        _shadowed[tokenId] = true;
    }

    function reveal(uint256 tokenId)
        public
        virtual
        override
        onlyManager(tokenId)
    {
        _shadowed[tokenId] = false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC5727)
        returns (bool)
    {
        return
            interfaceId == type(IERC5727Shadow).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
