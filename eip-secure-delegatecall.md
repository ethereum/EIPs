---
title: Secure Delegatecall Opcode
description: A secure version of delegatecall that returns the target contract's deployer address
author: nolan wang (https://x.com/ma1fan)
discussions-to:https://ethereum-magicians.org/t/introduce-sdelegatecall-opcode-for-enhanced-delegatecall-security/23045/1 
status: Draft
type: Standards Track
category: Core
created: 2025-03-03
---

## Abstract

This EIP introduces a new EVM opcode `SDELEGATECALL` (secure delegatecall) that enhances security when executing external contract code. It functions similarly to the existing `DELEGATECALL` opcode but additionally returns the deployer's address of the target contract, allowing the caller to verify the authenticity of the contract being called.

## Motivation

The standard `DELEGATECALL` opcode executes untrusted external code in the context of the calling contract, which has led to numerous security incidents and significant funds loss. For example, the [Bybit hack incident](https://x.com/benbybit/status/1892963530422505586) resulted in approximately $14 billion in lost funds when attackers replaced wallet contract code with backdoored versions.

By providing a way to verify the deployer of the target contract, `SDELEGATECALL` allows developers to implement additional security checks before execution continues, mitigating risks associated with malicious contract replacements or backdoors.

## Specification



A new EVM opcode `SDELEGATECALL` is introduced with the following properties:

1. The opcode takes the same inputs as the existing `DELEGATECALL` opcode:
   - `gas`: Gas to allocate for the call
   - `contractaddress`: Address of the contract to call
   - `argsOffset`, `argsSize`: Memory offset and size for call arguments
   - `retOffset`, `retSize`: Memory offset and size for return data

2. The opcode produces the following outputs:
   - `success`: Boolean indicating if the call was successful (1) or failed (0)
   - `deployer`: Address of the account that deployed the target contract
   - `data`: Return data from the called contract (same as `DELEGATECALL`)

3. The opcode SHALL execute the target contract code with the same context rules as `DELEGATECALL`.

4. The opcode SHALL return the deployer's address as determined the contract create transcation.

5. When the call completes, the stack items are arranged as follows (from top to bottom):
   - `success` (1 for success, 0 for failure)
   - `deployer` (the address of the contract deployer)
   - The standard return data is placed in memory at the specified `retOffset`

6. If the contract was created by another contract, the deployer address SHALL be the address of the creating contract, not the transaction sender.


## Rationale

By returning the deployer's address, `SDELEGATECALL` allows contracts to make informed decisions about execution based on the origin of the target contract. This provides a crucial security check when executing external code, as contracts can verify if the deployer is an expected/trusted address before continuing execution.

The opcode enhances security while preserving the essential functionality of `DELEGATECALL`, making it straightforward for developers to adopt.

## Backwards Compatibility

No backward compatibility issues found. This EIP introduces a new opcode without modifying the behavior of existing opcodes.

## Test Cases

TBD

## Reference Implementation

TBD

## Security Considerations

While `SDELEGATECALL` provides an additional security layer compared to regular `DELEGATECALL`, several considerations remain:

1. The deployer address alone may not be sufficient to establish trust, as legitimate deployers could also deploy malicious contracts.

2. Contracts using this opcode should implement proper authorization checks on the returned deployer address.

3. In the case of proxy contracts or contract factories, the deployer might be another contract rather than an EOA, requiring more complex verification.

4. This solution doesn't prevent all types of delegatecall attacks, only those involving unauthorized contract replacements.

5. Developers should consider implementing additional security measures such as:
   - Allowlists of trusted deployers
   - Contract signature verification
   - Code hash verification

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
