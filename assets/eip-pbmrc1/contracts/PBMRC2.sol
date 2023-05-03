// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
*    @dev 
*/
interface PBMRC2_NonPreloadedPBM is PBMRC1 {
  // <!-- TBD List of events emitted, and parameters for each functions -->

  /// Given a PBM token id, wrap an amount of ERC20 tokens into it.
  /// function will pull ERC20 tokens from msg.sender 
  /// Approval must be given to the PBM smart contract in order to for the pbm to pull money from msg.sender
  /// underlying data structure will record how much the msg.sender has loaded into the PBM
  /// the msg.sender is the user bearing the PBM token
  function load(uint256 tokenId, uint256 amount) external; 

  /// Given a PBM token id, wrap an amount of ERC20 tokens into it.
  /// function will pull ERC20 tokens from msg.sender 
  /// underlying data structure will record how much the msg.sender has loaded into the PBM to be given to a recipient
  function loadTo(uint256 tokenId, uint256 amount, address recipient) external; 

  /// function will pull ERC20 tokens from msg.sender to load into the PBM
  /// caller should have the approval to send the PBMs on behalf of the owner (`from` addresss)
  /// loads ERC20 token from the caller to the recipient specified in the `from` address
  function loadAndSafeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external; 

  /// function will pull ERC20 tokens from msg.sender to load into the PBM
  /// loads ERC20 token from the caller
  function loadAndSafeTransfer(address to, uint256 tokenId, uint256 amount, bytes memory data) external; 

  /// takes out the underlying token of value
  function unload() external;
}