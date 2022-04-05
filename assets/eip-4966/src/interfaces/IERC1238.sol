// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IERC1238 {
  /// @dev This emits when bond of any SBT is established by any mechanism.
  ///  This event emits when SBTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of SBTs
  ///  may be created and assigned without emitting Bond.
  event Bond(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  /// @notice Find the address bound to an ERC1238 soulbound token (short "SBT")
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an SBT
  /// @return The address of the owner bound to the SBT
  function boundTo(uint256 _tokenId) external view returns (address);
}
