// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "../../support/BigNumbers.sol";
import "../miller-rabin/MillerRabin.sol";
import "../PrimeFactoringBounty.sol";
import "./RandomPrimeAccumulator.sol";

contract PrimeFactoringBountyWithLockGeneration is PrimeFactoringBounty, VRFConsumerBase {
  using BigNumbers for *;

  bytes32 internal keyHash;
  uint256 internal fee;

  RandomPrimeAccumulator private randomNumberAccumulator;

  constructor(uint256 numberOfLocks, uint256 primesPerLock, uint256 bytesPerPrime)
    PrimeFactoringBounty(numberOfLocks)
    VRFConsumerBase(
      0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
      0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    )
  {
    keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    fee = 0; //0.1 * 10 ** 18; // 0.1 LINK

    randomNumberAccumulator = new RandomPrimeAccumulator(numberOfLocks, primesPerLock, bytesPerPrime);
    generateLargePrimes();
  }

  function generateLargePrimes() public returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomNumberAccumulator.accumulate(randomness);
    if (!randomNumberAccumulator.isDone()) generateLargePrimes();
    else {
      for (uint256 lockNumber = 0; lockNumber < randomNumberAccumulator.numberOfLocks(); lockNumber++) {
        bytes[] memory lock = new bytes[](1);
        lock[0] = randomNumberAccumulator.locks(lockNumber);
        LockManager.setLock(locks(), lockNumber, lock);
      }
    }
  }
}
