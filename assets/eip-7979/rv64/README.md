# Compiling validated EVM code to RISC-V: the 3x2 measurement

Two proposals, one experiment.  EIP-8337 validation proves every
destination constant and every instruction at one static stack
offset; that makes translation legal — to native code, or to a
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

The metric is retired RISC-V instructions, counted exactly by qemu.
RISC-V instruction count is the proving-cost proxy for the RISC-V
zkVMs (SP1, RISC Zero) and a rough native-throughput proxy.

## Measured results

Retired instructions, whole program, freestanding binaries (no libc,
so the counts are pure):

    kernel     interp/256  interp/64    ir/256    ir/64  aot/256  aot/64
    mul chain     6122597    4492253   4081563  1856126  1315924  120641
    call tree     7833101    7360257   3669063  2450626  1119924  405641

    ratios        1.0        1.4/1.1   1.5/2.1  3.3/3.2  4.7/7.0  50.8/19.3

The two kernels bracket the workload space: one arithmetic-heavy
loop, one call-heavy tree.  Four readings.  EVM64 alone buys
1.1–1.4x: under a bytecode interpreter, dispatch dominates and cheap
arithmetic hardly matters.  The register IR — translated once at
deploy under the validation proofs, then interpreted — buys 1.5–2.1x
at 256 bits and 3.2–3.3x composed with EVM64: this is the row for
consensus clients that will never JIT, and it keeps one dispatch per
operation, which is why it stops there.  Full AOT removes the
dispatch too: 4.7–7.0x from validation alone, and 19–51x composed —
far more than the product of the two, because a stack slot can live
in a machine register only when its offset is static (validation)
*and* its value fits the register (EVM64).  The proposals do not
merely add; they compound.

The translation here is deliberately naive — EVM stack shuffles
become `mv` chains that any peephole pass would coalesce — so these
ratios are floors, not ceilings.

## The same figures in a zkVM

The same twelve binaries, executed by the Zisk zkVM's emulator
(Polygon's RV64IMA zkVM, built for proving Ethereum blocks).  Zisk
*steps* are the unit its prover pays for:

    kernel     interp/256  interp/64    ir/256    ir/64  aot/256  aot/64
    mul chain     6123041    4492697   4082007  1856570  1316368  121085
    call tree     7833545    7360701   3669507  2451070  1120368  406085

    ratios         1.0       1.4/1.1   1.5/2.1  3.3/3.2  4.7/7.0  50.6/19.3

Every count is the qemu instruction count plus exactly 444 steps of
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
the baseline must not be a strawman).  The IR and AOT cells still meter
gas — per basic block, precomputed at translation, summing to the
same charges as the baseline's per-op metering — and keep the runtime
checks validation cannot retire: stack overflow and return-stack
depth, one compare each per call, none per instruction — exactly the
division of labor the validation EIP specifies.  Not present in any
cell: state access and merklization.  The kernels touch no storage,
so the table measures pure execution — the component these proposals
change; on many real transactions storage dominates.

Not counted: validation and translation themselves.  Those are
one-time deploy costs, measured in ../../eip-8337/cbench/.  The
counts here are the recurring execution the network pays for.

## Files

    evm64.py     EVM64 opcode remap over the yul7979 compiler
    aot.py       validated bytecode -> rv64 assembly (both widths)
    ir.py        validated bytecode -> register IR (both widths)
    interp.c     baseline bytecode interpreter, both widths
    interp_ir.c  register-IR interpreter, block-level gas
    runtime.c    _start, syscalls, hex printer; keeps counts pure
    zisk.ld      linker script for the Zisk zkVM build
    harness.py   builds all cells, verifies agreement, counts
    setup.sh     non-root toolchain from Ubuntu debs

Run `sh setup.sh` once, then `python3 harness.py` (or the phases
`examples`, `counter`, `measure [substring]`).  Every program runs in
all four cells and every cell must produce the same result (the
64-bit cells modulo 2^64); the 256-bit cells are additionally checked
against the pure-Python interpreter, and the fast TB-log counter is
checked against plain singlestep counting.

## Caveats

Placeholder opcodes throughout: the 64-bit twin of x in 0x01..0x1C is
0xC0+x, CALLDATALOAD64/MLOAD64/MSTORE64 are 0xE0..0xE2, as in
interp.c.  The translator raises on valid-but-unused EIP-7979
patterns (a JUMP into a CALLDEST, reads below the caller's own
arguments) and on opcodes the test programs never execute; the
interpreter traps likewise.  Instruction count ignores memory
hierarchy and branch prediction: it is the right proxy for zkVM
cycles, a cruder one for wall clock.
