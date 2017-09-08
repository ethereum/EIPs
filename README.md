# EIPs [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

# Contributing
First review [EIP-1](EIPS/eip-1.md). Then clone the repository and add your EIP to it. There is a [template EIP here](eip-X.md). Then submit a Pull Request to Ethereum's [EIPs repository](https://github.com/ethereum/EIPs).

# EIP status terms
* **Draft** - an EIP that is open for consideration
* **Accepted** - an EIP that is planned for immediate adoption, i.e. expected to be included in the next hard fork (for Core/Consensus layer EIPs).
* **Final** - an EIP that has been adopted in a previous hard fork (for Core/Consensus layer EIPs).
* **Deferred** - an EIP that is not being considered for immediate adoption. May be reconsidered in the future for a subsequent hard fork.

# Accepted EIPs (planned for adoption)
| Number                                                  |Title                                                                                | Author                | Layer       | Status    |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------- | --------------------  | ------------| ----------|
| [100](https://github.com/ethereum/EIPs/issues/100)      | Change difficulty adjustment to target mean block time including uncles             | Vitalik Buterin       | Core        | Accepted  |
| [140](https://github.com/ethereum/EIPs/pull/206)        | REVERT instruction in the Ethereum Virtual Machine                                  | Beregszaszi, Mushegian| Core        | Accepted  |
| [196](https://github.com/ethereum/EIPs/pull/213)        | Precompiled contracts for addition and scalar multiplication on the elliptic curve alt_bn128 | Reitwiessner | Core        | Accepted  |
| [197](https://github.com/ethereum/EIPs/pull/212)        | Precompiled contracts for optimal Ate pairing check on the elliptic curve alt_bn128 | Buterin, Reitwiessner | Core        | Accepted  |
| [198](https://github.com/ethereum/EIPs/pull/198)        | Precompiled contract for bigint modular exponentiation                              | Vitalik Buterin       | Core        | Accepted  |
| [211](https://github.com/ethereum/EIPs/pull/211)        | New opcodes: RETURNDATASIZE and RETURNDATACOPY                                      | Christian Reitwiessner| Core        | Accepted  |
| [214](https://github.com/ethereum/EIPs/pull/214)        | New opcode STATICCALL                                                               | Buterin, Reitwiessner | Core        | Accepted  |
| [649](https://github.com/ethereum/EIPs/pull/669)        | Metropolis Difficulty Bomb Delay and Block Reward Reduction                         | Schoedon, Buterin     | Core        | Accepted  |
| [658](https://github.com/ethereum/EIPs/pull/658)        | Embedding transaction return data in receipts                                       | Nick Johnson          | Core        | Accepted  |

# Deferred EIPs (adoption postponed)
| Number                                                  |Title                                                                                | Author                | Layer       | Status    |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------- | --------------------  | ------------| ----------|
| [86](https://github.com/ethereum/EIPs/pull/208)         | Abstraction of transaction origin and signature                                     | Vitalik Buterin       | Core        | Deferred  |
| [96](https://github.com/ethereum/EIPs/pull/210)         | Blockhash refactoring                                                               | Vitalik Buterin       | Core        | Deferred  |

# Finalized EIPs (standards that have been adopted)
| Number                                                  |Title                                                        | Author          | Layer       | Status  |
| ------------------------------------------------------- | ----------------------------------------------------------- | ----------------| ------------| --------|
| [2](EIPS/eip-2.md)                                      | Homestead Hard-fork Changes                                 | Vitalik Buterin | Core        | Final   |
| [6](EIPS/eip-6.md)                                      | Renaming Suicide Opcode                                     | Hudson Jameson  | Interface   | Final   |
| [7](EIPS/eip-7.md)                                      | DELEGATECALL                                                | Vitalik Buterin | Core        | Final   |
| [8](EIPS/eip-8.md)                                      | devp2p Forward Compatibility Requirements for Homestead     | Felix Lange     | Networking  | Final   |
| [141](EIPS/eip-141.md)                                  | Designated invalid EVM instruction                          | Alex Beregszaszi| Core        | Final   |
| [150](EIPS/eip-150.md)                                  | Gas cost changes for IO-heavy operations                    | Vitalik Buterin | Core        | Final   |
| [155](EIPS/eip-155.md)                                  | Simple replay attack protection                             | Vitalik Buterin | Core        | Final   |
| [160](EIPS/eip-160.md)                                  | EXP cost increase                                           | Vitalik Buterin | Core        | Final   |
| [161](EIPS/eip-161.md)                                  | State trie clearing (invariant-preserving alternative)      | Gavin Wood      | Core        | Final   |
| [170](EIPS/eip-170.md)                                  | Contract code size limit                                    | Vitalik Buterin | Core        | Final   |
