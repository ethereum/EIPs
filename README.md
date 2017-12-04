# EIPs [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

# Contributing
First review [EIP-1](EIPS/eip-1.md). Then clone the repository and add your EIP to it. There is a [template EIP here](eip-X.md). Then submit a Pull Request to Ethereum's [EIPs repository](https://github.com/ethereum/EIPs).

# EIP status terms
* **Draft** - an EIP that is open for consideration
* **Accepted** - an EIP that is planned for immediate adoption, i.e. expected to be included in the next hard fork (for Core/Consensus layer EIPs).
* **Final** - an EIP that has been adopted in a previous hard fork (for Core/Consensus layer EIPs).
* **Deferred** - an EIP that is not being considered for immediate adoption. May be reconsidered in the future for a subsequent hard fork.

# Deferred EIPs (adoption postponed until the Constantinople Metropolis hard fork)
| Number                                             | Title                                                                                        | Author                                     | Layer      | Status   |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------ | ---------- | -------- |
| [86](https://github.com/ethereum/EIPs/pull/208)    | Abstraction of transaction origin and signature                                              | Vitalik Buterin                            | Core       | Deferred |
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
| [55](EIPS/eip-55.md)                               | ERC-55 Mixed-case checksum address encoding                                                  | Vitalik Buterin                            | ERC       | Final    |
| [100](https://github.com/ethereum/EIPs/issues/100) | Change difficulty adjustment to target mean block time including uncles                      | Vitalik Buterin                            | Core       | Final    |
| [137](EIPS/eip-137.md)                             | Ethereum Domain Name Service - Specification                                                 | Nick Johnson                               | ERC        | Final    |
| [140](https://github.com/ethereum/EIPs/pull/206)   | REVERT instruction in the Ethereum Virtual Machine                                           | Alex Beregszaszi, Nikolai Mushegian        | Core       | Final    |
| [141](EIPS/eip-141.md)                             | Designated invalid EVM instruction                                                           | Alex Beregszaszi                           | Core       | Final    |
| [150](EIPS/eip-150.md)                             | Gas cost changes for IO-heavy operations                                                     | Vitalik Buterin                            | Core       | Final    |
| [155](EIPS/eip-155.md)                             | Simple replay attack protection                                                              | Vitalik Buterin                            | Core       | Final    |
| [160](EIPS/eip-160.md)                             | EXP cost increase                                                                            | Vitalik Buterin                            | Core       | Final    |
| [161](EIPS/eip-161.md)                             | State trie clearing (invariant-preserving alternative)                                       | Gavin Wood                                 | Core       | Final    |
| [162](EIPS/eip-162.md)                             | ERC-162 ENS support for reverse resolution of Ethereum addresses                             | Maurelian, Nick Johnson                    | ERC        | Final    |
| [170](EIPS/eip-170.md)                             | Contract code size limit                                                                     | Vitalik Buterin                            | Core       | Final    |
| [181](EIPS/eip-181.md)                             | ERC-181 ENS support for reverse resolution of Ethereum addresses                             | Nick Johnson                               | ERC        | Final    |
| [190](EIPS/eip-190.md)                             | ERC-190 Ethereum Smart Contract Packaging Standard                                           | Merriam, Coulter, Erfurt, Catalano, Matias | ERC        | Final    |
| [196](https://github.com/ethereum/EIPs/pull/213)   | Precompiled contracts for addition and scalar multiplication on the elliptic curve alt_bn128 | Christian Reitwiessner                     | Core       | Final    |
| [197](https://github.com/ethereum/EIPs/pull/212)   | Precompiled contracts for optimal Ate pairing check on the elliptic curve alt_bn128          | Vitalik Buterin, Christian Reitwiessner    | Core       | Final    |
| [198](https://github.com/ethereum/EIPs/pull/198)   | Precompiled contract for bigint modular exponentiation                                       | Vitalik Buterin                            | Core       | Final    |
| [211](https://github.com/ethereum/EIPs/pull/211)   | New opcodes: RETURNDATASIZE and RETURNDATACOPY                                               | Christian Reitwiessner                     | Core       | Final    |
| [214](https://github.com/ethereum/EIPs/pull/214)   | New opcode STATICCALL                                                                        | Vitalik Buterin, Christian Reitwiessner    | Core       | Final    |
| [606](EIPS/eip-606.md)                             | Hardfork Meta: Homestead                                                                     | Alex Beregszaszi                           | Meta       | Final    |
| [607](EIPS/eip-607.md)                             | Hardfork Meta: Spurious Dragon                                                               | Alex Beregszaszi                           | Meta       | Final    |
| [608](EIPS/eip-608.md)                             | Hardfork Meta: Tangerine Whistle                                                             | Alex Beregszaszi                           | Meta       | Final    |
| [609](EIPS/eip-609.md)                             | Hardfork Meta: Byzantium                                                                     | Alex Beregszaszi                           | Meta       | Final    |
| [649](https://github.com/ethereum/EIPs/pull/669)   | Metropolis Difficulty Bomb Delay and Block Reward Reduction                                  | Afri Schoedon, Vitalik Buterin             | Core       | Final    |
| [658](https://github.com/ethereum/EIPs/pull/658)   | Embedding transaction return data in receipts                                                | Nick Johnson                               | Core       | Final    |
| [706](EIPS/eip-706.md)                             | DEVp2p snappy compression                                                                    | Péter Szilágyi                             | Networking | Final    |
