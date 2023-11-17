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

The contract, then, serves the two purposes of (1) showing proof of a strict quantum supremacy[1] that is strong enough to 
indicate concerns in RSA and ECDSA security, and (2) acting as a leading indicator to protect Ethereum assets by triggering quantum-secure 
signature verification schemes.

## Motivation

Quantum supremacy[1] would be a demonstration of a quantum computer solving a problem that would take a classical computer an infeasible amount of time to solve.
Previous attempts have been made to demonstrate quantum supremacy, e.g. Kim[2], Arute[3] and Morvan[4], 
but they have been refuted or at least claimed to have no practical benefit, e.g. Begusic and Chan[5], Pednault[6], 
and a quote from Sebastian Weidt (The Telegraph, "Supercomputer makes calculations in blink of an eye that take rivals 47 years", 2023).
Quantum supremacy, by its current definition, is "irrespective of the usefulness of the problem".
This proposal, however, focuses on a stricter definition of a problem that indicates the earliest sign where an adversary may soon bypass current Ethereum cryptography standards.
This contract serves as trustless, unbiased proof of this strong quantum supremacy by generating a classically intractable problem on chain, 
to which even the creator does not know the solution.

Since quantum computers are expected[7] to break current security standards,
Ethereum assets are at risk. However, implementing quantum-secure
protocols can be costly and complicated.
In order to delay unnecessary costs, Ethereum assets can continue using current cryptographic standards and only fall back
to a quantum-secure scheme when there is reasonable risk of security failure due to quantum computers.
Therefore, this contract can serve to protect one's funds on Ethereum by acting as a trigger that activates when 
strong quantum supremacy has been achieved by solving the classically intractable puzzle.


## Specification

### Parameters

- In this contract, a "lock" refers to a generated puzzle for which a solution must be provided 
in order to withdraw funds and mark the contract as solved.

| Parameter                 | Value         |
|---------------------------|---------------|
| `BIT_SIZE_OF_PRIMES`      | `3072`        |
| `EIP_X_SINGLETON_ADDRESS` | `TBD`         |
| `MINIMUM_GAS_PAYOUT`      | `600,000,000` |
| `NUMBER_OF_LOCKS`         | `119`         |

### Puzzle

The puzzles that this contract generates are of prime factorization,
where given a positive integer _n_, the objective is to find a list of prime numbers whose product is equal to _n_.


### Requirements

- This contract MUST generate each of the `NUMBER_OF_LOCKS` locks by generating an integer of exactly `BIT_SIZE_OF_PRIMES` random bits.
- This contract MUST accept ETH from any account without restriction.
- This contract MUST allow someone to provide the prime factorization of any lock.
  If it is the correct solution and solves the last unsolved lock, then this contract MUST send all of its ETH to the solver and mark a flag to indicate that this contract has been solved.

### Deployment method

- The contract MUST be deployed as a Singleton ([ERC-2470]).
- After deploying the contract with parameters of `NUMBER_OF_LOCKS` locks, each probabilistically generating an integer composed
  of at least two `BIT_SIZE_OF_PRIMES`-bit primes, the contract's `triggerLockAccumulation()` method SHALL be called repeatedly until `generationIsDone == true`, i.e. all bits have been generated.

### Providing solutions

- The solution for each lock SHALL be provided separately.
- Providing solutions MUST follow a commit-reveal scheme to prevent front running.
- This scheme MUST require one day between commit and reveal.

### Rewarding the solver

Upon solving the final solution,
  - All funds in the contract MUST be sent to the solver
  - The `solved` flag MUST be set to `true`
  - Subsequent transactions to commit, reveal, or add funds to the contract MUST be reverted.

### Bounty funds

- Funds covering at least `MINIMUM_GAS_PAYOUT` gas SHALL be sent to the contract as a bounty.
  The funds must be updated to cover this amount as the value of gas increases.
- The contract MUST accept any additional funds from any account as a donation to the bounty.

## Rationale

### Puzzle

Prime factorization has a known, efficient, quantum solution[8]
but is believed to be intractable for classical computers. This then reliably serves as a test for strong quantum supremacy, since
finding a solution to this problem should only be doable by a quantum computer.


### Bounty Funds

The solver SHALL be reimbursed at least the cost of verifying the puzzle solutions. Therefore, to estimate the cost, an estimate
can be calculated by providing the solution of a known factorization. 
The expected number of prime factors is log(log(_n_)), so the expected
number of prime factors of a 3072-bit integer is less than 12. 

