"""Tests for the bounds-proving validator (magic_validator.py).

These are the shared vectors: test_minimal.py runs the same TESTS
against the reference validator, with the bounds-only rejections
flipped to valid.  STACK_LIMIT is reduced to 16 so that the overflow
tests are reachable with small vectors; the algorithm is independent
of the limit.
Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
import magic_validator as ref

TEST_STACK_LIMIT = 16


def call_chain(n: int) -> str:
    """Main calls sub 0; sub i calls sub i+1; the last sub returns.
    Return-stack depth reaches n."""
    code = bytes.fromhex("6004B000")           # PUSH1 4, CALLSUB, STOP
    for i in range(n - 1):
        nxt = 4 + 5 * (i + 1)                  # each sub is 5 bytes
        code += bytes([0xB1, 0x60, nxt, 0xB0, 0xB2])
    code += bytes([0xB1, 0xB2])                # last sub: CALLDEST, RETURNSUB
    return code.hex().upper()

TESTS = [
    # (name, bytecode hex, expected validity)

    # --- EIP test cases ---
    ("simple routine (EIP)",       "6004B000B1B2", True),
    ("two-level subroutines (EIP)","6004B000B16009B0B2B1B2", True),
    ("dest outside code (EIP)",    "60FFB000B1B2", False),
    ("bare RETURNSUB (EIP)",       "B2", False),
    ("subroutine at end (EIP)",    "600556B1B25B6003B0", True),

    # --- constraint 1: opcodes ---
    ("lone STOP",                  "00", True),
    ("undefined opcode",           "21", False),
    ("INVALID is valid",           "FE", True),
    ("undefined at return point",  "6004B021B1B2", False),

    # --- constraints 2/3: destinations ---
    ("JUMP into PUSH immediate",   "600156", False),
    ("JUMP to visited non-JUMPDEST", "5F5F01600256", False),
    ("JUMP not push-preceded",     "365B56", False),
    ("PUSH0-preceded JUMP",        "5B5F56", True),
    ("CALLSUB to JUMPDEST",        "6004B0005B", False),

    # --- constraint 4: underflow, return stack ---
    ("ADD on empty stack",         "01", False),
    ("POP on empty stack",         "50", False),
    ("sub consumes caller arg",    "6002600BB06003600BB000B18002B2", True),
    ("sub underflows outer",       "6004B000B15050B2", False),
    ("fall into sub, RETURNSUB",   "B1B2", False),

    # --- constraint 5: offsets and net effects ---
    ("JUMPI arms disagree at join","366005575F5B00", False),
    ("JUMPI diamond consistent",   "366006575F005B5F00", True),
    ("two RETURNSUBs disagree",    "6004B000B136600A57B25B5FB2", False),
    ("two RETURNSUBs agree",       "6004B000B136600A57B25B5F50B2", True),
    ("stack-neutral loop",         "5B600056", True),

    # --- reuse and multiple entry points ---
    ("called at two depths",       "6002600BB06003600BB000B18002B2", True),
    ("fall-through second entry",  "6008B05F600AB000B15FB150B2", True),

    # --- recursion ---
    ("recursion, no base case",    "6004B000B16004B0B2", True),
    ("recursion eats caller stack","6004B000B1506004B0", False),

    # --- call elimination: JUMP/JUMPI to a CALLDEST ---
    ("jump to CALLDEST",           "6004B000B15F600956B150B2", True),
    ("conditional jump to CALLDEST","6004B000B136600A57B2B1B2", True),
    ("jump to CALLDEST, nets disagree","6004B000B15F36600B57B2B150B2", False),
    ("unframed jump to called sub","6006B0600656B1B2", False),

    # --- constraint 4: overflow (STACK_LIMIT = 16 in the test build) ---
    ("17 pushes overflow",         "5F" * 17 + "00", False),
    ("16 pushes fit",              "5F" * 16 + "00", True),
    ("sub high amplified, 2 calls","6007B06007B000" + "B1" + "5F" * 9 + "B2", False),
    ("sub high fits, 1 call",      "6004B000" + "B1" + "5F" * 9 + "B2", True),
    ("call chain depth 17",        call_chain(17), False),
    ("call chain depth 16",        call_chain(16), True),
    ("growing recursion allowed",  "6004B000B15F6004B0", True),
]


def main() -> int:
    failures = 0
    for name, hexcode, expected in TESTS:
        code = bytes.fromhex(hexcode)
        got = ref.validate(code, stack_limit=TEST_STACK_LIMIT)
        ok = got == expected
        if not ok:
            failures += 1
        print(f"{'PASS' if ok else 'FAIL'}  {name:32s} "
              f"code=0x{hexcode:<28s} expected={expected} got={got}")
    print(f"\n{len(TESTS) - failures}/{len(TESTS)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
