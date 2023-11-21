// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./OrderFindingAccumulator.sol";

contract OrderFindingAccumulatorTestHelper {
  Accumulator public accumulator;

  constructor(uint256 numberOfLocks, uint256 bytesPerPrime, uint256 gcdIterationsPerCall) {
    accumulator = OrderFindingAccumulator.init(numberOfLocks, bytesPerPrime, gcdIterationsPerCall);
  }

  function triggerAccumulate(bytes memory randomBytes) public {
    OrderFindingAccumulator.accumulate(accumulator, randomBytes);
  }

  function isCheckingPrime() public view returns (bool) {
    return OrderFindingAccumulator.isCheckingPrime(accumulator);
  }
}
