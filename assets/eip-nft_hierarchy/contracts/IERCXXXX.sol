// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/// @notice The struct used to reference a token in an NFT contract
struct Token {
    address collection;
    uint256 id;
}

interface IERCXXXX {

    /// @notice Emitted when the parent tokens for an NFT is updated
    event UpdateParentTokens(uint256 indexed tokenId);

    /// @notice Get the parent tokens of an NFT
    /// @param tokenId The NFT to get the parent tokens for
    /// @return An array of parent tokens for this NFT
    function parentTokensOf(uint256 tokenId) external view returns (Token[] memory);

    /// @notice Check if another token is a parent of an NFT
    /// @param tokenId The NFT to check its parent for
    /// @param otherToken Another token to check as a parent or not
    /// @return Whether `otherToken` is a parent of `tokenId`
    function isParentToken(uint256 tokenId, Token memory otherToken) external view returns (bool);

}
