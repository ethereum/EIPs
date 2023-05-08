// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IERC721Errors} from "../interfaces/IERC721Errors.sol";

/// @title Reference Minimal ERC-721 Contract
contract ERC721 is IERC721, IERC721Errors {

    /// @notice The total number of NFTs in circulation.
    uint256 public totalSupply;

    /// @notice Gets the approved address for an NFT.
    /// @dev This implementation does not throw for zero-address queries.
    mapping(uint256 => address) public getApproved;

    /// @notice Gets the number of NFTs owned by an address.
    mapping(address => uint256) internal _balanceOf;

    /// @dev Tracks the assigned owner of an address.
    mapping(uint256 => address) internal _ownerOf;

    /// @dev Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @dev  EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @notice Gets the assigned owner for token `id`.
    /// @param id The id of the NFT being queried.
    /// @return The address of the owner of the NFT of id `id`.
    function ownerOf(uint256 id) external view virtual returns (address) {
        return _ownerOf[id];
    }

    /// @notice Gets number of NFTs owned by address `owner`.
    /// @param owner The address whose balance is being queried.
    /// @return The number of NFTs owned by address `owner`.
    function balanceOf(address owner) external view virtual returns (uint256) {
        return _balanceOf[owner];
    }

    /// @notice Sets approved address of NFT of id `id` to address `approved`.
    /// @param approved The new approved address for the NFT.
    /// @param id The id of the NFT to approve.
    function approve(address approved, uint256 id) external virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert SenderUnauthorized();
        }

        getApproved[id] = approved;
        emit Approval(owner, approved, id);
    }

    /// @notice Checks if `operator` is an authorized operator for `owner`.
    /// @param owner The address of the owner.
    /// @param operator The address of the owner's operator.
    /// @return True if `operator` is approved operator of `owner`, else False.
    function isApprovedForAll(address owner, address operator)
        external
        view
        virtual returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator The operator address that will manage the sender's NFTs.
    /// @param approved Whether operator is allowed to operate sender's NFTs.
    function setApprovalForAll(address operator, bool approved) external virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, false otherwise.
    function supportsInterface(bytes4 id) public pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC721_INTERFACE_ID;
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param id The id of the NFT being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param id The id of the NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  Transfers clear owner approvals, but `Approval` events are omitted.
    /// @param from The existing owner address of the NFT being transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param id The id of the NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (from != _ownerOf[id]) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorApprovals[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        _beforeTokenTransfer(from, to, id);

        delete getApproved[id];

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        emit Transfer(from, to, id);
    }

    /// @dev Mints NFT of id `id` to address `to`. To save gas, it is assumed
    ///  that `maxSupply` < `type(uint256).max` (ex. for tabs, cap is very low).
    /// @param to Address receiving the minted NFT.
    /// @param id Identifier of the NFT being minted.
    /// @return The id of the minted NFT.
    function _mint(address to, uint256 id) internal virtual returns (uint256) {
        if (to == address(0)) {
            revert ReceiverInvalid();
        }
        if (_ownerOf[id] != address(0)) {
            revert TokenAlreadyMinted();
        }

        _beforeTokenTransfer(address(0), to, id);

        unchecked {
            totalSupply++;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
        return id;
    }

    /// @dev Burns NFT of id `id`, removing it from existence.
    /// @param id Identifier of the NFT being burned
    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) {
            revert TokenNonExistent();
        }

        _beforeTokenTransfer(owner, address(0), id);

        unchecked {
            totalSupply--;
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];
        emit Transfer(owner, address(0), id);
    }

    /// @notice Pre-transfer hook for embedding additional transfer behavior.
    /// @param from The address of the existing owner of the NFT.
    /// @param to The address of the new owner of the NFT.
    /// @param id The id of the NFT being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 id)
        internal
        virtual
        {}

}
