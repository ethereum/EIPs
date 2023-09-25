// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5008 /* is IERC165 */ {
    /// @notice Emitted when the `nonce` of an NFT is changed
    event NonceChanged(uint256 tokenId, uint256 nonce);

    /// @notice Get the nonce of an NFT
    /// Throws if `tokenId` is not a valid NFT
    /// @param tokenId The id of the NFT
    /// @return The nonce of the NFT
    function nonce(uint256 tokenId) external view returns(uint256);
}