Deploying a contract with 119 locks of a provided 3072-bit integer having 16 factors then providing that solution for
each of them resulted in a cost of 583,338,223 gas. Providing a solution for a single lock cost 4,959,717 gas.
The majority of the cost comes from verifying that the provided factors are indeed prime with the Miller-Rabin primality test.

Since the number of factors is greater than the expected[9] number of factors of any integer, this may serve as an initial estimate of the cost to verify the solutions for randomly generated integers. Therefore, since the total cost is less than
`MINIMUM_GAS_PAYOUT` gas, a bounty covering at least `MINIMUM_GAS_PAYOUT` should be funded to the contract.


## Backwards Compatibility

Backwards compatibility does not apply as there are no past versions of a contract of this sort.

## Test Cases

- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/8a27c190021928a0be6e4885d373e2489332ef95/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/order-finding-accumulator.test.ts
- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/8a27c190021928a0be6e4885d373e2489332ef95/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/order-finding-bounty-with-lock-generation.test.ts
- https://github.com/nikojpapa/ethereum-quantum-bounty/blob/8a27c190021928a0be6e4885d373e2489332ef95/test/bounty-contracts/order-finding-bounty/order-finding-bounty-with-predetermined-locks/order-finding-bounty-with-predetermined-locks.test.ts

## Reference Implementation

### Quantum Supremacy Contract
https://github.com/nikojpapa/ethereum-quantum-bounty/blob/8a27c190021928a0be6e4885d373e2489332ef95/contracts/bounty-contracts/order-finding-bounty/order-finding-bounty-with-lock-generation/OrderFindingBountyWithLockGeneration.sol

### Example Proof-of-concept Account Having a Quantum Secure Verification Scheme After Quantum Supremacy Trigger
https://github.com/nikojpapa/ethereum-quantum-bounty/blob/8a27c190021928a0be6e4885d373e2489332ef95/contracts/bounty-fallback-account/BountyFallbackAccount.sol

## Security Considerations

### Bit-length of the integers
Order-finding reduces[10] to integer factoring, therefore
the modulus must also be difficult to factor.

Sander[11] proves that difficult to factor numbers without a known factorization, called an RSA-UFO, can be generated.
Using logic based on that described by Anoncoin using this method, this contract shall generate `NUMBER_OF_LOCKS` integers of `BIT_SIZE_OF_PRIMES` bits each to achieve a one in a billion chance of being insecure.

#### Predicted security
##### Classical
Burt Kaliski and RSA Laboratories ("TWIRL and RSA Key Size", 2003) recommends 3,072-bit key sizes for RSA to be secure beyond 2030,
although Joël Alwen (Wickr, "The Bit-Security of Cryptographic Primitives", 2017) claims that it is only considered secure for the next 2-3 decades.

##### Quantum
Breaking 256-bit elliptic curve encryption is expected[12] to require 2,330 qubits, although with current fault-tolerant regime, it is expected[13] that 13 * 10^6 physical qubits would be required to break 256-bit elliptic curve encryption within one day.

### Choosing the puzzle
The following are other options that were considered as the puzzle to be used along with the reasoning for not using them.

#### Order-finding

where given a positive integer _n_ and an integer _a_ coprime to _n_, the objective is to find the smallest positive integer
_k_ such that _a_ ^ _k_ = 1 (mod _n_).

Order-finding can be reduced[10] to factoring, and vice-versa. Since it is cheaper to verify an order-finding solution than a factorization solution, the puzzle is generated by first generating hard-to-factor numbers with high probability as a modulus and then generating a random number coprime to that modulus.

- need to generate hard to factor modulus
- cost estimation (deploy)
- cost estimation (solve) (Cleve[14])

To simulate expected gas costs -- given a random 3071-bit base and a random 3072-bit modulus, 196 random solutions of byte size equal to its iteration were sent to the contract.
The gas cost for all of these simulations never exceeded 44,305 gas. Therefore, we expect a minimum bounty covering a cost of 50,000 gas in even extreme gas markets (e.g. 1000 Gwei / gas) to reliably cover the
cost for a solver to provide a solution.

#### Sign a message given a public key
Given a random public key, the solver would need to sign a message, which the contract would verify to have been 
correctly signed by the public key. 
The downside to this approach is that the contract would act less like a leading indicator to secure ETH funds 
as by the time the puzzle is solved, the ability to forge signatures will have already been achieved.

