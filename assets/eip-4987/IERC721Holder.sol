/*
IERC721Holder

SPDX-License-Identifier: CC0-1.0
*/

import "@openzeppelin/contracts/interfaces/IERC165.sol";

pragma solidity ^0.8.0;

/**
 * @notice the ERC721 holder standard provides a common interface to query
 * token ownership and balance information
 */
interface IERC721Holder is IERC165 {
  /**
   * @notice emitted when the token is transferred to the contract
   * @param owner functional token owner
   * @param tokenAddress held token address
   * @param tokenId held token ID
   */
  event Hold(
    address indexed owner,
    address indexed tokenAddress,
    uint256 indexed tokenId
  );

  /**
   * @notice emitted when the token is released back to the user
   * @param owner functional token owner
   * @param tokenAddress held token address
   * @param tokenId held token ID
   */
  event Release(
    address indexed owner,
    address indexed tokenAddress,
    uint256 indexed tokenId
  );

  /**
   * @notice get the functional owner of a held token
   * @param tokenAddress held token address
   * @param tokenId held token ID
   * @return functional token owner
   */
  function heldOwnerOf(address tokenAddress, uint256 tokenId)
    external
    view
    returns (address);

  /**
   * @notice get the held balance of the token owner
   * @param tokenAddress held token address
   * @param owner functional token owner
   * @return held token balance
   */
  function heldBalanceOf(address tokenAddress, address owner)
    external
    view
    returns (uint256);
}
