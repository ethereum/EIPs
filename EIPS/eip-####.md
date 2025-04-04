---
title: GitChain
description: Use Git as execution engine
author: Etan Kissling (@etan-status), Ben Adams (@benaadams)
discussions-to: https://ethereum-magicians.org/t/eip-gitchain/23336
status: Draft
type: Standards Track
category: Core
created: 2025-04-01
---

## Abstract

This EIP combines the execution and consensus layer with a single efficient mechanism with much lower complexity.

## Motivation

The Git version control system can be used as a blockchain. The individual commits represent execution blocks and the act of pointing the `mainnet` branch to a specific commit represents consensus fork choice.

Switching the Ethereum engine to Git leverages pre-existing functionality, avoiding the need to reinvent wheels. Such a simplification not only increases security by reducing the attack scope, but also avoids frustration from failed testnet upgrades, complex syncing, multi-year data sharding plans and so on.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Storage

The execution state is tracked in the `mainnet` branch of a Git repository. Each account is represented by its own directory containing a `BALANCE` file with its balance, a `NONCE` file with its account nonce, and a `CODE` file with its EVM code (if present). Storage slots are represented with additional files in subdirectories.

### Accounts

Account addresses are deterministically derived from the GitHub account ID. The directory name is derived by separating the address in chunks of 4 bytes (8 letters each). For example, the account `0x0001020304050607080910111213141516171819` would be stored in directory `00010203/04050607/08091011/12131415/16171819`.

### Transactions

Transactions are created using a GitHub issue template. On creation of an issue, a GitHub action is triggered that eventually executes the transaction and updates the state by creating a commit to the Git repository.

The commit message backlinks to the issue, and the issue is closed as "completed" with a comment containing the corresponding receipt data. For each log, the GitHub action further adds a label to the issue for the log-emitting address and indexed topics.

The GitHub issue template follows the usual transaction fields (including `To`, `Value`, `Input`), with the following differences.

#### Signature

No signature is needed. The `From` address is derived from the GitHub account opening the issue. The `Nonce` is obtained from the current state when the transaction executes. Transactions are executed in ascending issue number order.

If a transaction fails as it lacks the required `BALANCE`, the issue is closed as "not completed".

#### Fee market

The base fee is set based on a moving average tracking the transaction execution time as given by the time difference of the GitHub issue being opened and it being closed by the system.

There are no priority fees. Transactions are always executed in order of submission.

Spam transactions are implicitly solved at the discretion of GitHub. Users creating lots of nonsensical GitHub issues MAY get banned and can contact GitHub support for followup.

#### Access list

Exhaustive access lists MUST be provided when submitting a transaction. The GitHub action executing the transaction will configure a Git sparse checkout based on the provided access list. Other state data will not be available to the GitHub actions runner.

Transactions that access disjunct accounts and storage slots MAY always execute in parallel. Transactions that read the same data MAY execute in parallel only while no transaction writing to the data is processing.

#### Blobs

Blobs can be uploaded directly into the issue as a comment. A GitHub action periodically deletes them when they expire.

#### Authorizations

Authorization lists work as expected.

However, to enable others to perform GitChain operations on behalf of the user, the authorizing user will have to submit an issue to create the authorization. Once that issue is processed, the user can prove that the authorization was created by computing a ZK proof over the confirmation email based on the GitHub DKIM signature. A new authorization type is required for other blockchains to consume GitChain authorizations.

Alternatively, users MAY follow traditional OAuth flows to allow a third party to create an issue on their behalf.

### Software upgrade

The software can be upgraded by anyone opening a pull request on GitHub. The pull request MAY change any code and MAY include irregular state transitions. The PR gets automatically merged if more than 2/3rd of the total balance reacts with 👍 during a periodic check by GitHub actions.

### Activation

When GitChain is initialized, a GitHub action is triggered that changes the email and password of the repository owner account to a random value, ensuring that there is no one with write or admin access to the repository. GitHub actions are the sole holder of admin and write access tokens to the repository. The initial genesis state is subsequently imported from Ethereum.

### Testing

#### Faucet

An initial balance can be requested by starring the repo on GitHub. A GitHub action checks whether the account was already initialized. If the account had not been not initialized yet (`NONCE` file does not exist), a transaction is created that increases the starring account's `BALANCE` by `5 ETH`, and initializes the `NONCE` to `1`.

#### Forks

Forks can be created through GitHub, and can either be tracked in separate repositories or in a different branch other than `mainnet`. Forks MUST NOT be used for production while any user has access to the repository.

## Rationale

GitChain follows a much simpler design with the following long-awaited advantages:

- **Single slot finality:** Transactions execute as quickly as possible and are finalized as soon as they become part of the `mainnet` branch.
- **Parallel transaction execution:** Transactions accessing disjunct storage slots execute in parallel. The concept of a "block" no longer exists, as each transaction is its own block.
- **Integrated transaction explorer:** Each account has its own GitHub link to see the balance as well as all transactions affecting it (commit log). The commits link back to the issues, and log topics can be filtered using GitHub labels.
- **Statelessness:** One can use a sparse checkout containing only the accounts one is interested about.
- **Scaling:** Custom GitHub actions runners could be added that run in a TEE and attest that the transaction execution was not tampered with. GitHub tokens provided by the system MUST NOT leave the TEE.
- **Compatibility:** Existing Ethereum state can be imported in a straight-forward way. The state format is not changed. A commitment to historical transactions and receipts can be added to the readme.
- **Democratic upgrade process:** Users can trigger hard forks at any time of their choosing using a straight-forward voting process.

### Alternative design

The design could be further simplified by simply having an archived repository with `BALANCES.txt` that assigns all 120 million ETH to Vitalik.

## Backwards Compatibility

Wallets would have to integrate the GitHub sign-in flow to authenticate transactions. Further, access lists are required to be exhaustive to support parallel transaction execution.

As GitHub does not natively support JSON-RPC, it would have to be bridged. Such a bridge could be implemented as a WASM module and served via GitHub pages for free.

## Security Considerations

Microsoft already controls a supermajority of build infrastructure across all Ethereum client and validator software. They further control the IDEs used by many developers, and, if malicious or required to do so by an adversarial government, could launch a sophisticated attack that can perform arbitrary state transitions in Ethereum.

GitChain enshrines this practical reality into the protocol, giving Microsoft a more direct control involving fewer hoops, but notably not extending access beyond what Microsoft has today.

This proposal leverages existing and well-established Git tooling and GitHub infrastructure, effectively increasing security by reducing complexity.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
