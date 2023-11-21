// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../../support/random-bytes-accumulator/RandomBytesAccumulator.sol";

contract RandomBytesAccumulatorTestHelper {
  Accumulator public accumulator;

  constructor(uint256 numberOfLocks, uint256 bytesPerPrime) {
    accumulator = RandomBytesAccumulator.init(numberOfLocks, bytesPerPrime);
  }

  function triggerAccumulate(bytes memory randomBytes) public {
    RandomBytesAccumulator.accumulate(accumulator, randomBytes);
  }
}
