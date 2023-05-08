// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

/// @title ERC-721 Bindable Errors Interface
interface IERC721BindableErrors {

    /// @notice Bind already exists.
    error BindExistent();

    /// @notice Bind does not exist.
    error BindNonexistent();

    /// @notice Bind is not valid.
    error BindInvalid();

    /// @notice Bound asset or bound asset owner is not valid.
    error BinderInvalid();

}
