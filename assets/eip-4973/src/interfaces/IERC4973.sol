// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Non-Transferrable Non-Fungible Account-bound Tokens (formerly Soulbound Tokens or "Badges")
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x6352211e.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when transfer of any account-bound token is established by any
  /// mechanism. This event emits when ACTs are created (`from` == 0) and
  /// destroyed (`to` == 0). Exception: during contract creation, any number of
  /// ACTs may be created and assigned without emitting Transfer.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ACTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an ACT
  /// @return The address of the owner bound to the ACT
  function ownerOf(uint256 _tokenId) external view returns (address);
}
