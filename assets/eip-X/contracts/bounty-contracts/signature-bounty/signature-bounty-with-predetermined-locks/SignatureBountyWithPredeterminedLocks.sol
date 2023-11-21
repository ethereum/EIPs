// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../SignatureBounty.sol";

contract SignatureBountyWithPredeterminedLocks is SignatureBounty {
  using ECDSA for bytes32;

  constructor(bytes[][] memory publicKeys, bytes32 messageArg)
    SignatureBounty(publicKeys.length)
  {
    message = messageArg;
    for (uint256 lockNumber = 0; lockNumber < publicKeys.length; lockNumber++) {
      LockManager.setLock(locks(), lockNumber, publicKeys[lockNumber]);
    }
  }
}
