// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

/// @title ERC-721 Binder Errors Interface
interface IERC721BinderErrors {

    /// @notice Asset binding already exists.
    error BindExistent();

    /// @notice Asset binding is not valid.
    error BindInvalid();

    /// @notice Asset binding does not exist.
    error BindNonexistent();

    /// @notice Originating address does not own the asset.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error SenderUnauthorized();

}
