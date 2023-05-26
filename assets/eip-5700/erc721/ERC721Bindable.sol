// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {ERC721} from "./ERC721.sol";
import {IERC721Bindable} from "../interfaces/IERC721Bindable.sol";

/// @title ERC-721 Bindable Reference Implementation.
contract ERC721Bindable is ERC721, IERC721Bindable {

    /// @notice Encapsulates a bound NFT contract address and identifier.
    struct Binder {
        address bindAddress;
        uint256 bindId;
    }

    /// @notice Tracks the token balance for a token-bound NFT.
    mapping(address => mapping(uint256 => uint256)) public boundBalanceOf; 

    /// @notice Tracks NFTs that bindable tokens are bound to.
    mapping(uint256 => Binder) internal _bound;

    /// @dev EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_BINDER_INTERFACE_ID = 0x2ac2d2bc;
    bytes4 private constant _ERC721_BINDABLE_INTERFACE_ID = 0xd92c3ff0;

    /// @notice Gets the NFT address and identifier token `tokenId` is bound to.
    /// @param tokenId The identifier of the token being queried.
    /// @return The token-bound NFT contract address and numerical identifier.
    function binderOf(uint256 tokenId) public view returns (address, uint256) {
        Binder memory bound = _bound[tokenId];
        return (bound.bindAddress, bound.bindId);
    }

    /// @notice Binds token `tokenId` to NFT `bindId` at address `bindAddress`.
    /// @param from The address of the unbound token owner.
    /// @param bindAddress The contract address of the NFT being bound to.
    /// @param bindId The identifier of the NFT being bound to.
    /// @param tokenId The identifier of the binding token.
    function bind(
        address from,
        address bindAddress,
        uint256 bindId,
        uint256 tokenId
    ) public {
        if (
            _bound[tokenId].bindAddress != address(0) ||
            IERC721(bindAddress).ownerOf(bindId) == address(0)
        ) {
            revert BindInvalid();
        }

        if (from != _ownerOf[tokenId]) {
            revert OwnerInvalid();
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
            boundBalanceOf[bindAddress][bindId]++;
        }

        _ownerOf[tokenId] = bindAddress;
        _bound[tokenId] = Binder(bindAddress, bindId);

        emit Transfer(from, bindAddress, tokenId);
        emit Bind(msg.sender, from,  bindAddress, bindId, tokenId);

    }

    /// @notice Unbinds token `tokenId` from NFT `bindId` at address `bindAddress`.
    /// @param from The address of the owner of the NFT the token is bound to.
    /// @param to The address of the unbound token new owner.
    /// @param bindAddress The contract address of the NFT being unbound from.
    /// @param bindId The identifier of the NFT being unbound from.
    /// @param tokenId The identifier of the unbinding token.
    function unbind(
        address from,
        address to,
        address bindAddress,
        uint256 bindId,
        uint256 tokenId
    ) public {
        Binder memory bound = _bound[tokenId];
        if (
            bound.bindAddress != bindAddress ||
            bound.bindId != bindId ||
            _ownerOf[tokenId] != bindAddress
        ) {
            revert BindInvalid();
        }

        IERC721 binder = IERC721(bindAddress);

        if (from != binder.ownerOf(bindId)) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != binder.getApproved(tokenId) &&
            !binder.isApprovedForAll(from, msg.sender)
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        delete getApproved[tokenId];

        unchecked {
            _balanceOf[to]++;
            _balanceOf[bindAddress]--;
            boundBalanceOf[bindAddress][bindId]--;
        }

        _ownerOf[tokenId] = to;
        delete _bound[tokenId];

        emit Unbind(msg.sender, from, to, bindAddress, bindId, tokenId);
        emit Transfer(bindAddress, to, tokenId);

		if (
			to.code.length != 0 &&
				IERC721Receiver(to).onERC721Received(msg.sender, bindAddress, tokenId, "")
                !=
                IERC721Receiver.onERC721Received.selector
		) {
			revert SafeTransferUnsupported();
        }

    }

    function supportsInterface(bytes4 id) public pure override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(id) || id == _ERC721_BINDABLE_INTERFACE_ID;
    }

}
