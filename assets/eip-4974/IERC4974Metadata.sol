// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./IERC4974.sol";

/// @title ERC-4974 EXP Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/EIP-4974
///  Note: the ERC-165 identifier for this interface is 0x74793a15.
interface IERC4974Metadata is IERC4974 {
    /// @notice A descriptive name for the EXP in this contract.
    function name() external view returns (string memory);

    /// @notice A one-line description of the EXP in this contract.
    function description() external view returns (string memory);
}