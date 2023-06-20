// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// TBD: add param docs for load, loadto. Check all params documented.

/**
 *  @dev This interface extends IPBMRC1, adding functions for working with non-preloaded PBMs.
 *  Non-preloaded PBMs are minted as empty containers without any underlying tokens of value,
 *  allowing the loading of the underlying token to happen at a later stage.
 */
interface PBMRC2_NonPreloadedPBM is IPBMRC1 {

  /// @notice This function extends IPBMRC1 to mint PBM tokens as empty containers without underlying tokens of value.
  /// @dev The loading of the underlying token of value can be done by calling the `load` function. The function parameters should be identical to IPBMRC1
  function safeMint(address receiver, uint256 tokenId, uint256 amount, bytes calldata data) external;

  /// @notice This function extends IPBMRC1 to mint PBM tokens as empty containers without underlying tokens of value.
  /// @dev The loading of the underlying token of value can be done by calling the `load` function. The function parameters should be identical to IPBMRC1
  function safeMintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

  /// @notice Wrap an amount of sovTokens into the PBM
  /// @dev function will pull sovTokens from msg.sender 
  /// Approval must be given to the PBM smart contract in order to for the pbm to pull money from msg.sender
  /// underlying data structure must record how much the msg.sender has been loaded into the PBM.  
  /// Emits {TokenLoad} event.
  /// @param amount    The amount of sovTokens to be loaded
  function load(uint256 amount) external; 
  
  /// @notice Retrieves the balance of the underlying sovToken associated with a specific PBM token type and user address.
  /// This function provides a way to check the amount of the underlying token that a user has loaded into a particular PBM token.
  /// @param user The address of the user whose underlying token balance is being queried.
  /// @return The balance of the underlying sovToken associated with the specified PBM token type and user address.
  function underlyingBalanceOf(address user) external view returns (uint256);

  /// @notice Unloads all of the underlying token belonging to the caller from the PBM smart contract.
  /// @dev The underlying token that belongs to the caller (msg.sender) will be removed and transferred
  /// back to the caller.
  /// Emits {TokenUnload} event.
  /// @param amount The quantity of the corresponding tokens to be unloaded. 
  /// Amount should not exceed the amount that the caller has originally loaded into the PBM smart contract.
  function unload(uint256 amount) external;

  /// @notice Emitted when an underlying token is loaded into a PBM
  /// @param caller Address by which sovToken is taken from.
  /// @param to Address by which the token is loaded and assigned to
  /// @param amount The quantity of tokens to be loaded
  /// @param sovToken The address of the underlying sovToken.
  /// @param sovTokenValue The amount of underlying sovTokens loaded
  event TokenLoad(address caller, address to, uint256 amount, address sovToken, uint256 sovTokenValue); 

  /// @notice Emitted when an underlying token is unloaded from a PBM.
  /// This event indicates the process of releasing the underlying token from the PBM smart contract.
  /// @param caller The address initiating the token unloading process.
  /// @param from The address from which the token is being unloaded and removed from.
  /// @param amount The quantity of the corresponding unloaded tokens.
  /// @param sovToken The address of the underlying sovToken.
  /// @param sovTokenValue The amount of unloaded underlying sovTokens transferred.
  event TokenUnload(address caller, address from, uint256 amount, address sovToken, uint256 sovTokenValue);
}