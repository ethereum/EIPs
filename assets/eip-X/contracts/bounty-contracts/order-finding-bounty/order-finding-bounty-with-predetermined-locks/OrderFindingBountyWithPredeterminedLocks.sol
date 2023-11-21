// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../OrderFindingBounty.sol";

contract OrderFindingBountyWithPredeterminedLocks is OrderFindingBounty {
  constructor(uint256 numberOfLocks)
    OrderFindingBounty(numberOfLocks) {}

  function setLock(uint256 lockNumber, bytes[] memory lock) public {
    LockManager.setLock(locks(), lockNumber, lock);
  }
}
