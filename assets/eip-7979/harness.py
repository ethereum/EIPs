"""The 2x2 measurement: interpretation vs AOT, 256-bit vs 64-bit.

Cells:
  interp/256  legacy bytecode on the baseline interpreter — status quo
  interp/64   EVM64 bytecode on the same interpreter — EVM64 alone
  aot/256     validated 7979 bytecode translated to rv64 — validation alone
  aot/64      both proposals composed

The metric is retired RISC-V instructions, counted exactly by qemu
(-singlestep -d nochain,exec).  RISC-V instruction count is the
proving-cost proxy for RISC-V zkVMs (SP1, RISC Zero) and a rough
native-throughput proxy; it ignores memory hierarchy and branch
prediction.  Deploy-time costs (validation, translation) are not in
the counts — they are one-time and measured in cbench/.

Correctness first: every cell of every program must produce the same
result — the 64-bit cells the same value modulo 2^64, exact for our
programs since add/mul/sub commute with truncation and all other
operands stay small.  The 256-bit cells are also checked against the
pure-Python interpreter (run7979.py) and the expected outputs of
test_translator.py.  The 7979 compilations must pass the reference
validator; the legacy ones must fail it.

Toolchain: riscv64 cross gcc + qemu-user, paths via environment or
the defaults below (see README.md for non-root setup from .debs).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "yul7979"))

from compile import compile_yul                     # noqa: E402
from run7979 import execute                         # noqa: E402
from evm64 import compile_yul64                     # noqa: E402
from aot import Translate64, Translate256           # noqa: E402
from ir import translate_ir, ir_ops_h               # noqa: E402
import minimal_validator                            # noqa: E402
from test_translator import EXAMPLES                # noqa: E402

GCC = os.environ.get("RV_GCC", (
    "/tmp/rv/usr/bin/riscv64-linux-gnu-gcc-11"
    " -B /tmp/rv/usr/lib/gcc-cross/riscv64-linux-gnu/11/"
    " -B /tmp/rv/usr/riscv64-linux-gnu/bin/")).split()
QEMU = os.environ.get("RV_QEMU", "/tmp/rv/usr/bin/qemu-riscv64")
ZISKEMU = os.environ.get("RV_ZISKEMU",
                         "/tmp/zisk-src/target/release/ziskemu")
CFLAGS = "-O2 -static -nostdlib -nostartfiles -ffreestanding".split()
ZFLAGS = ["-DZISK", "-mcmodel=medany"]
BUILD = os.environ.get("RV_BUILD", "/tmp/rvbuild")
ENV = dict(os.environ,
           LD_LIBRARY_PATH=os.environ.get("RV_LIBS",
                                          "/tmp/rv/usr/lib/x86_64-linux-gnu"))

MASK64 = (1 << 64) - 1


def word(v):
    return v.to_bytes(32, "big")


# Measurement kernels: workloads big enough that counts are signal.
# Values wrap modulo the word size; the oracle below wraps with them.
def mulchain_oracle(n, mask):
    s = 0
    for i in range(n):
        s = (s * 31 + i) & mask
    return s


def calls_oracle(n, mask):
    s = 0
    for i in range(n):
        s = (s + i + 4) & mask
    return s


KERNELS = [
    ("mul chain", """{
        mstore(0, chain(calldataload(0)))
        return(0, 32)
        function chain(n) -> r {
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                r := add(mul(r, 31), i)
            }
        }
    }""", word(5000), mulchain_oracle, 5000),

    ("call tree", """{
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
    }""", word(1500), calls_oracle, 1500),
]


def sh(args, **kw):
    return subprocess.run(args, env=ENV, capture_output=True, text=True,
                          timeout=600, **kw)


def compile_objects(zisk=False):
    os.makedirs(BUILD, exist_ok=True)
    with open(os.path.join(BUILD, "ir_ops.h"), "w") as f:
        f.write(ir_ops_h())
    suffix, extra0 = ("_z", ZFLAGS) if zisk else ("", [])
    for src in ("interp.c", "runtime.c"):
        obj = os.path.join(BUILD, src.replace(".c", suffix + ".o"))
        r = sh(GCC + CFLAGS + extra0 + ["-Wall", "-c", "-o", obj,
                                        os.path.join(HERE, src)])
        assert r.returncode == 0, r.stderr
    for obj, extra in ((f"interp_ir256{suffix}.o", []),
                       (f"interp_ir64{suffix}.o", ["-DWIDTH64"])):
        r = sh(GCC + CFLAGS + extra0 + ["-Wall", "-I", BUILD, "-c", "-o",
                                        os.path.join(BUILD, obj)] + extra +
               [os.path.join(HERE, "interp_ir.c")])
        assert r.returncode == 0, r.stderr


def prog_data(code, calldata):
    def arr(b):
        return ",".join(str(x) for x in b) if b else "0"
    return (f"typedef unsigned long u64;\n"
            f"const unsigned char CODE[] = {{{arr(code)}}};\n"
            f"const u64 CODE_LEN = {len(code)};\n"
            f"const unsigned char CALLDATA[] = {{{arr(calldata)}}};\n"
            f"const u64 CALLDATA_LEN = {len(calldata)};\n")


def build(tag, code, calldata, asm=None, ir_width=None, zisk=False):
    """Link a bytecode-interpreter binary (default), an AOT binary
    (asm given), or an IR-interpreter binary (ir_width given) — for
    qemu, or for the Zisk zkVM (zisk=True)."""
    suffix = "_z" if zisk else ""
    extra = ZFLAGS + ["-T", os.path.join(HERE, "zisk.ld")] if zisk else []
    pd = os.path.join(BUILD, f"{tag}{suffix}_pd.c")
    with open(pd, "w") as f:
        f.write(prog_data(code, calldata))
    out = os.path.join(BUILD, tag + suffix)
    parts = [pd, os.path.join(BUILD, f"runtime{suffix}.o")]
    if asm is not None:
        s = os.path.join(BUILD, f"{tag}.s")
        with open(s, "w") as f:
            f.write(asm)
        parts.append(s)
    elif ir_width is not None:
        pi = os.path.join(BUILD, f"{tag}_ir.c")
        with open(pi, "w") as f:
            f.write(translate_ir(code))
        parts += [pi, os.path.join(BUILD, f"interp_ir{ir_width}{suffix}.o")]
    else:
        parts.append(os.path.join(BUILD, f"interp{suffix}.o"))
    r = sh(GCC + CFLAGS + extra + ["-I", BUILD, "-o", out] + parts)
    assert r.returncode == 0, f"{tag}: {r.stderr}"
    return out


def run_binary(path):
    r = sh([QEMU, path])
    return r.stdout.strip()


def count_instructions(path):
    """Exact retired instructions: -d nochain,exec logs every executed
    translation block, -d in_asm gives each block's instruction count.
    Equivalent to -singlestep counting (verified) but ~10x faster."""
    log = os.path.join(BUILD, "qemu.log")
    r = sh([QEMU, "-d", "nochain,exec,in_asm", "-D", log, path])
    assert r.returncode == 0, f"count run failed: {r.stderr}"
    sizes, total = {}, 0
    with open(log, errors="replace") as f:
        it = iter(f)
        for line in it:
            if line.startswith("IN:"):
                pc, n = None, 0
                for asm in it:
                    if not asm.strip():
                        break
                    if asm.startswith("0x"):
                        if pc is None:
                            pc = int(asm.split(":")[0], 16)
                        n += 1
                if pc is not None:
                    sizes[pc] = n
            elif line.startswith("Trace"):
                pc = int(line.split("[")[1].split("/")[1], 16)
                total += sizes[pc]
    os.unlink(log)
    return total


def cells(name, src, calldata, zisk=False):
    """Build all six binaries for one program; return {cell: path}."""
    leg256 = compile_yul(src, "legacy")
    new256 = compile_yul(src, "7979")
    leg64 = compile_yul64(src, "legacy")
    new64 = compile_yul64(src, "7979")
    assert minimal_validator.validate(new256), f"{name}: 7979 must validate"
    assert not minimal_validator.validate(leg256), f"{name}: legacy must not"
    t = name.replace(" ", "_")
    z = zisk
    return {
        "interp/256": build(f"{t}_i256", leg256, calldata, zisk=z),
        "interp/64":  build(f"{t}_i64", leg64, calldata, zisk=z),
        "ir/256":     build(f"{t}_r256", new256, calldata, ir_width=256,
                            zisk=z),
        "ir/64":      build(f"{t}_r64", new64, calldata, ir_width=64,
                            zisk=z),
        "aot/256":    build(f"{t}_a256", new256, calldata,
                            Translate256(new256).translate(), zisk=z),
        "aot/64":     build(f"{t}_a64", new64, calldata,
                            Translate64(new64).translate(), zisk=z),
    }


CELL_ORDER = ["interp/256", "interp/64", "ir/256", "ir/64",
              "aot/256", "aot/64"]


def check_examples():
    """All 8 test_translator programs, all 4 cells, exact agreement."""
    failures = 0
    for name, src, cases in EXAMPLES:
        for calldata, expected in cases:
            bins = cells(name, src, calldata)
            exp256 = expected.hex()
            exp64 = word(int.from_bytes(expected, "big") & MASK64).hex()
            want = {c: exp64 if c.endswith("/64") else exp256
                    for c in CELL_ORDER}
            # cross-check the pure-Python interpreter on the same code
            s, r, _ = execute(compile_yul(src, "7979"), calldata)
            assert (s, r.hex()) == ("return", exp256), f"{name}: run7979"
            for cell in CELL_ORDER:
                got = run_binary(bins[cell])
                if got != want[cell]:
                    print(f"FAIL  {name} [{cell}]: got {got},"
                          f" want {want[cell]}")
                    failures += 1
        print(f"PASS  {name}")
    return failures


def check_counter():
    """The TB-log counter must agree with plain singlestep counting."""
    name, src, cases = EXAMPLES[0]
    path = cells(name, src, cases[0][0])["aot/64"]
    r = subprocess.run(
        f"{QEMU} -singlestep -d nochain,exec {path} 2>&1 >/dev/null"
        f" | grep -c '^Trace'",
        shell=True, env=ENV, capture_output=True, text=True, timeout=120)
    slow, fast = int(r.stdout.strip()), count_instructions(path)
    assert slow == fast, f"counters disagree: {slow} vs {fast}"
    print(f"counter check: {fast} instructions both ways")


def measure(which=None):
    head = " ".join(f"{c:>11s}" for c in CELL_ORDER)
    print(f"\n{'kernel':12s} {head}   ratios vs interp/256")
    for name, src, calldata, oracle, n in KERNELS:
        if which is not None and which not in name:
            continue
        bins = cells(name, src, calldata)
        exp256 = word(oracle(n, (1 << 256) - 1)).hex()
        exp64 = word(oracle(n, MASK64)).hex()
        want = {c: exp64 if c.endswith("/64") else exp256
                for c in CELL_ORDER}
        counts = {}
        for cell in CELL_ORDER:
            got = run_binary(bins[cell])
            assert got == want[cell], f"{name} [{cell}]: {got}"
            counts[cell] = count_instructions(bins[cell])
        again = count_instructions(bins["aot/64"])
        assert again == counts["aot/64"], "counts must be deterministic"
        base = counts["interp/256"]
        row = " ".join(f"{counts[c]:11d}" for c in CELL_ORDER)
        ratios = " ".join(f"{base / counts[c]:5.1f}x" for c in CELL_ORDER)
        print(f"{name:12s} {row}   {ratios}")


def run_zisk(path):
    r = sh([ZISKEMU, "-e", path])
    lines = [l for l in r.stdout.strip().splitlines() if l]
    return lines[-1] if lines else ""


def count_zisk(path):
    """Zisk steps: the zkVM's own unit of execution."""
    import re
    r = sh([ZISKEMU, "-e", path, "-m"])
    m = re.search(r"steps=(\d+)", r.stdout + r.stderr)
    assert m, f"no step count in ziskemu output: {r.stdout!r} {r.stderr!r}"
    return int(m.group(1))


