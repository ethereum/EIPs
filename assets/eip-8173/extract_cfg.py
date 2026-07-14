"""Extract the control-flow graph of valid EIP-7979 MAGIC code in one pass.

Because the code has been validated, every JUMP, JUMPI, and CALLSUB is
immediately preceded by a PUSH, so every destination is a compile-time
constant: the complete control flow is recovered in a single worklist
traversal, in time and space linear in the size of the code — the point
of validation.  No checks are performed here; the input is trusted.

Unreachable bytes are data and are never decoded.  A subroutine that
never returns contributes no return edges, so its callers' return points
are correctly absent from the graph.

Usage:
    python3 extract_cfg.py            # run the built-in demos
    python3 extract_cfg.py <hex>      # print the CFG of the given code
    python3 extract_cfg.py <hex> --dot  # emit Graphviz DOT instead

Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
import sys
from collections import defaultdict

JUMP, JUMPI, JUMPDEST = 0x56, 0x57, 0x5B
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
PUSH0, PUSH32 = 0x5F, 0x7F

# Terminators: control cannot fall through to the next instruction.
TERMINATORS = {0x00, 0xF3, 0xFD, 0xFE, 0xFF, JUMP, CALLSUB, RETURNSUB}

NAMES = {
    0x00: "STOP", 0x01: "ADD", 0x02: "MUL", 0x03: "SUB", 0x50: "POP",
    0x36: "CALLDATASIZE", 0x5B: "JUMPDEST", 0x56: "JUMP", 0x57: "JUMPI",
    0xB0: "CALLSUB", 0xB1: "CALLDEST", 0xB2: "RETURNSUB",
    0xF3: "RETURN", 0xFD: "REVERT", 0xFE: "INVALID", 0xFF: "SELFDESTRUCT",
}
NAMES.update({0x80 + i: f"DUP{i + 1}" for i in range(16)})
NAMES.update({0x90 + i: f"SWAP{i + 1}" for i in range(16)})
NAMES.update({PUSH0 + i: f"PUSH{i}" for i in range(33)})


def name(op):
    return NAMES.get(op, f"OP_{op:02X}")


def instr_size(op):
    return 1 + (op - PUSH0) if PUSH0 <= op <= PUSH32 else 1


def is_push(op):
    return PUSH0 <= op <= PUSH32


def push_value(code, pc):
    """Immediate value of the PUSH at pc, zero-padded past end of code."""
    n = instr_size(code[pc]) - 1
    imm = code[pc + 1:pc + 1 + n]
    return int.from_bytes(imm.ljust(n, b"\0"), "big")


def extract_cfg(code):
    """One-pass CFG extraction.  Returns (visited, edges) where visited
    maps each reachable pc to its opcode, and edges maps pc to a list of
    (kind, target): kind in {fall, jump, branch, call, ret}; a target of
    len(code) is the implicit STOP."""
    visited = {}                      # pc -> opcode
    edges = defaultdict(list)         # pc -> [(kind, target)]
    returns = set()                   # entries known to return
    pending = defaultdict(list)       # entry -> [(call site, return pc, caller entry)]
    enter_parents = defaultdict(list)  # entry -> entries that enter it

    OUTER = None
    work = [(0, OUTER, None)]         # (pc, governing entry, preceding push value)

    def resolve(entry):
        """Mark an entry as returning; flush its pending return points
        and resolve entries that enter it without a call, in cascade."""
        stack = [entry]
        while stack:
            e = stack.pop()
            if e in returns:
                continue
            returns.add(e)
            for site, ret_pc, caller in pending.pop(e, ()):
                edges[site].append(("ret", ret_pc))
                work.append((ret_pc, caller, None))
            stack.extend(enter_parents[e])

    while work:
        pc, entry, push_val = work.pop()
        if pc >= len(code):
            continue                            # implicit STOP
        op = code[pc]

        # A CALLDEST is its own governing entry.  An arrival without
        # a call — by fall-through or by jump — links the arriving
        # entry as a parent: if this entry returns, so does that one.
        if op == CALLDEST and entry != pc:
            enter_parents[pc].append(entry)
            if pc in returns:
                resolve(entry)
            entry = pc

        if pc in visited:
            continue
        visited[pc] = op
        nxt = pc + instr_size(op)

        if op == CALLSUB:
            dest = push_val
            edges[pc].append(("call", dest))
            work.append((dest, dest, None))
            if dest in returns:
                edges[pc].append(("ret", nxt))
                work.append((nxt, entry, None))
            else:
                pending[dest].append((pc, nxt, entry))
        elif op == RETURNSUB:
            resolve(entry)
        elif op == JUMP:
            edges[pc].append(("jump", push_val))
            work.append((push_val, entry, None))
        elif op == JUMPI:
            edges[pc].append(("branch", push_val))
            edges[pc].append(("fall", nxt))
            work.append((push_val, entry, None))
            work.append((nxt, entry, None))
        elif op not in TERMINATORS:
            edges[pc].append(("fall", nxt))
            work.append((nxt, entry, push_value(code, pc) if is_push(op) else None))

    return visited, dict(edges)


def basic_blocks(code, visited, edges):
    """Group reachable instructions into basic blocks.  Returns
    (blocks, block_edges): blocks is a sorted list of instruction-pc
    lists; block_edges maps a block's first pc to [(kind, target pc)]."""
    leaders = {0} if 0 in visited else set()
    for pc, out in edges.items():
        many = len(out) > 1
        for kind, t in out:
            if t in visited and (kind != "fall" or many):
                leaders.add(t)
    leaders.update(pc for pc, op in visited.items() if op in (JUMPDEST, CALLDEST))

    blocks, block_edges = [], {}
    for pc in sorted(visited):
        if pc in leaders or not blocks or blocks[-1][-1] + instr_size(visited[blocks[-1][-1]]) != pc:
            blocks.append([])
        blocks[-1].append(pc)
    for blk in blocks:
        block_edges[blk[0]] = edges.get(blk[-1], [])
    return blocks, block_edges


