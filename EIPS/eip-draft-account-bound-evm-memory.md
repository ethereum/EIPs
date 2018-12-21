---
eip: <to be assigned>
title: Account-bound EVM memory
author: Andreas Olofsson (@androlo)
discussions-to: https://ethereum-magicians.org/t/account-bound-evm-memory/2270
status: Draft
type: Standard Track
category: Core
created: 2018-12-21
replaces: 1153
---

## Simple Summary
Changes EVM memory from being VM-bound to being account-bound, making it persist throughout the entire execution of a transaction.

## Abstract
This proposal is to change EVM memory from being bound to a VM instance to instead being account-bound, lasting throughout an entire transaction (i.e. in between contract-to-contract calls). This modification would make it possible for programmers (and language designers) to implement things like re-entrancy protection, general "static" variables, and custom contract-to-contract messaging. It could also be used to harmonize several currently existing instructions (such as call instructions, calldata instructions, and `RETURN`/`REVERT`) and potentially deprecate some of them along with their backing EVM infrastructure.

## Motivation

Right now, the EVM has a "hole" in its storage capacities between VM bound memory and permanent storage. This makes it hard to add reentrancy locks, general "static" variables, and other things that would have to stay alive throughout an entire transaction (but not longer). Making memory account-bound rather then VM bound would change that. Besides enabling a number of useful features it could also be used for call-, and returndata management, which is currently being done through special purpose memories with their own semantics, instructions, and gas rules.

## Specification

This is a very big and open-ended proposal. The following (naive) specification is given only as a starting point for discussion.

Memory is kept in an `address->Memory` map outside of any running VM. In this document, this will be referred to as `accountMemory`, and `accountMemory[address]` would be the `Memory` associated with the provided address. Once a transaction finishes executing, the entire map is discarded.

In the simplest case, `MLOAD`, `MSTORE`, and `MSTORE8` remains un-changed, and would automatically use the memory associated with the account address of the currently running contract. Optionally, a new `MLOAD` instruction could be added with an additional parameter for specifying which account's memory should be read. Current `MLOAD` would then become a simple alias for the more general version, with the account parameter being the address of the currently running contract by default. It would still only be possible to write to the memory of the currently running contract.

`CALL`, `CALLDATA`, and `RETURN/REVERT` related instructions could use `accountMemory[0]` as storage for both call and return-data, rather then using their own special memories and related instructions. This means that in contract code, calldata and returndata is only "live" until the next call - just like it works with returndata now.

Depending on the actual implementation, it could be useful to change memory entirely and even add a memory allocation instruction that handles things on the EVM level, but that is beyond the scope of this draft proposal.

Additionally, the current `CALLDATACOPY` instruction could be succeeded by a general instruction for copying data between memories. It could also allow the target memory to be the same as the source, to avoid having to use the identity precompile and make a call in order to copy memory.

## Rationale

Account-bound, "transient", or "static" memory are not new ideas, and has been discussed several times and for several years. It does not just add some new useful features, like most proposals, but it fundamentally changes the way contracts work. The question is how to do it. 

This EIP suggests one way of doing it that does not only add new features, but also makes it possible simplify and even remove some features that has already been implemented, while at the same time keeping things mostly the same for the language designers (no new storage space) and keeping changes at a minimum.

## Backwards Compatibility

Memory would behave differently, and would have to be allocated in a different way by programmers and language designers.

## Test Cases

Test cases will be added in later. There are some related work (and tests) in my my [tstorage repo](https://github.com/androlo/tstorage) which contains some suggestions and ideas around EIP 1153 (transient storage) as well as example LLL and Solidity contracts along with a modified EVM and LLL/Solidity compiler that both support the suggested new instructions. The principle is pretty much the same as with account-bound memory; in fact, the `TLOAD` and `TSTORE` instructions used in that repo were implemented using memory in a way similar to what is proposed here, which lead me to think it through a bit more and ultimately scrap the idea entirely.

## Implementation

As mentioned, a naive specification and thus also implementation is all that is
provided here.

As specified, memory is kept in an `address->Memory` mapping outside of any running VM. When an `MLOAD` or `MSTORE` is made, it automatically refers to `accountMemory[addressOfCurrentContractAcc]`. The EVM itself could keep this as the backing data structure for memory and use memory the same way it does now, except instead of instantiating a new EVM memory object when a new VM is created it would reference `accountMemory[address]` for the related contract account instead.

When it comes to calls, things would probably have to work similar to how the dirty account map works now, meaning that (in the naive case) the entire account memory map would have to be copied before being passed on to a new vm, and discarded in case the call is reverted. This obviously leads to a lot more copying, as a lot of "useless" data (i.e. data that is only relevant to a certain account and vm) would have to be copied when new calls are made. If something like this was implemented, the onerous would be on language designers to reduce memory size as much as possible; it could even make freeing of memory a relevant issue, unlike now, which would complicate memory allocation a great deal.

#### Call and calldata

Call could use `accountMemory[0]` instead of current calldata memory to store calldata. A convention could be to use address `0x00` for the length of the data and `0x20` and beyond for the data itself. The call instructions themselves would not change, only their implementations.

The calldata instructions (`CALLDATALOAD`, `CALLDATASIZE`, `CALLDATACOPY`) could simply refer to `accountMemory[0]` instead of the current calldata array.

The data sent along with a transaction (txdata) would have to be copied into `accountMemory[0]` as part of setting up the transaction.

Needless to say, these conventions would ensure that call-, and returndata continues to be read-only, since the account with address `0` can not contain code and write to memory using the `MSTORE` instruction.

#### Returndata

Returndata could use `accountMemory[0]` just like calldata, with the same conventions.

#### Gas

First of all, there are alternatives to how call-, and returndata could be managed. It could be good to clear the memory before anything is written. It could also just overwrite. Another alternative is that the memory could be initialized once (at the beginning of a transaction) and then extended for each call, meaning it would not store length at `0x00` and the data after that, but use an allocator:

`0x00` - Length of data

`0x20` - Position of data in memory

`0x40` - Free memory pointer

This would be more advanced, but would mean that gas could be handled the exact same way as with other memory, potentially using the exact same formula because it is after all doing the exact same thing (i.e. writing bytes to an expandable byte array).

Gas could also be metered based on total amount of memory expansion, whether by call and returndata or any other memory. The total memory cost of a transaction would then be bound mainly to the number of bytes that are written throughout a transaction, and not so much to where those bytes happens to be placed. One gas convention would be enough for all of these cases, and that would be the generic convention used for memory.

#### Programming languages

When it comes to programming languages, a standard they could use is to utilize the first byte (or 32 bytes) as a marker for whether or not a countract's memory has been initialized. This slot could be set to `1` the first time the contract is run, and before any other code in the contract is run it would have to check whether this is set. If not, it would set it and also run any other "static initialization" needed, such as resetting free memory pointers and initializing static variables. After that, it could basically just continue to allocate and use memory as it would normally.

Static variables would be relatively simple to add to Solidity; the only difference from non-static variables would be that they should probably be declared directly in the contract body (static fields), so that the compiler can reserve their addresses in a good and simple way. The basic rule for types would be that if a type can be used for a memory variable, it could be used for a static variable as well.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
