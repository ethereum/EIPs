"""Benchmarks for the EIP-7979 reference validator (magic_validator.py).

Reproduces the complexity measurements: validation runs in time and
space linear in the size of the code.  Four shapes of near-24KB input:

  1. straight-line code       the plain walk, no control flow
  2. dense JUMPI diamonds     two work items per branch
  3. deep call chains         Phase 2's children-first sweep
  4. a recursion pump         the worst case: a huge mutually recursive
                              cycle, each entry eating one caller item
                              per lap, driving the repeat-until-stable
                              loop through ~1024 laps before rejection

Shapes 1-3 run at a flat cost per byte: linear, no asterisk.  Shape 4
shows the worst-case constant — time O(1024 * n), still linear in the
input because 1024 is the protocol's stack limit, not the attacker's
choice — and only invalid code gets near it.

Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
import time
import magic_validator as ref


def straight_line(pairs=12000):
    """PUSH0/POP pairs: the stack never exceeds one item."""
    return b"\x5f\x50" * pairs + b"\x00"


def jumpi_diamonds(size=24000):
    """CALLDATASIZE, PUSH2 t, JUMPI, PUSH0, POP, JUMPDEST — repeated."""
    d = bytearray()
    while len(d) + 9 < size:
        t = len(d) + 7                              # the JUMPDEST
        d += bytes([0x36, 0x61, t >> 8, t & 0xFF,
                    0x57, 0x5F, 0x50, 0x5B])
    return bytes(d) + b"\x00"


def call_chain(n_subs):
    """Top level calls sub 1; sub i calls sub i+1; the last returns.
    Valid iff n_subs <= 1024 (the return stack limit)."""
    code = bytearray([0x61, 0, 5, 0xB0, 0x00])      # PUSH2 5, CALLSUB, STOP
    pos = 5
    for _ in range(n_subs - 1):
        nxt = pos + 6
        code += bytes([0xB1, 0x61, nxt >> 8, nxt & 0xFF, 0xB0, 0xB2])
        pos += 6
    return bytes(code + bytearray([0xB1, 0xB2]))


def recursion_pump(n_subs=2700):
    """A single huge cycle: each entry pops one caller item, then calls
    the next; the last calls the first.  Every lap raises every entry's
    inputs by one, until the first crosses the stack limit: invalid."""
    code = bytearray([0x61, 0, 5, 0xB0, 0x00])
    pos = 5
    for i in range(n_subs):
        nxt = pos + 7 if i < n_subs - 1 else 5
        code += bytes([0xB1, 0x50, 0x61, nxt >> 8, nxt & 0xFF, 0xB0, 0xB2])
        pos += 7
    return bytes(code)


BENCHES = [
    ("straight-line, 12K push/pop pairs", straight_line(), True),
    ("dense JUMPI diamonds",              jumpi_diamonds(), True),
    ("call chain, 1000 subroutines",      call_chain(1000), True),
    ("call chain, 2900 subroutines",      call_chain(2900), False),
    ("recursion pump, 2700 entries",      recursion_pump(), False),
]

if __name__ == "__main__":
    for name, code, expected in BENCHES:
        start = time.perf_counter()
        got = ref.validate(code)
        ms = (time.perf_counter() - start) * 1000
        flag = "" if got == expected else "  <-- UNEXPECTED"
        print(f"{name:38s} {len(code):6d} bytes {ms:9.1f} ms"
              f"  valid={got}{flag}")