def measure_zisk(which=None):
    """The same six cells, measured in the Zisk zkVM emulator:
    steps are Zisk's own execution unit, the basis of proving cost."""
    compile_objects(zisk=True)
    head = " ".join(f"{c:>11s}" for c in CELL_ORDER)
    print(f"\nZisk zkVM steps")
    print(f"{'kernel':12s} {head}   ratios vs interp/256")
    for name, src, calldata, oracle, n in KERNELS:
        if which is not None and which not in name:
            continue
        bins = cells(name, src, calldata, zisk=True)
        exp256 = word(oracle(n, (1 << 256) - 1)).hex()
        exp64 = word(oracle(n, MASK64)).hex()
        want = {c: exp64 if c.endswith("/64") else exp256
                for c in CELL_ORDER}
        counts = {}
        for cell in CELL_ORDER:
            got = run_zisk(bins[cell])
            assert got == want[cell], f"{name} [{cell}]: {got!r}"
            counts[cell] = count_zisk(bins[cell])
        base = counts["interp/256"]
        row = " ".join(f"{counts[c]:11d}" for c in CELL_ORDER)
        ratios = " ".join(f"{base / counts[c]:5.1f}x" for c in CELL_ORDER)
        print(f"{name:12s} {row}   {ratios}")


def main(argv):
    """Phases so a run fits in one sitting: `examples`, `counter`,
    `measure [substring]`, `zisk [substring]`, or everything with no
    arguments (zisk runs only if ziskemu is present)."""
    compile_objects()
    phase = argv[1] if len(argv) > 1 else "all"
    if phase in ("examples", "all"):
        if check_examples():
            return 1
    if phase in ("counter", "all"):
        check_counter()
    if phase in ("measure", "all"):
        measure(argv[2] if len(argv) > 2 else None)
    if phase == "zisk" or (phase == "all" and os.path.exists(ZISKEMU)):
        measure_zisk(argv[2] if len(argv) > 2 else None)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
