---
eip: X
title: Quantum Supremacy Oracle
author: Nicholas Papadopoulos (@nikojpapa), Danny Ryan (@djrtwo)
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2023-06-26
requires: [ERC-2470]
---

## Abstract

This proposal introduces a smart contract containing a classically intractable puzzle that is expected to only be able to be solved using quantum computers.
The contract is funded with ETH, which can only be retrieved by solving the problem.
On-chain applications can then watch this contract to be aware of the quantum advantage milestone of solving this puzzle.
For example, Ethereum smart contract wallets can, using custom verification schemes such as those based on [ERC-4337](./eip-4337.md), watch this contract and fall back to a quantum secure signature verification scheme if and when it is solved.

The contract, then, serves the two purposes of (1) showing proof of a strict [quantum supremacy] that is strong enough to 
indicate concerns in RSA and ECDSA security, and (2) acting as a leading indicator to protect Ethereum assets by triggering quantum-secure 
signature verification schemes.

## Motivation

[Quantum supremacy] "is the goal of demonstrating that a programmable quantum computer can solve a problem that no classical computer can solve in any feasible amount of time".
Previous attempts have been made to demonstrate quantum supremacy, e.g. [Kim](https://www.nature.com/articles/s41586-023-06096-3), [Arute](https://www.nature.com/articles/s41586-019-1666-5) and [Morvan](https://arxiv.org/abs/2304.11119), 
but they have been refuted or at least claimed to have no practical benefit, e.g. [Begusic and Chan](https://arxiv.org/pdf/2306.16372.pdf), [Pednault](https://arxiv.org/pdf/1910.09534.pdf), 
and a quote from Sebastian Weidt in The Telegraph.
Quantum supremacy, by its current definition, is "irrespective of the usefulness of the problem".
This proposal, however, focuses on a stricter definition of a problem that indicates the earliest sign where an adversary may soon bypass current Ethereum cryptography standards.
This contract serves as trustless, unbiased proof of this strong quantum supremacy by generating a classically intractable problem on chain, 
to which even the creator does not know the solution.

[The Telegraph Link]: https://thequantuminsider.com/2023/07/04/google-claims-latest-quantum-experiment-would-take-decades-on-classical-computer/

Since quantum computers are [expected](https://www.nature.com/articles/d41586-023-00017-0) to break current security standards,
Ethereum assets are at risk. However, implementing quantum-secure
protocols can be costly and complicated.
In order to delay unnecessary costs, Ethereum assets can continue using current cryptographic standards and only fall back
to a quantum-secure scheme when there is reasonable risk of security failure due to quantum computers.
Therefore, this contract can serve to protect one's funds on Ethereum by acting as a trigger that activates when 
strong quantum supremacy has been achieved by solving the classically intractable puzzle.

[protocols Link]: https://csrc.nist.gov/News/2022/pqc-candidates-to-be-standardized-and-round-4


## Specification

### Parameters

- In this contract, a "lock" refers to a generated puzzle for which a solution must be provided 
in order to withdraw funds and mark the contract as solved.

| Parameter                 | Value    |
|---------------------------|----------|
| `EIP_X_SINGLETON_ADDRESS` | `TBD`    |
| `MINIMUM_GAS_PAYOUT`      | `50,000` |
| `MODULUS_BIT_SIZE`        | `784`    |
| `NUMBER_OF_LOCKS`         | `1`      |

### Puzzle

The puzzle that this contract generates is one of order-finding,
where given a positive integer _n_ and an integer _a_ coprime to _n_, the objective is to find the smallest positive integer
_k_ such that _a_ ^ _k_ = 1 (mod _n_).

[order-finding Link]: https://en.wikipedia.org/wiki/Shor%27s_algorithm#Quantum_order-finding_subroutine


### Requirements

- Generating locks, (one for each `NUMBER_OF_LOCKS`)
  - This contract SHALL generate an integer, the modulus, of exactly `MODULUS_BIT_SIZE` random bits. 
    It SHALL then generate another integer, the base, of <= `MODULUS_BIT_SIZE` bits and reduce it modulo the first generated integer.
  - If the base is equal to 1 or -1 mod _n_ or is coprime to the modulus, it MUST be thrown out and another base MUST be generated.
- This contract MUST accept ETH from any account without restriction.
- This contract MUST allow someone to provide the multiplicative order of the base with the modulus.
  If it is the correct solution, then this contract MUST send all of its ETH to the solver and mark a flag to indicate that this contract has been solved.

[multiplicative order Link]: https://en.wikipedia.org/wiki/Multiplicative_order

### Deployment method

- The contract MUST be deployed as a [Singleton][ERC-2470].
- After deploying the contract with parameters of `NUMBER_OF_LOCKS` lock having a `MODULUS_BIT_SIZE`-bit modulus, the contract's `triggerLockAccumulation()` method SHALL be called repeatedly until `generationIsDone == true`, i.e. all bits have been generated.

### Providing solutions

- Providing solutions MUST follow a commit-reveal scheme to prevent front running.
- This scheme MUST require one day between commit and reveal.

[commit-reveal Link]: https://medium.com/swlh/exploring-commit-reveal-schemes-on-ethereum-c4ff5a777db8
[front running Link]: https://solidity-by-example.org/hacks/front-running/

### Bounty funds

- Funds of at least `MINIMUM_GAS_PAYOUT` gas SHALL be sent to the contract as a bounty.
  The funds must be updated to cover this amount as the value of gas increases.
- The contract MUST accept any additional funds from any account as a donation to the bounty.

### Rewarding the solver

Upon solving the final solution,
  - All funds in the contract MUST be sent to the solver
  - The `solved` flag MUST be set to `true`
  - Subsequent transactions to commit, reveal, or add funds to the contract MUST be reverted.

## Rationale

### Puzzle

Order-finding has a known, efficient, quantum solution
but is intractable for classical computers. This then reliably serves as a test for strong quantum supremacy, since
finding a solution to this problem should only be doable by a quantum computer.

[solution Link]: https://en.wikipedia.org/wiki/Shor%27s_algorithm#Quantum_order-finding_subroutine

Fewer qubits are required to solve this problem compared to the amount needed to
break current cryptographic standards,
so this is expected to be solvable before current security standards are breakable. In this way, the contract can act as
a leading indicator and signal a safe moment of concern to switch to quantum-secure cryptographic schemes.

[qubits Link]: https://en.wikipedia.org/wiki/Qubit


### Bounty Funds

To simulate expected gas costs -- given a random 783-bit base and a random 784-bit modulus, 196 random solutions of byte size equal to its iteration were sent to the contract.
The gas cost for all of these simulations never exceeded 44,305 gas. Therefore, we expect a minimum bount covering a cost 50,000 gas in even extreme gas markets (e.g. 1000 Gwei / gas) to reliably cover the
cost for a solver to provide a solution.


## Backwards Compatibility

Backwards compatibility does not apply as there are no past versions of a contract of this sort.

## Test Cases

- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/d27f6822808efb9f9ed3972e7cc9ce8443ecbff2/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/order-finding-accumulator.test.ts
- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/d27f6822808efb9f9ed3972e7cc9ce8443ecbff2/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/order-finding-bounty-with-lock-generation.test.ts
- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/d27f6822808efb9f9ed3972e7cc9ce8443ecbff2/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-predetermined-locks/order-finding-bounty-with-predetermined-locks.test.ts

## Reference Implementation

### Quantum Supremacy Contract
https://github.com/nikojpapa/ethereum-quantum-bounty/blob/d27f6822808efb9f9ed3972e7cc9ce8443ecbff2/contracts/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/OrderFindingBountyWithLockGeneration.sol

### Example Proof-of-concept Account Having a Quantum Secure Verification Scheme After Quantum Supremacy Trigger
https://github.com/nikojpapa/ethereum-quantum-bounty/blob/d27f6822808efb9f9ed3972e7cc9ce8443ecbff2/contracts/bounty-fallback-account/BountyFallbackAccount.sol

## Security Considerations

### Bit length of the modulus
[Cleve] details a lower bound for the query complexity on the general order-finding problem and defines 
how the quantum solution used in [Shor's](https://api.semanticscholar.org/CorpusID:15291489) algorithm fits into it. 

We would like 256-bit security, which is satisfied if we hit a 2^256 lower bound on the query complexity.
The lower bound given in the paper shows us, then, that a 782-bit modulus is necessary to achieve this.
To make this cheaper and easier, we make this 784 in order to be a whole number of bytes, namely 98 bytes.
This would require 1568 qubits, as the order is bounded by twice the modulus ([Cleve]).

Breaking 256-bit elliptic curve encryption is [expected](https://arxiv.org/abs/1706.06752) to require 2330 qubits, although with current fault-tolerant regime, it is [expected](https://avs.scitation.org/doi/10.1116/5.0073075) that 13 * 10^6 physical qubits would be required to break 256-bit elliptic curve encryption within one day.

[security Link]: https://api.semanticscholar.org/CorpusID:209527904

### Choosing the puzzle
The following are other options that were considered as the puzzle to be used along with the reasoning for not using them.

#### Sign a message given a public key
Given a random public key, the solver would need to sign a message, which the contract would verify to have been 
correctly signed by the public key. 
The downside to this approach is that the contract would act less like a leading indicator to secure ETH funds 
as by the time the puzzle is solved, the ability to forge signatures will have already been achieved. 

#### Factor many large, randomly generated numbers
[Sander](https://link.springer.com/chapter/10.1007/978-3-540-47942-0_21) proves that difficult to factor numbers without a known factorization, called RSA-UFOs, can be generated. 
Using logic based on that described by Anoncoin, one could generate 120 integers of 3,072 bits each to achieve a one in a billion chance of being insecure.
[RSA Security](https://web.archive.org/web/20170417095741/https://www.emc.com/emc-plus/rsa-labs/historical/twirl-and-rsa-key-size.htm) recommends 3,072-bit key sizes for RSA to be secure beyond 2030, 
but [Alwen](https://wickr.com/the-bit-security-of-cryptographic-primitives-2/) claims that it is only considered secure for the next 2-3 decades.
Therefore, while this method requires no trust, the cost of generating this problem would be large, and it would not serve as much of a leading indicator since if a quantum computer could solve this, they could already break current cryptographic security standards.

[logic Link]: https://anoncoin.github.io/RSA_UFO/


#### Factor a product of large, generated primes
Instead of generating an RSA-UFO, the contract could implement current RSA key generation protocols and first generate 
two large primes to produces the product of the primes. 
This method has the flaw that the minter has the capability to see the primes, 
and therefore some level of trust would need to be given that the minter would throw the values away.

#### Powers of Tau
This also has a trust factor, albeit very small. It requires that at least one person in the party is honest.


### Front running and censorship

One day is required before one can reveal a commitment. It is largely infeasible to censor an economically viable transaction for such a period of time.

Assuming the reveal transaction is willing to pay market rate for transaction fees, the 1559 fee mechanism and its exponential adjustment makes it infeasible for an economic attacker to spam costly transactions to artifically increase the base-fee for extended period of time.

Additionally, even if a large percentage of the proposers collude to censor, the inclusion of the reveal transaction on chain will be delayed but only as a function of the ratio of censoring to non-censoring proposers. E.g., if 90% of proposers censor, then the reveal transaction will take 10x as long as expected to be included -- on the order of 120s given mainnet block times. If, instead, 99% of proposers censor, then the transaction will take ~100x as long to be included -- on the order of 1200s. Still in these extreme regimes, reveal times on the order of a day are safe.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

[Cleve]: https://arxiv.org/abs/quant-ph/9911124
[ERC-2470]: ./eip-2470.md
[Quantum supremacy]: https://en.wikipedia.org/wiki/Quantum_supremacy
