// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../BountyContract.sol";

contract SignatureBounty is BountyContract {
  using ECDSA for bytes32;

  bytes32 public message;

  constructor(uint256 numberOfLocks)
    BountyContract(numberOfLocks) {}

  function _verifySolution(uint256 lockNumber, bytes memory solution) internal view override returns (bool) {
    address lock = BytesLib.toAddress(getLock(lockNumber)[0], 0);
    address signerAddress = message.toEthSignedMessageHash().recover(solution);
    return signerAddress == lock;
  }
}
