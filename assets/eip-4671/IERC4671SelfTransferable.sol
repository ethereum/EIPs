// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671SelfTransferable is IERC4671 {
    /// @notice Transfer a token to another wallet owned by the current token owner
    /// @param tokenId Identifier of the token to transfer
    /// @param recipient Address of the wallet owned by the current token owner
    /// @param signature Signed data (tokenId, recipient) by the current owner of the token
    function transfer(uint256 tokenId, address recipient, bytes memory signature) external;
}
