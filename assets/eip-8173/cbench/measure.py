"""Verify the C port against the Python, then time the shapes."""
import os
import random
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import magic_validator as ref                       # noqa: E402
from test_validator import TESTS                    # noqa: E402
from bench_validator import (call_chain, jumpi_diamonds,  # noqa: E402
                             recursion_pump, straight_line)
from bench_minimal import mixed_chain               # noqa: E402

V = os.path.join(HERE, "validator")


def run_c(code, limit):
    with tempfile.NamedTemporaryFile(delete=False) as f:
        f.write(code)
        path = f.name
    out = subprocess.run([V, path, str(limit)], capture_output=True, text=True)
    os.unlink(path)
    return out.stdout.strip() == "1"


def main() -> int:
    bad = sum(run_c(bytes.fromhex(h), 16) != e for _, h, e in TESTS)
    print(f"vectors: {len(TESTS) - bad}/{len(TESTS)}")
    rng = random.Random(7979)
    alpha = bytes([0xB0, 0xB0, 0xB1, 0xB1, 0xB2, 0xB2, 0x56, 0x57, 0x5B,
                   0x5F, 0x60, 0x60, 0x61, 0x80, 0x90, 0x50, 0x00, 0x01,
                   0x36, 0x82, 0x93, 0xA1, 0xFD, 0xFE])
    mism = 0
    for _ in range(500):
        code = bytes(rng.choice(alpha) for _ in range(rng.randint(1, 48)))
        if run_c(code, 16) != ref.validate(code, stack_limit=16):
            mism += 1
    print(f"fuzz: {500 - mism}/500 agree")
    shapes = [("straight-line 24KB", straight_line(), 300),
              ("JUMPI diamonds 24KB", jumpi_diamonds(), 300),
              ("mixed subroutines 24KB", mixed_chain(1100), 300),
              ("call chain 2900", call_chain(2900), 300),
              ("recursion pump 2700 (worst case)", recursion_pump(), 30)]
    shape = os.path.join(HERE, "shape.bin")
    for name, code, reps in shapes:
        open(shape, "wb").write(code)
        out = subprocess.run([V, "-b", shape, str(reps)],
                             capture_output=True, text=True).stdout.strip()
        print(f"{name:36s} {out}")
    os.unlink(shape)
    return 1 if bad or mism else 0


if __name__ == "__main__":
    raise SystemExit(main())
