// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Pull is IERC4671 {
    /// @notice Pull a token from the owner wallet to the caller's wallet
    /// @param tokenId Identifier of the token to transfer
    /// @param owner Address that owns tokenId
    /// @param signature Signed data (tokenId, owner, recipient) by the owner of the token
    function pull(uint256 tokenId, address owner, bytes memory signature) external;
}
