// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../AccumulatorUtils.sol";
import "../LockManager.sol";


struct Accumulator {
  Locks locks;
  bool generationIsDone;

  bytes _currentLock;
  uint256 _currentLockNumber;
  uint256 _bytesPerLock;
}


library RandomBytesAccumulator {

  function init(uint256 numberOfLocks, uint256 bytesPerLock) internal pure returns (Accumulator memory accumulator)
  {
    accumulator.locks = LockManager.init(numberOfLocks);
    accumulator._bytesPerLock = bytesPerLock;
    return accumulator;
  }

  function accumulate(Accumulator storage accumulator, bytes memory randomBytes) internal {
    if (accumulator.generationIsDone) return;

    accumulator._currentLock = AccumulatorUtils.getRemainingBytes(randomBytes, accumulator._currentLock, accumulator._bytesPerLock);
    if (accumulator._currentLock.length >= accumulator._bytesPerLock) {
      accumulator.locks.vals[accumulator._currentLockNumber] = [accumulator._currentLock];
      ++accumulator._currentLockNumber;
      accumulator._currentLock = '';
    }
    if (accumulator._currentLockNumber >= accumulator.locks.numberOfLocks) accumulator.generationIsDone = true;
  }
}
