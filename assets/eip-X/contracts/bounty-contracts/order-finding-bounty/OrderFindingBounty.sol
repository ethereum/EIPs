// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../BountyContract.sol";
import "../support/BigNumbers.sol";

abstract contract OrderFindingBounty is BountyContract {
  using BigNumbers for *;

  constructor(uint256 numberOfLocks) BountyContract(numberOfLocks) {}

  function _verifySolution(uint256 lockNumber, bytes memory solution) internal view override returns (bool) {
    bytes[] memory lock = getLock(lockNumber);
    require(lock.length > 0, 'Lock has not been generated yet.');
    bytes memory modulus = lock[0];
    bytes memory base = lock[1];

    BigNumber memory answer = base.init(false).modexp(solution.init(false), modulus.init(false));
    return answer.eq(BigNumbers.one());
  }
}
