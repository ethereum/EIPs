// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./MillerRabin.sol";

contract MillerRabinTestHelper {
  function isPrime(bytes memory primeCandidate) public view returns (bool) {
    return MillerRabin.isPrime(primeCandidate);
  }
}
