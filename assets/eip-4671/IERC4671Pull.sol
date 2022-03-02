// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Pull is IERC4671 {
    // Event emitted when a IERC4671 token is transfered from owner to recipient
    event Pulled(address owner, address recipient);

    /// @notice Pull a token from the owner wallet to the caller's wallet
    /// @param tokenId Identifier of the token to transfer
    /// @param owner Address that owns tokenId
    /// @param signature Signed data (tokenId, owner, recipient) by the owner of the token
    function pull(uint256 tokenId, address owner, bytes memory signature) external;
}
