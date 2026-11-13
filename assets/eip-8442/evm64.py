"""Reference semantics for the 64-bit opcodes.

Every instruction is a pure function on Python ints.  Operands are
256-bit words of which only the low 64 bits are read; results are
64-bit values, pushed zero-extended.  Stack order follows the EVM:
the first argument is the top of the stack.

OPCODES maps each opcode to (name, function, gas, inputs, outputs).
Memory and calldata instructions take the buffer as a leading argument.
"""

MASK = (1 << 64) - 1
MOD = 1 << 64


def u(x):
    """The low 64 bits of x, as an unsigned integer."""
    return x & MASK


def s(x):
    """The low 64 bits of x, as a two's-complement signed integer."""
    x = x & MASK
    return x - MOD if x >> 63 else x


# Arithmetic


def add64(a, b):
    return (u(a) + u(b)) & MASK


def mul64(a, b):
    return (u(a) * u(b)) & MASK


def sub64(a, b):
    return (u(a) - u(b)) & MASK


def div64(a, b):
    return u(a) // u(b) if u(b) else 0


def sdiv64(a, b):
    a, b = s(a), s(b)
    if b == 0:
        return 0
    q = abs(a) // abs(b)                       # truncate toward zero
    return (-q if (a < 0) != (b < 0) else q) & MASK


def mod64(a, b):
    return u(a) % u(b) if u(b) else 0


def smod64(a, b):
    a, b = s(a), s(b)
    if b == 0:
        return 0
    r = abs(a) % abs(b)                        # sign of the dividend
    return (-r if a < 0 else r) & MASK


def addmod64(a, b, n):
    return (u(a) + u(b)) % u(n) if u(n) else 0


def mulmod64(a, b, n):
    return (u(a) * u(b)) % u(n) if u(n) else 0


def exp64(a, b):
    return pow(u(a), u(b), MOD)


def signextend64(b, x):
    b, x = u(b), u(x)
    if b >= 7:
        return x
    bit = 8 * b + 7
    low = (1 << (bit + 1)) - 1
    return x | (MASK ^ low) if x >> bit & 1 else x & low


# Comparison and bitwise


def lt64(a, b):
    return int(u(a) < u(b))


def gt64(a, b):
    return int(u(a) > u(b))


def slt64(a, b):
    return int(s(a) < s(b))


def sgt64(a, b):
    return int(s(a) > s(b))


def eq64(a, b):
    return int(u(a) == u(b))


def iszero64(a):
    return int(u(a) == 0)


def and64(a, b):
    return u(a) & u(b)


def or64(a, b):
    return u(a) | u(b)


def xor64(a, b):
    return u(a) ^ u(b)


def not64(a):
    return u(a) ^ MASK


def shl64(shift, x):
    return (u(x) << u(shift)) & MASK if u(shift) < 64 else 0


def shr64(shift, x):
    return u(x) >> u(shift) if u(shift) < 64 else 0


def sar64(shift, x):
    return (s(x) >> min(u(shift), 63)) & MASK


def clz64(a):
    return 64 - u(a).bit_length()


# Calldata and memory: the 256-bit instruction, reduced modulo 2^64


def _word(buf, offset):
    """32 bytes of buf at offset, zero-padded past the end, as an int."""
    chunk = bytes(buf[offset:offset + 32])
    return int.from_bytes(chunk + b"\x00" * (32 - len(chunk)), "big")


def calldataload64(calldata, i):
    return u(_word(calldata, u(i)))


def mload64(memory, offset):
    return u(_word(memory, u(offset)))


def mstore64(memory, offset, value):
    """Writes the 32-byte word u(value) at offset, extending memory as
    MSTORE does; memory is a bytearray."""
    offset = u(offset)
    end = offset + 32
    if len(memory) < end:
        memory.extend(b"\x00" * (end - len(memory)))
    memory[offset:end] = u(value).to_bytes(32, "big")


# Gas tiers

VERYLOW64, LOW64, MID64 = 2, 3, 5
EXP64_BASE, EXP64_PER_BYTE = 5, 25


def exp64_gas(b):
    """Static cost plus the per-byte cost of the exponent's low 64 bits."""
    return EXP64_BASE + EXP64_PER_BYTE * ((u(b).bit_length() + 7) // 8)


# opcode: (name, function, gas, inputs, outputs)
OPCODES = {
    0xC1: ("ADD64", add64, VERYLOW64, 2, 1),
    0xC2: ("MUL64", mul64, LOW64, 2, 1),
    0xC3: ("SUB64", sub64, VERYLOW64, 2, 1),
    0xC4: ("DIV64", div64, LOW64, 2, 1),
    0xC5: ("SDIV64", sdiv64, LOW64, 2, 1),
    0xC6: ("MOD64", mod64, LOW64, 2, 1),
    0xC7: ("SMOD64", smod64, LOW64, 2, 1),
    0xC8: ("ADDMOD64", addmod64, MID64, 3, 1),
    0xC9: ("MULMOD64", mulmod64, MID64, 3, 1),
    0xCA: ("EXP64", exp64, exp64_gas, 2, 1),
    0xCB: ("SIGNEXTEND64", signextend64, LOW64, 2, 1),
    0xCC: ("CALLDATALOAD64", calldataload64, VERYLOW64, 1, 1),
    0xCD: ("MLOAD64", mload64, VERYLOW64, 1, 1),
    0xCE: ("MSTORE64", mstore64, VERYLOW64, 2, 0),
    0xD0: ("LT64", lt64, VERYLOW64, 2, 1),
    0xD1: ("GT64", gt64, VERYLOW64, 2, 1),
    0xD2: ("SLT64", slt64, VERYLOW64, 2, 1),
    0xD3: ("SGT64", sgt64, VERYLOW64, 2, 1),
    0xD4: ("EQ64", eq64, VERYLOW64, 2, 1),
    0xD5: ("ISZERO64", iszero64, VERYLOW64, 1, 1),
    0xD6: ("AND64", and64, VERYLOW64, 2, 1),
    0xD7: ("OR64", or64, VERYLOW64, 2, 1),
    0xD8: ("XOR64", xor64, VERYLOW64, 2, 1),
    0xD9: ("NOT64", not64, VERYLOW64, 1, 1),
    0xDB: ("SHL64", shl64, VERYLOW64, 2, 1),
    0xDC: ("SHR64", shr64, VERYLOW64, 2, 1),
    0xDD: ("SAR64", sar64, VERYLOW64, 2, 1),
    0xDE: ("CLZ64", clz64, LOW64, 1, 1),
}
