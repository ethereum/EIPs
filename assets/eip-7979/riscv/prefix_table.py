"""EIP-12504: the prefix encoding against single-byte opcodes, at the
three tiers of the 3x2 measurement.

The same 64-bit instruction set is assembled two ways -- EIP-7937's
prefix (0xC0, then the twin's opcode) and EIP-12504's single-byte
opcodes (the twin's opcode plus 0xC0) -- and run on the two kernels at
each tier.  One bytecode interpreter, the PREFIX64 build of interp.c,
runs every interpreted cell, so across that row the encoding is the only
difference.  The translators read prefixed code through PrefixedCode,
which decodes each prefix at translation time, as any translator would.
The metric is executed RISC-V instructions, counted exactly by qemu.

Run after setup.sh:  . /tmp/rvenv.sh; python3 prefix_table.py
"""
import harness as H
from harness import compile_yul, Translate64, Translate256
from evm64 import compile_yul64, compile_yul64_prefix, PrefixedCode

TIERS = ["interpreted bytecode", "register IR", "compiled (AOT)"]
COLS = ["256-bit", "64-bit, prefixed", "64-bit, single-byte"]


def fmt(n):
    return f"{n / 1e6:.1f}M" if n >= 1e6 else f"{round(n / 1e3)}K"


def gain(base, n):
    return f"({base / n:.0f}x)" if base / n >= 10 else f"({base / n:.1f}x)"


def main():
    H.compile_objects()
    for name, src, calldata, oracle, n in H.KERNELS:
        t = name.replace(" ", "_")
        leg256, new256 = compile_yul(src, "legacy"), compile_yul(src, "7979")
        leg64, new64 = compile_yul64(src, "legacy"), compile_yul64(src, "7979")
        leg64p = compile_yul64_prefix(src, "legacy")
        new64p = PrefixedCode(compile_yul64_prefix(src, "7979"))
        build = {
            ("interpreted bytecode", "256-bit"):
                H.build(f"{t}_pi256", leg256, calldata, prefix=True),
            ("interpreted bytecode", "64-bit, prefixed"):
                H.build(f"{t}_pi64p", leg64p, calldata, prefix=True),
            ("interpreted bytecode", "64-bit, single-byte"):
                H.build(f"{t}_pi64", leg64, calldata, prefix=True),
            ("register IR", "256-bit"):
                H.build(f"{t}_pr256", new256, calldata, ir_width=256),
            ("register IR", "64-bit, prefixed"):
                H.build(f"{t}_pr64p", new64p, calldata, ir_width=64),
            ("register IR", "64-bit, single-byte"):
                H.build(f"{t}_pr64", new64, calldata, ir_width=64),
            ("compiled (AOT)", "256-bit"):
                H.build(f"{t}_pa256", new256, calldata,
                        Translate256(new256).translate()),
            ("compiled (AOT)", "64-bit, prefixed"):
                H.build(f"{t}_pa64p", new64p, calldata,
                        Translate64(new64p).translate()),
            ("compiled (AOT)", "64-bit, single-byte"):
                H.build(f"{t}_pa64", new64, calldata,
                        Translate64(new64).translate()),
        }
        want = {"256-bit": H.word(oracle(n, (1 << 256) - 1)).hex()}
        want["64-bit, prefixed"] = want["64-bit, single-byte"] = \
            H.word(oracle(n, H.MASK64)).hex()
        counts = {}
        for key, path in build.items():
            got = H.run_binary(path)
            assert got == want[key[1]], (name, key, got)
            counts[key] = H.count_instructions(path)
        base = counts[("interpreted bytecode", "256-bit")]
        print(f"\n{name}: {len(leg64p)} bytes prefixed, {len(leg64)} single-byte\n")
        print("|                      | " + " | ".join(COLS) + " |")
        print("|----------------------|" + "|".join("-" * (len(c) + 2) for c in COLS) + "|")
        for tier in TIERS:
            cells = []
            for col in COLS:
                c = counts[(tier, col)]
                cells.append(fmt(c) if (tier, col) == ("interpreted bytecode", "256-bit")
                             else f"{fmt(c)} {gain(base, c)}")
            print(f"| {tier:20s} | " + " | ".join(cells) + " |")
        print("\nexact:", ", ".join(f"{k[0]}/{k[1]}={v}" for k, v in counts.items()))


if __name__ == "__main__":
    main()
