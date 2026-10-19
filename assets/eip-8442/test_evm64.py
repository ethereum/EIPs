"""Tests for the 64-bit opcode semantics.

Two checks.  First, the defining property: each 64-bit instruction
computes what its 256-bit twin computes on the operands' low 64 bits —
zero-extended, or sign-extended for the signed instructions — reduced
modulo 2^64.  The twins are implemented here independently, from the
Yellow Paper semantics, and the property is checked on edge values and
on random words whose upper 192 bits are garbage.  Second, the fixed
vectors tabulated in the EIP's Test Cases, which this file prints as
markdown when run with --table.
"""
import random
import sys

import evm64 as e

M256 = (1 << 256) - 1
MOD256 = 1 << 256


def s256(x):
    return x - MOD256 if x >> 255 else x


def sext(x):
    """Sign-extend the low 64 bits of x to a 256-bit word."""
    return e.s(x) & M256


# The 256-bit instructions, as the Yellow Paper defines them.

def tdiv(a, b):
    q = abs(a) // abs(b)
    return -q if (a < 0) != (b < 0) else q


def tmod(a, b):
    r = abs(a) % abs(b)
    return -r if a < 0 else r


TWINS = {
    # name: (256-bit function, extension of each operand: "u" or "s")
    "ADD64": (lambda a, b: (a + b) & M256, "uu"),
    "MUL64": (lambda a, b: (a * b) & M256, "uu"),
    "SUB64": (lambda a, b: (a - b) & M256, "uu"),
    "DIV64": (lambda a, b: a // b if b else 0, "uu"),
    "SDIV64": (lambda a, b: tdiv(s256(a), s256(b)) & M256 if b else 0, "ss"),
    "MOD64": (lambda a, b: a % b if b else 0, "uu"),
    "SMOD64": (lambda a, b: tmod(s256(a), s256(b)) & M256 if b else 0, "ss"),
    "ADDMOD64": (lambda a, b, n: (a + b) % n if n else 0, "uuu"),
    "MULMOD64": (lambda a, b, n: (a * b) % n if n else 0, "uuu"),
    "EXP64": (lambda a, b: pow(a, b, MOD256), "uu"),
    "SIGNEXTEND64": (lambda b, x: x if b > 30 else (
        x | (M256 ^ ((1 << (8 * b + 8)) - 1)) if x >> (8 * b + 7) & 1
        else x & ((1 << (8 * b + 8)) - 1)), "uu"),
    "LT64": (lambda a, b: int(a < b), "uu"),
    "GT64": (lambda a, b: int(a > b), "uu"),
    "SLT64": (lambda a, b: int(s256(a) < s256(b)), "ss"),
    "SGT64": (lambda a, b: int(s256(a) > s256(b)), "ss"),
    "EQ64": (lambda a, b: int(a == b), "uu"),
    "ISZERO64": (lambda a: int(a == 0), "u"),
    "AND64": (lambda a, b: a & b, "uu"),
    "OR64": (lambda a, b: a | b, "uu"),
    "XOR64": (lambda a, b: a ^ b, "uu"),
    "NOT64": (lambda a: a ^ M256, "u"),
    "SHL64": (lambda sh, x: (x << sh) & M256 if sh < 256 else 0, "uu"),
    "SHR64": (lambda sh, x: x >> sh if sh < 256 else 0, "uu"),
    "SAR64": (lambda sh, x: (s256(x) >> min(sh, 255)) & M256, "us"),
    "CLZ64": (lambda a: 256 - a.bit_length(), "u"),
}

EDGE = [0, 1, 2, 7, 63, 64, 65, 255, 256,
        (1 << 63) - 1, 1 << 63, (1 << 63) + 1, (1 << 64) - 1,
        1 << 64, (1 << 64) + 1, (1 << 200) | 5, M256, M256 - 1]


def extend(x, how):
    return e.u(x) if how == "u" else sext(x)


def check_property(trials=20000, seed=64):
    rnd = random.Random(seed)
    by_name = {name: fn for _, (name, fn, _, _, _) in e.OPCODES.items()}
    for name, (twin, how) in TWINS.items():
        f = by_name[name]
        n = len(how)
        cases = []
        for _ in range(trials // len(TWINS)):
            cases.append([rnd.choice(EDGE) if rnd.random() < 0.3
                          else rnd.getrandbits(rnd.choice((64, 256)))
                          for _ in range(n)])
        for i in range(len(EDGE)):
            cases.append([EDGE[(i + k) % len(EDGE)] for k in range(n)])
        for args in cases:
            want = twin(*[extend(x, h) for x, h in zip(args, how)]) & e.MASK
            if name == "CLZ64":
                want -= 192
            got = f(*args)
            assert got == want, (name, [hex(x) for x in args], hex(got), hex(want))
            assert 0 <= got <= e.MASK


# Fixed vectors: (name, inputs top first, expected output).  Memory
# and calldata vectors are handled separately below.

X = 0x10000000000000005          # 2^64 + 5: garbage above bit 63
VECTORS = [
    ("ADD64", [0xFFFFFFFFFFFFFFFF, 1], 0),
    ("ADD64", [X, 7], 12),
    ("SUB64", [0, 1], 0xFFFFFFFFFFFFFFFF),
    ("MUL64", [0x100000000, 0x100000000], 0),
    ("DIV64", [16, 3], 5),
    ("DIV64", [1, 0], 0),
    ("SDIV64", [0xFFFFFFFFFFFFFFF8, 2], 0xFFFFFFFFFFFFFFFC),
    ("SDIV64", [0x8000000000000000, 0xFFFFFFFFFFFFFFFF], 0x8000000000000000),
    ("SDIV64", [0x8000000000000000, 0], 0),
    ("MOD64", [17, 5], 2),
    ("MOD64", [17, 0], 0),
    ("SMOD64", [0xFFFFFFFFFFFFFFF9, 3], 0xFFFFFFFFFFFFFFFF),
    ("SMOD64", [0xFFFFFFFFFFFFFFF9, 0], 0),
    ("ADDMOD64", [0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 7], 2),
    ("ADDMOD64", [1, 2, 0], 0),
    ("MULMOD64", [0x8000000000000000, 0x8000000000000000, 0xFFFFFFFFFFFFFFFF], 0x4000000000000000),
    ("MULMOD64", [2, 3, 0], 0),
    ("EXP64", [2, 64], 0),
    ("EXP64", [3, 40], pow(3, 40, 1 << 64)),
    ("SIGNEXTEND64", [0, 0x80], 0xFFFFFFFFFFFFFF80),
    ("SIGNEXTEND64", [1, 0x80], 0x80),
    ("SIGNEXTEND64", [7, 0x80], 0x80),
    ("LT64", [X, 7], 1),
    ("GT64", [7, X], 1),
    ("SLT64", [0xFFFFFFFFFFFFFFFF, 0], 1),
    ("SGT64", [0, 0xFFFFFFFFFFFFFFFF], 1),
    ("EQ64", [X, 5], 1),
    ("ISZERO64", [1 << 64], 1),
    ("AND64", [X, 0xFF], 5),
    ("OR64", [X, 2], 7),
    ("XOR64", [0xFF, 0x0F], 0xF0),
    ("NOT64", [0], 0xFFFFFFFFFFFFFFFF),
    ("SHL64", [63, 1], 0x8000000000000000),
    ("SHL64", [64, 1], 0),
    ("SHL64", [X - 4, 1], 2),           # the shift too is read modulo 2^64
    ("SHR64", [1, 0x8000000000000000], 0x4000000000000000),
    ("SHR64", [64, 0x8000000000000000], 0),
    ("SAR64", [1, 0x8000000000000000], 0xC000000000000000),
    ("SAR64", [64, 0x8000000000000000], 0xFFFFFFFFFFFFFFFF),
    ("SAR64", [100, 0x8000000000000000], 0xFFFFFFFFFFFFFFFF),
    ("CLZ64", [1], 63),
    ("CLZ64", [1 << 64], 64),
]

GAS_VECTORS = [                  # EXP64: exponent (top first: base, exponent)
    ([2, 0], 5),
    ([2, 255], 30),
    ([2, 256], 55),
    ([2, 1 << 64], 5),           # exponent 2^64 reads as 0: result 1
]

BUF = bytes(range(40))            # bytes 0x00..0x27


def check_vectors():
    by_name = {name: (fn, gas) for _, (name, fn, gas, _, _) in e.OPCODES.items()}
    for name, args, want in VECTORS:
        got = by_name[name][0](*args)
        assert got == want, (name, args, hex(got), hex(want))
    for args, gas in GAS_VECTORS:
        assert e.exp64_gas(args[1]) == gas, (args, e.exp64_gas(args[1]), gas)
    assert e.exp64(2, 1 << 64) == 1
    # calldata
    assert e.calldataload64(BUF, 0) == 0x18191A1B1C1D1E1F
    assert e.calldataload64(BUF, 8) == 0x2021222324252627
    assert e.calldataload64(BUF, 16) == 0
    assert e.calldataload64(BUF, 1 << 64) == 0x18191A1B1C1D1E1F   # offset mod 2^64
    # memory
    mem = bytearray(BUF[:32])
    assert e.mload64(mem, 0) == 0x18191A1B1C1D1E1F
    assert e.mload64(mem, 8) == 0 and len(mem) == 32   # the model does not grow on load
    e.mstore64(mem, 0, X)
    assert mem[:32] == (5).to_bytes(32, "big")
    assert e.mload64(mem, 0) == 5
    e.mstore64(mem, 8, 0xFFFFFFFFFFFFFFFF)
    assert len(mem) == 40 and mem[8:32] == bytes(24) and mem[32:40] == b"\xff" * 8


def table():
    print("| Op | Inputs, top first | Output |")
    print("|----|-------------------|--------|")
    for name, args, want in VECTORS:
        print(f"| `{name}` | {', '.join(hex(a) for a in args)} | {hex(want)} |")


if __name__ == "__main__":
    check_property()
    check_vectors()
    if "--table" in sys.argv:
        table()
    else:
        print("ok")
