// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./OrderFindingAccumulator.sol";
import "../OrderFindingBounty.sol";


contract OrderFindingBountyWithLockGeneration is OrderFindingBounty {
  uint256 private iteration;

  Accumulator private orderFindingAccumulator;

  constructor(uint256 numberOfLocks, uint256 byteSizeOfModulus, uint256 gcdIterationsPerCall)
    OrderFindingBounty(numberOfLocks)
  {
    orderFindingAccumulator = OrderFindingAccumulator.init(numberOfLocks, byteSizeOfModulus, gcdIterationsPerCall);
  }

  function locks() internal view override returns (Locks storage) {
    return orderFindingAccumulator.locks;
  }

  function isCheckingPrime() public view returns (bool) {
    return OrderFindingAccumulator.isCheckingPrime(orderFindingAccumulator);
  }

  function currentPrimeCheck() public view returns (bytes memory) {
    return OrderFindingAccumulator.currentPrimeCheck(orderFindingAccumulator);
  }

  function triggerLockAccumulation() public {
    require(!orderFindingAccumulator.generationIsDone, 'Locks have already been generated');
    bytes memory randomNumber = '';
    if (!OrderFindingAccumulator.isCheckingPrime(orderFindingAccumulator)) randomNumber = _generateRandomBytes();
    OrderFindingAccumulator.accumulate(orderFindingAccumulator, randomNumber);
  }

  function generationIsDone() public view returns (bool) {
    return orderFindingAccumulator.generationIsDone;
  }

  function _generateRandomBytes() private returns (bytes memory) {
    return abi.encodePacked(keccak256(abi.encodePacked(block.difficulty, iteration++)));
  }
}
