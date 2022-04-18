// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Non-Transferrable Non-Fungible Tokens (Soulbound Tokens or "Badges")
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x6352211e.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when transfer of any soulbound token is established by any
  /// mechanism. This event emits when SBTs are created (`from` == 0) and
  /// destroyed (`to` == 0). Exception: during contract creation, any number of
  /// SBTs may be created and assigned without emitting Transfer.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  /// @notice Find the address bound to an ERC4973 soulbound token
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an SBT
  /// @return The address of the owner bound to the SBT
  function ownerOf(uint256 _tokenId) external view returns (address);
}
