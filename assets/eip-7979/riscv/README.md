# Compiling validated EVM code to RISC-V: the 3x2 measurement

Two proposals, one experiment.  Validation of static control flow
(validator.py in ../yul-compiler) proves every destination
constant and every instruction at one static stack offset; that makes translation legal — to native code, or to a
register intermediate code a client can interpret.  EVM64 adds
instructions operating modulo 2^64 — no modes, no prefixes, just
opcodes, which validation covers for free as table entries under the
fork rule.  The experiment measures each proposal alone and both
together, on the same programs, at three execution tiers:

|                     | 256-bit words | 64-bit words |
|---------------------|---------------|--------------|
| **Interpreted bytecode** | status quo | EVM64 alone |
| **Interpreted register IR** | the deployable middle path | |
| **Compiled AOT**    | validation alone | both        |
| **Compiled by LLVM** |              | both, optimized: the ceiling |

The metric is executed RISC-V instructions, counted exactly by qemu.
RISC-V instruction count is the proving-cost proxy for the RISC-V
zkVMs (SP1, RISC Zero) and a rough native-throughput proxy.

## Measured results

Executed instructions, whole program, freestanding binaries (no libc,
so the counts are pure):

    kernel         interp/256  interp/64    ir/256    ir/64  aot/256  aot/64  llvm/64
    mul chain         6122597    4492253   4081563  1856126  1315924  120641    30572
    call tree         7833101    7360257   3669063  2450626  1119924  405641     8069
    xorshift          5508040    4397696   3820627  1981167  1158952  147652    30571
    euclid            8262394    7175321   4742181  2721724  1412775  234200    70438
    store and sum     8982270    6140885   6190798  2860281  2157989  396651   273627

    ratio to interp/256
    mul chain             1.0        1.4       1.5      3.3      4.7    50.8    200.3
    call tree             1.0        1.1       2.1      3.2      7.0    19.3    970.8
    xorshift              1.0        1.3       1.4      2.8      4.8    37.3    180.2
    euclid                1.0        1.2       1.7      3.0      5.8    35.3    117.3
    store and sum         1.0        1.5       1.5      3.1      4.2    22.6     32.8

Five kernels, each a loop driven by a count from calldata, each
exercising a different part of the machine: *mul chain*, the multiplier
and the ALU on a dependent chain; *call tree*, calls and returns, seven
of each per iteration; *xorshift*, the shifter and the logic unit;
*euclid*, the divider in a data-dependent loop; *store and sum*, the
memory unit alone.  Their code is below.  Five readings.  EVM64 alone
buys 1.1–1.5x: under a bytecode interpreter, dispatch dominates and
cheap arithmetic hardly matters.  The register IR — translated once at
deploy under the validation proofs, then interpreted — buys 1.4–2.1x at
256 bits and 2.8–3.3x composed with EVM64: this is the row for
consensus clients that will never JIT, and it keeps one dispatch per
operation, which is why it stops there.  Full AOT removes the dispatch
too: 4.2–7.0x from validation alone, and 19–51x composed — far more
than the product of the two, because a stack slot can live in a
machine register only when its offset is static (validation) *and* its
value fits the register (EVM64).  The proposals do not merely add; they
compound.

The AOT translation is deliberately naive — EVM stack shuffles become
`mv` chains that any peephole pass would coalesce — so its ratios are
floors.  The last column is the ceiling: the same validated code
through LLVM at -O2 (the seventh cell, below), 33x to 971x, and 1.4x to
50x over the naive AOT.  The spread is the kernels': the optimizer sees
through the call tree's calls entirely, and can do little about store
and sum's memory.

## The kernels

Each kernel is a Yul program in the subset `../yul-compiler` compiles,
driven by a count from calldata, returning one word.  The harness checks
every cell's result against a Python oracle at the width in use: the
64-bit cells compute the 64-bit function, the 256-bit cells the same
instructions at 256 bits, which for the chain and xorshift is a 256-bit
variant of the function and for the rest the same value.  Counts are
chosen so that each runs five to nine million interpreted instructions.

**mul chain** — the multiplier and the ALU on a dependent chain: one
multiply and two adds per iteration and nothing else, so dispatch and
arithmetic are all there is.  n = 5000.

    {
        mstore(0, chain(calldataload(0)))
        return(0, 32)
        function chain(n) -> r {
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                r := add(mul(r, 31), i)
            }
        }
    }

**call tree** — calls and returns: seven `CALLSUB`s and seven
`RETURNSUB`s per iteration through a tree three deep, and almost no
arithmetic, so the return stack, the frames and the per-call checks are
what is measured.  n = 1500.

    {
        mstore(0, run(calldataload(0)))
        return(0, 32)
        function f0(x) -> r { r := add(x, 1) }
        function f1(x) -> r { r := f0(f0(x)) }
        function f2(x) -> r { r := f1(f1(x)) }
        function run(n) -> r {
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                r := add(r, f2(i))
            }
        }
    }

