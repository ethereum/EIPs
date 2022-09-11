// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5633 {
  /**
   * @dev Emitted when a token type `id` is set or cancel to soulbound, according to `bounded`.
   */
  event Soulbound(uint256 indexed id, bool bounded);

  /**
   * @dev Returns true if a token type `id` is soulbound.
   */
  function isSoulbound(uint256 id) external view returns (bool);
}