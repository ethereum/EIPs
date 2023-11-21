// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../../support/BigNumbers.sol";
import "../PrimeFactoringBounty.sol";
import "../../support/random-bytes-accumulator/RandomBytesAccumulator.sol";


/* Using methods based on:
 * - Sander, T. (1999). Efficient Accumulators without Trapdoor Extended Abstract. In: Information and Communication Security, V. Varadharajan and Y. Mu (editors), Second International Conference, ICICS’99, pages 252-262.
 * - https://anoncoin.github.io/RSA_UFO/
 *
 * The number of locks should be log(1-p) / log(1 - 0.16), where p is the probability that at least one lock
 * is difficult to factor.
 */
contract PrimeFactoringBountyWithRsaUfo is PrimeFactoringBounty {
  uint256 private iteration;

  Accumulator private randomBytesAccumulator;

  constructor(uint256 numberOfLocks, uint256 bytesPerPrime)
    PrimeFactoringBounty(numberOfLocks)
  {
    randomBytesAccumulator = RandomBytesAccumulator.init(numberOfLocks, 3 * bytesPerPrime);
  }

  function locks() internal view override returns (Locks storage) {
    return randomBytesAccumulator.locks;
  }

  function triggerLockAccumulation() public {
    require(!generationIsDone(), 'Locks have already been generated');
    bytes memory randomNumber = abi.encodePacked(keccak256(abi.encodePacked(block.difficulty, iteration++)));
    RandomBytesAccumulator.accumulate(randomBytesAccumulator, randomNumber);
  }

  function generationIsDone() public view returns (bool) {
    return randomBytesAccumulator.generationIsDone;
  }
}
