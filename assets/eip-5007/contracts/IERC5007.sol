// SPDX-License-Identifier: CC0

pragma solidity ^0.8.0;

interface IERC5007 /* is IERC721 */ {
    /// @notice Get the start time of the NFT
    /// @dev Throws if `tokenId` is not valid NFT
    /// @param tokenId  The tokenId of the NFT
    /// @return The start time of the NFT
    function startTime(uint256 tokenId) external view returns (uint64);
    
    /// @notice Get the end time of the NFT
    /// @dev Throws if `tokenId` is not valid NFT
    /// @param tokenId  The tokenId of the NFT
    /// @return The end time of the NFT
    function endTime(uint256 tokenId) external view returns (uint64);
}
