// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
*    @dev 
*/
interface PBMRC2_NonPreloadedPBM is PBMRC1 {
  // <!-- TBD List of events emitted, and parameters for each functions -->

  /// loads a token of value into the PBM
  function load() external; 

  function loadAndSafeTransferFrom() external; 

  /// takes out the underlying token of value
  function unload() external;
}