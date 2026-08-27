"""Benchmarks for the reference validator (minimal_validator.py).

Reproduces the Python numbers quoted under "Why it is linear": 2-3
microseconds per byte on ordinary shapes, with the recursion pump —
the demand relaxation's O(1024 * n) worst case, invalid code — well
above that.  The bounds-proving validator (magic_validator.py) runs
alongside for comparison; cbench/ measures the same costs natively.

Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
import time

import magic_validator as full
import minimal_validator as mv
from bench_validator import call_chain, jumpi_diamonds, recursion_pump, straight_line


def mixed_chain(n_subs):
    """Subroutines with 16-byte straight-line bodies: a realistic mix."""
    code = bytearray([0x61, 0, 5, 0xB0, 0x00])
    pos = 5
    for i in range(n_subs):
        body = [0x5F, 0x50] * 8
        if i < n_subs - 1:
            nxt = pos + 22
            unit = [0xB1] + body + [0x61, nxt >> 8, nxt & 0xFF, 0xB0, 0xB2]
        else:
            unit = [0xB1] + body + [0xB2]
        code += bytes(unit)
        pos += len(unit)
    return bytes(code)


BENCHES = [
    ("straight-line, 12K push/pop pairs", straight_line()),
    ("dense JUMPI diamonds",              jumpi_diamonds()),
    ("mixed subroutines, ~24KB",          mixed_chain(1100)),
    ("call chain, 2900 subroutines",      call_chain(2900)),
    ("recursion pump, 2700 entries",      recursion_pump()),
]

if __name__ == "__main__":
    print(f"{'shape':36s} {'bytes':>6s} {'minimal':>10s} {'bounds-proving':>15s}")
    for name, code in BENCHES:
        t = time.perf_counter()
        rm = mv.validate(code)
        dm = (time.perf_counter() - t) * 1e6 / len(code)
        t = time.perf_counter()
        rf = full.validate(code)
        df = (time.perf_counter() - t) * 1e6 / len(code)
        print(f"{name:36s} {len(code):6d} {dm:7.2f} us {df:12.2f} us"
              f"  minimal={rm} full={rf}")
