// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {IERC1155Errors} from "../interfaces/IERC1155Errors.sol";

/// @title Dopamine Minimal ERC-1155 Contract
/// @notice This is a minimal ERC-1155 implementation that 
contract ERC1155 is IERC1155, IERC1155Errors {

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev  EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;

    /// @notice Gets an address' number of tokens owned of a specific type.
    mapping(address => mapping(uint256 => uint256)) public _balanceOf;

    /// @notice Transfers `amount` tokens of id `id` from address `from` to 
    ///  address `to`, while ensuring `to` is capable of receiving the token.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the token to be transferred.
    /// @param to The new owner address of the token being transferred.
    /// @param id The id of the token being transferred.
    /// @param amount The number of tokens being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                amount,
                data
            ) !=
            IERC1155Receiver.onERC1155Received.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }

    /// @notice Transfers tokens `ids` in corresponding batches `amounts` from 
    ///  address `from` to address `to`, while ensuring `to` can receive tokens.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the token to be transferred.
    /// @param to The new owner address of the token being transferred.
    /// @param ids A list of the token ids being transferred.
    /// @param amounts A list of the amounts of each token id being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (ids.length != amounts.length) {
            revert ArityMismatch();
        }

        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];
            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;
            unchecked { 
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                amounts,
                data
            ) !=
            IERC1155Receiver.onERC1155BatchReceived.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }

    /// @notice Retrieves balance of address `owner` for token of id `id`.
    /// @param owner The token owner's address.
    /// @param id The id of the token being queried.
    /// @return The number of tokens address `owner` owns of type `id`.
    function balanceOf(address owner, uint256 id) public view virtual returns (uint256) {
        return _balanceOf[owner][id];
    }

    /// @notice Retrieves balances of multiple owner / token type pairs.
    /// @param owners List of token owner addresses.
    /// @param ids List of token type identifiers.
    /// @return balances List of balances corresponding to the owner / id pairs.
    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) {
            revert ArityMismatch();
        }

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = _balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// @notice Sets the operator for the sender address.
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, False otherwise.
    function supportsInterface(bytes4 id) public pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC1155_INTERFACE_ID;
    }

    /// @notice Mints token of id `id` to address `to`.
    /// @param to Address receiving the minted NFT.
    /// @param id The id of the token type being minted.
    function _mint(address to, uint256 id) internal virtual {
        unchecked {
            ++_balanceOf[to][id];
        }

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                1,
                ""
            ) !=
            IERC1155Receiver.onERC1155Received.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }

}

