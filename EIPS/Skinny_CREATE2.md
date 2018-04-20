```
EIP: <to be assigned>
Title: Skinny CREATE2
Author: Vitalik Buterin
Category: Core
Status: Draft
Created: 2018-04-20
```

### Specification

Adds a new opcode at 0xf5, which takes 4 stack arguments: endowment, memory_start, memory_length, salt. Behaves identically to CREATE, except using `sha3(msg.sender ++ salt ++ init_code)[12:]` instead of the usual sender-and-nonce-hash as the address the contract is created.

### Motivation

Allows interactions to (actually or counterfactually in channels) be made with addresses that do not exist yet on-chain but can be relied on to only possibly eventually contain code that has been created by a particular piece of init code. Important for state-channel use cases that involve counterfactual interactions with contracts.
