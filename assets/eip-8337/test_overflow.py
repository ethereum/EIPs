"""Tests for the bounds-proving validator (overflow_validator.py).

These are the shared vectors: test_validator.py runs the same TESTS
against the reference validator, with the bounds-only rejections
flipped to valid.  STACK_LIMIT is reduced to 16 so that the overflow
tests are reachable with small vectors; the algorithm is independent
of the limit.
Opcodes: CALLDEST=0xBB, CALLSUB=0xBC, RETURNSUB=0xBF.
"""
import overflow_validator as ref

TEST_STACK_LIMIT = 16


def call_chain(n: int) -> str:
    """Main calls sub 0; sub i calls sub i+1; the last sub returns.
    Return-stack depth reaches n."""
    code = bytes.fromhex("6004BC00")           # PUSH1 4, CALLSUB, STOP
    for i in range(n - 1):
        nxt = 4 + 5 * (i + 1)                  # each sub is 5 bytes
        code += bytes([0xBB, 0x60, nxt, 0xBC, 0xBF])
    code += bytes([0xBB, 0xBF])                # last sub: CALLDEST, RETURNSUB
    return code.hex().upper()

TESTS = [
    # (name, bytecode hex, expected validity)

    # --- EIP test cases ---
    ("simple routine (EIP)",       "6004BC00BBBF", True),
    ("two-level subroutines (EIP)","6004BC00BB6009BCBFBBBF", True),
    ("dest outside code (EIP)",    "60FFBC00BBBF", False),
    ("bare RETURNSUB (EIP)",       "BF", False),
    ("subroutine at end (EIP)",    "600556BBBF5B6003BC", True),

    # --- constraint 1: opcodes ---
    ("lone STOP",                  "00", True),
    ("undefined opcode",           "21", False),
    ("INVALID is valid",           "FE", True),
    ("undefined at return point",  "6004BC21BBBF", False),

    # --- constraints 2/3: destinations ---
    ("JUMP into PUSH immediate",   "600156", False),
    ("JUMP to visited non-JUMPDEST", "5F5F01600256", False),
    ("JUMPDEST byte in PUSH data",  "600456605B00", False),
    ("JUMPDEST byte in live PUSH data", "36600857615B00005B600556", False),
    ("CALLDEST byte in PUSH data",  "6004BC60BB00", False),
    ("JUMPDEST in unreachable code", "600456005B00", True),
    ("JUMP not push-preceded",     "365B56", False),
    ("PUSH0-preceded JUMP",        "5B5F56", True),
    ("CALLSUB to JUMPDEST",        "6004BC005B", False),

    # --- constraint 5: underflow, return stack ---
    ("ADD on empty stack",         "01", False),
    ("POP on empty stack",         "50", False),
    ("sub consumes caller arg",    "6002600BBC6003600BBC00BB8002BF", True),
    ("sub underflows outer",       "6004BC00BB5050BF", False),
    ("fall into sub, RETURNSUB",   "BBBF", False),

    # --- constraint 4: offsets and net effects ---
    ("JUMPI arms disagree at join","366005575F5B00", False),
    ("JUMPI diamond consistent",   "366006575F005B5F00", True),
    ("two RETURNSUBs disagree",    "6004BC00BB36600A57BF5B5FBF", False),
    ("two RETURNSUBs agree",       "6004BC00BB36600A57BF5B5F50BF", True),
    ("stack-neutral loop",         "5B600056", True),

    # --- reuse and multiple entry points ---
    ("called at two depths",       "6002600BBC6003600BBC00BB8002BF", True),
    ("fall-through second entry",  "6008BC5F600ABC00BB5FBB50BF", True),

    # --- recursion ---
    ("recursion, no base case",    "6004BC00BB6004BCBF", True),
    ("recursion eats caller stack","6004BC00BB506004BC", False),

    # --- call elimination: JUMP/JUMPI to a CALLDEST ---
    ("jump to CALLDEST",           "6004BC00BB5F600956BB50BF", True),
    ("conditional jump to CALLDEST","6004BC00BB36600A57BFBBBF", True),
    ("jump to CALLDEST, nets disagree","6004BC00BB5F36600B57BFBB50BF", False),
    ("unframed jump to called sub","6006BC600656BBBF", False),

    # Framing is a property of entries
    ("shared revert block, both framings", "36600C576008BC00BB600C56BB5F80FD", True),
    ("entered by jump and by call, returns", "366008576008BC00BBBF", False),
    ("framed chain: called, jumps on, returns", "6004BC00BB600856BBBF", True),
    ("unframed chain: jumped to, jumps on, returns", "600356BB600756BBBF", False),
    ("unframed chain of three links, no return", "600356BB600756BB600B56BB00", True),
    ("unframed chain of three links, returns", "600356BB600756BB600B56BBBF", False),

    # --- constraint 5: overflow (STACK_LIMIT = 16 in the test build) ---
    ("17 pushes overflow",         "5F" * 17 + "00", False),
    ("16 pushes fit",              "5F" * 16 + "00", True),
    ("sub high amplified, 2 calls","6007BC6007BC00" + "BB" + "5F" * 9 + "BF", False),
    ("sub high fits, 1 call",      "6004BC00" + "BB" + "5F" * 9 + "BF", True),
    ("call chain depth 17",        call_chain(17), False),
    ("call chain depth 16",        call_chain(16), True),
    ("growing recursion allowed",  "6004BC00BB5F6004BC", True),
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
