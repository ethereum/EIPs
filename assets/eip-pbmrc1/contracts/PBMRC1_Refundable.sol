// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
*    @title Conditional PBM
*    @dev 
*/
abstract contract  PBMRC4_RefundablePBM {

  
  /// mapping of user address to a list of token ids spent by a user to a recipient.
  mapping (uint256 => TokenConfig) internal tokenTypes; 

}


// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
*    @dev 
*/
interface PBMRC1_Refundable {

  /// @dev Returns `true` or `false` if a particular token is meant to allow a refund process.
  function isRefundable(uint256 tokenId) external view returns (bool);

  /// @notice Issues a refund to a PBM user
  /// @dev If a PBM token is refundable, merchant will be able to call this function to undo the entire payment process, and returning the PBM to the user. 
  Compliant smart contract must keep a record of the payment details in order to execute a refund.
  /// @param tokenId
  /// @param
  /// @param
  function revertPBMPayment(address user, uint256 tokenId, )


}