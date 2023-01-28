// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

/// @title ERC-1155 Errors Interface
interface IERC1155Errors {

    /// @notice Arity mismatch between two arrays.
    error ArityMismatch();

    /// @notice Originating address does not own the NFT.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-1155 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error SenderUnauthorized();

    /// @notice Token has already minted.
    error TokenAlreadyMinted();

    /// @notice NFT does not exist.
    error TokenNonExistent();

}
