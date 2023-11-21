// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../../support/BigNumbers.sol";
import "../miller-rabin/MillerRabin.sol";

contract RandomPrimeAccumulator {
  using BigNumbers for *;

  bytes[] public locks;
  bool public isDone;
  uint256 public numberOfLocks;

  uint256 private bytesPerPrime;
  uint256 private primesPerLock;
  bytes[] private primeNumbers;
  bytes private primeCandidate;
  uint256 private primesCounter;
  uint256 private lockCounter;

  constructor(uint256 numberOfLocksInit, uint256 primesPerLockInit, uint256 bytesPerPrimeInit) {
    numberOfLocks = numberOfLocksInit;
    locks = new bytes[](numberOfLocks);
    primesPerLock = primesPerLockInit;
    bytesPerPrime = bytesPerPrimeInit;
    primeNumbers = new bytes[](primesPerLock);

    _resetPrimeCandidate();
    isDone = false;
  }

  function accumulate (uint256 randomNumber) public _isNotDone {
    if (_primeCandidateIsReset()) randomNumber |= (1 << 255);
    primeCandidate = BytesLib.concat(primeCandidate, abi.encodePacked(randomNumber));
    if (primeCandidate.length < bytesPerPrime) return;
    primeCandidate = BytesLib.slice(primeCandidate, 0, bytesPerPrime);

//    BigNumber memory madeEven = primeCandidate.init(false).shr(1).shl(1);
//    BigNumber memory oddPrimeCandidate = madeEven.add(BigNumbers.one());
//    primeCandidate = oddPrimeCandidate.val;

    if (MillerRabin.isPrime(primeCandidate)) {
      for (uint256 i = 0; i < primesCounter; i++) {
        bytes memory siblingPrime = primeNumbers[i];
        if (BytesLib.equal(siblingPrime, primeCandidate)) return;
      }

      primeNumbers[primesCounter] = primeCandidate;
      primesCounter++;

      if (primesCounter == primesPerLock) {
        BigNumber memory lockCandidate = BigNumbers.one();
        for (uint256 primeComponentIndex = 0; primeComponentIndex < primeNumbers.length; primeComponentIndex++) {
          lockCandidate = lockCandidate.mul(primeNumbers[primeComponentIndex].init(false));
        }

        for (uint256 i = 0; i < lockCounter; i++) {
          bytes memory lock = locks[i];
          if (BytesLib.equal(lock, lockCandidate.val)) {
            primesCounter--;
            return;
          }
        }

        locks[lockCounter] = lockCandidate.val;
        lockCounter++;
        primesCounter = 0;

        if (lockCounter == locks.length) isDone = true;
      }
    }
    _resetPrimeCandidate();
  }

  function _resetPrimeCandidate() private {
    primeCandidate = '';
  }

  function _primeCandidateIsReset() private view returns (bool) {
    return BytesLib.equal(primeCandidate, '');
  }

  modifier _isNotDone() {
    require(!isDone, 'Already accumulated enough bits');
    _;
  }
}