#### Factor a product of large, generated primes
Instead of generating an RSA-UFO, the contract could implement current RSA key generation protocols and first generate 
two large primes to produces the product of the primes. 
This method has the flaw that the minter has the capability to see the primes, 
and therefore some level of trust would need to be given that the minter would throw the values away.

#### Decentralized trusted setup
This inherently has a trust factor, albeit very small. It requires that at least one person in the party is honest.
A fully trustless setup is preferred. However, further investigation may be done to potentially uncover a valid puzzle that uses a 
decentralized setup and has an advantage (perhaps with a lower cost or a greater leading indicator) worth the additional trust.


### Front running and censorship

One day is required before one can reveal a commitment. It is largely infeasible to censor an economically viable transaction for such a period of time.

Assuming the reveal transaction is willing to pay market rate for transaction fees, the 1559 fee mechanism and its exponential adjustment makes it infeasible for an economic attacker to spam costly transactions to artifically increase the base-fee for extended period of time.

Additionally, even if a large percentage of the proposers collude to censor, the inclusion of the reveal transaction on chain will be delayed but only as a function of the ratio of censoring to non-censoring proposers. E.g., if 90% of proposers censor, then the reveal transaction will take 10x as long as expected to be included -- on the order of 120s given mainnet block times. If, instead, 99% of proposers censor, then the transaction will take ~100x as long to be included -- on the order of 1200s. Still in these extreme regimes, reveal times on the order of a day are safe.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

[1]:
```csl-json
    {
      "type": "misc"
      "id": 1,
      "author"=[
        {
          "family": "Preskill",
          "given": "John"
        }
      ],
      "DOI": "10.48550/arXiv.1203.5813",
      "title": "Quantum computing and the entanglement frontier", 
      "original-date": {
        "date-parts": [
          [2012, 11, 10]
        ]
      },
      "URL": "https://doi.org/10.48550/arXiv.1203.5813"
    }
    ```
[2]:
```csl-json
    {
      "type": "article"
      "id": 2,
      "author"=[
        {
          "family": "Kim",
          "given": "Youngseok"
        },
        {
          "family": "Eddins",
          "given": "Andrew"
        },
        {
          "family": "Anand",
          "given": "Sajant"
        },
        {
          "family": "Wei",
          "given": "Ken Xuan"
        },
        {
          "family": "van den Berg",
          "given": "Ewout"
        },
        {
          "family": "Rosenblatt",
          "given": "Sami"
        },
        {
          "family": "Nayfeh",
          "given": "Hasan"
        },
        {
          "family": "Wu",
          "given": "Yantao"
        },
        {
          "family": "Zaletel",
          "given": "Michael"
        },
        {
          "family": "Temme",
          "given": "Kristan"
        },
        {
          "family": "Kandala",
          "given": "Abhinav"
        },
      ],
      "DOI": "10.1038/s41586-023-06096-3",
      "title": "Evidence for the utility of quantum computing before fault tolerance", 
      "original-date": {
        "date-parts": [
          [2023, 06, 15]
        ]
      },
      "URL": "https://doi.org/10.1038/s41586-023-06096-3"
    }
    ```
