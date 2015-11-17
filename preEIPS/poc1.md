Testnet simplifications:

1. Difficulty formula

D(genesisblock) = 2^22
D(block) = D(block.parent) + D(block.parent) / 1024 * (1 if block.timestamp < block.parent.timestamp + 42 else -1)


2. Fees

All fees are burned

{ poc-2:
txFee = 100x
x = 100000000000000 = 10^14
blockReward = 1500000000000000000 = 1.5 * 10^18;
}

{ poc-3:
stepFee = 1x 
dataFee = 20x
memoryFee = 5x
extroFee = 40x
cryptoFee = 20x
newContractFee = 100x
txFee = 100x
x = 100000000000000 = 10^14
blockReward = 1500000000000000000 = 1.5 * 10^18;
}


3. Premine

We should all put our ethereum addresses made with the pyethtool.py script at https://github.com/ethereum/website/blob/master/pyethtool/pyethtool.py below:

Each address gets 2^200 units premined

{ poc-2:
8a40bfaa73256b60764c1bf40675a99083efb075 (G)
93658b04240e4bd4046fd2d6d417d20f146f4b43 (J)
1e12515ce3e0f817a4ddef9ca55788a1d66bd2df (V)
80c01a26338f0d905e295fccb71fa9ea849ffa12 (A)
}
{ poc-3:
8a40bfaa73256b60764c1bf40675a99083efb075 (G)
e6716f9544a56c530d868e4bfbacb172315bdead (J)
1e12515ce3e0f817a4ddef9ca55788a1d66bd2df (V)
1a26338f0d905e295fccb71fa9ea849ffa12aaf4 (A)
}


4. PoW

sha(sha(blockheader_without_nonce) ++ nonce) <= 2^256 / difficulty

where:
nonce and all outputs from sha are byte arrays of length 32;
++ is the concatenation operator;
<= operands are treated as bytearrays in BE format.


5. Uncles

Nodes should NOT attempt to collect any uncles, although uncles should be included in the reward calculation.


6. Block & transactions formats:

Though RLP is data-agnostic, it does specify a canonical representation for integer quantities. It is big-endian with no leading zero-bytes. Thus for elements than feasibly can be stored as integers, it becomes important to specify whether they should adhere to this canonical representation or be left in some other (perhaps more 'native') format.

In the case of counts, balances, fees and amounts of wei, the canon-integer form must be used when storing in RLP. We call these INTs.

In the case of hashes (256-bit or 160-bit), user-visible strings and specialised byte-arrays (e.g. hex-prefix notation from the trie), they should be stored as unformatted byte-array data and not altered into some other form. We call these BINs.

When interpreting RLP data, clients are required to consider non-canonical INT fields in the same way as otherwise invalid RLP data and dismiss it completely.

Specifically:

for the Block header:
[
    parentHash: BIN,
    unclesHash: BIN,
    coinbase: BIN,
    stateRoot: BIN,
    transactionsHash: BIN,
    difficulty: INT,
    timestamp: INT,
    extraData: BIN,
    nonce: BIN
]

(note: 'nonce', the last element, refers to a hash here and so is binary)

for entries in the State trie for normal addresses:
[
    balance: INT,
    nonce: INT
]

and for contract addresses:
[
    balance: INT,
    nonce: INT,
    contractRoot: BIN
]

(note: 'nonce', the second element, refers to a tx-count here and so is integer)

for transactions:
[
    nonce: INT,
    recvAddr: BIN,
    value: INT,
    data: [...],
    v: INT,
    r: INT,
    s: INT
]

(note: 'nonce', the first element, refers to a tx-count here and so is integer)

