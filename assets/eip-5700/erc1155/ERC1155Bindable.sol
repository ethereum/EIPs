// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {ERC1155} from "./ERC1155.sol";
import {IERC1155Bindable} from "../interfaces/IERC1155Bindable.sol";
import {IERC1155Binder} from "../interfaces/IERC1155Binder.sol";

/// @title ERC-1155 Bindable Reference Implementation.
/// @dev Only supports the "delegated" binding mode.
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
        address to,
        uint256 tokenId,
		uint256 amount,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

		IERC1155Binder binder = IERC1155Binder(bindAddress);
		if (to != bindAddress) {
			revert BinderInvalid();
		}

        boundBalanceOf[bindAddress][bindId][tokenId] += amount;
        _balanceOf[from][tokenId] -= amount;
        _balanceOf[to][tokenId] += amount;
		
        emit Bind(msg.sender, from, bindAddress, tokenId, amount, bindId, bindAddress);
		emit TransferSingle(msg.sender, from, bindAddress, tokenId, amount);

        if (
            binder.onERC1155Bind(msg.sender, from, to, tokenId, amount, bindId, data)
            !=
            IERC1155Binder.onERC1155Bind.selector
        ) {
            revert BindInvalid();
        } 

    }

    /// @inheritdoc IERC1155Bindable
    function batchBind(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        address bindAddress,
        bytes calldata data
    ) public {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

		IERC1155Binder binder = IERC1155Binder(bindAddress);
		if (to != bindAddress) {
			revert BinderInvalid();
		}

        if (tokenIds.length != amounts.length || tokenIds.length != bindIds.length) {
            revert ArityMismatch();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {

            boundBalanceOf[bindAddress][bindIds[i]][tokenIds[i]] += amounts[i];
            _balanceOf[from][tokenIds[i]] -= amounts[i];
            _balanceOf[to][tokenIds[i]] += amounts[i];
        }
		
        emit BindBatch(msg.sender, from, bindAddress, tokenIds, amounts, bindIds, bindAddress);
		emit TransferBatch(msg.sender, from, bindAddress, tokenIds, amounts);

        if (
            binder.onERC1155BatchBind(msg.sender, from, to, tokenIds, amounts, bindIds, data)
            !=
            IERC1155Binder.onERC1155Bind.selector
        ) {
            revert BindInvalid();
        } 

    }

    /// @inheritdoc IERC1155Bindable
    function unbind(
        address from,
        address to,
        uint256 tokenId,
		uint256 amount,
		uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public {
		IERC1155Binder binder = IERC1155Binder(bindAddress);
        if (
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

		_balanceOf[to][tokenId] += amount;
		_balanceOf[from][tokenId] -= amount;
        boundBalanceOf[bindAddress][bindId][tokenId] -= amount;

        emit Bind(msg.sender, bindAddress, to, tokenId, amount, bindId, bindAddress);
		emit TransferSingle(msg.sender, bindAddress, to, tokenId, amount);

        if (
            binder.onERC1155Unbind(msg.sender, from, to, tokenId, amount, bindId, data)
            !=
            IERC1155Binder.onERC1155Unbind.selector
        ) {
            revert BindInvalid();
        } 

		if (
			to.code.length != 0 &&
				IERC1155Receiver(to).onERC1155Received(msg.sender, from, amount, tokenId, "")
                !=
                IERC1155Receiver.onERC1155Received.selector
		) {
			revert SafeTransferUnsupported();
        }

    }

    /// @inheritdoc IERC1155Bindable
    function batchUnbind(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
		uint256[] calldata bindIds,
		address bindAddress,
        bytes calldata data
    ) public {
		IERC1155Binder binder = IERC1155Binder(bindAddress);

        if (
            msg.sender != from &&
            !binder.isApprovedForAll(from, msg.sender)
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        if (tokenIds.length != amounts.length || tokenIds.length != bindIds.length) {
            revert ArityMismatch();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {

            if (binder.ownerOf(bindIds[i]) != from) { 
                revert BinderInvalid(); 
            }

            _balanceOf[to][tokenIds[i]] += amounts[i];
            _balanceOf[from][tokenIds[i]] -= amounts[i];
            boundBalanceOf[bindAddress][bindIds[i]][tokenIds[i]] -= amounts[i];
        }
		
        emit UnbindBatch(msg.sender, from, bindAddress, tokenIds, amounts, bindIds, bindAddress);
		emit TransferBatch(msg.sender, from, bindAddress, tokenIds, amounts);

        if (
            binder.onERC1155BatchUnbind(msg.sender, from, to, tokenIds, amounts, bindIds, data)
            !=
            IERC1155Binder.onERC1155BatchUnbind.selector
        ) {
            revert BindInvalid();
        } 

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
