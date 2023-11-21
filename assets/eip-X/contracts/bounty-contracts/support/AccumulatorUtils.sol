// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

library AccumulatorUtils {
  function getRemainingBytes(bytes memory randomBytes, bytes memory currentBytes, uint256 bytesPerLock) internal pure returns (bytes memory) {
    uint256 numBytesToAccumulate = Math.min(randomBytes.length, bytesPerLock - currentBytes.length);
    bytes memory bytesToAccumulate = BytesLib.slice(randomBytes, 0, numBytesToAccumulate);
    return BytesLib.concat(currentBytes, bytesToAccumulate);
  }
}
