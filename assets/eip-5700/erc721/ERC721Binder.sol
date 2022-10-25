// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {ERC721} from "./ERC721.sol";
import {IERC721Bindable} from "../interfaces/IERC721Bindable.sol";
import {IERC721Binder} from "../interfaces/IERC721Binder.sol";

/// @title ERC-721 Binder Reference Implementation
contract ERC721Binder is IERC721Binder {

    struct Bindable {
        address tokenAddress;
        uint256 tokenId;
    }

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    /// @notice Tracks ownership of bound assets.
    mapping(uint256 => address) _ownerOf;

    /// @notice Maps an asset to a list of all bound bindables.
    mapping(uint256 => Bindable[]) _boundTokens;

    /// @notice Maps a token address and identifier to the bound tokens index.
    mapping(address => mapping(uint256 => uint256)) _boundIndexes;

    /// @dev  EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_BINDER_INTERFACE_ID = 0x2ac2d2bc;
    bytes4 private constant _ERC721_BINDABLE_INTERFACE_ID = 0xd92c3ff0;

    /// @inheritdoc IERC721Binder
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    /// @inheritdoc IERC721Binder
    function ownerOf(uint256 id) public view returns (address) {
        return _ownerOf[id];
    }

    /// @inheritdoc IERC721Binder
    function onERC721Bind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        bytes calldata data
    ) public returns (bytes4) {
        if (_ownerOf[bindId] != to) {
            revert OwnerInvalid();
        }

        if (_boundIndexes[msg.sender][tokenId] != 0) {
            revert BindExistent();
        }

        if (!IERC721Bindable(msg.sender).supportsInterface(_ERC721_BINDABLE_INTERFACE_ID)) {
            revert BindInvalid();
        }

        _boundIndexes[msg.sender][tokenId] = _boundTokens[bindId].length;
        _boundTokens[bindId].push(Bindable(msg.sender, tokenId));

        return IERC721Binder.onERC721Bind.selector;
    }

    /// @inheritdoc IERC721Binder
    function onERC721Unbind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        bytes calldata data
    ) public returns (bytes4) {
        if (_ownerOf[bindId] != from) {
            revert OwnerInvalid();
        }

        if (_boundIndexes[msg.sender][tokenId] == 0) {
            revert BindNonexistent();
        }

        uint256 boundLastIndex = _boundTokens[bindId].length - 1;
        uint256 boundIndex = _boundIndexes[msg.sender][tokenId];

        if (boundIndex != boundLastIndex) {
            Bindable memory bindable = _boundTokens[bindId][boundLastIndex];
            _boundTokens[bindId][boundIndex] = bindable;
            _boundIndexes[bindable.tokenAddress][bindable.tokenId] = boundIndex;
        }

        delete _boundIndexes[msg.sender][tokenId];
        delete _boundTokens[bindId][boundLastIndex];

        return IERC721Binder.onERC721Unbind.selector;
    }

    /// @notice Transfers an asset from address `from` to address `to`.
    function transfer(
        address from,
        address to,
        uint256 bindId
    ) public {
        if (msg.sender != from && !_isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        if (from != _ownerOf[bindId]) {
            revert OwnerInvalid();
        }
 
        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        _ownerOf[bindId] = to;

        Bindable[] memory bindables = _boundTokens[bindId];
        for (uint256 i = 0; i < bindables.length; ++i) {
            IERC721Bindable(bindables[i].tokenAddress).transferFrom(from, to, bindables[i].tokenId);
        }

    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == _ERC165_INTERFACE_ID || id == _ERC721_BINDER_INTERFACE_ID;
    }

}
