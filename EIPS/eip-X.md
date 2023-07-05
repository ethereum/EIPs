---
eip: X
title: Quantum Supremacy Puzzle
author: Nicholas Papadopoulos (@nikojpapa)
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2023-06-26
requires: [ERC-2470]
---

# TODO
- Specify sanity solution check
- Show example of submitting solution
- Security considerations

## Abstract

[Quantum supremacy](https://en.wikipedia.org/wiki/Quantum_supremacy) indicates the earliest sign where an adversary can bypass current Etherium cryptography standards. To protect one's funds on Etherium, it would be useful to watch a trigger that activates when quantum supremacy has been achieved.
This ERC serves to show proof of quantum supremacy and trigger quantum-secure signature verification schemes on Etherium assets. Previous attempts have been made to demonstrate quantum supremacy, but they have been invalidated because of problem-tailoring, trapdoors, etc. This contract will prevent any notion of cheating by generating a classically impossible problem on chain, to which even the creator does not know the solution. The contract will be funded with ETH, which can only be retrieved by solving the problem.
Etherium accounts can then using custom verification schemes, such as those based on [ERC-4337](./eip-4337.md), can watch this contract and fall back to a quantum secure signature verification scheme if and when it is solved. 

## Motivation

- Proving quantum supremacy using blockchain verifiable methods
- Defining a point in time when quantum-secure protection of assets should be used

## Specification

### Requirements

- The paper [
  Efficient Accumulators without Trapdoor Extended Abstract](https://link.springer.com/chapter/10.1007/978-3-540-47942-0_21) by Tomas Sander proves that difficult to factor numbers without a known factorization can be generated. Using logic based on that described by [Anoncoin](https://anoncoin.github.io/RSA_UFO/), this contract shall generate 120 integers of 3,072 bits each to achieve a one in a billion chance of being insecure.
- This contract shall accept funds from any account without restriction.
- This contract shall allow someone to provide a factorization of one of the integers. If it is the correct solution and is the last integer to be solved, then this contract shall send all of its funds to the solver and mark a flag to indicate that this contract has been solved.

### Deployment Method

- The contract will be deployed as a [Singleton][ERC-2470]

- After deploying the contract with parameters of 120 locks having 3072 random bits each, the contract's `triggerLockAccumulation()` method will be called repeatedly until all bits have been generated.

- After lock generation, the deployers should solve all locks that can be readily solved, leaving only the difficult ones unsolved.

### Providing solutions

- The solution for each lock shall be provided separately. Providing solutions will follow a [commit-reveal](https://medium.com/swlh/exploring-commit-reveal-schemes-on-ethereum-c4ff5a777db8) scheme to prevent [front running](https://solidity-by-example.org/hacks/front-running/.)
- This scheme shall require one day between commit and reveal per lock, but allow simultaneous commits and reveals for different locks.

### Providing the bounty funds

Funds covering 6,000,000 gas for each unsolved lock shall be sent to the contract as a bounty. The funds must be updated to cover this amount as the value of gas increases.
The contract shall accept any additional funds from any account as a donation to the bounty.

### Providing the Final Solution

Upon solving the final solution, all funds in the contract shall be sent to the solver, the `solved` flag shall be marked `true`, and no further attempts to commit, reveal, or add funds to the contract shall be allowed.

## Rationale

- The reason to split up the lock generation and solving into many calls is to avoid hitting the gas limit of a transaction in any one call.
- Solving all readily solvable locks at the time of deployment allows for a less expensive transaction to finally solve the contract, since one would only need to pay to solve the difficult locks.
- It is estimated that less than 5,000,000 gas will be required to provide a solution for a single lock. The funds awarded to the solver must cover this cost with a margin of error and provide an additional reward to the solver as an incentive.

## Backwards Compatibility

Does not apply as there are no past versions of a Quantum Supremacy contract being used.

## Test Cases

- https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/test/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-rsa-ufo/prime-factoring-bounty-with-rsa-ufo.test.ts
- https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/test/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-rsa-ufo/rsa-ufo-accumulator.test.ts
- https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/test/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-predetermined-locks/prime-factoring-bounty-with-predetermined-locks.test.ts

## Reference Implementation

### Quantum Supremacy Contract
https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/contracts/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-rsa-ufo/PrimeFactoringBountyWithRsaUfo.sol

### Example Proof-of-concept Account Having a Quantum Secure Verification Scheme After Quantum Supremacy Trigger
https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/contracts/bounty-fallback-account/BountyFallbackAccount.sol

## Security Considerations
- By requiring one day between commit and reveal, it is infeasible to front run because the cost required to keep a reveal transaction in the mempool for a full day is greater than all the Eth in existence.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

[ERC-2470]: ./eip-2470.md
