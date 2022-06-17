// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x6352211e.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when a new token is created and bound to an account by
  /// any mechanism.
  /// Note: For a reliable `_from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Attest(address indexed _to, uint256 indexed _tokenId);
  /// @dev This emits when an existing ABT is revoked from an account and
  /// destroyed by any mechanism.
  /// Note: For a reliable `_from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Revoke(address indexed _to, uint256 indexed _tokenId);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 _tokenId) external view returns (address);
  /// @notice Destroys `tokenId`. At any time, an ABT receiver must be able to
  ///  disassociate themselves from an ABT publicly through calling this
  ///  function.
  /// @dev Must emit a `event Revoke` with the `address _to` field pointing to
  ///  the zero address.
  /// @param _tokenId The identifier for an ABT
  function burn(uint256 _tokenId) external;
}
