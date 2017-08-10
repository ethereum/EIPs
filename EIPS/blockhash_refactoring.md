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

If `block.number >= METROPOLIS_FORK_BLKNUM + 256`, then the BLOCKHASH opcode instead returns the result of executing a call (NOT a transaction) with the parameters:

* `SENDER`: <account from which the opcode was called>
* `GAS`: 1000000
* `TO`: BLOCKHASH_CONTRACT_ADDR
* `VALUE`: 0
* `DATA`: 32 byte zero-byte-leftpadded integer representing the stack argument with which the opcode was called

Also, for blocks where `block.number >= METROPOLIS_FORK_BLKNUM`, the gas cost is increased from 20 to 800 to reflect the higher costs of processing the algorithm in the contract code.


### Contract model

The contract, when called by the SYSTEM account, records provided block hashes
selectively on different levels. The levels differs by intervals (frequency)
at what the block hashes are stored.

Let `n` be the current block number.
Let `p = n - 1` be the previous block number.
Let `h` be the block hash of the previous `p` block.
Let `B` be the base -- the number of records kept on every level.

The levels are numbered with `k`, starting from 0.
A given level `k` of stored block hashes has the _interval_ of `B**k` blocks.

The recursive level update formula is:

```python
def update(k, p):
    n = p - B**k          # The number of the block hash to be moved.
    i = (n / B**k) % B    # The index of the storage slot where to move the block hash.
    if i == 0:
        update(k + 1, n)  # Update higher level.
    storage[k][i] = storage[k - 1][0]  # Move the block hash from lower level.
```

where
- `storage[k]` is contract storage dedicated to level `k`,
- `storage[-1][0]` is `h`.


### Implementation parameters

- `B` is `256`,
- `k` is max 2 (3 levels in total).


### BLOCKHASH_CONTRACT_CODE

BLOCKHASH_CONTRACT_CODE is set to:

```
0x73fffffffffffffffffffffffffffffffffffffffe3314156100995760014303602052610100602051076040526000604051141561008d576101006020510360605261010061010060605105076080526000608051141561008157620100006060510360a0526101006201000060a051050760c0526101005460c05161020001555b60005460805161010001555b60003560405155610171565b60003560e05260e0514313156100b557600060e05112156100b8565b60005b156101645760e051430361010052610100610100511315156100e75761010060e0510754610120526020610120f35b600061010060e0510714156101635762010100610100511315156101205761010061010060e05105076101000154610140526020610140f35b6201000060e05107151561013e576301010100610100511315610141565b60005b15610162576101006201000060e05105076102000154610160526020610160f35b5b5b6000610180526020610180f35b
```

The Serpent source code is:

```python
# Setting the block hash
if msg.sender == 2**160 - 2:

    # Level 0
    # Use storage fields 0..255 to store the hashes of the last 256
    # blocks.
    n0 = block.number - 1
    i0 = n0 % 256

    if i0 == 0:
        # Level 1
        # Use storage fields 256..511 to store the hashes of 256
        # blocks with block.number % 256 == 0.
        n1 = n0 - 256
        i1 = (n1 / 256) % 256

        if i1 == 0:
            # Level 2
            # Use storage fields 512..767 to store the hashes of 256
            # blocks with block.number % 65536 == 0.
            n2 = n1 - 256*256
            i2 = (n2 / (256*256)) % 256
            # Move to be replaced record from level 1 to level 2.
            ~sstore(512 + i2, ~sload(256))

        # Move to be replaced record from level 0 to level 1.
        ~sstore(256 + i1, ~sload(0))

    # Save the provided hash of the previous block.
    ~sstore(i0, ~calldataload(0))

# Getting the block hash
else:
    number = ~calldataload(0)
    if block.number > number and number >= 0:
        distance = block.number - number
        if distance <= 256:
            return(~sload(number % 256))
        if number % 256 == 0:
            if distance <= 65792:
                return(~sload(256 + (number / 256) % 256))
            if (not (number % 65536) and distance <= 16843008):
                return(~sload(512 + (number / 65536) % 256))
    return(0)
```

### Rationale

This removes the need for implementations to have an explicit way to look into historical block hashes, simplifying the protocol definition and removing a large component of the "implied state" (information that is technically state but is not part of the state tree) and thereby making the protocol more "pure". Additionally, it allows blocks to directly point to blocks far behind them, which enables extremely efficient and secure light client protocols.
