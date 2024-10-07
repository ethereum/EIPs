---
eip: eip-xxxx
title: GETCONTRACT opcode
description: Global byte code accessing by it's hash
author: Tim Pechersky (@peersky)
discussions-to: https://ethereum-magicians.org/t/erc-7744-code-index/20569/11
status: Draft
type: Standards Track
category: Core
created: 2024-10-07
---

# Abstract

Initially proposed in erc track, this EIP is now moved to core track, discussion kept in the same thread as they are related and can be seen as exclusive.

This is a proposal to add a new opcode, `GETCONTRACT`. The `GETCONTRACT` opcode would return the address containing the bytecode by it's hash.

# Motivation

Content addressing by it's hash is a common pattern in database design. It allows to store and retrieve data by it's unique footprint in the storage. This pattern is widely used in the industry and it allows to abstract from actual storage location and allows to reuse the same bytecode in multiple contracts.

Today, existing contract discovery relies on addresses, which are non-deterministic and can be obfuscated through proxies. Indexing by bytecode hash provides a deterministic and tamper-proof way to identify and verify contract code, enhancing security and trust in the Ethereum ecosystem.

Consider a security auditor who wants to attest to the integrity of a contract’s code. By referencing bytecode hashes, auditors can focus their audit on the bytecode itself, without needing to assess deployment parameters or storage contents. This method verifies the integrity of a contract’s codebase without auditing the entire contract state.

Additionally, bytecode referencing allows whitelist contracts before deployment, allowing developers to get pre-approval for their codebase without disclosing the code itself, or even pre-setup infrastructure that will change it behavior upon adding some determined functionality on chain.

For developers relying on extensive code reuse, bytecode referencing protects against malicious changes that can occur with address-based referencing through proxies. This builds long-term trust chains extending to end-user applications.

For decentralized application (dApp) developers, a code index can save gas costs by allowing them to reference existing codebase instead of redeploying them, optimizing resource usage. This can be useful for dApps that rely on extensive re-use of same codebase as own dependencies.

This also allows to build new core standards more conveniently, for example, [EIP-7702](./eip-7702) can use it as dependency, to allow users who want to set up one-time code on their EOAs by referring to `GETCONTRACT` instead of uploading the code itself or having to figure out where was the required code deployed.

## Specification

### Opcode Definition

* **Mnemonic:** `GETCONTRACT`
* **Opcode Value:** `0xfe`
* **Input:**
    * `codehash`: A single 32-byte code hash from the stack.
* **Output:**
    * `address`:  If the `codehash` exists in the state, pushes the corresponding contract address onto the stack. Otherwise, pushes 0.
* **Gas Cost:** ?? (TBD)
* **Stack Effects:** Pops 1 item, pushes 1 item.
* **Error Handling:**  If the `codehash` is invalid or the bytecode retrieval encounters an error, the instruction will revert.

### Example Usage

```solidity
function getContractAddress(bytes32 codehash) public view returns (address) {
    address contractAddress = GETCONTRACT(codehash);
    return contractAddress;
}
