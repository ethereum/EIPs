# EIPs [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

# Contributing
First review [EIP-1](EIPS/eip-1.md). Then clone the repository and add your EIP to it. There is a [template EIP here](eip-X.md). Then submit a Pull Request to Ethereum's [EIPs repository](https://github.com/ethereum/EIPs).

# EIP status terms
* **Draft** - an EIP that is open for consideration
* **Accepted** - an EIP that is planned for immediate adoption, i.e. expected to be included in the next hard fork (for Core/Consensus layer EIPs).
* **Final** - an EIP that has been adopted in a previous hard fork (for Core/Consensus layer EIPs).
* **Deferred** - an EIP that is not being considered for immediate adoption. May be reconsidered in the future for a subsequent hard fork.

# Non-final EIPs
| Number                    | Title                                                   | Author                        | Layer     | Status     |
| ------------------------- | ------------------------------------------------------- | ----------------------------- | --------- | ---------- |
| [3](EIPS/eip-3.mediawiki) |  Addition of CALLDEPTH opcode                           | Martin Holst Swende           | Core      | Draft      |
| [4](EIPS/eip-4.md)        |  EIP Classification                                     | Joseph Chow                   | Meta      | Draft      |
| [5](EIPS/eip-5.md)        |  Gas Usage for `RETURN` and `CALL*`                     | Christian Reitwiessner        | Core      | Draft      |
| [101](EIPS/eip-101.md)    |  Serenity Currency and Crypto Abstraction               | Vitalik Buterin               |           | Active     |
| [158](EIPS/eip-158.md)    |  State clearing                                         | Vitalik Buterin               | Core      | Superseded |
| [165](EIPS/eip-165.md)    |  ERC-165 Standard Interface Detection                   | Christian Reitwiessner        | Interface    | Draft |
| [234](EIPS/eip-234.md)    |  Add `blockHash` to JSON-RPC filter options             | Micah Zoltu                   | Interface | Draft      |
| [615](EIPS/eip-615.md)    |  Subroutines and Static Jumps for the EVM               | Greg Colvin                   | Core   | Draft      |
| [616](EIPS/eip-616.md)    |  SIMD Operations for the EVM                            | Greg Colvin                   | Core      | Draft      |
| [681](EIPS/eip-681.md)    |  ERC-681 URL Format for Transaction Requests  | Daniel A. Nagy                 | Interface | Draft      |
| [758](EIPS/eip-758.md)    |  Subscriptions and filters for transaction return data  | Jack Peterson                 | Interface | Draft      |
| [801](EIPS/eip-801.md)    |  ERC-801 Canary Standard                                | ligi                          | Interface | Draft      |

