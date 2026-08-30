"""Tests for the reference validator (minimal_validator.py).

Shares the vectors of test_validator.py, run with STACK_LIMIT reduced
to 16 so the overflow examples stay small.  The overflow-only
rejections of the bounds-proving validator are valid here — overflow
is not validated — and every other expectation, underflow included,
is unchanged.
Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
import minimal_validator as ref
from test_validator import TESTS

# Rejected only for overflow by the bounds-proving validator.
OVERFLOW_ONLY = {
    "17 pushes overflow",
    "sub high amplified, 2 calls",
    "call chain depth 17",
}


def main() -> int:
    failures = 0
    for name, hexcode, expected in TESTS:
        want = True if name in OVERFLOW_ONLY else expected
        got = ref.validate(bytes.fromhex(hexcode), stack_limit=16)
        ok = got == want
        if not ok:
            failures += 1
        print(f"{'PASS' if ok else 'FAIL'}  {name:32s} "
              f"code=0x{hexcode:<28s} expected={want} got={got}")
    print(f"\n{len(TESTS) - failures}/{len(TESTS)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
