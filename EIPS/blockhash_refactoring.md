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

### Description of light client protocol

We can define a "probabilistic total-difficulty proof" as an RLP list as follows:

    [header1, proof1, header2, proof2, ...]
    
Where each header is a block header, and each proof[i] is a Merkle branch from header[i] to the hash of header[i + 1]. More formally, the proof is an RLP list where each element contains as a substring the hash of the next element, and the last element is the hash of the next header; the elements are taken from the branch of the state tree in header[i] that points to the hash of header[i + 1] that is available in the storage of the BLOCKHASH_CONTRACT_ADDR.

The proof serves to verify that the headers are linked to each other in the given order, and that the given chain has an approximate total difficulty equal to `sum(2 ** 256 / mining_result[i])` where `mining_result[i]` is the result of running the ethash verification function on the given header. A node producing a proof will take case to create a proof that contains as many low-mining-result blocks as possible; a specific algorithm would be to look for all "key blocks" whose mining result is less than 1/50000 of maximum for a valid block allowed by the most recent block difficulty, and then if these blocks do not have a direct connection because they are not an even multiple of 256 or 65536 apart, it would find "glue blocks" to link between them; for example, linking 3904322 to 3712498 might go through 3735552 (multiple of 65536, directly linked in 3904322) and 3712512 (multiple of 256, directly linked in 3735552), and finally 3712512 links directly to 3712498.

For a chain 1 million blocks long, such an algorithm would find 20 key blocks, of which ~1% require zero glue blocks, ~72% require one glue block and ~27% require two glue blocks, so a total sub-chain of ~45 blocks. Each header is ~500 bytes, and each proof will be another ~1500 bytes, so the total size would be ~90 KB.

TODO: provide the algorithm by which a light client would use these proofs to authenticate the chain, and exactly how it would switch between asking for probabilistic proofs and simply asking for the most recent blocks in the chain from a particular point that already has been probabilistically proven.
