// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC7507 {

    /// @notice Emitted when the expires of a user for an NFT is changed
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice Get the user expires of an NFT
    /// @param tokenId The NFT to get the user expires for
    /// @param user The user to get the expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId, address user) external view returns(uint256);

    /// @notice Set the user expires of an NFT
    /// @param tokenId The NFT to set the user expires for
    /// @param user The user to set the expires for
    /// @param expires The user could use the NFT before expires in UNIX timestamp
    function setUser(uint256 tokenId, address user, uint64 expires) external;

}
