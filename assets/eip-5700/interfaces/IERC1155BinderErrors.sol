// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

/// @title ERC-1155 Binder Errors Interface
interface IERC1155BinderErrors {

    /// @notice Asset has already minted.
    error AssetAlreadyMinted();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

}