def disasm(code, pc):
    op = code[pc]
    if is_push(op) and op != PUSH0:
        return f"{name(op)} 0x{push_value(code, pc):X}"
    return name(op)


def print_cfg(code, title=""):
    visited, edges = extract_cfg(code)
    blocks, block_edges = basic_blocks(code, visited, edges)
    if title:
        print(f"=== {title}: 0x{code.hex().upper()} ===")
    for blk in blocks:
        print(f"block @{blk[0]}:")
        for pc in blk:
            print(f"    {pc:4}: {disasm(code, pc)}")
        for kind, t in block_edges[blk[0]]:
            target = "exit" if t >= len(code) else f"@{t}"
            print(f"    -> {kind} {target}")
    dead = len(code) - sum(instr_size(op) for op in visited.values())
    print(f"({len(visited)} reachable instructions, {dead} data bytes)\n")


def dot_cfg(code):
    visited, edges = extract_cfg(code)
    blocks, block_edges = basic_blocks(code, visited, edges)
    style = {"call": ' [style=dashed,label="call"]',
             "ret": ' [style=dotted,label="ret"]',
             "branch": ' [label="taken"]', "jump": "", "fall": ""}
    out = ["digraph cfg {", "    node [shape=box,fontname=monospace];"]
    for blk in blocks:
        label = "\\l".join(f"{pc}: {disasm(code, pc)}" for pc in blk) + "\\l"
        out.append(f'    b{blk[0]} [label="{label}"];')
    exits = any(t >= len(code) for es in block_edges.values() for _, t in es)
    if exits:
        out.append('    exit [shape=ellipse,label="STOP"];')
    for blk in blocks:
        for kind, t in block_edges[blk[0]]:
            target = "exit" if t >= len(code) else f"b{t}"
            out.append(f"    b{blk[0]} -> {target}{style[kind]};")
    out.append("}")
    return "\n".join(out)


DEMOS = [
    ("simple routine",           "6004B000B1B2"),
    ("two levels of subroutines","6004B000B16009B0B2B1B2"),
    ("subroutine at end of code","600556B1B25B6003B0"),
    ("SQUARE called at two depths","6002600BB06003600BB000B18002B2"),
    ("fall-through second entry","6008B05F600AB000B15FB150B2"),
    ("recursion, no base case",  "6004B000B16004B0B2"),
    ("jump to a CALLDEST",      "6004B000B15F600956B150B2"),
]

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--dot"]
    if args:
        code = bytes.fromhex(args[0].removeprefix("0x"))
        print(dot_cfg(code) if "--dot" in sys.argv else print_cfg(code) or "", end="")
    else:
        for title, hexcode in DEMOS:
            print_cfg(bytes.fromhex(hexcode), title)
