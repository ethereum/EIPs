// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../BountyContract.sol";
import "../support/BigNumbers.sol";
import "./miller-rabin/MillerRabin.sol";

abstract contract PrimeFactoringBounty is BountyContract {
  using BigNumbers for *;

  constructor(uint256 numberOfLocks) BountyContract(numberOfLocks) {}

  function _verifySolution(uint256 lockNumber, bytes memory solution) internal view override returns (bool) {
    bytes[] memory primes = abi.decode(solution, (bytes[]));
    BigNumber memory product = BigNumbers.one();
    for (uint256 i = 0; i < primes.length; i++) {
      bytes memory primeFactor = primes[i];
      require(MillerRabin.isPrime(primeFactor), 'Given solution is not prime');
      product = product.mul(primeFactor.init(false));
    }

    BigNumber memory lock = getLock(lockNumber)[0].init(false);
    return product.eq(lock);
  }
}
