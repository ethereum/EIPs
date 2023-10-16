// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {ERC1155} from "./ERC1155.sol";
import {IERC1155Bindable} from "../interfaces/IERC1155Bindable.sol";

/// @title ERC-1155 Bindable Reference Implementation.
contract ERC1155Bindable is ERC1155, IERC1155Bindable {

    /// @notice Tracks the bound balance of an asset for a specific token type.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public boundBalanceOf;

    /// @dev  EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_BINDER_INTERFACE_ID = 0x2ac2d2bc;
    bytes4 private constant _ERC1155_BINDABLE_INTERFACE_ID = 0xd92c3ff0;

    /// @inheritdoc IERC1155Bindable
    function boundBalanceOfBatch(
        address bindAddress,
        uint256[] calldata bindIds,
        uint256[] calldata tokenIds
    ) public view returns (uint256[] memory balances) {
        if (bindIds.length != tokenIds.length) {
            revert ArityMismatch();
        }

        balances = new uint256[](bindIds.length);

        unchecked {
            for (uint256 i = 0; i < bindIds.length; ++i) {
                balances[i] = boundBalanceOf[bindAddress][bindIds[i]][tokenIds[i]];
            }
        }
    }

    /// @inheritdoc IERC1155Bindable
    function bind(
        address from,
        address bindAddress,
        uint256 bindId,
        uint256 tokenId,
        uint256 amount
    ) public {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        if (IERC721(bindAddress).ownerOf(bindId) == address(0)) {
            revert BindInvalid();
        }

        boundBalanceOf[bindAddress][bindId][tokenId] += amount;
        _balanceOf[from][tokenId] -= amount;
        _balanceOf[bindAddress][tokenId] += amount;

		emit TransferSingle(msg.sender, from, bindAddress, tokenId, amount);
        emit Bind(msg.sender, from, bindAddress, bindId, tokenId, amount);

    }

    /// @notice Binds `amounts` tokens of `tokenIds` to NFT `bindId` at address `bindAddress`.
    /// @param from The owner address of the unbound tokens.
    /// @param bindAddress The contract address of the NFTs being bound to.
    /// @param bindId The identifiers of the NFT being bound to.
    /// @param tokenIds The identifiers of the binding token types.
    /// @param amounts The number of tokens per type binding to the NFTs.
    function batchBind(
        address from,
        address bindAddress,
        uint256 bindId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        if (IERC721(bindAddress).ownerOf(bindId) == address(0)) {
            revert BindInvalid();
        }

        if (tokenIds.length != amounts.length) {
            revert ArityMismatch();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _balanceOf[from][tokenIds[i]] -= amounts[i];
            _balanceOf[bindAddress][tokenIds[i]] += amounts[i];
            boundBalanceOf[bindAddress][bindId][tokenIds[i]] += amounts[i];
        }

		emit TransferBatch(msg.sender, from, bindAddress, tokenIds, amounts);
        emit BindBatch(msg.sender, from, bindAddress, bindId, tokenIds, amounts);

    }

    /// @notice Unbinds `amount` tokens of `tokenId` from NFT `bindId` at address `bindAddress`.
    /// @param from The owner address of the NFT the tokens are bound to.
    /// @param to The address of the unbound tokens' new owner.
    /// @param bindAddress The contract address of the NFT being unbound from.
    /// @param bindId The identifier of the NFT being unbound from.
    /// @param tokenId The identifier of the unbinding token type.
    /// @param amount The number of tokens unbinding from the NFT.
    function unbind(
        address from,
        address to,
        address bindAddress,
        uint256 bindId,
        uint256 tokenId,
        uint256 amount
    ) public {
        IERC721 binder = IERC721(bindAddress);

        if (binder.ownerOf(bindId) != from) {
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

		_balanceOf[to][tokenId] += amount;
		_balanceOf[bindAddress][tokenId] -= amount;
        boundBalanceOf[bindAddress][bindId][tokenId] -= amount;

        emit Unbind(msg.sender, bindAddress, to, bindAddress, bindId, tokenId, amount);
		emit TransferSingle(msg.sender, bindAddress, to, tokenId, amount);

		if (
			to.code.length != 0 &&
				IERC1155Receiver(to).onERC1155Received(msg.sender, from, amount, tokenId, "")
                !=
                IERC1155Receiver.onERC1155Received.selector
		) {
			revert SafeTransferUnsupported();
        }
    }

    /// @notice Unbinds `amount` tokens of `tokenId` from NFT `bindId` at address `bindAddress`.
    /// @param from The owner address of the unbound tokens.
    /// @param to The address of the unbound tokens' new owner.
    /// @param bindAddress The contract address of the NFTs being unbound from.
    /// @param bindId The identifiers of the NFT being unbound from.
    /// @param tokenIds The identifiers of the unbinding token types.
    /// @param amounts The number of tokens per type unbinding from the NFTs.
    function batchUnbind(
        address from,
        address to,
        address bindAddress,
        uint256 bindId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public {
        IERC721 binder = IERC721(bindAddress);

        if (binder.ownerOf(bindId) != from) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != binder.getApproved(bindId) &&
            !binder.isApprovedForAll(from, msg.sender)
        ) {
            revert SenderUnauthorized();
        }

        if (tokenIds.length != amounts.length) {
            revert ArityMismatch();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {

            _balanceOf[to][tokenIds[i]] += amounts[i];
            _balanceOf[bindAddress][tokenIds[i]] -= amounts[i];
            boundBalanceOf[bindAddress][bindId][tokenIds[i]] -= amounts[i];
        }

        emit UnbindBatch(msg.sender, from, to, bindAddress, bindId, tokenIds, amounts);
		emit TransferBatch(msg.sender, from, bindAddress, tokenIds, amounts);

		if (
			to.code.length != 0 &&
				IERC1155Receiver(to).onERC1155BatchReceived(msg.sender, from, tokenIds, amounts, "")
                !=
                IERC1155Receiver.onERC1155BatchReceived.selector
		) {
			revert SafeTransferUnsupported();
        }
    }

    function supportsInterface(bytes4 id) public pure override(ERC1155, IERC165) returns (bool) {
        return super.supportsInterface(id) || id == _ERC1155_BINDABLE_INTERFACE_ID;
    }

}