The nonce in the transaction refers to the total amount of transactions send from the address up until that moment in time. Not the total amount (ie. equal to the sender's nonce specified in the address)

for blocks, there are no immediate data field, but lists:
[
    blockHeader: [...]
    uncleList: [uncleHash1: BIN, uncleHash2: BIN, ...]
    txList: [...]
]

Uncle-blocks contain only the uncle's header.


8. Block hashes

When mining a block we use the header of the block without the nonce. This hash is also used during nonce validation [prevHash, uncleHash, coinbase, stateRoot, transactionsHash, difficulty, timestamp, extraData]

When saving and refering to blocks (e.g. broadcasting, fetching, etc) we use the hash of the entire block ie [header (with nonce), uncle list, tx list]


9. Genesis Block

The header of the genesis block is 8 items, and is specified thus:

[zeroHash256, sha3(rlp([])), zeroHash160, state_root, sha3(rlp([])), 2**22, 0, "", 42]

zeroHash256 refers to the parent hash, a 256-bit hash which is all zeroes.
zeroHash160 refers to the coinbase address, a 160-bit hash which is all zeroes.
2^22 refers to the difficulty.
0 refers to the timestamp (the Unix epoch).
"" refers to the extradata.
sha3(rlp([])) values refer to the hashes of the transaction and uncle lists, both empty.

The SHA-3 hash of the RLP of this block (in its entirety) is:

ab6b9a5613970faa771b12d449b2e9bb925ab7a369f0a4b86b286e9d540099cf


10. VM

When a contract address receives a transaction, a virtual machine is initiated with the contract's state.

10. a. Terms

There exists a stack of variable size that stores 256-bit values at each location. (Note: most instructions operate solely on the stack altering its state in some way.)

S'[i] is the ith item counting down from the top of the pre-stack (i.e. the stack immediately after instruction execution), with the top of the stack corresponding to i == 0.

S[i] is the ith item counting down from the top of the post-stack (i.e. the stack immediately prior to instruction execution), with the top of the stack corresponding to i == 0.


The exists a permanent store addressable by a 256-bit value that stores 256-bit values at each location.

P'[i] is the permanent store (sometimes refered to as 'state' or 'store') of the VM at index i counting from zero PRIOR to instruction execution.

P[i] is the permanent store (sometimes refered to as 'state' or 'store') of the VM at index i counting from zero AFTER to instruction execution.


The exists a temporary store addressable by a 256-bit value that stores 256-bit values at each location.

T'[i] is the temporary store (sometimes refered to as 'memory') of the VM at index i counting from zero PRIOR to instruction execution.

T[i] is the temporary store (sometimes refered to as 'memory') of the VM at index i counting from zero AFTER instruction execution.


PC' is the program counter PRIOR to instruction execution.

PC is the program counter AFTER instruction execution.


FEE(I, S', P', D) is the fee associated with the execution of instruction I with a machine of stack S', permanent store P' and which has already completed D operations.

It is defined as F where:

IF I == SSTORE AND P[ S'[0] ] != 0 AND S'[1] == 0 THEN
    F = S + dataFee - memoryFee
IF I == SSTORE AND P[ S'[0] ] == 0 AND S'[1] != 0 THEN
    F = S + dataFee + memoryFee
IF I == SLOAD
    F = S + dataFee
IF I == EXTRO OR I == BALANCE
    F = S + extroFee
IF I == MKTX
    F = S + txFee
IF I == SHA256 OR I == SHA3 OR I == RIPEMD160 OR I == ECMUL OR I == ECADD
    OR I == ECSIGN OR I == ECRECOVER OR I == ECVALID THEN
    F = S + cryptoFee 

Where:

S = D >= 16 ? stepFee : 0

Notably, MLOAD and MSTORE have no associated 'memory' cost. SLOAD and SSTORE both have a per-time fee (dataFee). There is also a usage 'fee' (not really a fee as it is all ultimately returned to the contract) that is owed to the contract for all non-zero permanent storage elements. This 'fee', memoryFee, is paid by the contract when a permanent storage address is set to a non-zero value and recovered when that address is set to a zero value. On SUICIDE, all permanent storage is dissolved and so all outstanding memoryFees are recovered.
    
    
B[ A ] is the balance of the address given by A, with A interpreted as an address.

ADDRESS is the address of the present contract.


10. b. Initial Operation

STEPSDONE := 0
PC' := 0
FOR ALL i: T'[i] := 0
S' is initialised such that its cardinality is zero (i.e. the stack starts empty).
P' must be equal to the value of P when the previous execution halted.

10. c. General Operation

The given steps are looped:
1. Execution halts if B[ ADDRESS ] < F( P'[PC'], S', P', STEPSDONE )
2. B[ ADDRESS ] := B[ ADDRESS ] - F( P'[PC'], S', P', STEPSDONE )
3. The operation given by P'[PC'] determines PC, P, T, S.
4. PC' := PC; P' := P; T' := T; S' := S; STEPSDONE := STEPSDONE + 1

10. d. VM Operations

Summary line:
<Op-code>: <Mnemonic> -<R> +<A>

