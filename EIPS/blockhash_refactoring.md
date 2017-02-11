### Preamble

    EIP: <to be assigned>
    Title: Blockhash refactoring
    Author: Vitalik Buterin
    Type: Standard Track
    Category: Core
    Status: Draft
    Created: 2017-02-10
    
### Summary

Stores blockhashes in the state, reducing the protocol complexity and the need for client implementation complexity in order to process the BLOCKHASH opcode. Also extends the range of how far back blockhash checking can go, with the side effect of creating direct links between blocks with very distant block numbers, facilitating much more efficient initial light client syncing.

### Parameters

* `METROPOLIS_FORK_BLKNUM`: TBD
* `SUPER_USER`: 2**160 - 2
* `BLOCKHASH_CONTRACT_ADDR`: 0xf0 (ie. 240)
* `BLOCKHASH_CONTRACT_CODE`: see below

### Specification

If `block.number == METROPOLIS_FORK_BLKNUM`, then when processing the block, before processing any transactions set the code of BLOCKHASH_CONTRACT_ADDR to BLOCKHASH_CONTRACT_CODE.

If `block.number >= METROPOLIS_FORK_BLKNUM`, then when processing a block, before processing any transactions execute a call with the parameters:

* `SENDER`: SUPER_USER
* `GAS`: 1000000
* `TO`: BLOCKHASH_CONTRACT_ADDR
* `VALUE`: 0
* `DATA`: <32 bytes corresponding to the block's prevhash>

If `block.number >= METROPOLIS_FORK_BLKNUM + 256`, then the BLOCKHASH opcode instead returns the result of executing a call with the parameters:

* `SENDER`: <account from which the opcode was called>
* `GAS`: 1000000
* `TO`: BLOCKHASH_CONTRACT_ADDR
* `VALUE`: 0
* `DATA`: 32 byte zero-byte-leftpadded integer representing the stack argument with which the opcode was called

Also, the gas cost is increased from 20 to 350 to reflect the higher costs of processing the algorithm in the contract code.

### BLOCKHASH_CONTRACT_CODE

BLOCKHASH_CONTRACT_CODE is set to the compile output of the following Serpent code:

```python
if msg.sender == {SUPERUSER}:
    prevblock_number = block.number - 1
    ~sstore(prevblock_number % 256, ~calldataload(0))
    if prevblock_number % 256 == 0:
        ~sstore(256 + (prevblock_number / 256) % 256, ~calldataload(0))
    if prevblock_number % 65536 == 0:
        ~sstore(512 + (prevblock_number / 65536) % 256, ~calldataload(0))
else:
    if ~calldataload(0) >= block.number or ~calldataload(0) < {METROPOLIS_FORK_BLKNUM}:
        return 0
    if block.number - ~calldataload(0) >= 256:
        return ~sload(~calldataload(0) % 256)
    elif block.number - ~calldataload(0) >= 65536 and ~calldataload(0) % 256 == 0:
        return ~sload(256 + (~calldataload(0) / 256) % 256)
    elif block.number - ~calldataload(0) >= 16777216 and ~calldataload(0) % 65536 == 0:
        return ~sload(512 + (~calldataload(0) / 65536) % 256)
    else:
        return 0
        
```

### Rationale

This removes the need for implementaitons to have an explicit way to look into historical block hashes, simplifying the protocol definition and removing a large component of the "implied state" (information that is technically state but is not part of the state tree) and thereby making the protocol more "pure". Additionally, it allows blocks to directly point to blocks far behind them, which enables extremely efficient and secure light client protocols.
