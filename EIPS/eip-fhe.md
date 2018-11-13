---
eip: 760
title: Homomorphically encrypted storage
author:	silur <huohuli@protonmail.ch>
type: Standard Track
category: Core
status: Draft
created: 2017-11-07
---

## Simple Summary
Storages could include a layer where data is stored and handled by the same opcodes using fully homomorphic encryption, allowing to store and evaluate any boolean logic on confidental data while
preserving concensus on modifications.

## Abstract
Byzantium upgrade made zk-snarks possible but as we know with zk-snarks, data doesn't actually move only the validity of the commitment provided on the data.
Fully homomorphic encryption allows anyone to bootstrap a "storage-key" for their data which allows any endparty to execute mutually agreed boolean circuits on
encrypted data, without decrypting it, including searching and indexing too. This allows secure storage and operations on healthcare records or customer databases, enabling services easy compliance with EU GDPR. Concensus about data modification will still be transparent for storage keys are stored in the contracts.

## Motivation
A very common problem among people who wants to migrate or enter their business to blockchains is that they cannot put confidential data into a public ledger,
although they still need to overcome distrust between different types of customers. Uploading critical business data into a blockchain where competitors or unauthorized personnel can scrape and analyze it is not an option so in all cases these parties stay with the centralized non-transparent model.
This EIP issues this problem with enabling distribution of existing infrastructures on the blockchain, without exposing sensitive data into publicity.

## Specification

Contract storages will have a subset (or extension?) dedicated for encrypted data with a map of storage-keys on which can operate on a specified offset range.
Bootstrapping is implemented using learning with errors which is known to be as hard as lattice shortest-vector problems (are quantum-resistant by design),
and allow near-infinite amounts of operations on secrets.

Implementation should include a flag of LWE-depth and noise `n`. Boolean primitives `x` are handled as gadget matrices (generated with a decomposition
function `D(v))` with the restriction that there exists an LWE sample outputing a small vector `u` where `ux -v` are less or equal to an agreed precision (see Gentry-Saha-Waters).
Decomposition algorithms shall include entropy to keep error limits independent.
Operating on encrypted data with these gadgets are possible with the use of a key-switching context which will output another sample with a different key
on the same data with only negligible difference on the noise parameter, which enables us billions of consequential switches.
Specifically the key-switching takes k LWE sample ciphertexts, an R-lipschitzian morphism of Z-modules, a key sample KS with noise limit `l`, and `Aks` and `Vks`
being the amplitude and variance of error, the algorithm shall output:
`||error(c)||∞ <= R||error(c)||∞  + nt*n*Aks + n*2^-(t+1)` in worst case and
`variance(error(c)) <= R^2*variance(error(c)) + nt*n*Vks + n*2^(2*(t+1))` in average case

One way to implement this without introducing an equivalent opcode for each circuit operator in EVM would be to make only 2 new opcodes `FHEE` and `FHEL` to enter and leave `FHE` context that indicates that opcodes in the section should perform their equivalents on the specified FHE circuit descriptor left on the top of stack before calling `FHEE`.

Most of the mathematical design is based on the academic works of Ilaria Chillotti1, Nicolas Gama, Mariya Georgieva, and Malika Izabachene, cryptology ePrint 2017/430
## Rationale
An operation context-switching flag was decided so the same opcodes in the VM that can handle encrypted data with only knowledge of the context and the circuit descriptor.
TLWE was choosen for it's extremely fast bootstraping and quasi-limitless homomorphic property which is a huge step in homomorphic encryption.
## Backwards Compatibility
VM implementations without this feature should revert on encountering `FHEE`
## Test Cases
Realistic amount of key-switches (as in RL business cases) 
## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
