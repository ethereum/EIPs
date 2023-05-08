// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

/// @title ERC-1155 Bindable Errors Interface
interface IERC1155BindableErrors {

    /// @notice Bind is not valid.
    error BindInvalid();

    /// @notice Bound asset or bound asset owner is not valid.
    error BinderInvalid();

}
