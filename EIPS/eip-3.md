```
EIP: 3
Title: Addition of CALLDEPTH opcode
Author: Martin Holst Swende <martin@swende.se>
Status: Draft
Type: Standards Track
Layer: Consensus (hard-fork)
Created: 2015-11-19
```

# Abstract

This is a proposal to add a new opcode, `CALLDEPTH`. The `CALLDEPTH` opcode would return the remaining available call stack depth. 

# Motivation

There is a limit specifying how deep contracts can call other contracts; the call stack. The limit is currently `256`. If a contract invokes another contract (either via `CALL` or `CALLCODE`), the operation will fail if the call stack depth limit has been reached. 

This behaviour makes it possible to subject a contract to a "call stack attack" [1]. In such an attack, an attacker first creates a suitable depth of the stack, e.g. by recursive calls. After this step, the attacker invokes the targeted contract. If the targeted calls another contract, that call will fail. If the return value is not properly checked to see if the call was successfull, the consequences could be damaging. 

Example: 

1. Contract `A` want's to be invoked regularly, and pays Ether to the invoker in every block.
2. When contract `A` is invoked, it calls contracts `B` and `C`, which consumes a lot of gas. After invocation, contract `A` pays Ether to the caller. 
3. Malicious user `X` ensures that the stack depth is shallow before invoking A. Both calls to `B` and `C` fail, but `X` can still collect the reward. 

It is possible to defend against this in two ways:

1. Check return value after invocation. 
2. Check call stack depth experimentally. A library [2] by Piper Merriam exists for this purpose. This method is quite costly in gas.


[1] a.k.a "shallow stack attack" and "stack attack". However, to be precise, the word ''stack'' has a different meaning within the EVM, and is not to be confused with the ''call stack''.

[2] https://github.com/pipermerriam/ethereum-stack-depth-lib 
