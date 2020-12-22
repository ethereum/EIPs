---
eip: x
title: CREATE3
author: Moody Salem
category: Core
type: Standards Track
status: Draft
created: 2020-12-22
---

### Specification

This EIP is a fork of [./eip-1014.md](EIP-1014) which adds an account creation opcode that does not involve the init code.

Adds a new opcode (`CREATE3`) at `0xf6`, which takes 4 stack arguments: endowment, memory_start, memory_length, salt. 
Behaves identically to `CREATE2` (`0xf5`), except using `keccak256( 0xfe ++ address ++ salt )[12:]`,
which does not include the hash of the init code.

The `CREATE3` has the same `gas` schema as `CREATE2`, but with one fewer `GSHA3WORD` opcode, to account for the difference
in lengths of the preimages.
The `hashcost` is deducted at the same time as memory-expansion gas and `CreateGas` is deducted: _before_ evaluation
of the resulting address and the execution of `init_code`.

- `0xfe` is a single byte, 
- `address` is always `20` bytes, 
- `salt` is always `32` bytes (a stack item). 

The preimage for the final hashing round is thus always exactly `53` bytes long (does not include hash of the init code).

### Motivation

The core motivations are the same as [./eip-1014.md](EIP-1014), i.e. deploying a smart contract at a deterministic address.
This variation removes the hash of the init code from the preimage. The issue with the existing `CREATE2` opcode
is that computing the hash of the init code on-chain requires the entire bytecode of the target contract to be included
in the contract computing the first preimage.

### Rationale

#### Address formula

* As with CREATE2, ensures that addresses created with this scheme cannot collide with addresses created using the traditional `keccak256(rlp([sender, nonce]))` formula, as `0xfe` can only be a starting byte for RLP for data many petabytes long.
* The addresses created with this scheme cannot collide with addresses created using the `CREATE2`, as `0xfe` will never collide with `0xff`.
* Ensures that the hash preimage has a fixed size.

#### Gas cost

The concerns for `CREATE2` gas cost in regard to init code preimage length do not apply.

### Clarifications

This EIP makes collisions possible. The behaviour at collisions is specified by [EIP-684](https://github.com/ethereum/EIPs/issues/684):

> If a contract creation is attempted, due to either a creation transaction or the `CREATE`, `CREATE2`, (or future `CREATE3`) opcode,
> and the destination address already has either nonzero nonce, or nonempty code, then the creation throws immediately, with exactly 
> the same behavior as would arise if the first byte in the init code were an invalid opcode. This applies retroactively starting from genesis.

Specifically, if `nonce` or `code` is nonzero, then the create-operation fails. 

With [EIP-161](./eip-161.md) 

> Account creation transactions and the `CREATE` operation SHALL, prior to the execution of the initialisation code,
> increment the nonce over and above its normal starting value by one

This means that if a contract is created in a transaction, the `nonce` is immediately non-zero, with the side-effect 
that a collision within the same transaction will always fail -- even if it's carried out from the `init_code` itself.

It should also be noted that `SELFDESTRUCT` (`0xff`) has no immediate effect on `nonce` or `code`, thus a contract cannot 
be destroyed and recreated within one transaction.

### Examples

Example 0
* address `0x0000000000000000000000000000000000000000`
* salt `0x0000000000000000000000000000000000000000000000000000000000000000`
* gas (assuming no mem expansion): ~`32006`~
* result: ~`0x4D1A2e2bB4F88F0250f26Ffff098B0b30B26BF38`~

Example 1
* address `0xdeadbeef00000000000000000000000000000000`
* salt `0x0000000000000000000000000000000000000000000000000000000000000000`
* gas (assuming no mem expansion): ~`32006`~
* result: ~`0xB928f69Bb1D91Cd65274e3c79d8986362984fDA3`~

Example 2
* address `0xdeadbeef00000000000000000000000000000000`
* salt `0x000000000000000000000000feed000000000000000000000000000000000000`
* gas (assuming no mem expansion): ~`32006`~
* result: ~`0xD04116cDd17beBE565EB2422F2497E06cC1C9833`~

Example 3
* address `0x0000000000000000000000000000000000000000`
* salt `0x0000000000000000000000000000000000000000000000000000000000000000`
* gas (assuming no mem expansion): ~`32006`~
* result: ~`0x70f2b2914A2a4b783FaEFb75f459A580616Fcb5e`~

Example 4
* address `0x00000000000000000000000000000000deadbeef`
* salt `0x00000000000000000000000000000000000000000000000000000000cafebabe`
* gas (assuming no mem expansion): ~`32006`~
* result: ~`0x60f3f640a8508fC6a86d45DF051962668E1e8AC7`~

Example 5
* address `0x00000000000000000000000000000000deadbeef`
* salt `0x00000000000000000000000000000000000000000000000000000000cafebabe`
* gas (assuming no mem expansion): ~`32012`~
* result: ~`0x1d8bfDC5D46DC4f61D6b6115972536eBE6A8854C`~

Example 6
* address `0x0000000000000000000000000000000000000000`
* salt `0x0000000000000000000000000000000000000000000000000000000000000000`
* gas (assuming no mem expansion): ~`32000`~
* result: ~`0xE33C0C7F7df4809055C3ebA6c09CFe4BaF1BD9e0`~

