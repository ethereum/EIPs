ALTERATIONS FOR SUICIDE

Suicide's semantics are now:

All funds are immediately transferred to the nominated recipient account, but the account itself remains valid. It is tagged for destruction, to be completed simultaneously with all remaining gas being refunded to the origination account (this can safely happen simultaneously since the suicidal account is necessarily a contract account and the transaction originator is necessarily externally controlled, non-contract account).




All accounts become the same type; code/storage is just empty for the non-contract accounts.

Contract creation just specifies an initialiser; return of initialiser is body.

[ nonce, price, gas, to, value, data, v, r, s] (to is 0 for contract creation)

CALLDATACOPY instruction:
CALLDATACOPY MEMINDEX CALLDATAINDEX LEN?
CODESIZE
CODECOPY MEMINDEX CODEINDEX LEN

CALL is now [ gas, to, value, datain, datain_sz, dataout, dataout_sz ]
CREATE is now [ value, datain, datain_sz ]

Section 0x30 is now:
        ADDRESS,
        BALANCE,
        ORIGIN,
        CALLER,
        CALLVALUE,
        CALLDATALOAD,
        CALLDATASIZE,
        CALLDATACOPY = 0x37,
        CODESIZE = 0x38,
        CODECOPY = 0x39,
        GASPRICE = 0x3a,


Section 0x00 is now:
        STOP = 0x00,                ///< halts execution
        ADD,
        MUL,
        SUB,
        DIV,
        SDIV,
        MOD,
        SMOD,
        EXP,
        NEG,
        LT,
        GT,
        SLT = 0x0c,    // signed less than
        SGT = 0x0d,    // signed greater than
        EQ = 0x0e,
        NOT,




Use actual formula (LTMA) for gas limit:
gasLimit = floor((parent.gasLimit * (EMAFACTOR - 1) + floor(parent.gasUsed * BLK_LIMIT_FACTOR_NUM / BLK_LIMIT_FACTOR_DEN)) / EMA_FACTOR)

BLK_LIMIT_FACTOR_NUM = 6
BLK_LIMIT_FACTOR_DEN = 5
EMA_FACTOR = 1024

For network protocol, switch IP Address to a 4-byte byte-array rather than a list of numbers. 

Block format is now:
[ header, [ [tx0, s0, g0], [tx1, s1, g1], ...], [u0, u1, u2, ...] ]

Block header format:
[prevHash, unclesHash, coinbase, stateRoot, txsTrieRoot, difficulty, number, minGasPrice, gasLimit, gasUsed, timestamp, extraData, nonce]

extraData is a byte array length <= 1024.

minGasPrice can default to 10 szabo for now.

use triehash for the txlist instead of sha3ing the RLP:
triehash = Trie("").update(0, [tx0, s0, g0]).update(1, [tx1, s1, g1]).update( ..... ).root

Where [tx(i), s(i), g(i)] are the ith transaction, the state root after applying the ith transaction, and the gas after applying the ith transaction and 0,1, etc are just numbers

GAS costs:
Remove gas burn for tx data
5 GAS per byte of TXDATA
500 GAS per TXCOST
TXs no longer pay CREATE/CALL.


Genesis block

Genesis block is: ( B32(0, 0, ...), B32(sha3(B())), B20(0, 0, ...), B32(stateRoot), B32(0, 0, ...), P(2^22), P(0), P(0), P(1000000), P(0), P(0), B(), B32(sha3(B(42))), B(), B() )

Genesis block items (as hex) are:
parentHash: 00000000000000000000000000000000000000000000000000000000000000000
unclesHash: 1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347
coinbase: 0000000000000000000000000000000000000000
stateRoot: 11cc4aaa3b2f97cd6c858fcc0903b9b34b071e1798c91645f0e05e267028cb4a
txsTrieRoot: <<empty string>>
difficulty: 400000
number: <<empty string>>
mixGasPrice: <<empty string>>
gasLimit: 0f4240
gasUsed: <<empty string>>
timestamp: <<empty string>>
extraData: <<empty string>>
nonce: 04994f67dc55b09e814ab7ffc8df3686b4afb2bb53e60eae97ef043fe03fb829
transaction: <<empty string>>
uncles: <<empty string>>

Genesis block RLP encoded (as hex) is:
f8abf8a7a00000000000000000000000000000000000000000000000000000000000000000a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347940000000000000000000000000000000000000000a011cc4aaa3b2f97cd6c858fcc0903b9b34b071e1798c91645f0e05e267028cb4aa1680834000008080830f4240808080a004994f67dc55b09e814ab7ffc8df3686b4afb2bb53e60eae97ef043fe03fb829c0c0

Note: B32 specifies a byte array of length 32, B20 specifies a byte array of length 20, B32(0, 0, ...) specifies a byte array filled with zeroes, B() specifies an empty byte array, B(42) specified a byte array of length 1 whose only element is of vaue 42, P specifies a positive integer (to be encoded as a bytearray in bigendian with no leading zeroes).


Javascript Bindings

async & sync

async is getX(..., function() {})
sync is X(...)



