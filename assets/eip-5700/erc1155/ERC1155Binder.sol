// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {IERC1155Bindable} from "../interfaces/IERC1155Bindable.sol";
import {IERC1155Binder} from "../interfaces/IERC1155Binder.sol";

/// @title ERC-1155 Binder Reference Implementation
contract ERC1155Binder is IERC1155Binder {

    struct Bindable {
        address tokenAddress;
        uint256 tokenId;
    }

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    /// @notice Tracks ownership of bound assets.
    mapping(uint256 => address) _ownerOf;

    /// @dev  EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_BINDER_INTERFACE_ID = 0x2ac2d2bc;
    bytes4 private constant _ERC1155_BINDABLE_INTERFACE_ID = 0xd92c3ff0;

    /// @inheritdoc IERC1155Binder
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    /// @inheritdoc IERC1155Binder
    function ownerOf(uint256 id) public view returns (address) {
        return _ownerOf[id];
    }

    /// @inheritdoc IERC1155Binder
    function onERC1155Bind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
    ) public returns (bytes4) {
        return IERC1155Binder.onERC1155Bind.selector;
    }

    /// @inheritdoc IERC1155Binder
	function onERC1155BatchBind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        bytes calldata data
	) public returns (bytes4) {
        return IERC1155Binder.onERC1155BatchBind.selector;
    }

    /// @inheritdoc IERC1155Binder
    function onERC1155Unbind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
    ) public returns (bytes4) {
        return IERC1155Binder.onERC1155Unbind.selector;
    }

    /// @inheritdoc IERC1155Binder
	function onERC1155BatchUnbind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        bytes calldata data
	) public returns (bytes4) {
        return IERC1155Binder.onERC1155BatchUnbind.selector;
    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == _ERC165_INTERFACE_ID || id == _ERC1155_BINDER_INTERFACE_ID;
    }

    /// @notice Mints a new asset identified by `id` to address `to`.
    function _mint(address to, uint256 id) internal {
        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        if (_ownerOf[id] != address(0)) {
            revert AssetAlreadyMinted();
        }

        _ownerOf[id] = to;
    }

}
