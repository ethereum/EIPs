/*
Consumer

SPDX-License-Identifier: CC0-1.0
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./IERC721Holder.sol";

/**
 * @title Consumer
 *
 * @notice this contract implements an example "consumer" of the proposed
 * held token ERC standard.
 
 * This example consumer contract will query ERC721 ownership and balances
 * including any "held" tokens
 */
contract Consumer {
  using Address for address;

  // members
  IERC721 public token;

  /**
   * @param token_ address of ERC721 token
   */
  constructor(address token_) {
    token = IERC721(token_);
  }

  /**
   * @notice get the functional owner of a token
   * @param tokenId token id of interest
   */
  function getOwner(uint256 tokenId) external view returns (address) {
    // get raw owner
    address owner = token.ownerOf(tokenId);

    // if owner is not contract, return
    if (!owner.isContract()) {
      return owner;
    }

    try IERC165(owner).supportsInterface(0x16b900ff) returns (bool ret) {
      // contract does not support token holder interface
      if (!ret) {
        return owner;
      }
    } catch {
      return owner;
    }

    // check for held owner
    address addr = IERC721Holder(owner).heldOwnerOf(address(token), tokenId);
    if (addr == address(0)) {
      return owner;
    }

    return addr;
  }

  /**
   * @notice get the total user balance including held tokens
   * @param owner user address
   * @param holders list of token holder addresses
   */
  function getBalance(address owner, address[] calldata holders)
    external
    view
    returns (uint256)
  {
    // start with raw token balance
    uint256 balance = token.balanceOf(owner);

    // consider each provided token holder contract
    for (uint256 i = 0; i < holders.length; i++) {
      balance += IERC721Holder(holders[i]).heldBalanceOf(address(token), owner);
    }

    return balance;
  }
}
