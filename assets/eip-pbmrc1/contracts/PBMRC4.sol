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