If PC is not defined explicitly, then it must be assumed PC := PC' + 1. Exceptions are PUSH, JMP and JMPI.

The cardinality of S (i.e. size of the stack) is altered by A - R between S & S', by adding or removing items as necessary from the front.

Where:
R: The minimal cardinality of the stack for this instruction to proceed. If this is not achieved then the machine halts with an stack underflow exception. (Note: In some cases of some implementations, this is also the number of values "popped" from the implementation's stack during the course of instruction execution.)
(A - R): The net change in cardinality of the stack over the course of instruction execution.

FOR ALL i: if S[i] is not defined explicitly, then it must be assumed S[i] := S'[i + R - A] where i + R >= A.
FOR ALL i: if T[i] is not defined explicitly, then it must be assumed T[i] := T'[i].
FOR ALL i: if P[i] is not defined explicitly, then it must be assumed P[i] := P'[i].

The expression (COND ? ONE : ZERO), where COND is an expression and ONE and ZERO are both value placeholders, evaluates to ONE if COND is true, and ZERO if COND is false. This is similar to the C-style ternary operator.

When a 32-byte machine datum is interpreted as a 160-bit address or hash, the rightwards 20 bytes are taken (i.e. the low-order bytes when interpreting the data as Big-Endian).

++ is the concatenation operator; all operands are byte arrays (mostly 32-byte arrays here, since that's the size of the VM's data & address types).

LEFT_BYTES(A, n) returns the array bytes comprising the first (leftmost) n bytes of the 32 byte array A, which can be considered equivalent to a single value in the VM.

10. e. VM Op-code Set

 •	0x00: STOP -0 +0
 ◦	Halts execution.
 •	0x01: ADD -2 +1
 ◦	S[0] := S'[0] + S'[1]
 •	0x02: MUL -2 +1
 ◦	S[0] := S'[0] * S'[1]
 •	0x03: SUB -2 +1
 ◦	S[0] := S'[0] + S'[1]
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
 •	0x0b: LE -2 +1
 ◦	S[0] := S'[0] <= S'[1] ? 1 : 0
 •	0x0c: GT -2 +1
 ◦	S[0] := S'[0] > S'[1] ? 1 : 0
 •	0x0d: GE -2 +1
 ◦	S[0] := S'[0] >= S'[1] ? 1 : 0
 •	0x0e: EQ -2 +1
 ◦	S[0] := S'[0] == S'[1] ? 1 : 0
 •	0x0f: NOT -1 +1
 ◦	S[0] := S'[0] == 0 ? 1 : 0
 •	0x10: MYADDRESS -0 +1
 ◦	S[0] := ADDRESS
 •	0x11: TXSENDER -0 +1
 ◦	S[0] := A
 ◦	Where A is the address of the sender of the transaction that initiated this instance.
 •	0x12: TXVALUE -0 +1
 ◦	S[0] := V
 ◦	Where V is the value of the transaction that initiated this instance.
 •	0x13: TXDATAN -0 +1
 ◦	S[0] := N
 ◦	Where N is the number of data items of the transaction that initiated this instance.
 •	0x14: TXDATA -1 +1
 ◦	S[0] := D[ S'[0] ]
 ◦	Where D[i] is the ith data item, counting from zero, of the transaction that initiated this instance.
 •	0x15: BLK_PREVHASH -0 +1
 ◦	S[0] := H
 ◦	Where H is the SHA3 hash of the previous block.
 •	0x16: BLK_COINBASE -0 +1
 ◦	S[0] := A
 ◦	Where A is the coinbase address of the current block.
 •	0x17: BLK_TIMESTAMP -0 +1
 ◦	S[0] := T
 ◦	Where T is the timestamp of the current block (given as the Unix time_t when this block began its existence).
 •	0x18: BLK_NUMBER -0 +1
 ◦	S[0] := N
 ◦	Where N is the block number of the current block (counting upwards from genesis block which has N == 0).
 •	0x19: BLK_DIFFICULTY -0 +1
 ◦	S[0] := D
 ◦	Where D is the difficulty of the current block.
 •	0x1a: BLK_NONCE -0 +1
 ◦	S[0] := H
 ◦	Where H is the none of the previous block.
 •	0x1b: BASEFEE -0 +1
 ◦	S[0] := V
 ◦	Where V is the value of the current base fee (i.e. the fee multiplier).
 •	 0x20: SHA256 -(minimum: 1) +1
 ◦	S[0] := SHA256( S'[1] ++ S'[2] ++ ... S'[N] ++ LEFT_BYTES(S'[N], R) )
 ◦	Where:
 ◦	N = FLOOR(S'[0] / 32)
 ◦	R = S'[0] % 32
 •	 0x21: RIPEMD160 -(minimum: 1) +1
 ◦	S[0] := RIPEMD160( S'[1] ++ S'[2] ++ ... S'[N] ++ LEFT_BYTES(S'[N], R) )
 ◦	Where all entities are as in SHA256 (0x20), above.
 •	0x22: ECMUL -3 +1
 •	0x23: ECADD -4 +1
 •	0x24: ECSIGN -2 +1
 •	0x25: ECRECOVER -4 +1
 •	0x26: ECVALID -2 +1
 •	0x27: SHA3 -(minimum: 1) +1
 ◦	S[0] := SHA3( S'[1] ++ S'[2] ++ ... S'[N] ++ LEFT_BYTES(S'[N], R) )
 ◦	Where all entities are as in SHA256 (0x20), above.
 •	0x30: PUSH X -0 +1
 ◦	PC := PC' + 2
 ◦	S[0] := P[PC' + 1]
 •	0x31: POP -1 +0
 •	0x32: DUP -1 +2
 ◦	S[0] := S'[0]
 •	0x33: SWAP -2 +2
 ◦	S[0] := S'[1]
 ◦	S[1] := S'[0]
 •	0x34: MLOAD -1 +1
 ◦	S[0] := T'[ S'[0] ]
 •	0x35: MSTORE -2 +0
 ◦	T[ S'[0] ] := S'[1]
 •	0x36: SLOAD -1 +1
 ◦	S[0] := P'[ S'[0] ]
 •	0x37: SSTORE -2 +0
 ◦	P[ S'[0] ] := S'[1]
 •	0x38: JMP -1 +0
 ◦	PC := S'[0]
 •	0x39: JMPI -2 +0
 ◦	PC := S'[0] == 0 ? PC' : S'[1]
 •	0x3a: IND -0 +1
 ◦	S[0] := PC
 •	0x3b: EXTRO -2 +1
 ◦	S[0] := CONTRACT[ S'[0] ].P[ S'[1] ]
 ◦	Where CONTRACT[ A ].P is the permanent store of the contract A, with A interpreted as an address.
 •	0x3c: BALANCE -1 +1
 ◦	S[0] := B[ S'[0] ]
 •	0x3d: MKTX -(minimum: 3) +0
 ◦	Executes a transaction where:
 ◦	The recipient is given by S'[0], when interpreted as an address.
 ◦	The value is given by S'[1]
 ◦	The data of the transaction is given by S'[3], S'[4], ... S'[ 2 + S'[2] ]
 ◦	(Thus the number of data items of the transaction is given by S'[2].)
 •	0x3f: SUICIDE -1 +0
 ◦	Halts execution.
 ◦	FOR ALL i: IF P[i] NOT EQUAL TO 0 THEN B[ S'[0] ] := B[ S'[0] ] + memoryFee
 ◦	B[ S'[0] ] := B[ S'[0] ] + B[ ADDRESS ]
 ◦	Removes all contract-related information from the Ethereum system.


11. VM Memory State

The memory state of the contract (which forms contractRoot) is formed by a secondary trie which may exist within the same database as the rest of the state. The root of this secondary trie defines the contractRoot.

Whereas the main state trie has keys of length 160-bit (pertaining to an address in ethereum), the secondary contract state trie has keys of length 256-bit (pertaining to a point in memory of the virtual machine). In both cases, the key is a fixed length number of bytes. Leftly zeroes are not removed.

Both tries have values encoded as RLP, whereby the value is interpreted as a single RLP element that is a 256-bit binary block (i.e. a 32 byte array).

11. a. No Zeroes Stored in Trie

Nodes in the memory trie may have any value EXCEPT zero (which is encoded in RLP as the empty byte array). We are able to do this because we assume that the value of a memory location, if not specified in the trie, defaults to zero.

If a location in memory ever becomes zero, no value is stored in the trie for that location (requiring the removal of an entry from the trie if the previous value at that location is non-zero). If a memory lookup (i.e. SLOAD) ever happens for an undefined key, then the value returned is zero.


12. VM Tests

