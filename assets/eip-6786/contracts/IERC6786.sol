// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC6786 {

    /// @dev Logged when royalties were paid for a NFT
    /// @notice Emitted when royalties are paid for the NFT with address tokenAddress and id tokenId
    event RoyaltiesPaid(address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);

    /// @notice sends msg.value to the creator for a NFT
    /// @dev Throws if there is no on-chain information about the creator
    /// @param tokenAddress The address of NFT contract
    /// @param tokenId The NFT id
    function payRoyalties(address tokenAddress, uint256 tokenId) external payable;

    /// @notice Get the amount of royalties which was paid for
    /// @param tokenAddress The address of NFT contract
    /// @param tokenId The NFT id
    /// @return The amount of royalties paid for the NFT in paymentToken
    function getPaidRoyalties(address tokenAddress, uint256 tokenId) external view returns (uint256);
}
