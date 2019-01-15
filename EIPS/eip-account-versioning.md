---
eip: 1072
title: Generalized Account Versioning Scheme
author: Wei Tang (@sorpaas)
discussions-to: To be added
status: Draft
type: Standards Track
category: Core
created: 2017-12-30
---

## Abstract

This defines a method of hard forking while maintaining the exact functionality of existing account by allowing multiple versions of the virtual machines to execute in the same block. This is also useful to define future account state structures when we introduce the on-chain WebAssembly virtual machine.

## Motivation

By allowing account versioning, we can execute different virtual machine for contracts created at different times. This allows breaking features to be implemented while making sure existing contracts work as expected.

Note that this specification might not apply to all hard forks. We have emergency hard forks in the past due to network attacks. Whether they should maintain existing account compatibility should be evaluated in individual basis. If the attack can only be executed once against some particular contracts, then the scheme defined here might still be applicable. Otherwise, having a plain emergency hard fork might still be a good idea.

## Specification

### Account State

After the first hard fork using this scheme, newly created account state stored in the world state trie is changed to become a five-item RLP encoding: `nonce`, `balance`, `storageRoot`, `codeHash` and `version`. The `version` field defines that when a contract call transaction or `CALL` opcode is executed against this contract, which version of the virtual machine should be used. Four-item RLP encoding account state are considered to have the `version` 0.

`CREATE`/`CREATE2` opcode, the contract creation transaction, and a normal call which initialize a new account, would only deploy accounts of the newest version.

The behavior of `CALLCODE` and `DELEGATECALL` are not affected by the hard fork -- they would fetch the contract code (even if the contract is deployed in a newer version) and still use the virtual machine version defined in the current contract (or in the case of within the input of contract creation transaction or `CREATE` opcode, the newest virtual machine version) to execute the code.

If a message call transaction creates a new account, the newly created account will have the newest account version number in the network.

Precompiled contracts, once created, use the given account version. If the account does not exist yet, newest version of the VM is used (as in the standard message call transaction). This is made so that VMs do not need full permission of the state trie but only with in the smart contract boundary. It is expected that once a precompiled contract is created, its behavior will not change.

### Gas Boundary

With the boundary between the VM and the blockchain, we don't consider there're additional gas cost involved. VM used defines the gas table applied. As examples, intrinsic gas only applies to actual transactions so only the newest ones are used. `CALL` and `CREATE` will use the old gas cost as the opcode gas cost, and once switched to the new VM, use the new gas cost from there.

## Example

Consider we would like to have the REVERT opcode hard fork in Ethereum Classic using this scheme. After the hard fork, we have:

* Existing accounts are still of four-item RLP encoding. When a transaction has `to` field pointing to them, they're executed using version 0 of EVM. REVERT is the same as INVALID and consumes all the gases.
* A new contract creation transaction is executed using version 1 virtual machine, and would only create version 1 account on the blockchain. When executing them, it uses version 1 of EVM and REVERT uses the new behavior.
* When a version 0 account issues a CALL to version 1 account, sub-execution of the version 1 account uses the version 1 virtual machine.
* When a version 1 account issues a CALL to version 0 account, sub-execution of the version 0 account uses the version 0 vritual machine.
* When a version 0 account issues a CREATE, it always uses the newest version of the virtual machine, so it only creates version 1 new accounts.

## Discussions

### Performance

Currently nearly all full node implementations uses config parameters to decide which virtual machine version to use. Switching vitual machine version is simply an operation that changes a pointer using a different set of config parameters. As a result, this scheme has nearly zero impact to performance.

### Smart Contract Boundary and Formal Verification

Many current efforts are on-going for getting smart contracts formally verified. However, for any hard fork that introduces new opcodes or change behaviors of existing opcodes would break the verification of an existing contract has previously be formally verified. Using the scheme described here, we define the boundary of how a smart contract interacts with the blockchain and it might help the formal verification efforts:

* A smart contract has only immutable access to information of blockchain account balances and codes.
* A smart contract has only immutable access of block information.
* A smart contract or a contract creation transaction can modify only its own storage and codes.
* A smart contract can only interact with the blockchain in a mutable way using `CALL` or `CREATE`.

### WebAssembly

This scheme can also be helpful when we deploy on-chain WebAssembly virtual machine. In that case, WASM contracts and EVM contracts can co-exist and the execution boundary and interaction model are clearly defined as above.
