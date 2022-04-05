// SPDX-License-Identifier: CC0

pragma solidity ^0.8.0;

import "./IERC888.sol";

/// @title ERC-888 EXP Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/EIP-888
///  Note: the ERC-165 identifier for this interface is ###ERC888Metadata###.
interface IERC888Metadata is IERC888 {
    /// @notice A descriptive name for the EXP in this contract.
    function name() external view returns (string memory);

    /// @notice A one-line description of the EXP in this contract.
    function description() external view returns (string memory);
}