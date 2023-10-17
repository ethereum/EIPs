// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC6150.sol";
import "./interfaces/IERC6150AccessControl.sol";

abstract contract ERC6150AccessControl is ERC6150, IERC6150AccessControl {
    mapping(address => mapping(uint256 => bool)) private _isAdminOf;

    function isAdminOf(
        uint256 tokenId,
        address account
    ) public view virtual override returns (bool) {
        return _isAdminOf[account][tokenId];
    }

    function canMintChildren(
        uint256 parentId,
        address account
    ) public view virtual override returns (bool) {
        return isAdminOf(parentId, account);
    }

    function canBurnTokenByAccount(
        uint256 tokenId,
        address account
    ) public view virtual override returns (bool) {
        require(isLeaf(tokenId), "not a leaf token");
        return isAdminOf(tokenId, account);
    }

    function _afterMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId
    ) internal virtual override {
        _isAdminOf[to][tokenId] = true;
    }

    function _addAdmin(address admin, uint256 tokenId) internal virtual {
        require(admin != address(0), "zero address");
        require(_exists(tokenId), "tokenId doesn't exist");
        _isAdminOf[admin][tokenId] = true;
    }

    function _removeAdmin(address admin, uint256 tokenId) internal virtual {
        require(_isAdminOf[admin][tokenId] == true, "not an admin");
        require(admin != ownerOf(tokenId), "cannot remove owner");
        _isAdminOf[admin][tokenId] = false;
    }
}
