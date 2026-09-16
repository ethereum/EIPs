"""The EVM opcode table shared by the EIP-8337 validators.

opcode_info() gives each opcode's size, stack pops and pushes, and
whether it terminates its basic block; push_value() reads a PUSH's
immediate.  Current through the Prague fork, plus this EIP's three
instructions at their placeholder values: CALLSUB=0xB0, CALLDEST=0xB1,
RETURNSUB=0xB2.
"""

JUMP, JUMPI, JUMPDEST = 0x56, 0x57, 0x5B
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
PUSH0, PUSH32 = 0x5F, 0x7F


def opcode_info(op):
    """Return (size, pops, pushes, is_terminator); size 0 is invalid.
    A terminator cannot fall through to the next instruction."""
    if PUSH0 <= op <= PUSH32:                # PUSH0..PUSH32
        return op - PUSH0 + 1, 0, 1, False
    if 0x80 <= op <= 0x8F:                   # DUP1..DUP16
        n = op - 0x7F
        return 1, n, n + 1, False
    if 0x90 <= op <= 0x9F:                   # SWAP1..SWAP16
        n = op - 0x8F
        return 1, n + 1, n + 1, False
    if 0xA0 <= op <= 0xA4:                   # LOG0..LOG4
        return 1, op - 0xA0 + 2, 0, False
    if op in TABLE:
        pops, pushes, term = TABLE[op]
        return 1, pops, pushes, term
    return 0, 0, 0, False


# (pops, pushes, is_terminator) for the remaining opcodes, current
# through the Prague fork, plus this EIP's three.
TABLE = {
    0x00: (0, 0, True),                                       # STOP
    **{op: (2, 1, False) for op in (                          # binary operations:
        *range(0x01, 0x08), 0x0A, 0x0B,                       #   ADD..SMOD, EXP, SIGNEXTEND
        *range(0x10, 0x15), 0x16, 0x17, 0x18,                 #   LT..EQ, AND, OR, XOR
        *range(0x1A, 0x1E), 0x20)},                           #   BYTE..SAR, KECCAK256
    0x08: (3, 1, False), 0x09: (3, 1, False),                 # ADDMOD, MULMOD
    **{op: (1, 1, False) for op in (                          # unary operations:
        0x15, 0x19, 0x31, 0x35, 0x3B, 0x3F,                   #   ISZERO, NOT, BALANCE, CALLDATALOAD, EXTCODESIZE, EXTCODEHASH
        0x40, 0x49, 0x51, 0x54, 0x5C)},                       #   BLOCKHASH, BLOBHASH, MLOAD, SLOAD, TLOAD
    **{op: (0, 1, False) for op in (                          # push one item:
        0x30, 0x32, 0x33, 0x34, 0x36, 0x38, 0x3A, 0x3D,       #   ADDRESS..RETURNDATASIZE
        *range(0x41, 0x49), 0x4A, 0x58, 0x59, 0x5A)},         #   COINBASE..BASEFEE, BLOBBASEFEE, PC, MSIZE, GAS
    **{op: (3, 0, False) for op in (0x37, 0x39, 0x3E, 0x5E)}, # CALLDATACOPY, CODECOPY, RETURNDATACOPY, MCOPY
    0x3C: (4, 0, False),                                      # EXTCODECOPY
    0x50: (1, 0, False),                                      # POP
    **{op: (2, 0, False) for op in (0x52, 0x53, 0x55, 0x5D)}, # MSTORE, MSTORE8, SSTORE, TSTORE
    JUMP: (1, 0, True), JUMPI: (2, 0, False), JUMPDEST: (0, 0, False),
    CALLSUB: (1, 0, True), CALLDEST: (0, 0, False), RETURNSUB: (0, 0, True),
    0xF0: (3, 1, False), 0xF5: (4, 1, False),                 # CREATE, CREATE2
    0xF1: (7, 1, False), 0xF2: (7, 1, False),                 # CALL, CALLCODE
    0xF4: (6, 1, False), 0xFA: (6, 1, False),                 # DELEGATECALL, STATICCALL
    0xF3: (2, 0, True), 0xFD: (2, 0, True),                   # RETURN, REVERT
    0xFE: (0, 0, True), 0xFF: (1, 0, True),                   # INVALID, SELFDESTRUCT
}


def push_value(code, pc):
    """Immediate value of the PUSH at pc, zero-padded past end of code."""
    n = code[pc] - PUSH0
    return int.from_bytes(code[pc + 1:pc + 1 + n].ljust(n, b"\0"), "big")