**xorshift** — the shifter and the logic unit: the hash mixer's
instruction mix, shifts and exclusive-ors on one dependent value.  The
interpreter pays four-limb shifts; the twins pay one instruction each.
n = 3000.

    {
        mstore(0, mix(calldataload(0)))
        return(0, 32)
        function mix(n) -> x {
            x := 0x5851f42d4c957f2d
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                x := xor(x, shl(13, x))
                x := xor(x, shr(7, x))
                x := xor(x, shl(17, x))
            }
        }
    }

**euclid** — the divider and a data-dependent loop: a remainder per
step, a step count that depends on the data, and a subroutine call per
pair.  The operands fit one limb, the 256-bit AOT's fast path.
n = 1000.

    {
        mstore(0, gcds(calldataload(0)))
        return(0, 32)
        function gcd(a, b) -> g {
            for {} b {} {
                let t := mod(a, b)
                a := b
                b := t
            }
            g := a
        }
        function gcds(n) -> s {
            for { let i := 1 } lt(i, n) { i := add(i, 1) } {
                s := add(s, gcd(add(mul(i, i), 1), add(mul(i, 3), 7)))
            }
        }
    }

**store and sum** — the memory unit alone: n words stored, then read
back and added, with the address arithmetic and nothing else, so the
cost of the EVM's memory model shows by itself.  n = 3000.

    {
        mstore(0, sum(calldataload(0)))
        return(0, 32)
        function sum(n) -> s {
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                mstore(mul(i, 32), add(i, 1))
            }
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                s := add(s, mload(mul(i, 32)))
            }
        }
    }

## The same figures in a zkVM

