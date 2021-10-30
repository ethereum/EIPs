// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC-721 Consumer Role extension
///  Note: the ERC-165 identifier for this interface is 0x953c8dfa
interface IERC721Consumer is IERC721 {

    /// @notice This emits when consumer of a token changes.
    /// address(0) used as previousConsumer indicates that there was no consumer set prior to this event
    /// address(0) used as a newConsumer indicates that the consumer role is absent
    event ConsumerChanged(address indexed previousConsumer, address indexed newConsumer);

    /// @notice Get the consumer of a token
    /// @dev address(0) consumer address indicates that there is no consumer currently set for that token
    /// @param _tokenId The identifier for a token
    /// @return The address of the consumer of the token
    function consumerOf(uint256 _tokenId) view external returns (address);

    /// @notice Set the address of the new consumer for the given token
    /// @dev Throws unless `msg.sender` is the current owner, an authorised operator or the approved address for this token. Throws if `_tokenId` is not valid token
    /// @dev Set _newConsumer to address(0) to renounce the consumer role.
    /// @param _newConsumer The address of the new consumer for the token.
    function changeConsumer(address _newConsumer, uint256 _tokenId) external;
}
