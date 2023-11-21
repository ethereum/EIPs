// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../../support/BigNumbers.sol";
import "../../support/random-bytes-accumulator/RandomBytesAccumulator.sol";
import "../SignatureBounty.sol";


contract SignatureBountyWithLockGeneration is SignatureBounty {
  uint256 private iteration;

  Accumulator private locksAccumulator;
  Accumulator private messageAccumulator;

  uint8 private numberOfMessages = 1;
  uint8 private messageByteSize = 32;
  uint8 private publicKeyByteSize = 20;

  constructor(uint256 numberOfLocks)
    SignatureBounty(numberOfLocks)
  {
    locksAccumulator = RandomBytesAccumulator.init(numberOfLocks, publicKeyByteSize);
    messageAccumulator = RandomBytesAccumulator.init(numberOfMessages, messageByteSize);
  }

  function locks() internal view override returns (Locks storage) {
    return locksAccumulator.locks;
  }

  function triggerLockAccumulation() public {
    require(!generationIsDone(), 'Locks have already been generated');

    bytes memory randomNumber = abi.encodePacked(keccak256(abi.encodePacked(block.difficulty, iteration++)));
    if (messageAccumulator.generationIsDone) {
      RandomBytesAccumulator.accumulate(locksAccumulator, randomNumber);
    } else {
      RandomBytesAccumulator.accumulate(messageAccumulator, randomNumber);
      if (messageAccumulator.generationIsDone) message = BytesLib.toBytes32(messageAccumulator.locks.vals[0][0], 0);
    }
  }

  function generationIsDone() public view returns (bool) {
    return locksAccumulator.generationIsDone;
  }
}
