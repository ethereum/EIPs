# yul7979: a Yul-subset compiler for EIP-7979

An answer, in code, to "will compilers use it?"

Yul already has functions.  This compiler emits them onto the three
instructions of [EIP-7979](../../../EIPS/eip-7979.md) nearly one-to-one — function
definitions to `CALLDEST` … `RETURNSUB`, calls to `PUSH CALLSUB` — and
the output passes the reference validator of the companion validation
EIP.  The same compiler has a legacy backend that emits the same
programs the way compilers must today, synthesizing calls and returns
from dynamic jumps, for a like-for-like comparison.

## The loop

    python3 test_translator.py

For every example program, the test compiles both ways and checks
four things: the 7979 output validates (`minimal_validator.py`); the
legacy output does not (its dynamic return jumps cannot); both
execute to identical results on every input (`run7979.py`, a small
EVM with the three instructions and the runtime checks of the EIP);
and size and gas are reported side by side.

## Measured

Eight programs — calls, nested calls, recursion, loops, branches,
early returns — compiled by the same unoptimized code generator, the
backends differing only in how calls and returns are emitted:

| program               | bytes saved | gas saved |
|-----------------------|------------:|----------:|
| square                |         18% |       14% |
| sum of squares        |         24% |       16% |
| abs                   |         12% |       10% |
| fib (loop-heavy)      |          7% |        1% |
| factorial (recursive) |         17% |       11% |
| sum words             |          8% |        4% |
| find (break)          |          6% |        4% |
| guard (leave)         |         13% |       11% |
| **total**             |     **13%** |    **5%** |

The savings track call density, as they should: code that mostly
loops gains little, code that calls gains most.  These are floor
numbers — an optimizing backend that used call elimination for tail
calls and shared epilogues would gain more.

## The subset

Functions with zero or one return value, `let`, assignment, `if`,
`for` with `break` and `continue`, `leave`, calls, and the everyday
builtins.  No `switch`, no multi-value returns, no optimizer, and
locals must stay within `DUP16` reach.  The point is not coverage;
it is that nothing about the translation is clever.  The code
generator is a plain stack scheduler, identical for both backends,
and the 7979 backend is the *simpler* half: a call is two
instructions instead of four and a label, and a return needs no
address plumbing at all.

## Files

* `compile.py` — tokenizer, parser, and the two-backend code generator.
* `run7979.py` — the interpreter: EVM subset plus `CALLSUB`,
  `CALLDEST`, `RETURNSUB`, with EIP runtime semantics and Yellow
  Paper gas tiers.  (Memory expansion is not charged; both
  compilations of a program use identical memory.)
* `test_translator.py` — the closed loop and the comparison table.
* `minimal_validator.py`, `magic_validator.py` — the validation EIP's
  reference validator and its opcode table.  Exact copies: these
  assets must stand alone, so the files are repeated here verbatim
  and must stay byte-identical to the originals.

Placeholder opcodes: `CALLSUB`=0xB0, `CALLDEST`=0xB1, `RETURNSUB`=0xB2.