[3]:
```csl-json
    {
      "type": "article"
      "id": 2,
      "author"=[{"family": "Arute", "given": "Frank"}, {"family": "Arya", "given": "Kunal"}, {"family": "Babbush", "given": "Ryan"}, {"family": "Bacon", "given": "Dave"}, {"family": "Bardin", "given": "Joseph C."}, {"family": "Barends", "given": "Rami"}, {"family": "Biswas", "given": "Rupak"}, {"family": "Boixo", "given": "Sergio"}, {"family": "Brandao", "given": "Fernando G. S. L."}, {"family": "Buell", "given": "David A."}, {"family": "Burkett", "given": "Brian"}, {"family": "Chen", "given": "Yu"}, {"family": "Chen", "given": "Zijun"}, {"family": "Chiaro", "given": "Ben"}, {"family": "Collins", "given": "Roberto"}, {"family": "Courtney", "given": "William"}, {"family": "Dunsworth", "given": "Andrew"}, {"family": "Farhi", "given": "Edward"}, {"family": "Foxen", "given": "Brooks"}, {"family": "Fowler", "given": "Austin"}, {"family": "Gidney", "given": "Craig"}, {"family": "Giustina", "given": "Marissa"}, {"family": "Graff", "given": "Rob"}, {"family": "Guerin", "given": "Keith"}, {"family": "Habegger", "given": "Steve"}, {"family": "Harrigan", "given": "Matthew P."}, {"family": "Hartmann", "given": "Michael J."}, {"family": "Ho", "given": "Alan"}, {"family": "Hoffmann", "given": "Markus"}, {"family": "Huang", "given": "Trent"}, {"family": "Humble", "given": "Travis S."}, {"family": "Isakov", "given": "Sergei V."}, {"family": "Jeffrey", "given": "Evan"}, {"family": "Jiang", "given": "Zhang"}, {"family": "Kafri", "given": "Dvir"}, {"family": "Kechedzhi", "given": "Kostyantyn"}, {"family": "Kelly", "given": "Julian"}, {"family": "Klimov", "given": "Paul V."}, {"family": "Knysh", "given": "Sergey"}, {"family": "Korotkov", "given": "Alexander"}, {"family": "Kostritsa", "given": "Fedor"}, {"family": "Landhuis", "given": "David"}, {"family": "Lindmark", "given": "Mike"}, {"family": "Lucero", "given": "Erik"}, {"family": "Lyakh", "given": "Dmitry"}, {"family": "Mandr{\\`a}", "given": "Salvatore"}, {"family": "McClean", "given": "Jarrod R."}, {"family": "McEwen", "given": "Matthew"}, {"family": "Megrant", "given": "Anthony"}, {"family": "Mi", "given": "Xiao"}, {"family": "Michielsen", "given": "Kristel"}, {"family": "Mohseni", "given": "Masoud"}, {"family": "Mutus", "given": "Josh"}, {"family": "Naaman", "given": "Ofer"}, {"family": "Neeley", "given": "Matthew"}, {"family": "Neill", "given": "Charles"}, {"family": "Niu", "given": "Murphy Yuezhen"}, {"family": "Ostby", "given": "Eric"}, {"family": "Petukhov", "given": "Andre"}, {"family": "Platt", "given": "John C."}, {"family": "Quintana", "given": "Chris"}, {"family": "Rieffel", "given": "Eleanor G."}, {"family": "Roushan", "given": "Pedram"}, {"family": "Rubin", "given": "Nicholas C."}, {"family": "Sank", "given": "Daniel"}, {"family": "Satzinger", "given": "Kevin J."}, {"family": "Smelyanskiy", "given": "Vadim"}, {"family": "Sung", "given": "Kevin J."}, {"family": "Trevithick", "given": "Matthew D."}, {"family": "Vainsencher", "given": "Amit"}, {"family": "Villalonga", "given": "Benjamin"}, {"family": "White", "given": "Theodore"}, {"family": "Yao", "given": "Z. Jamie"}, {"family": "Yeh", "given": "Ping"}, {"family": "Zalcman", "given": "Adam"}, {"family": "Neven", "given": "Hartmut"}, {"family": "Martinis", "given": "John M."}],
      "DOI": "10.1038/s41586-019-1666-5",
      "title": "Quantum supremacy using a programmable superconducting processor", 
      "original-date": {
        "date-parts": [
          [2019, 08, 24]
        ]
      },
      "URL": "https://doi.org/10.1038/s41586-019-1666-5"
    }
    ```
[4]:
```csl-json
    {
      "type": "misc"
      "id": 4,
      "author"=[{"family": "Morvan", "given": "A."}, {"family": "Villalonga", "given": "B."}, {"family": "Mi", "given": "X."}, {"family": "Mandr\u00e0", "given": "S."}, {"family": "Bengtsson", "given": "A."}, {"family": "V.", "given": "P."}, {"family": "Chen", "given": "Z."}, {"family": "Hong", "given": "S."}, {"family": "Erickson", "given": "C."}, {"family": "K.", "given": "I."}, {"family": "Chau", "given": "J."}, {"family": "Laun", "given": "G."}, {"family": "Movassagh", "given": "R."}, {"family": "Asfaw", "given": "A."}, {"family": "T.", "given": "L."}, {"family": "Peralta", "given": "R."}, {"family": "Abanin", "given": "D."}, {"family": "Acharya", "given": "R."}, {"family": "Allen", "given": "R."}, {"family": "I.", "given": "T."}, {"family": "Anderson", "given": "K."}, {"family": "Ansmann", "given": "M."}, {"family": "Arute", "given": "F."}, {"family": "Arya", "given": "K."}, {"family": "Atalaya", "given": "J."}, {"family": "C.", "given": "J."}, {"family": "Bilmes", "given": "A."}, {"family": "Bortoli", "given": "G."}, {"family": "Bourassa", "given": "A."}, {"family": "Bovaird", "given": "J."}, {"family": "Brill", "given": "L."}, {"family": "Broughton", "given": "M."}, {"family": "B.", "given": "B."}, {"family": "A.", "given": "D."}, {"family": "Burger", "given": "T."}, {"family": "Burkett", "given": "B."}, {"family": "Bushnell", "given": "N."}, {"family": "Campero", "given": "J."}, {"family": "S.", "given": "H."}, {"family": "Chiaro", "given": "B."}, {"family": "Chik", "given": "D."}, {"family": "Chou", "given": "C."}, {"family": "Cogan", "given": "J."}, {"family": "Collins", "given": "R."}, {"family": "Conner", "given": "P."}, {"family": "Courtney", "given": "W."}, {"family": "L.", "given": "A."}, {"family": "Curtin", "given": "B."}, {"family": "M.", "given": "D."}, {"family": "Del", "given": "A."}, {"family": "Demura", "given": "S."}, {"family": "Di", "given": "A."}, {"family": "Dunsworth", "given": "A."}, {"family": "Faoro", "given": "L."}, {"family": "Farhi", "given": "E."}, {"family": "Fatemi", "given": "R."}, {"family": "S.", "given": "V."}, {"family": "Flores", "given": "L."}, {"family": "Forati", "given": "E."}, {"family": "G.", "given": "A."}, {"family": "Foxen", "given": "B."}, {"family": "Garcia", "given": "G."}, {"family": "Genois", "given": "E."}, {"family": "Giang", "given": "W."}, {"family": "Gidney", "given": "C."}, {"family": "Gilboa", "given": "D."}, {"family": "Giustina", "given": "M."}, {"family": "Gosula", "given": "R."}, {"family": "Grajales", "given": "A."}, {"family": "A.", "given": "J."}, {"family": "Habegger", "given": "S."}, {"family": "C.", "given": "M."}, {"family": "Hansen", "given": "M."}, {"family": "P.", "given": "M."}, {"family": "D.", "given": "S."}, {"family": "Heu", "given": "P."}, {"family": "R.", "given": "M."}, {"family": "Huang", "given": "T."}, {"family": "Huff", "given": "A."}, {"family": "J.", "given": "W."}, {"family": "B.", "given": "L."}, {"family": "V.", "given": "S."}, {"family": "Iveland", "given": "J."}, {"family": "Jeffrey", "given": "E."}, {"family": "Jiang", "given": "Z."}, {"family": "Jones", "given": "C."}, {"family": "Juhas", "given": "P."}, {"family": "Kafri", "given": "D."}, {"family": "Khattar", "given": "T."}, {"family": "Khezri", "given": "M."}, {"family": "Kieferov\u00e1", "given": "M."}, {"family": "Kim", "given": "S."}, {"family": "Kitaev", "given": "A."}, {"family": "R.", "given": "A."}, {"family": "N.", "given": "A."}, {"family": "Kostritsa", "given": "F."}, {"family": "M.", "given": "J."}, {"family": "Landhuis", "given": "D."}, {"family": "Laptev", "given": "P."}, {"family": "-M.", "given": "K."}, {"family": "Laws", "given": "L."}, {"family": "Lee", "given": "J."}, {"family": "W.", "given": "K."}, {"family": "D.", "given": "Y."}, {"family": "J.", "given": "B."}, {"family": "T.", "given": "A."}, {"family": "Liu", "given": "W."}, {"family": "Locharla", "given": "A."}, {"family": "D.", "given": "F."}, {"family": "Martin", "given": "O."}, {"family": "Martin", "given": "S."}, {"family": "R.", "given": "J."}, {"family": "McEwen", "given": "M."}, {"family": "C.", "given": "K."}, {"family": "Mieszala", "given": "A."}, {"family": "Montazeri", "given": "S."}, {"family": "Mruczkiewicz", "given": "W."}, {"family": "Naaman", "given": "O."}, {"family": "Neeley", "given": "M."}, {"family": "Neill", "given": "C."}, {"family": "Nersisyan", "given": "A."}, {"family": "Newman", "given": "M."}, {"family": "H.", "given": "J."}, {"family": "Nguyen", "given": "A."}, {"family": "Nguyen", "given": "M."}, {"family": "Yuezhen", "given": "M."}, {"family": "E.", "given": "T."}, {"family": "Omonije", "given": "S."}, {"family": "Opremcak", "given": "A."}, {"family": "Petukhov", "given": "A."}, {"family": "Potter", "given": "R."}, {"family": "P.", "given": "L."}, {"family": "Quintana", "given": "C."}, {"family": "M.", "given": "D."}, {"family": "Rocque", "given": "C."}, {"family": "Roushan", "given": "P."}, {"family": "C.", "given": "N."}, {"family": "Saei", "given": "N."}, {"family": "Sank", "given": "D."}, {"family": "Sankaragomathi", "given": "K."}, {"family": "J.", "given": "K."}, {"family": "F.", "given": "H."}, {"family": "Schuster", "given": "C."}, {"family": "J.", "given": "M."}, {"family": "Shorter", "given": "A."}, {"family": "Shutty", "given": "N."}, {"family": "Shvarts", "given": "V."}, {"family": "Sivak", "given": "V."}, {"family": "Skruzny", "given": "J."}, {"family": "C.", "given": "W."}, {"family": "D.", "given": "R."}, {"family": "Sterling", "given": "G."}, {"family": "Strain", "given": "D."}, {"family": "Szalay", "given": "M."}, {"family": "Thor", "given": "D."}, {"family": "Torres", "given": "A."}, {"family": "Vidal", "given": "G."}, {"family": "Vollgraff", "given": "C."}, {"family": "White", "given": "T."}, {"family": "W.", "given": "B."}, {"family": "Xing", "given": "C."}, {"family": "J.", "given": "Z."}, {"family": "Yeh", "given": "P."}, {"family": "Yoo", "given": "J."}, {"family": "Young", "given": "G."}, {"family": "Zalcman", "given": "A."}, {"family": "Zhang", "given": "Y."}, {"family": "Zhu", "given": "N."}, {"family": "Zobrist", "given": "N."}, {"family": "G.", "given": "E."}, {"family": "Biswas", "given": "R."}, {"family": "Babbush", "given": "R."}, {"family": "Bacon", "given": "D."}, {"family": "Hilton", "given": "J."}, {"family": "Lucero", "given": "E."}, {"family": "Neven", "given": "H."}, {"family": "Megrant", "given": "A."}, {"family": "Kelly", "given": "J."}, {"family": "Aleiner", "given": "I."}, {"family": "Smelyanskiy", "given": "V."}, {"family": "Kechedzhi", "given": "K."}, {"family": "Chen", "given": "Y."}, {"family": "Boixo", "given": "S."}],
      "DOI": "10.48550/arXiv.2304.11119",
      "title": "Phase transition in Random Circuit Sampling", 
      "original-date": {
        "date-parts": [
          [2023, 04, 21]
        ]
      },
      "URL": "https://doi.org/10.48550/arXiv.2304.11119"
    }
    ```
[5]:
```csl-json
    {
      "type": "misc"
      "id": 5,
      "author"=[{"family": "Begušić", "given": "Tomislav"}, {"family": "Kin-Lic Chan", "given": "Garnet"}],
      "DOI": "10.48550/arXiv.2306.16372",
      "title": "Fast classical simulation of evidence for the utility of quantum computing before fault tolerance", 
      "original-date": {
        "date-parts": [
          [2023, 06, 28]
        ]
      },
      "URL": "https://doi.org/10.48550/arXiv.2306.16372"
    }
    ```
[6]:
```csl-json
    {
      "type": "misc"
      "id": 6,
      "author"=[{"family": "Pednault", "given": "Edwin"}, {"family": "Gunnels", "given": "John A."}, {"family": "Nannicini", "given": "Giacomo"}, {"family": "Horesh", "given": "Lior"}, {"family": "Wisnieff", "given": "Robert"}],
      "DOI": "10.48550/arXiv.1910.09534",
      "title": "Leveraging Secondary Storage to Simulate Deep 54-qubit Sycamore Circuits", 
      "original-date": {
        "date-parts": [
          [2019, 08, 22]
        ]
      },
      "URL": "https://doi.org/10.48550/arXiv.1910.09534",
      "custom": {
        "additional-urls": [
          "https://api.semanticscholar.org/CorpusID:204800933"
        ]
      }
    ```
[7]:
```csl-json
    {
      "type": "article"
      "id": 7,
      "author"=[{"family": "Castelvecchi", "given": "Davide"}],
      "DOI": "10.1038/d41586-023-00017-0",
      "title": "Are quantum computers about to break online privacy?", 
      "original-date": {
        "date-parts": [
          [2023, 01, 06]
        ]
      },
      "URL": "https://doi.org/10.1038/d41586-023-00017-0"
    ```
[8]:
```csl-json
    {
      "type": "article"
      "id": 8,
      "author"=[{"family": "Shor", "given": "Peter W."}],
      "DOI": "10.1137/S0097539795293172",
      "title": "Polynomial-Time Algorithms for Prime Factorization and Discrete Logarithms on a Quantum Computer", 
      "original-date": {
        "date-parts": [
          [1995, 01, 25]
        ]
      },
      "URL": "https://doi.org/10.1137/S0097539795293172"
    ```
[9]:
```csl-json
    {
      "type": "article"
      "id": 10,
      "author"=[{"family": "Erdös", "given": "P."}, {"family": "Kac", "given": "M."}],
      "DOI": "10.2307/2371483",
      "title": "The Gaussian Law of Errors in the Theory of Additive Number Theoretic Functions", 
      "original-date": {
        "date-parts": [
          [1940, 04]
        ]
      },
      "URL": "https://www.semanticscholar.org/paper/The-Gaussian-Law-of-Errors-in-the-Theory-of-Number-Erd%C3%B6s-Kac/261864821aa770542be65dbe16640684ab786fa9",
      "custom": {
        "additional-urls": [
          "https://doi.org/10.2307/2371483"
        ]
      }
    ```
[10]:
```csl-json
    {
      "type": "article"
      "id": 11,
      "author"=[{"family": "Woll", "given": "Heather"}],
      "DOI": "10.1016/0890-5401(87)90030-7",
      "title": "Reductions among number theoretic problems", 
      "original-date": {
        "date-parts": [
          [1986, 07, 02]
        ]
      },
      "URL": "https://doi.org/10.1016/0890-5401(87)90030-7"
    ```
[11]:
```csl-json
    {
      "type": "inproceedings"
      "id": 9,
      "author"=[{"family": "Sander", "given": "Tomas"}],
      "DOI": "10.1007/978-3-540-47942-0_21",
      "title": "Efficient Accumulators without Trapdoor Extended Abstract", 
      "original-date": {
        "date-parts": [
          [1999, 09, 11]
        ]
      },
      "custom": {
        "additional-urls": [
          "https://doi.org/10.1007/978-3-540-47942-0_21"
        ]
      }
    ```
[12]:
```csl-json
    {
      "type": "misc"
      "id": 13,
      "author"=[{"family": "Roetteler", "given": "Martin"}, {"family": "Naehrig", "given": "Michael"}, {"family": "Svore", "given": "Krysta M."}, {"family": "Lauter", "given": "Kristin"}],
      "DOI": "10.48550/arXiv.1706.06752",
      "title": "Quantum resource estimates for computing elliptic curve discrete logarithms", 
      "original-date": {
        "date-parts": [
          [2017, 08, 31]
        ]
      },
      "URL": "https://doi.org/10.48550/arXiv.1706.06752"
    ```
[13]:
```csl-json
    {
      "type": "article"
      "id": 14,
      "author"=[{"family": "Webber", "given": "Mark"}, {"family": "Elfving", "given": "Vincent"}, {"family": "Weidt", "given": "Sebastian"}, {"family": "Hensinger", "given": "Winfried K."}],
      "DOI": "10.1116/5.0073075",
      "title": "The impact of hardware specifications on reaching quantum advantage in the fault tolerant regime", 
      "original-date": {
        "date-parts": [
          [2022, 01, 15]
        ]
      },
      "URL": "https://doi.org/10.1116/5.0073075"
    ```
[14]:
```csl-json
    {
      "type": "misc"
      "id": 12,
      "author"=[{"family": "Cleve", "given": "Richard"}],
      "DOI": "10.1016/j.ic.2004.04.001",
      "title": "The query complexity of order-finding", 
      "original-date": {
        "date-parts": [
          [1999, 11, 30]
        ]
      },
      "URL": "https://doi.org/10.1016/j.ic.2004.04.001"
      "custom": {
        "additional-urls": [
          "https://doi.org/10.48550/arXiv.quant-ph/9911124"
        ]
      }
    ```
[ERC-2470]: ./eip-2470.md
