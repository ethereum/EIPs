PoC 4

### Big Changes

We now make a distinction between state and code. Code is stored as an immutable byte array node in the state tree. Accounts have both a state and code hash. When creating contracts, two byte arrays containing EVM code are given: an initialiser (run once then discarded) and the body (stored in the state tree as mentioned).

Transaction types are distinguished between 

(i) A message call transaction now contains the following fields:

    [ NONCE, VALUE, GASPRICE, GAS, TO, DATA, V, R, S ]

(i) b. Whereas a contract creation transaction contains:

    [ NONCE, VALUE, GASPRICE, GAS, 0, CODE, INIT, V, R, S ] (do we need the 0? take it out and it becomes ambiguous with the message call transaction above - How so, there's INIT which takes out the ambiguousity?) - both INIT and DATA are bytearrays hence the ambiguity.

INIT gets run on creation. If this means that 

### VM Execution Model

The current operation is no longer taken from the (256-bit int) storage (P), but instead from a separate immutable byte array of code (C). All operations are bytes, and so are mostly the same as before. The only difference is for PUSH, which must now be split into 32 different opcodes, one for each length of data you wish to push onto the stack. This will mostly be PUSH32 or PUSH1.

So, given C is the list of bytes of the currently executing code (which, could be CODE or INIT). So the operation to be done is O:

O = C[ PC' ]

### Addresses & Words

Addresses are now formed from words by taking the left 160-bits. Words are formed from addresses conversely, through left-alignment.

### VM Opcode Set

# 0s: arithmetic operations

 •	0x00: STOP -0 +0
 ◦	Halts execution.
 ◦	Any gas left over gets returned to caller (or in the case of the top-level call, the sender converted back to ETH).
 •	0x01: ADD -2 +1
 ◦	S[0] := S'[0] + S'[1]
 •	0x02: MUL -2 +1
 ◦	S[0] := S'[0] * S'[1]
 •	0x03: SUB -2 +1
 ◦	S[0] := S'[0] - S'[1]
 •	0x04: DIV -2 +1
 ◦	S[0] := S'[0] / S'[1]
 •	0x05: SDIV -2 +1
 ◦	S[0] := S'[0] / S'[1]
 ◦	S'[0] & S'[1] are interpreted as signed 256-bit values for the purposes of this operation.
 •	0x06: MOD -2 +1
 ◦	S[0] := S'[0] % S'[1]
 •	0x07: SMOD -2 +1
 ◦	S[0] := S'[0] % S'[1]
 ◦	S'[0] & S'[1] are interpreted as signed 256-bit values for the purposes of this operation.
 •	0x08: EXP -2 +1
 ◦	S[0] := S'[0] + S'[1]
 •	0x09: NEG -1 +1
 ◦	S[0] := -S'[0]
 •	0x0a: LT -2 +1
 ◦	S[0] := S'[0] < S'[1] ? 1 : 0
 •	0x0b: GT -2 +1
 ◦	S[0] := S'[0] > S'[1] ? 1 : 0
 •	0x0c: EQ -2 +1
 ◦	S[0] := S'[0] == S'[1] ? 1 : 0
 •	0x0d: NOT -1 +1
 ◦	S[0] := S'[0] == 0 ? 1 : 0

# 10s: bit operations

 •	0x10: AND -2 +1
 ◦	S[0] := S'[0] AND S'[1]
 •	0x11: OR -2 +1
 ◦	S[0] := S'[0] OR S'[1]
 •	0x12: XOR -2 +1
 ◦	S[0] := S'[0] XOR S'[1]
 •	0x13: BYTE -2 +1
 ◦	S[0] := S'[0]th byte of S'[1]
 ▪	if S'[0] < 32
 ◦	S[0] := 0
 ▪	otherwise
 ◦	for Xth byte, we count from left - 0th is therefore the leftmost (most significant in BE) byte.

# 20s: crypto opcodes

 •	0x20: SHA3 -2 +1
 ◦	S[0] := SHA3( T'[ S'[0] ++ ... ++ (S'[0] + S'[1]) ])

# 30s: closure state opcodes

 •	0x30: ADDRESS -0 +1
 ◦	S[0] := ADDRESS
 ◦	i.e. the address of this closure.
 •	0x31: BALANCE -1 +1
 ◦	S[0] := B[ S'[0] ]
 ◦	i.e. the balance of this closure.
 •	0x32: ORIGIN -0 +1
 ◦	S[0] := A
 ◦	Where A is the address of the account that made the original transaction leading to the current closure and is paying the fees
 •	0x33: CALLER -0 +1
 ◦	S[0] := A
 ◦	Where A is the address of the object that made this call.
 •	0x34: CALLVALUE -0 +1
 ◦	S[0] := V
 ◦	Where V is the value attached to this call.
 •	0x35: CALLDATALOAD -1 +0
 ◦	S[0] := D[ S'[0] ... (S'[0] + 31) ]
 ◦	Where D is the data attached to this call (as a byte array).
 ◦	Any bytes that are out of bounds of the data are defined as zero.
 •	0x36: CALLDATASIZE -0 +1
 ◦	S[0] := DS
 ◦	Where DS is the number of bytes of data attached to this call.
 •	0x37: GASPRICE -0 +1
 ◦	S[0] := V
 ◦	Where V is the current gas price (né fee multiplier).

# 40s: block operations

 •	0x40: PREVHASH -0 +1
 ◦	S[0] := H
 ◦	Where H is the SHA3 hash of the previous block.
 •	0x41: COINBASE -0 +1
 ◦	S[0] := A
 ◦	Where A is the coinbase address of the current block.
 •	0x42: TIMESTAMP -0 +1
 ◦	S[0] := T
 ◦	Where T is the timestamp of the current block (given as the Unix time_t when this block began its existence).
 •	0x43: NUMBER -0 +1
 ◦	S[0] := N
 ◦	Where N is the block number of the current block (counting upwards from genesis block which has N == 0).
 •	0x44: DIFFICULTY -0 +1
 ◦	S[0] := D
 ◦	Where D is the difficulty of the current block.
 •	0x45: GASLIMIT -0 +1
 ◦	S[0] := L
 ◦	Where L is the total gas limit of the current block. Always 10^6.

# 50s: stack, memory, storage and execution path operations

 •	0x51: POP -1 +0
 •	0x52: DUP -1 +2
 ◦	S[0] := S'[0]
 •	0x53: SWAP -2 +2
 ◦	S[0] := S'[1]
 ◦	S[1] := S'[0]
 •	0x54: MLOAD -1 +1
 ◦	S[0] := T'[ S'[0] ... S'[0] + 31 ]
 •	0x55: MSTORE -2 +0
 ◦	T[ S'[0] ... S'[0] + 31 ] := S'[1]
 •	0x56: MSTORE8 -2 +0
 ◦	T[ S'[0] ... S'[0] + 31 ] := S'[1] & 0xff
 •	0x57: SLOAD -1 +1
 ◦	S[0] := P'[ S'[0] ]
 •	0x58: SSTORE -2 +0
 ◦	P[ S'[0] ] := S'[1]
 •	0x59: JUMP -1 +0
 ◦	PC := S'[0]
 •	0x5a: JUMPI -2 +0
 ◦	PC := S'[1] == 0 ? PC' : S'[0]
 •	0x:5b PC -0 +1
 ◦	S[0] := PC
 •	0x5c: MSIZE -0 +1
 ◦	S[0] = sizeof(T)
 •	0x5d: GAS
 ◦	S[0] := G
 ◦	Where G is the amount of gas remaining after executing the opcode.

# 60s & 70s: push
 •	0x60: PUSH1 0 +1
 ◦	S[0] := C[ PC' + 1 ]
 ◦	PC := PC' + 2
 •	0x61: PUSH2 0 +1
 ◦	S[0] := C[ PC' + 1 ] ++ C[ PC' + 2 ]
 ◦	PC := PC' + 3
...
 •	0x7f: PUSH32 0 +1
 ◦	S[0] := C[ PC' + 1 ] ++ C[ PC' + 2 ] ++ ... ++ C[ PC' + 32 ]
 ◦	PC := PC' + 33

# f0s: closure-level operations

 •	0xf0: CREATE -5 +1
 ◦	Immediately creates a contract where:
 ◦	The endowment is given by S'[0]
 ◦	The body code of the eventual closure is given by T'[ S'[1] ... ( S'[1] + S'[2] - 1 ) ]
 ◦	The initialisation code of the eventual closure is given by T'[ S'[3] ... ( S'[3] + S'[4] - 1 ) ]
 ◦	(Thus the total number of bytes of the transaction data is given by S'[2] + S'[4].)
 ◦	S[0] = A
 ◦	where A is the address of the created contract or 0 if the creation failed.
 ◦	Fees are deducted from the sender balance to pay for enough gas to complete the operation (i.e. contract creation fee + initial storage fee). If there was not enough gas to complete the operation, then all gas will be deducted and the operation fails.
 •	0xf1: CALL -7 +1
 ◦	Immediately executes a call where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The gas is given by S'[2]
 ◦	The input data of the call is given by T'[ S'[3] ... ( S'[3] + S'[4] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction is given by S'[4].)
 ◦	The output data of the call is given by T[ S'[5] ... ( S'[5] + MIN( S'[6], S[0] ) - 1 ) ]
 ◦	If 0 gas is specified, transfer all gas from the caller to callee gas balance, otherwise transfer only the amount given. If there isn't enough gas in the caller balance, operation fails.
 ◦	If the value is less than the amount in the caller's balance then nothing is executed and the S'[2] gas gets refunded to the caller.
 ◦	See Appendix A for execution.
 ◦	Add any remaining callee gas to the caller's gas.
 ◦	S[0] = R
 ◦	where R = 1 when the instrinsic return code of the call is true, R = 0 otherwise.
 •	NOT YET: POST -5 +1
 ◦	Registers for delayed execution a call where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The gas to supply the transaction with is given by S'[2] (paid for from the current gas balance)
 ◦	The input data of the call is given by T'[ S'[3] ... ( S'[3] + S'[4] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction is given by S'[4].)
 ◦	Contract pays for itself to run at a defered time from its own GAS supply. The miner has no choice but to execute.
 •	NOT YET: ALARM -6 +1
 ◦	Registers for delayed execution a call where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The gas (to convert from ETH at the later time) is given by S'[2]
 ◦	The number of blocks to wait before executing is S'[3]
 ◦	The input data of the call is given by T'[ S'[4] ... ( S'[4] + S'[5] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction is given by S'[5].)
 ◦	Total gas used now is S'[3] * S'[5] * deferFee.
 ◦	Contract pays for itself to run at the defered time converting given amount of gas from its ETH balance; if it cannot pay it terminates as a bad transaction. TODO: include baseFee and allow miner freedom to determine whether to execute or not. If not, the next miner will have the chance.
 •	0xf2: RETURN -2 +0
 ◦	Halts execution.
 ◦	R := T[ S'[0] ... ( S'[0] + S'[1] - 1 ) ]
 ◦	Where the output data of the call is specified as R.
 ◦	Any gas left over gets returned to caller (or in the case of the top-level call, the sender converted back to ETH).
 •	0xff: SUICIDE -1 +0
 ◦	Halts execution.
 ◦	FOR ALL i: IF P[i] NOT EQUAL TO 0 THEN B[ S'[0] ] := B[ S'[0] ] + memoryFee
 ◦	B[ S'[0] ] := B[ S'[0] ] + B[ ADDRESS ]
 ◦	Removes all contract-related information from the Ethereum system.



## Appendix A: 

CALL has intrinsic parameters:

TO, VALUE, GAS, INOFFSET, INSIZE, OUTOFFSET, OUTSIZE

It also finishes an intrinsic boolean value relating to the success of the operation.

The process for evaluating CALL is as follows:

1. Let ROLLBACK := S where S is the current state.
2. Let program counter (PC) = 0.
Let it be known that all storage operations operate on TO's state.
Note that the memory is empty, thus (last used index + 1) = 0.
3. Set TXDATA to the first INSIZE bytes of memory starting from INOFFSET in the caller memory.
4. Repeat
    * Calculate the cost of the current instruction (see below), set to C
        * If the instruction is invalid or STOP, goto step 6.
    * If GAS < C then GAS := 0; S := ROLLBACK and evaluation finishes, returning false. 
    * GAS := GAS - C
    * Apply the instruction.
    Until an operation execution error has occured or the instruction is STOP, RETURN or SUICIDE.
5. If the output data of the call (R) is specified (through RETURN), then let the OUTSIZE bytes of caller memory beginning at OUTOFFSET.
6. Returns true.


## Appendix B

Creation of a contract requires than an address be made: this is now defined as the left 160 bits of the SHA3 hash of the RLP encoded structure:

[ SENDER, NONCE ]

Should this address already be in use (i.e. have a node in the state tree) then, the address is incremented (as a bigendian int) and retried until it succeeds.


## Examples in HLL

A few new contracts:

### Namecoin

    if tx.data[0] > 1000 and !contract.storage[tx.data[0]]:
         contract.storage[tx.data[0]] = tx.data[1]

### Currency

    if !contract.storage[1000]:
        contract.storage[1000] = 1
                contract.storage[tx.sender] = 10^18
    else:
        fbal = contract.storage[tx.sender]
        tbal = contract.storage[tx.data[0]]
        if fbal >= tx.data[1]:
            contract.storage[tx.sender] = fbal - tx.data[1]
            contract.storage[tx.data[0]] = tbal + tx.data[1]
                
### Proprietary data feed

    if tx.sender = <owner here>:
        contract.storage[tx.data[0]] = tx.data[1]
    else:
        a = bytes(32)
        a[0] = contract.storage[tx.data[0]]
        return(a,32)

### Stdlib (callable namecoin)

Idea: [ 0, key, value ] to register, [ 1, key, returnsize, data... ] to use

        if tx.data[0] == 0:
                if tx.data[1] > 1000 and !contract.storage[tx.data[1]]:
                        contract.storage[tx.data[1]] = tx.data[2]
        else:
                a = bytes(tx.data[2])
                call(contract.storage[tx.data[1]],tx.value,tx.data+96,tx.datan-96,a,tx.data[2])
                return(a,tx.data[2])

### Compilation tricks

* Compile `bytes(expr)` as MSIZE DUP < EXPR > 1 SUB 0 PUSH SWAP MSTORE8
* At the start of every compiled program, if `tx.data` is used more than zero times put `<(n+1)*32> CALLDATA PUSH (n+1) DUP MSTORE` where `n` represents the number of variables in the program (known at compile-time).


PoC 4 (was PoC 3.5)

EVM:

'Contracts' become 'Closures'.
'Transactions' become the things that are signed in some way and go in the transaction block. A transaction is enacted with a Message Call.
'Message Calls' encode a transfer of value (ETH) and invoke any code associated with the receiving object.

The original caller (i.e. the original transaction's txsender) pre-pays for a specific amount of 'GAS'. What was baseFee now describes the ETH -> GAS price. Gas is the internal currency of the transaction. Execution operations deplete the GAS supply, as per the original ratios. Once the transaction is finished, any remaining GAS is reconverted back to ETH and refunded.

Storage remains 256-bit address, 256-bit data.

Word size: 256-bit (i.e. stack item size 256-bit).

Memory is byte array (256-bit address, 8-bit data); memoryFee is proportional to greatest index that has ever been referenced in this instance and thus it's highly unlikely addresses will ever go above 32-bit. Whenever a higher memory index is used, the fee difference to take it to the higher usage from the original (lower) usage is charged. MEMSIZE is initially just the size of the input data. Note: MSTORE and MLOAD increase the highest-accessed index to their target index + 31.

### Big Changes

NOTE: Crypto functions, except SHA3, removed.
NOTE: SHA3 takes memory location & byte count.

(i) A transaction now contains the following fields:

    [ NONCE, VALUE, GASPRICE, GAS, TO, DATA, V, R, S ]

* NONCE is a number, as in PoC-3
* VALUE is a number, as in PoC-3
* GAS is (as a number) the amount of GAS that will be exchanged from the sender's ETH balance in order to pay for all costs that happen due to this transaction.
* TO is a number (no longer the fixed 20-byte address that it was in PoC-3)
* GASPRICE is the wei per gas that the sender is willing to pay, as a number.
* DATA is a series of bytes
* V, R, S are numbers as before

To evaluate:

Let GASFEE := GAS * GASPRICE

1. If GAS < TXDATAGAS * len(DATA) + CALLGAS , exit
1. Subtract GASFEE + VALUE from the sender's balance. If the sender's balance is too low, exit.
2. Let G := GAS - (TXDATAGAS * len(DATA) + CALLGAS)
3. Execute CALL operation with the instrinsic parameters (TO, VALUE, G, DATA, sizeof(DATA), 0, 0), (see Appendix A).
4. Add G * GASPRICE to sender's ETH balance where G is the remaining balance of gas from the CALL operation.

(i) b. If the transaction creates a contract, it must be of the form:

    [ NONCE, VALUE, GASPRICE, STORAGE, V, R, S ]

Execution works as follows: 4. The algorithm is relatively computationally quick to verify, although  there is no “nice” verification formula that can be run inside EVM  code.

Let GASFEE = (SSTOREGAS * D + CREATEGAS) * GASPRICE
where:
D is number of non-zero items of STORAGE

1. Subtract GASFEE + VALUE from the sender's balance. If the sender's balance is too low, the transaction is declared invalid and no state change is recorded.
2. Put the contract into the blockchain, with the first portion of storage initialised to STORAGE and balance initialised to VALUE.

NOTE:
(i) To determine if the transaction RLP encodes contract creation, extract nonce/value/basefee and then check if the following (fourth) item is a list - if so it's a creation transaction.    

(ii) MKTX is renamed CALL. See appendix A for its execution.

(iii) A new opcode RETURN is added. This allows the caller's memory bounded between OUTOFFSET and OUTOFFSET + OUTSIZE to be specified

(iv) There is a block size limit (i.e. total gas allowed to be spent per block) which for PoC-3.5 is 10^6.

### How to define instruction/step cost:

Constants:

* STEPGAS = 1
* SHA3GAS = 20
* SLOADGAS = 20
* SSTOREGAS = 100
* BALANCEGAS = 20
* CREATEGAS = 100
* CALLGAS = 20
* MEMORYGAS = 1
* TXDATAGAS = 5 [not used in the VM]

Given an instruction, it is possible to calculate the gas cost of executing it as follows:

* Unless covered by another rule below, an operation costs < STEPGAS > gas
* SHA3 costs < SHA3GAS > gas
* SLOAD costs < SLOADGAS > gas
* BALANCE costs < BALANCEGAS > gas
* SSTORE costs < D * SSTOREGAS > gas where:
- if the new value of the storage is non-zero and the old is zero, D = 2;
- if the new value of the storage is zero and the old is non-zero, D = 0;
- 1 otherwise.
* CALL costs < CALLGAS + G > gas, where G is the quantity of gas provided; some gas may be refunded though.
* CREATE costs < CREATEGAS + G > gas, where G is the quantity of gas provided.
* When you read or write memory with MSTORE, MLOAD, RETURN, SHA3, CALLDATA or CALL, enlarge the memory so that all bytes now fit in it (memory must always be a whole number of 32-byte words). Suppose that the highest previously accessed memory index is M, and the new index is N. If (N + 31) / 32 > (M + 31) / 32, add an additional < ((N + 31) / 32 - (M + 31) / 32) * MEMORYGAS > gas to the cost.

For example, if you call `(TO, VALUE, 5000, 512, 512, 1024, 1024)`, and currently `N = 1024`, then we note that the total size of memory required is 2048 (the destination range is [1024, 2047]) and so 1024 addition , so the cost is `CALLGAS + 5000 + 1024 * MEMORYGAS = 6044`.

### VM Opcode Set

# 0s: arithmetic operations

 •	0x00: STOP -0 +0
 ◦	Halts execution.
 ◦	Any gas left over gets returned to caller (or in the case of the top-level call, the sender converted back to ETH).
 •	0x01: ADD -2 +1
 ◦	S[0] := S'[0] + S'[1]
 •	0x02: MUL -2 +1
 ◦	S[0] := S'[0] * S'[1]
 •	0x03: SUB -2 +1
 ◦	S[0] := S'[0] - S'[1]
 •	0x04: DIV -2 +1
 ◦	S[0] := S'[0] / S'[1]
 •	0x05: SDIV -2 +1
 ◦	S[0] := S'[0] / S'[1]
 ◦	S'[0] & S'[1] are interpreted as signed 256-bit values for the purposes of this operation.
 •	0x06: MOD -2 +1
 ◦	S[0] := S'[0] % S'[1]
 •	0x07: SMOD -2 +1
 ◦	S[0] := S'[0] % S'[1]
 ◦	S'[0] & S'[1] are interpreted as signed 256-bit values for the purposes of this operation.
 •	0x08: EXP -2 +1
 ◦	S[0] := S'[0] + S'[1]
 •	0x09: NEG -1 +1
 ◦	S[0] := -S'[0]
 •	0x0a: LT -2 +1
 ◦	S[0] := S'[0] < S'[1] ? 1 : 0
 •	0x0b: GT -2 +1
 ◦	S[0] := S'[0] > S'[1] ? 1 : 0
 •	0x0c: EQ -2 +1
 ◦	S[0] := S'[0] == S'[1] ? 1 : 0
 •	0x0d: NOT -1 +1
 ◦	S[0] := S'[0] == 0 ? 1 : 0

# 10s: bit operations

 •	0x10: AND -2 +1
 ◦	S[0] := S'[0] AND S'[1]
 •	0x11: OR -2 +1
 ◦	S[0] := S'[0] OR S'[1]
 •	0x12: XOR -2 +1
 ◦	S[0] := S'[0] XOR S'[1]
 •	0x13: BYTE -2 +1
 ◦	S[0] := S'[0]th byte of S'[1]
 ▪	if S'[0] < 32
 ◦	S[0] := 0
 ▪	otherwise
 ◦	for Xth byte, we count from left - 0th is therefore the leftmost (most significant in BE) byte.

# 20s: crypto opcodes

 •	0x20: SHA3 -2 +1
 ◦	S[0] := SHA3( T'[ S'[0] ++ ... ++ (S'[0] + S'[1]) ])

# 30s: closure state opcodes

 •	0x30: ADDRESS -0 +1
 ◦	S[0] := ADDRESS
 ◦	i.e. the address of this closure.
 •	0x31: BALANCE -1 +1
 ◦	S[0] := B[ S'[0] ]
 ◦	i.e. the balance of this closure.
 •	0x32: ORIGIN -0 +1
 ◦	S[0] := A
 ◦	Where A is the address of the account that made the original transaction leading to the current closure and is paying the fees
 •	0x33: CALLER -0 +1
 ◦	S[0] := A
 ◦	Where A is the address of the object that made this call.
 •	0x34: CALLVALUE -0 +1
 ◦	S[0] := V
 ◦	Where V is the value attached to this call.
 •	0x35: CALLDATALOAD -1 +0
 ◦	S[0] := D[ S'[0] ... (S'[0] + 31) ]
 ◦	Where D is the data attached to this call (as a byte array).
 ◦	Any bytes that are out of bounds of the data are defined as zero.
 •	0x36: CALLDATASIZE -0 +1
 ◦	S[0] := DS
 ◦	Where DS is the number of bytes of data attached to this call.
 •	0x37: GASPRICE -0 +1
 ◦	S[0] := V
 ◦	Where V is the current gas price (né fee multiplier).

# 40s: block operations

 •	0x40: PREVHASH -0 +1
 ◦	S[0] := H
 ◦	Where H is the SHA3 hash of the previous block.
 •	0x41: COINBASE -0 +1
 ◦	S[0] := A
 ◦	Where A is the coinbase address of the current block.
 •	0x42: TIMESTAMP -0 +1
 ◦	S[0] := T
 ◦	Where T is the timestamp of the current block (given as the Unix time_t when this block began its existence).
 •	0x43: NUMBER -0 +1
 ◦	S[0] := N
 ◦	Where N is the block number of the current block (counting upwards from genesis block which has N == 0).
 •	0x44: DIFFICULTY -0 +1
 ◦	S[0] := D
 ◦	Where D is the difficulty of the current block.
 •	0x45: GASLIMIT -0 +1
 ◦	S[0] := L
 ◦	Where L is the total gas limit of the current block. Always 10^6.

# 50s: stack, memory, storage and execution path operations

 •	0x50: PUSH X -0 +1
 ◦	PC := PC' + 2
 ◦	S[0] := P[PC' + 1]
 •	0x51: POP -1 +0
 •	0x52: I -1 +2
 ◦	S[0] := S'[0]
 •	0x53: SWAP -2 +2
 ◦	S[0] := S'[1]
 ◦	S[1] := S'[0]
 •	0x54: MLOAD -1 +1
 ◦	S[0] := T'[ S'[0] ... S'[0] + 31 ]
 •	0x55: MSTORE -2 +0
 ◦	T[ S'[0] ... S'[0] + 31 ] := S'[1]
 •	0x56: MSTORE8 -2 +0
 ◦	T[ S'[0] ... S'[0] + 31 ] := S'[1] & 0xff
 •	0x57: SLOAD -1 +1
 ◦	S[0] := P'[ S'[0] ]
 •	0x58: SSTORE -2 +0
 ◦	P[ S'[0] ] := S'[1]
 •	0x59: JUMP -1 +0
 ◦	PC := S'[0]
 •	0x5a: JUMPI -2 +0
 ◦	PC := S'[1] == 0 ? PC' : S'[0]
 •	0x:5b PC -0 +1
 ◦	S[0] := PC
 •	0x5c: MSIZE -0 +1
 ◦	S[0] = sizeof(T)
 •	0x5d: GAS
 ◦	S[0] := G
 ◦	Where G is the amount of gas remaining after executing the opcode.

# 60s: closure-level operations

 •	0x60: CREATE -5 +1
 ◦	Immediately creates a contract where:
 ◦	The endowment is given by S'[0]
 ◦	The input data of the call is given by T'[ S'[1] ... ( S'[1] + S'[2] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction data is given by S'[2].)
 ◦	S[0] = A
 ◦	where A is the address of the created contract.
 ◦	Fees are deducted from the sender balance to pay for enough gas to complete the operation (i.e. contract creation fee + initial storage fee).
 •	0x61: CALL -7 +1
 ◦	Immediately executes a call where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The gas is given by S'[2]
 ◦	The input data of the call is given by T'[ S'[3] ... ( S'[3] + S'[4] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction is given by S'[4].)
 ◦	The output data of the call is given by T[ S'[5] ... ( S'[5] + MIN( S'[6], S[0] ) - 1 ) ]
 ◦	If 0 gas is specified, transfer all gas from the caller to callee gas balance, otherwise transfer only the amount given. If there isn't enough gas in the caller balance, operation fails.
 ◦	If the value is less than the amount in the caller's balance then nothing is executed and the S'[2] gas gets refunded to the caller.
 ◦	See Appendix A for execution.
 ◦	Add any remaining callee gas to the caller's gas.
 ◦	S[0] = R
 ◦	where R = 1 when the instrinsic return code of the call is true, R = 0 otherwise.
 •	NOT YET: POST -5 +1
 ◦	Registers for delayed execution a call where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The gas to supply the transaction with is given by S'[2] (paid for from the current gas balance)
 ◦	The input data of the call is given by T'[ S'[3] ... ( S'[3] + S'[4] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction is given by S'[4].)
 ◦	Contract pays for itself to run at a defered time from its own GAS supply. The miner has no choice but to execute.
 •	NOT YET: ALARM -6 +1
 ◦	Registers for delayed execution a call where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The gas (to convert from ETH at the later time) is given by S'[2]
 ◦	The number of blocks to wait before executing is S'[3]
 ◦	The input data of the call is given by T'[ S'[4] ... ( S'[4] + S'[5] - 1 ) ]
 ◦	(Thus the number of bytes of the transaction is given by S'[5].)
 ◦	Total gas used now is S'[3] * S'[5] * deferFee.
 ◦	Contract pays for itself to run at the defered time converting given amount of gas from its ETH balance; if it cannot pay it terminates as a bad transaction. TODO: include baseFee and allow miner freedom to determine whether to execute or not. If not, the next miner will have the chance.
 •	0x62: RETURN -2 +0
 ◦	Halts execution.
 ◦	R := T[ S'[0] ... ( S'[0] + S'[1] - 1 ) ]
 ◦	Where the output data of the call is specified as R.
 ◦	Any gas left over gets returned to caller (or in the case of the top-level call, the sender converted back to ETH).
 •	0x7f: SUICIDE -1 +0
 ◦	Halts execution.
 ◦	FOR ALL i: IF P[i] NOT EQUAL TO 0 THEN B[ S'[0] ] := B[ S'[0] ] + memoryFee
 ◦	B[ S'[0] ] := B[ S'[0] ] + B[ ADDRESS ]
 ◦	Removes all contract-related information from the Ethereum system.

## Appendix A: 

CALL has intrinsic parameters:

TO, VALUE, GAS, INOFFSET, INSIZE, OUTOFFSET, OUTSIZE

It also finishes an intrinsic boolean value relating to the success of the operation.

The process for evaluating CALL is as follows:

1. Let ROLLBACK := S where S is the current state.
2. Let program counter (PC) = 0.
Let it be known that all storage operations operate on TO's state.
Note that the memory is empty, thus (last used index + 1) = 0.
3. Set TXDATA to the first INSIZE bytes of memory starting from INOFFSET in the caller memory.
4. Repeat
    * Calculate the cost of the current instruction (see below), set to C
        * If the instruction is invalid or STOP, goto step 6.
    * If GAS < C then GAS := 0; S := ROLLBACK and evaluation finishes, returning false. 
    * GAS := GAS - C
    * Apply the instruction.
    Until an operation execution error has occured or the instruction is STOP, RETURN or SUICIDE.
5. If the output data of the call (R) is specified (through RETURN), then let the OUTSIZE bytes of caller memory beginning at OUTOFFSET.
6. Returns true.


## Appendix B

Creation of a contract is as before, except that should there be an address collision in the creation of contract, the address is incremented (as a bigendian int) and retried until it succeeds.


## Examples in HLL

A few new contracts:

### Namecoin

    if tx.data[0] > 1000 and !contract.storage[tx.data[0]]:
         contract.storage[tx.data[0]] = tx.data[1]

### Currency

    if !contract.storage[1000]:
        contract.storage[1000] = 1
                contract.storage[tx.sender] = 10^18
    else:
        fbal = contract.storage[tx.sender]
        tbal = contract.storage[tx.data[0]]
        if fbal >= tx.data[1]:
            contract.storage[tx.sender] = fbal - tx.data[1]
            contract.storage[tx.data[0]] = tbal + tx.data[1]
                
### Proprietary data feed

    if tx.sender = <owner here>:
        contract.storage[tx.data[0]] = tx.data[1]
    else:
        a = bytes(32)
        a[0] = contract.storage[tx.data[0]]
        return(a,32)

### Stdlib (callable namecoin)

Idea: [ 0, key, value ] to register, [ 1, key, returnsize, data... ] to use

        if tx.data[0] == 0:
                if tx.data[1] > 1000 and !contract.storage[tx.data[1]]:
                        contract.storage[tx.data[1]] = tx.data[2]
        else:
                a = bytes(tx.data[2])
                call(contract.storage[tx.data[1]],tx.value,tx.data+96,tx.datan-96,a,tx.data[2])
                return(a,tx.data[2])

### Compilation tricks

* Compile `bytes(expr)` as MSIZE DUP < EXPR > 1 SUB 0 PUSH SWAP MSTORE8
* At the start of every compiled program, if `tx.data` is used more than zero times put `<(n+1)*32> CALLDATA PUSH (n+1) DUP MSTORE` where `n` represents the number of variables in the program (known at compile-time).