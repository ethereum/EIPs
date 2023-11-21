// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "solidity-bytes-utils/contracts/BytesLib.sol";

struct Commit {
  bytes solutionHash;
  uint256 timestamp;
}

library CommitRevealManager {
  uint256 private constant ONE_DAY_IN_SECONDS = 86400;

  function commitSolution(
    mapping(address => mapping(uint256 => Commit)) storage commits,
    address sender,
    uint256 lockNumber,
    bytes memory solutionHash
  ) internal {
    Commit storage commit = commits[sender][lockNumber];
    commit.solutionHash = solutionHash;
    commit.timestamp = block.timestamp;
  }

  function getMyCommit(
    mapping(address => mapping(uint256 => Commit)) storage commits,
    address sender,
    uint256 lockNumber
  ) internal view returns (bytes memory, uint256) {
    Commit storage commit = commits[sender][lockNumber];
    _requireCommitExists(commit);
    return (commit.solutionHash, commit.timestamp);
  }

  function verifyReveal(
    mapping(address => mapping(uint256 => Commit)) storage commits,
    address sender,
    uint256 lockNumber,
    bytes memory solution
  ) internal view returns (bool) {
    Commit storage commit = commits[sender][lockNumber];
    _requireCommitExists(commit);
    require(block.timestamp - commit.timestamp >= ONE_DAY_IN_SECONDS, 'Cannot reveal within a day of the commit');

    bytes memory solutionEncoding = abi.encode(sender, solution);
    bytes32 solutionHash = keccak256(solutionEncoding);
    return BytesLib.equal(abi.encodePacked(solutionHash), commit.solutionHash);
  }

  function _requireCommitExists(Commit memory commit) private pure {
    require(!BytesLib.equal(commit.solutionHash, ""), 'Not committed yet');
  }
}
