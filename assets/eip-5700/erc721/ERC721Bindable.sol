// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {ERC721} from "./ERC721.sol";
import {IERC721Bindable} from "../interfaces/IERC721Bindable.sol";
import {IERC721Binder} from "../interfaces/IERC721Binder.sol";

/// @title ERC-721 Bindable Reference Implementation.
/// @dev Supports both "legacy" and "delegated" binding modes.
contract ERC721Bindable is ERC721, IERC721Bindable {

    /// @notice Encapsulates a bound asset contract address and identifier.
    struct Binder {
        address bindAddress;
        uint256 bindId;
    }

    /// @notice Tracks the bound balance of a specific asset.
    mapping(address => mapping(uint256 => uint256)) public boundBalanceOf; 

    /// @notice Tracks bound assets of an NFT.
    mapping(uint256 => Binder) internal _bound;

    /// @dev EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_BINDER_INTERFACE_ID = 0x2ac2d2bc;
    bytes4 private constant _ERC721_BINDABLE_INTERFACE_ID = 0xd92c3ff0;

    /// @inheritdoc IERC721Bindable
    function binderOf(uint256 tokenId) public returns (address, uint256) {
        Binder memory bound = _bound[tokenId];
        return (bound.bindAddress, bound.bindId);
    }

    /// @inheritdoc IERC721Bindable
    function bind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public {
        if (_bound[tokenId].bindAddress != address(0)) {
            revert BindExistent();
        }

        if (from != _ownerOf[tokenId]) {
            revert OwnerInvalid();
        }

		IERC721Binder binder = IERC721Binder(bindAddress);
        address assetOwner = binder.ownerOf(bindId);
		if (to != assetOwner && to != bindAddress) {
			revert BinderInvalid();
		}

        if (
            msg.sender != from &&
            msg.sender != getApproved[tokenId] &&
            !_operatorApprovals[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        delete getApproved[tokenId];

        unchecked {
            _balanceOf[from]--;
            _balanceOf[bindAddress]++;
            _balanceOf[assetOwner]++;
            boundBalanceOf[bindAddress][bindId]++;
        }

        _ownerOf[tokenId] = to;
        _bound[tokenId] = Binder(bindAddress, bindId);

        emit Bind(msg.sender, from, to, tokenId, bindId, bindAddress);
        emit Transfer(from, to, tokenId);

        if (
            binder.onERC721Bind(msg.sender, from, to, tokenId, bindId, "")
            !=
            IERC721Binder.onERC721Bind.selector
        ) {
            revert BindInvalid();
        } 

    }

    /// @inheritdoc IERC721Bindable
    function unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public {
        Binder memory bound = _bound[tokenId];
        if (bound.bindAddress != address(0)) {
            revert BindNonexistent();
        }

		IERC721Binder binder = IERC721Binder(bindAddress);
        if (
			bound.bindAddress != bindAddress || 
		    bound.bindId != bindId ||
			binder.ownerOf(bindId) != from
		) {
            revert BinderInvalid();
        }

        if (
            msg.sender != from &&
            !binder.isApprovedForAll(from, msg.sender)
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        address delegatedOwner = _ownerOf[tokenId];

        delete getApproved[tokenId];

        unchecked {
            _balanceOf[to]++;
            _balanceOf[from]--;
            _balanceOf[bindAddress]--;
            boundBalanceOf[bindAddress][bindId]--;
        }

        _ownerOf[tokenId] = to;
        delete _bound[tokenId];

        emit Bind(msg.sender, from, to, tokenId, bindId, bindAddress);
        emit Transfer(delegatedOwner, to, tokenId);

        if (
            binder.onERC721Unbind(msg.sender, from, to, tokenId, bindId, "")
            !=
            IERC721Binder.onERC721Unbind.selector
        ) {
            revert BindInvalid();
        } 

		if (
			to.code.length != 0 &&
				IERC721Receiver(to).onERC721Received(msg.sender, delegatedOwner, tokenId, "")
                !=
                IERC721Receiver.onERC721Received.selector
		) {
			revert SafeTransferUnsupported();
        }

    }

    /// @inheritdoc IERC721
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) {

        address bindAddress = _bound[tokenId].bindAddress;
        uint256 bindId = _bound[tokenId].bindId;

        if (bindAddress == address(0)) {
            return super.transferFrom(from, to, tokenId);
        } 

        if (msg.sender != bindAddress) {
            revert BindExistent();
        }

		IERC721Binder binder = IERC721Binder(bindAddress);

        if (
			binder.ownerOf(bindId) != from
		) {
            revert BinderInvalid();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        delete getApproved[tokenId];

        uint256 bindBal = boundBalanceOf[bindAddress][bindId];
        unchecked {
            _balanceOf[from] -= bindBal;
            _balanceOf[to] += bindBal;
        }

        emit Transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 id) public pure override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(id) || id == _ERC721_BINDABLE_INTERFACE_ID;
    }

}