# Deferred EIPs
| Number                                             | Title                                                                                        | Author                                     | Layer      | Status   |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------ | ---------- | -------- |
| [86](https://github.com/ethereum/EIPs/pull/208)    | Abstraction of transaction origin and signature                                              | Vitalik Buterin                            | Core       | Deferred (to be replaced) |
| [96](https://github.com/ethereum/EIPs/pull/210)    | Blockhash refactoring                                                                        | Vitalik Buterin                            | Core       | Deferred |
| [145](EIPS/eip-145.md)                             | Bitwise shifting instructions in EVM                                                         | Alex Beregszaszi, Paweł Bylica             | Core       | Deferred |

# Finalized EIPs (standards that have been adopted)
| Number                                             | Title                                                                                        | Author                                     | Layer      | Status   |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------| ---------- | -------- |
| [2](EIPS/eip-2.md)                                 | Homestead Hard-fork Changes                                                                  | Vitalik Buterin                            | Core       | Final    |
| [6](EIPS/eip-6.md)                                 | Renaming Suicide Opcode                                                                      | Hudson Jameson                             | Interface  | Final    |
| [7](EIPS/eip-7.md)                                 | DELEGATECALL                                                                                 | Vitalik Buterin                            | Core       | Final    |
| [8](EIPS/eip-8.md)                                 | devp2p Forward Compatibility Requirements for Homestead                                      | Felix Lange                                | Networking | Final    |
| [20](EIPS/eip-20-token-standard.md)                | ERC-20 Token Standard                                                                        | Fabian Vogelsteller, Vitalik Buterin       | ERC        | Final    |
| [55](EIPS/eip-55.md)                               | ERC-55 Mixed-case checksum address encoding                                                  | Vitalik Buterin                            | ERC        | Final    |
| [100](https://github.com/ethereum/EIPs/issues/100) | Change difficulty adjustment to target mean block time including uncles                      | Vitalik Buterin                            | Core       | Final    |
| [137](EIPS/eip-137.md)                             | Ethereum Domain Name Service - Specification                                                 | Nick Johnson                               | ERC        | Final    |
| [140](https://github.com/ethereum/EIPs/pull/206)   | REVERT instruction                                                                           | Alex Beregszaszi, Nikolai Mushegian        | Core       | Final    |
| [141](EIPS/eip-141.md)                             | Designated invalid EVM instruction                                                           | Alex Beregszaszi                           | Core       | Final    |
| [150](EIPS/eip-150.md)                             | Gas cost changes for IO-heavy operations                                                     | Vitalik Buterin                            | Core       | Final    |
| [155](EIPS/eip-155.md)                             | Simple replay attack protection                                                              | Vitalik Buterin                            | Core       | Final    |
| [160](EIPS/eip-160.md)                             | EXP cost increase                                                                            | Vitalik Buterin                            | Core       | Final    |
| [161](EIPS/eip-161.md)                             | State trie clearing (invariant-preserving alternative)                                       | Gavin Wood                                 | Core       | Final    |
| [162](EIPS/eip-162.md)                             | ERC-162 Initial ENS Hash Registrar                                                           | Maurelian, Nick Johnson                    | ERC        | Final    |
| [170](EIPS/eip-170.md)                             | Contract code size limit                                                                     | Vitalik Buterin                            | Core       | Final    |
| [181](EIPS/eip-181.md)                             | ERC-181 ENS support for reverse resolution of Ethereum addresses                             | Nick Johnson                               | ERC        | Final    |
| [190](EIPS/eip-190.md)                             | ERC-190 Ethereum Smart Contract Packaging Standard                                           | Merriam, Coulter, Erfurt, Catalano, Matias | ERC        | Final    |
| [196](https://github.com/ethereum/EIPs/pull/213)   | Precompiled contracts for addition and scalar multiplication on the elliptic curve alt_bn128 | Christian Reitwiessner                     | Core       | Final    |
| [197](https://github.com/ethereum/EIPs/pull/212)   | Precompiled contracts for optimal Ate pairing check on the elliptic curve alt_bn128          | Vitalik Buterin, Christian Reitwiessner    | Core       | Final    |
| [198](https://github.com/ethereum/EIPs/pull/198)   | Precompiled contract for bigint modular exponentiation                                       | Vitalik Buterin                            | Core       | Final    |
| [211](https://github.com/ethereum/EIPs/pull/211)   | New opcodes: RETURNDATASIZE and RETURNDATACOPY                                               | Christian Reitwiessner                     | Core       | Final    |
| [214](https://github.com/ethereum/EIPs/pull/214)   | New opcode STATICCALL                                                                        | Vitalik Buterin, Christian Reitwiessner    | Core       | Final    |
| [649](https://github.com/ethereum/EIPs/pull/669)   | Metropolis Difficulty Bomb Delay and Block Reward Reduction                                  | Afri Schoedon, Vitalik Buterin             | Core       | Final    |
| [658](https://github.com/ethereum/EIPs/pull/658)   | Embedding transaction status code in receipts                                                | Nick Johnson                               | Core       | Final    |
| [706](EIPS/eip-706.md)                             | DEVp2p snappy compression                                                                    | Péter Szilágyi                             | Networking | Final    |

# Active EIPs (standards that have been adopted but never meant to be completed)

| Number                                             | Title                                                                                        | Author                                     | Layer      | Status   |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------| ---------- | -------- |
| [1](EIPS/eip-1.md)                                 | EIP Purpose and Guidelines                                                                   | Martin Becze, Hudson Jameson               | Meta       | Active    |

# Past Hard Forks
| Codename                              | Aliases                     | Block number   | Date (UTC) |
|-------------------------------------- |---------------------------- |----------------|------------|
| [Homestead](EIPS/eip-606.md)          |                             | 1,150,000      | 2016-03-14 |
| [DAO Fork](EIPS/eip-779.md)           |                             | 1,920,000      | 2016-07-20 |
| [Tangerine Whistle](EIPS/eip-608.md)  | Anti-DoS, EIP 150           | 2,463,000      | 2016-10-18 |
| [Spurious Dragon](EIPS/eip-607.md)    | State-clearing, EIP 158/161 | 2,675,000      | 2016-11-22 |
| [Byzantium](EIPS/eip-609.md)          | Metropolis: Part 1          | 4,730,000      | 2017-10-16 |
