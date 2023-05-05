// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
*    @dev 
*/
interface PBMRC2_NonPreloadedPBM is PBMRC1 {

  /// @notice These 2 functions are similar to PBMRC1, except that there's no need to transfer an underlying token of value into the 
  /// pbm smart contract. The PBM will just be an empty envelope at this point in time, since it doesn't have an underlying token.
  function safeMint(address receiver, uint256 tokenId, uint256 amount, bytes calldata data) external;
  function safeMintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

  /// Given a PBM token id, wrap an amount of ERC20 tokens that is purpose bound by `tokenId` 
  /// function will pull ERC20 tokens from msg.sender 
  /// Approval must be given to the PBM smart contract in order to for the pbm to pull money from msg.sender
  /// underlying data structure must record how much the msg.sender has loaded in for the particular pbm `tokenId`
  /// in this function call, the msg.sender is the user bearing the PBM token
  /// loading conditions can be specify in this function.
  /// @dev allocates underlying token to be used exclusively by the PBM token `tokenId` type
  function load(uint256 tokenId, uint256 amount) external; 

  /// Given a PBM token id, wrap an amount of ERC20 tokens into it.
  /// function will pull ERC20 tokens from msg.sender 
  /// underlying data structure will record how much the msg.sender has loaded into the PBM to be given to a recipient
  /// @dev allocates underlying token to be used exclusively by the PBM token `tokenId` type for `recipient`
  function loadTo(uint256 tokenId, uint256 amount, address recipient) external; 
  

  /// @notice Unloads the underlying token from the PBM smart contract by extracting the specified amount of the token.
/// Emits {TokenUnload} event
/// @param tokenId Identifier of the PBM token type to be unloaded.
/// @param amount The quantity of the corresponding tokens to be unloaded.
function unload(uint256 tokenId, uint256 amount) external;


  /// TBD: consider removing address ERC20Token, uint256 ERC20TokenValue , since these variables are to be immutable?
  /// Emitted when an underlying token is loaded into a PBM
  /// @param caller Address by which ERC20token is taken from.
  /// @param to Address by which the token is loaded and assigned to
  /// @param tokenId Identifier of the PBM token types being loaded
  /// @param amount The quantity of tokens to be loaded
  /// @param ERC20Token The address of the underlying ERC-20 token.
  /// @param ERC20TokenValue The amount of underlying ERC-20 tokens loaded
  event TokenLoad(address caller, address to, uint256 tokenId, uint256 amount, address ERC20Token, uint256 ERC20TokenValue); 

  /// @notice Emitted when an underlying token is unloaded from a PBM.
  /// This event indicates the process of releasing the underlying token from the PBM smart contract.
  /// @param caller The address initiating the token unloading process.
  /// @param from The address from which the token is being unloaded and removed.
  /// @param tokenId Identifier of the PBM token types being unloaded.
  /// @param amount The quantity of the corresponding unloaded tokens.
  /// @param ERC20Token The address of the underlying ERC-20 token.
  /// @param ERC20TokenValue The amount of unloaded underlying ERC-20 tokens transferred.
  event TokenUnload(address caller, address from, uint256 tokenId, uint256 amount, address ERC20Token, uint256 ERC20TokenValue);
}


/**
  TBD: decide if the below functions should be included in the interface.
  thought process here is, it should not. adds complexity, functions should only do 1 thing, and 
  if needed the implementors can figure this out themselves.
 */
  // function loadAndUnwrap();
  // function loadAndUnwrapTo();

  // /// function will pull ERC20 tokens from msg.sender to load into the PBM
  // /// caller should have the approval to send the PBMs on behalf of the owner (`from` addresss)
  // /// loads ERC20 token from the caller to be given to the recipient specified in the `from` address bound to `tokenId`
  // /// subsequently unwraps 
  // function loadAndSafeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external; 

  // /// function will pull ERC20 tokens from msg.sender to load into the PBM
  // /// loads ERC20 token from the caller
  // function loadAndSafeTransfer(address to, uint256 tokenId, uint256 amount, bytes memory data) external; 