The same twelve binaries, executed by the Zisk zkVM's emulator
(Polygon's RV64IMA zkVM, built for proving Ethereum blocks).  Zisk
*steps* are the unit its prover pays for:

    kernel     interp/256  interp/64    ir/256    ir/64  aot/256  aot/64
    mul chain     6123041    4492697   4082007  1856570  1316368  121085
    call tree     7833545    7360701   3669507  2451070  1120368  406085

    ratio to interp/256
    mul chain         1.0        1.4       1.5      3.3      4.7    50.6
    call tree         1.0        1.1       2.1      3.2      7.0    19.3

The other three kernels have not been run in Zisk;
`python3 harness.py zisk` adds their rows.  Every count is the qemu
instruction count plus exactly 444 steps of
fixed startup, so the ratios reproduce to three digits: the
instruction-count proxy is not a proxy here — in an RV64 zkVM these
*are* the proving-cost figures.  Outputs were verified in-VM (the
UART echoes the returndata) and counts are deterministic across
runs.  To reproduce: build `ziskemu` from the zisk repo (tag
v1.0.0-alpha), set `RV_ZISKEMU`, and run `python3 harness.py zisk`.
The binaries differ from the qemu ones only in `zisk.ld`, `-DZISK`,
and `-mcmodel=medany`: output through Zisk's UART, exit by the same
ecall, a private stack.  The ziskemu used here was built with
proof-verifier bodies stubbed and some host crates unoptimized to
fit this sandbox's build limits — neither touches the emulator core
that counts steps.

## What the counts include, and what they don't

The interpreter cells pay everything a mainnet client pays: JUMPDEST
analysis before the first instruction, a dynamic destination check at
every jump, gas and stack bounds at every step, 256-bit arithmetic in
four 64-bit limbs, computed-goto dispatch (the respectable technique;
the baseline must not be a strawman).  The IR, AOT and LLVM cells
still meter gas — per basic block, precomputed at translation, summing
to the same charges as the baseline's per-op metering — and keep the
runtime checks validation cannot retire: stack overflow and
return-stack depth, one compare each per call, none per instruction —
exactly the division of labor the validation EIP specifies (what the
optimizer then makes of those checks is described below).  Not present in any
cell: state access and merklization.  The kernels touch no storage,
so the table measures pure execution — the component these proposals
change; on many real transactions storage dominates.

Not counted: validation and translation themselves.  Those are
one-time deploy costs.  The
counts here are the recurring execution the network pays for.

## The prefix encoding

EIP-7937 encodes the same 64-bit instructions as `0xC0` followed by
the twin's opcode; EIP-8442 encodes them as single-byte opcodes.
`prefix_table.py` measures the two encodings against each other at all
three tiers.  The PREFIX64 build of interp.c adds one handler, a
second dispatch on the byte after the prefix, and runs every
interpreted cell of that table, so across the interpreted row the
encoding is the only difference; the translators read prefixed code
through `PrefixedCode`, which decodes each prefix at translation time.
Executed RISC-V instructions, exact:

    kernel         tier         256-bit   64 prefixed  64 single-byte
    mul chain      interpreted  6332643      5132437       4707299
                   register IR  4081563      1856126       1856126
                   compiled     1315924       120641        120641
    call tree      interpreted  8163147      7894441       7690303
                   register IR  3669063      2450626       2450626
                   compiled     1119924       405641        405641
    xorshift       interpreted  5721097      5069931       4610753
                   register IR  3820627      1981167       1981167
                   compiled     1158952       147652        147652
    euclid         interpreted  8626290      7951086       7541215
                   register IR  4742181      2721724       2721724
                   compiled     1412775       234200        234200
    store and sum  interpreted  9237337      7014194       6401952
                   register IR  6190798      2860281       2860281
                   compiled     2157989       396651        396651

The prefix costs 17 instructions per prefixed instruction under this
interpreter -- one more pass through the dispatch loop plus the
handler -- 3% of the call tree's interpreted total, 5% of euclid's,
9% of the mul chain's, 10% of xorshift's and of store and sum's, and
nothing after translation.  The code is a byte longer per 64-bit
instruction: 60 bytes against 53 for the mul chain, 127 against 120
for the call tree, 91 against 80 for xorshift, 116 against 104 for
euclid, 100 against 86 for store and sum.  The interpreted 256-bit cells differ
from the table above because the PREFIX64 build is a different
binary; within this table every interpreted cell is one binary.

## The seventh cell: an optimizing compiler

Mainnet clients cannot run an optimizing compiler at deploy: nothing
in LLVM is bounded, and deposit gas is linear in bytes.  They can run
one at build time: a precompile written as EVM code and compiled to
native with the rest of the client, by the people who ship it,
reviewed like the rest of the client.  And a chain that does not pay
for compile time -- an L2 whose sequencer runs the binary while the
fraud proof interprets the bytecode, a prover that establishes the
binary once -- can run it at deploy.  This cell measures what it buys.
`llvm.py` emits the validated code as LLVM IR from the same recovered
facts aot.py spends: a stack slot is an alloca, a subroutine is a
function, a jump is a branch, a 64-bit twin is an i64 operation on an
i256 slot, trunc and zext.  Then `opt -O2` and `llc -O2` (LLVM 15) for
the same RISC-V target, linked against the same runtime, counted in
the same qemu.  Gas is charged per block exactly as in aot.py.
Compilation is not counted; that is the point.  The cell has not been
run in Zisk.

What the optimizer did: inlined every subroutine, so the call tree's
`f2(f1(f0(x)))` became `x + 4` and the depth and overflow checks
folded to constants; promoted every slot to a register and narrowed
every value to 64 bits -- no i256 survives in the optimized IR; and
coalesced the `mv` chains.  The mul chain's loop is six instructions
an iteration, the call tree's five, one of each the gas check.

What it did with gas: the counter's final value is dead in this
harness (nothing returns it), so only the trap decisions survive, and
scalar evolution rewrote them.  The mul chain tests once, before the
loop, whether 10^10 gas covers n iterations, then branches on that bit
each iteration; store and sum keeps the counter and makes it the
loop's induction variable.  On a chain the gas remaining is live at
return, which costs one subtraction per call, not per block.  The
optimizer did not merge checks across blocks: it cannot know that out
of gas is all or nothing within a frame.  The front end does, and
could.

What is left in store and sum is byte order.  Its load loop is 32
instructions an iteration, 22 of them reversing the loaded word from
the EVM's big-endian memory into a little-endian register; its store
loop writes the 32 bytes of each word one at a time.  With the Zbb
extension (`rev8`) the cell is 213619 -- 1.9x the AOT, 42x the
baseline -- the loads fixed and the stores not, and the other four
kernels change by 27 instructions each.  An ISA choice for such a
chain.

## Files

    evm64.py     EVM64 opcode remap over the yul-compiler
    aot.py       validated bytecode -> RISC-V assembly (both widths)
    ir.py        validated bytecode -> register IR (both widths)
    llvm.py      validated bytecode -> LLVM IR (both widths), the seventh cell
    interp.c     baseline bytecode interpreter, both widths
    interp_ir.c  register-IR interpreter, block-level gas
    runtime.c    _start, syscalls, hex printer; keeps counts pure
    zisk.ld      linker script for the Zisk zkVM build
    harness.py   builds all cells, verifies agreement, counts
    prefix_table.py  the prefix encoding against single-byte, three tiers
    setup.sh     non-root toolchain from Ubuntu debs

Run `sh setup.sh` once, then `python3 harness.py` (or the phases
`examples`, `counter`, `measure [substring]`), and `python3
prefix_table.py` for the prefix table.  Every program runs in
every cell and every cell must produce the same result (the
64-bit cells modulo 2^64); the 256-bit cells are additionally checked
against the pure-Python interpreter, and the fast TB-log counter is
checked against plain singlestep counting.  The llvm/64 cell is built
when `llc` is present (setup.sh fetches LLVM 15; `RV_LLVM` points
elsewhere); `python3 llvm.py xorshift 64` prints the IR it feeds LLVM.

## Caveats

Placeholder opcodes throughout: the 64-bit twin of x in 0x01..0x1C is
0xC0+x, CALLDATALOAD64/MLOAD64/MSTORE64 are 0xE0..0xE2, as in
interp.c.  The translator raises on valid-but-unused EIP-7979
patterns (a JUMP into a CALLDEST, reads below the caller's own
arguments) and on opcodes the test programs never execute; the
interpreter traps likewise.  Instruction count ignores memory
hierarchy and branch prediction: it is the right proxy for zkVM
cycles, a cruder one for wall clock.
