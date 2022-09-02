// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC-721 Consumer Role extension
///  Note: the ERC-165 identifier for this interface is 0x953c8dfa
interface IERC721Consumable is IERC721 {

    /// @notice Emitted when `owner` changes the `consumer` of an NFT
    /// The zero address for consumer indicates that there is no consumer address
    /// When a Transfer event emits, this also indicates that the consumer address
    /// for that NFT (if any) is set to none
    event ConsumerChanged(address indexed owner, address indexed consumer, uint256 indexed tokenId);

    /// @notice Get the consumer address of an NFT
    /// @dev The zero address indicates that there is no consumer
    /// Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to get the consumer address for
    /// @return The consumer address for this NFT, or the zero address if there is none
    function consumerOf(uint256 _tokenId) view external returns (address);

    /// @notice Change or reaffirm the consumer address for an NFT
    /// @dev The zero address indicates there is no consumer address
    /// Throws unless `msg.sender` is the current NFT owner, an authorised
    /// operator of the current owner or approved address
    /// Throws if `_tokenId` is not valid NFT
    /// @param _consumer The new consumer of the NFT
    function changeConsumer(address _consumer, uint256 _tokenId) external;
}
