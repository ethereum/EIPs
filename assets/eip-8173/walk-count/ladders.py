"""The ladders of "EVM: Any Jump, Anywhere": traversals and walks.

Builds the ladder programs -- N-1 blocks of jumpdest/gas/jump and a
final jumpdest/stop -- and prints what the EIP quotes: the jump edges
a traversal follows, (N-1)*N of them, and the walks a sound walker
must count, floor(e*(N-1)!) of them.  A traversal shares one seen set,
so each edge is followed once; a walk carries its own, so the forks
compound.

    python3 ladders.py
"""
import math

JUMPDEST, GAS, JUMP, STOP = 0x5B, 0x5A, 0x56, 0x00

def build(blocks):
    return bytes([JUMPDEST, GAS, JUMP]) * (blocks - 1) + bytes([JUMPDEST, STOP])

def edges(code):
    """The jump edges a traversal follows, each once."""
    out, seen = [], set()
    def step(pc, entry):
        if pc >= len(code) or code[pc] == STOP or pc in seen:
            return
        seen.add(pc)
        if code[pc] == JUMPDEST:
            entry = pc
        if code[pc] == JUMP:
            for d, op in enumerate(code):
                if op == JUMPDEST:
                    out.append((entry, d))
                    step(d, d)
        else:
            step(pc + 1, entry)
    step(0, 0)
    return sorted(out)

def walks(code):
    """The walks a sound walker counts: a walk forks at every jump to
    every JUMPDEST, and ends at the stop or on revisiting a block."""
    out = []
    def walk(pc, seen, route):
        if pc >= len(code) or code[pc] == STOP or pc in seen:
            out.append(route)
            return
        if code[pc] == JUMP:
            for d, op in enumerate(code):
                if op == JUMPDEST:
                    walk(d, seen | {pc}, route + [d])
        else:
            walk(pc + 1, seen | {pc}, route)
    walk(0, set(), [0])
    return out

if __name__ == "__main__":
    for blocks in (2, 3):
        code = build(blocks)
        print(f"{blocks} blocks, bytes {code.hex().upper()}:")
        print(f"  {len(edges(code))} jump edges:")
        for a, b in edges(code):
            print(f"    {a} → {b}")
        print(f"  {len(walks(code))} walks:")
        for route in walks(code):
            print("    " + " → ".join(map(str, route)))
    print(f"\n{'blocks':>6} {'edges':>6} {'walks':>9} {'= ⌊e·(N−1)!⌋':>12}")
    for n in range(2, 9):
        w = len(walks(build(n)))
        f = math.floor(math.e * math.factorial(n - 1))
        assert n < 3 or w == f
        print(f"{n:>6} {(n-1)*n:>6} {w:>9,} {f:>12,}")
