// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "./support/CommitRevealManager.sol";
import "./support/LockManager.sol";

abstract contract BountyContract {
  bool public solved;

  mapping(address => mapping(uint256 => Commit)) private commits;
  Locks private locksDefault;

  constructor(uint256 numberOfLocksArg) {
    locksDefault = LockManager.init(numberOfLocksArg);
  }

  modifier requireUnsolved() {
    require(!solved, 'Already solved');
    _;
  }

  function locks() internal view virtual returns (Locks storage) {
    return locksDefault;
  }

  function _verifySolution(uint256 lockNumber, bytes memory solution) internal view virtual returns (bool);

  function getLock(uint256 lockNumber) public view returns (bytes[] memory) {
    return LockManager.getLock(locks(), lockNumber);
  }

  function numberOfLocks() public view returns (uint256) {
    return locks().numberOfLocks;
  }

  function commitSolution(uint256 lockNumber, bytes memory solutionHash) public requireUnsolved {
    CommitRevealManager.commitSolution(commits, msg.sender, lockNumber, solutionHash);
  }

  function getMyCommit(uint256 lockNumber) public view returns (bytes memory, uint256) {
    return CommitRevealManager.getMyCommit(commits, msg.sender, lockNumber);
  }

  function solve(uint256 lockNumber, bytes memory solution) public requireUnsolved {
    require(CommitRevealManager.verifyReveal(commits, msg.sender, lockNumber, solution), "Solution hash doesn't match");
    require(_verifySolution(lockNumber, solution), 'Invalid solution');

    LockManager.setLocksSolvedStatus(locks(), lockNumber, true);
    if (LockManager.allLocksSolved(locks())) {
      solved = true;
      _sendBountyToSolver();
    }
  }

  function _sendBountyToSolver() private {
    Address.sendValue(payable(msg.sender), bounty());
  }

  function bounty() public view returns (uint256) {
    return address(this).balance;
  }

  receive() external payable {
    addToBounty();
  }

  fallback() external payable {
    addToBounty();
  }

  function addToBounty() public payable requireUnsolved {
  }
}
