---
eip: X
title: Quantum Supremacy Puzzle
author: Nicholas Papadopoulos (@nikojpapa), Danny Ryan 
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2023-06-26
requires: [ERC-2470]
---

# TODO
- Show example of submitting solution

## Abstract

[Quantum supremacy](https://en.wikipedia.org/wiki/Quantum_supremacy) indicates the earliest sign where an adversary can bypass current Ethereum cryptography standards.
To protect one's funds on Ethereum, it would be useful to watch a trigger that activates when quantum supremacy has been achieved.
This ERC serves to both show proof of a stricter quantum supremacy (one that is strong enough to indicate concerns in RSA security) and trigger quantum-secure signature verification schemes on Ethereum assets.
Previous attempts have been made to demonstrate quantum supremacy, e.g. [Kim](https://www.nature.com/articles/s41586-023-06096-3), [Arute](https://www.nature.com/articles/s41586-019-1666-5) and [Morvan](https://arxiv.org/abs/2304.11119), but they have been refuted or at least claimed to have no practical benefit, e.g. [Begusic and Chan](https://arxiv.org/pdf/2306.16372.pdf), [Pednault](https://arxiv.org/pdf/1910.09534.pdf), and a quote from Sebastian Weidt in [The Telegraph](https://thequantuminsider.com/2023/07/04/google-claims-latest-quantum-experiment-would-take-decades-on-classical-computer/).
This contract will prevent any notion of cheating by generating a classically impossible problem on chain, to which even the creator does not know the solution.
The contract will be funded with ETH, which can only be retrieved by solving the problem.
Ethereum accounts can then, using custom verification schemes such as those based on [ERC-4337](./eip-4337.md), watch this contract and fall back to a quantum secure signature verification scheme if and when it is solved. 

## Motivation

- Defining a point in time when quantum-secure protection of Ethereum assets should be used
- Proving practical quantum supremacy using blockchain verifiable methods

## Specification

### Requirements

- This contract shall generate 1 integer, the modulus, of exactly 784 bits. 
  It shall then generate another integer, the base, of <= 784 bits and reduce it modulo the first generated integer.
- This contract shall accept funds from any account without restriction.
- This contract shall allow someone to provide the [order](https://en.wikipedia.org/wiki/Shor%27s_algorithm#Quantum_order-finding_subroutine) of the base with the modulus.
  If it is the correct solution, then this contract shall send all of its funds to the solver and mark a flag to indicate that this contract has been solved.

### Deployment Method

- The contract will be deployed as a [Singleton][ERC-2470]
- After deploying the contract with parameters of 1 locks having a 784-bit modulus, the contract's `triggerLockAccumulation()` method will be called repeatedly until all bits have been generated.

### Providing solutions

- Providing solutions will follow a [commit-reveal](https://medium.com/swlh/exploring-commit-reveal-schemes-on-ethereum-c4ff5a777db8) scheme to prevent [front running](https://solidity-by-example.org/hacks/front-running/.)
- This scheme shall require one day between commit and reveal per lock, but allow simultaneous commits and reveals for different locks.

### Bounty funds
Funds covering 50,000 gas for each unsolved lock shall be sent to the contract as a bounty.
The funds must be updated to cover this amount as the value of gas increases.
The contract shall accept any additional funds from any account as a donation to the bounty.

### Providing the Final Solution

Upon solving the final solution, all funds in the contract shall be sent to the solver, the `solved` flag shall be marked `true`, and no further attempts to commit, reveal, or add funds to the contract shall be allowed.

## Rationale

- The reason to split up the lock generation and solving into many calls is to avoid hitting the gas limit of a transaction in any one call.
- It is estimated that less than 50,000 gas will be required to provide a solution for a single lock.
  The funds awarded to the solver must cover this cost with a margin of error and provide an additional reward to the solver as an incentive.

## Backwards Compatibility

Does not apply as there are no past versions of a Quantum Supremacy contract being used.

## Test Cases

- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/ac7cdbb32a74649f061a4012c9221ecf00b0ab32/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/order-finding-accumulator.test.ts
- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/ac7cdbb32a74649f061a4012c9221ecf00b0ab32/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/order-finding-bounty-with-lock-generation.test.ts
- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/ac7cdbb32a74649f061a4012c9221ecf00b0ab32/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-predetermined-locks/order-finding-bounty-with-predetermined-locks.test.ts

## Reference Implementation

### Quantum Supremacy Contract
https://github.com/nikojpapa/ethereum-quantum-bounty/blob/ac7cdbb32a74649f061a4012c9221ecf00b0ab32/contracts/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/OrderFindingBountyWithLockGeneration.sol

### Example Proof-of-concept Account Having a Quantum Secure Verification Scheme After Quantum Supremacy Trigger
https://github.com/nikojpapa/ethereum-quantum-bounty/blob/ac7cdbb32a74649f061a4012c9221ecf00b0ab32/contracts/bounty-fallback-account/BountyFallbackAccount.sol

## Security Considerations

### Bit length of the modulus
[Cleve](https://arxiv.org/abs/quant-ph/9911124) details a lower bound for the query complexity on the general order-finding problem and defines 
how the quantum solution used in [Shor's](https://api.semanticscholar.org/CorpusID:15291489) algorithm fits into it. 

We would like 256-bit [security](https://api.semanticscholar.org/CorpusID:209527904), which is satisfied if we hit a 2^256 lower bound on the query complexity.
The lower bound given in the paper shows us, then, that a 782-bit modulus is necessary to achieve this.
To make this cheaper and easier, we make this 784 in order to be a whole number of bytes, namely 98 bytes.

### Choosing the puzzle
Different puzzles were considered before landing on the current implementation.

#### Sign a message given a public key
Given a random public key, the solver would need to sign a message, which the contract would verify to have been correctly signed by the public key. The downside to this approach is that the contract would act less like a canary to secure ETH funds as by the time the puzzle is solved, the ability to forge signatures will have already been achieved. The current puzzle of factoring integers is expected to be the first problem that quantum computers will solve, so it should act as a better canary.

#### Factor many large, randomly generated numbers
The paper [Efficient Accumulators without Trapdoor Extended Abstract](https://link.springer.com/chapter/10.1007/978-3-540-47942-0_21) by Tomas Sander proves that difficult to factor numbers without a known factorization, called an RSA-UFO, can be generated. 
Using [logic](https://anoncoin.github.io/RSA_UFO/) based on that described by Anoncoin, one could generate 120 integers of 3,072 bits each to achieve a one in a billion chance of being insecure.
[RSA Security](https://web.archive.org/web/20170417095741/https://www.emc.com/emc-plus/rsa-labs/historical/twirl-and-rsa-key-size.htm) recommends 3,072-bit key sizes for RSA to be secure beyond 2030, 
but [Alwen](https://wickr.com/the-bit-security-of-cryptographic-primitives-2/) claims that it is only considered secure for the next 2-3 decades.
Therefore, while this method requires no trust, the cost of generating this problem would be large, and it would not serve as much of a leading indicator since if a quantum computer could solve this, they could already break current cryptographic security standards.

#### Factor a product of large, generated primes
Instead of generating an RSA-UFO, the contract could implement current RSA key generation protocols and first generate two large primes to produces the product of the primes. This method has the flaw that the miner or minter has the capability to see the primes, and therefore some level of trust would need to be given that the minter would throw the values away.

#### Powers of Tau
This also has a trust factor, albeit very small. It requires that at least one person in the party is honest.


### Front running
- By requiring one day between commit and reveal, it is infeasible to front run because the cost required to keep a reveal transaction in the mempool for a full day is greater than all the Eth in existence.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

[ERC-2470]: ./eip-2470.md
