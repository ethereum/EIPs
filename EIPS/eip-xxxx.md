---
eip: 0000
title: EVMDEPS opcode
description: Opcode to see EVM dependencies of smart contract
author: Tim Pechersky (@peersky)
discussions-to: https://ethereum-magicians.org/t/eip-7784-getcontract-code/21325
status: Draft
type: Standards Track
category: Core
created: 2024-10-07
---

## Abstract

This is a proposal to add a new opcode, `EVMDEPS`. The `EVMDEPS` opcode would return the dependencies of the smart contract such as opcodes used, libraries used, and EVM version used.

## Motivation

As Ethereum development moves forwardit becomes 

## Specification

### Opcode Definition

* **Mnemonic:** `GETCONTRACT`
* **Opcode Value:** `0x4f`
* **Input:**
    * `codehash`: A single 32-byte code hash from the stack.
* **Output:**
    * `address`:  If the `codehash` exists in the state, pushes the corresponding contract address onto the stack. Otherwise, pushes 0.
* **Gas Cost:** ?? (TBD)
* **Stack Effects:** Pops 1 item, pushes 1 item.
* **Error Handling:**  If the `codehash` is invalid or the bytecode retrieval encounters an error, the instruction will revert.

Every contract stored in EVM MUST be added to the state trie with the key being the keccak256 hash of the contract's bytecode, provided it is not already present and the contract did not invoke the `SELFDESTRUCT` opcode.


### Example Usage

```solidity
function getContractAddress(bytes32 codehash) public view returns (address) {
    address contractAddress;
    assembly {
        contractAddress := GETCONTRACT(codehash)
    }
    return contractAddress;
}
```

## Rationale

**Bytecode over Addresses**: Bytecode is deterministic and can be verified on-chain, while addresses are opaque and mutable.

**EIP not ERC**: This EIP is proposed as a core standard, as it enables global index by default, abstracts developers from need to maintain the index, and can be used as a dependency for other EIPs.

**Do not re-index**: There is small, yet non-zero probability of hash collision attack. Disallowing updates to indexed location of bytecode coupes with this.

## Security Considerations

**Malicious Code**: The index does NOT guarantee the safety or functionality of indexed contracts. Users MUST exercise caution and perform their own due diligence before interacting with indexed contracts.

**Storage contents of registered contracts**: The index only refers to the bytecode of the contract, not the storage contents. This means that the contract state is not indexed and may change over time.
****
## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
