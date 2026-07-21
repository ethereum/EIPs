"""The closed loop: compile Yul both ways, validate, execute, compare.

For each example program: the 7979 output must pass the reference
validator (minimal_validator.py); the legacy output must fail it (a
dynamic return jump cannot validate — that is the point); both must
execute to identical results on every test input; and the size and
gas of the two compilations are reported side by side.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from compile import compile_yul                      # noqa: E402
from run7979 import execute                         # noqa: E402
import minimal_validator                            # noqa: E402


def word(v):
    return v.to_bytes(32, "big")


# (name, source, [(calldata, expected returndata)])
EXAMPLES = [
    ("square", """{
        mstore(0, square(calldataload(0)))
        return(0, 32)
        function square(x) -> r { r := mul(x, x) }
    }""", [(word(7), word(49)), (word(0), word(0))]),

    ("sum of squares", """{
        mstore(0, hyp(calldataload(0), calldataload(32)))
        return(0, 32)
        function hyp(a, b) -> r { r := add(square(a), square(b)) }
        function square(x) -> r { r := mul(x, x) }
    }""", [(word(3) + word(4), word(25))]),

    ("abs", """{
        mstore(0, abs(calldataload(0)))
        return(0, 32)
        function abs(x) -> r {
            r := x
            if slt(x, 0) { r := sub(0, x) }
        }
    }""", [(word(5), word(5)),
           ((-5) % 2**256 and ((2**256 - 5).to_bytes(32, "big")), word(5))]),

    ("fib", """{
        mstore(0, fib(calldataload(0)))
        return(0, 32)
        function fib(n) -> r {
            let a := 0
            let b := 1
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                let t := add(a, b)
                a := b
                b := t
            }
            r := a
        }
    }""", [(word(0), word(0)), (word(10), word(55)), (word(20), word(6765))]),

    ("factorial (recursive)", """{
        mstore(0, fact(calldataload(0)))
        return(0, 32)
        function fact(n) -> r {
            r := 1
            if gt(n, 1) { r := mul(n, fact(sub(n, 1))) }
        }
    }""", [(word(1), word(1)), (word(5), word(120)), (word(12), word(479001600))]),

    ("sum words", """{
        mstore(0, sum(div(calldatasize(), 32)))
        return(0, 32)
        function sum(k) -> r {
            for { let i := 0 } lt(i, k) { i := add(i, 1) } {
                r := add(r, calldataload(mul(i, 32)))
            }
        }
    }""", [(word(1) + word(2) + word(3), word(6)), (b"", word(0))]),

    ("find (break)", """{
        mstore(0, find(calldataload(0), div(calldatasize(), 32)))
        return(0, 32)
        function find(x, k) -> r {
            r := not(0)
            for { let i := 1 } lt(i, k) { i := add(i, 1) } {
                if eq(calldataload(mul(i, 32)), x) {
                    r := i
                    break
                }
            }
        }
    }""", [(word(9) + word(4) + word(9) + word(7), word(2)),
           (word(1) + word(4), b"\xff" * 32)]),

    ("guard (leave)", """{
        mstore(0, f(calldataload(0)))
        return(0, 32)
        function f(x) -> r {
            r := 1
            if iszero(x) { leave }
            r := add(x, x)
        }
    }""", [(word(0), word(1)), (word(21), word(42))]),
]


def main() -> int:
    failures = 0
    rows = []
    for name, src, cases in EXAMPLES:
        new = compile_yul(src, "7979")
        old = compile_yul(src, "legacy")
        ok_new = minimal_validator.validate(new)
        ok_old = minimal_validator.validate(old)
        if not ok_new:
            print(f"FAIL  {name}: 7979 output does not validate")
            failures += 1
        if ok_old:
            print(f"FAIL  {name}: legacy output validates (it should not)")
            failures += 1
        gas_new = gas_old = 0
        for calldata, expected in cases:
            sn, rn, gn = execute(new, calldata)
            so, ro, go = execute(old, calldata)
            gas_new, gas_old = gas_new + gn, gas_old + go
            if (sn, rn) != ("return", expected):
                print(f"FAIL  {name}: 7979 got {sn} {rn.hex()}")
                failures += 1
            if (so, ro) != ("return", expected):
                print(f"FAIL  {name}: legacy got {so} {ro.hex()}")
                failures += 1
        rows.append((name, len(new), len(old), gas_new, gas_old))
        print(f"PASS  {name}")

    print(f"\n{'program':22s} {'7979':>6s} {'legacy':>7s} {'bytes':>6s} "
          f"{'7979':>7s} {'legacy':>7s} {'gas':>6s}")
    tn = to = tgn = tgo = 0
    for name, sn, so, gn, go in rows:
        print(f"{name:22s} {sn:6d} {so:7d} {100*(so-sn)//so:5d}% "
              f"{gn:7d} {go:7d} {100*(go-gn)//go:5d}%")
        tn, to, tgn, tgo = tn + sn, to + so, tgn + gn, tgo + go
    print(f"{'total':22s} {tn:6d} {to:7d} {100*(to-tn)//to:5d}% "
          f"{tgn:7d} {tgo:7d} {100*(tgo-tgn)//tgo:5d}%")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
