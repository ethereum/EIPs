"""A sound walker, and the walk counts for two calling conventions.

The walker's knowledge rule is minimal and uncontestable:
  * it knows a jump's destination only when the immediately preceding
    instruction pushed it (adjacency -- no dataflow, no compiler idioms);
  * it maintains the machine's return stack itself, because CALLSUB and
    RETURNSUB alone can touch it, so a walk's own history determines it;
  * any other jump destination is data: the walker forks to every
    JUMPDEST in the code.
Walks end at STOP or the end of code; a walk that visits the same
instruction more than CAP times is abandoned (counted, not extended).

The program family: K calls to a shared SQUARE routine, written with
today's jump convention and with CALLSUB/CALLDEST/RETURNSUB.

The one-bit exhibit: the two-call program given one boolean input, so
the truth is exactly two traces; both walkers' trees are printed walk
by walk.  run7979.py, a byte-identical copy of the reference
interpreter among EIP-7979's assets, executes every program and
supplies the gas figures.
"""
PUSH1, JUMP, JUMPI, JUMPDEST, STOP = 0x60, 0x56, 0x57, 0x5B, 0x00
CALLDATALOAD = 0x35
DUP1, MUL, SWAP1 = 0x80, 0x02, 0x90
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2

def build_jump(K):
    """push RTN_i; push v; push SQUARE; jump; RTN_i: jumpdest ... stop
       SQUARE: jumpdest dup1 mul swap1 jump"""
    n = K * 9 + 1                       # call site: 2+2+2+1, landing: 1+... per call 8 bytes + jumpdest
    # layout: per call: push RTN(2) push v(2) push SQ(2) jump(1) jumpdest(1) = 8; then stop(1); SQUARE at 8K+1
    sq = 8 * K + 1
    code = bytearray()
    for i in range(K):
        rtn = 8 * (i + 1) - 1
        code += bytes([PUSH1, rtn, PUSH1, i + 2, PUSH1, sq, JUMP, JUMPDEST])
    code.append(STOP)
    code += bytes([JUMPDEST, DUP1, MUL, SWAP1, JUMP])
    assert len(code) == sq + 5 and code[sq] == JUMPDEST
    return bytes(code)

def build_callsub(K):
    """(push v; push SQUARE; callsub) x K; stop; SQUARE: calldest dup1 mul returnsub"""
    sq = 5 * K + 1
    code = bytearray()
    for i in range(K):
        code += bytes([PUSH1, i + 2, PUSH1, sq, CALLSUB])
    code.append(STOP)
    code += bytes([CALLDEST, DUP1, MUL, RETURNSUB])
    assert code[sq] == CALLDEST
    return bytes(code)

def build_bit_jump():
    """SQUARE(2); if input bit, skip SQUARE(3).  Jump convention.
    layout: 0: push RTN1(2) push 2(2) push SQ(2) jump(1) -> 7
    RTN1=7: jumpdest ; 8: push 0(2) calldataload(1) push SKIP(2) jumpi(1) -> 14
    14: push RTN2(2) push 3(2) push SQ(2) jump(1) -> 21
    RTN2=21: jumpdest ; SKIP=22: jumpdest stop ; SQ=24: jumpdest dup1 mul swap1 jump"""
    RTN1, RTN2, SKIP, SQ = 7, 21, 22, 24
    code = bytes([PUSH1, RTN1, PUSH1, 2, PUSH1, SQ, JUMP,
                  JUMPDEST, PUSH1, 0, CALLDATALOAD, PUSH1, SKIP, JUMPI,
                  PUSH1, RTN2, PUSH1, 3, PUSH1, SQ, JUMP,
                  JUMPDEST, JUMPDEST, STOP,
                  JUMPDEST, 0x80, 0x02, 0x90, JUMP])
    assert code[SQ] == JUMPDEST and code[SKIP] == JUMPDEST
    return code

def build_bit_callsub():
    """Same program with callsub/calldest/returnsub.
    0: push 2(2) push SQ(2) callsub(1) -> 5
    5: push 0(2) calldataload(1) push SKIP(2) jumpi(1) -> 11
    11: push 3(2) push SQ(2) callsub(1) -> 16
    SKIP=16: jumpdest stop ; SQ=18: calldest dup1 mul returnsub"""
    SKIP, SQ = 16, 18
    code = bytes([PUSH1, 2, PUSH1, SQ, CALLSUB,
                  PUSH1, 0, CALLDATALOAD, PUSH1, SKIP, JUMPI,
                  PUSH1, 3, PUSH1, SQ, CALLSUB,
                  JUMPDEST, STOP,
                  CALLDEST, 0x80, 0x02, RETURNSUB])
    assert code[SQ] == CALLDEST
    return code

def jumpdests(code):
    out, pc = [], 0
    while pc < len(code):
        if code[pc] == JUMPDEST: out.append(pc)
        pc += 2 if code[pc] == PUSH1 else 1
    return out

def walk_count(code, cap, labels=None):
    """Returns (walks, nodes, routes): leaves of the walk tree, total
    steps, and -- when labels name positions -- one line per walk,
    naming each control transfer it took: '>' marks a transfer the
    walker knows, '?' one it guesses.  cap: max visits per instruction
    per walk.  The true execution of the K-call family visits SQUARE
    K times, so cap=K is the least sound bound; smaller loses the true
    path, larger only grows the tree."""
    dests = jumpdests(code)
    walks = nodes = 0
    routes = [] if labels is not None else None

    def name(d):
        return labels.get(d, str(d)) if labels is not None else ""

    def done(route, how):
        nonlocal walks
        walks += 1
        if routes is not None:
            routes.append(route + " " + how)

    # state: (pc, last_push, return_stack, visits, route)
    stack = [(0, None, (), {}, "0")]
    while stack:
        pc, last, rets, vis, route = stack.pop()
        nodes += 1
        if pc >= len(code) or code[pc] == STOP:
            done(route, "stop"); continue
        v = vis.get(pc, 0) + 1
        if v > cap:
            done(route, "abandoned"); continue   # counted, not extended
        vis = dict(vis); vis[pc] = v
        op = code[pc]
        if op == PUSH1:
            stack.append((pc + 2, code[pc + 1], rets, vis, route))
        elif op == JUMP:
            if last is not None:
                stack.append((last, None, rets, vis, route + " >" + name(last)))
            else:                          # data: fork to every JUMPDEST
                for d in dests:
                    stack.append((d, None, rets, vis, route + " ?" + name(d)))
        elif op == CALLSUB:
            if last is not None:
                stack.append((last, None, rets + (pc + 1,), vis, route + " >" + name(last)))
            else:
                for d in (i for i in range(len(code)) if code[i] == CALLDEST):
                    stack.append((d, None, rets + (pc + 1,), vis, route + " ?" + name(d)))
        elif op == JUMPI:
            if last is not None:            # dest certain; condition is data:
                stack.append((last, None, rets, vis, route + " >" + name(last)))
                stack.append((pc + 1, None, rets, vis, route))      # both arms
            else:
                for d in dests:
                    stack.append((d, None, rets, vis, route + " ?" + name(d)))
                stack.append((pc + 1, None, rets, vis, route))
        elif op == RETURNSUB:
            if rets: stack.append((rets[-1], None, rets[:-1], vis, route + " >" + name(rets[-1])))
            else: done(route, "halt")      # would halt: counted
        else:
            stack.append((pc + 1, None, rets, vis, route))
    return walks, nodes, routes

def closed_form(K):
    """walks(jump) = 1 + K + K^2 + ... + K^K"""
    return sum(K ** i for i in range(K + 1))

if __name__ == "__main__":
    from run7979 import execute   # byte-identical copy of EIP-7979's reference interpreter

    print(f"{'K':>2} {'jumpdests':>9} {'walks(jump)':>12} {'formula':>12}"
          f" {'walks(callsub)':>14} {'gas(jump)':>9} {'gas(callsub)':>12}")
    for K in range(1, 7):
        j, c = build_jump(K), build_callsub(K)
        wj, _, _ = walk_count(j, cap=K)
        wc, _, _ = walk_count(c, cap=K)
        assert wc == 1 and wj == closed_form(K)
        (sj, _, gj), (sc, _, gc) = execute(j, b""), execute(c, b"")
        assert sj == sc == "stop"
        print(f"{K:>2} {len(jumpdests(j)):>9} {wj:>12,} {closed_form(K):>12,}"
              f" {wc:>14,} {gj:>9} {gc:>12}")
    print("closed form confirmed; callsub: one walk at every K; gas from the interpreter")

    BIT1, BIT0 = b"\x01" + b"\x00" * 31, b"\x00" * 32
    bj, bc = build_bit_jump(), build_bit_callsub()
    wj, _, rj = walk_count(bj, 2, labels={7: "RTN1", 21: "RTN2", 22: "SKIP", 24: "SQ"})
    wc, _, rc = walk_count(bc, 2, labels={5: "RTN1", 16: "SKIP", 18: "SQ"})
    assert (wj, wc) == (13, 2)
    gas = [execute(code, bits)[2] for code in (bj, bc) for bits in (BIT1, BIT0)]
    assert gas == [58, 96, 48, 76]
    print(f"\none-bit exhibit: jump tree {wj} walks, callsub tree {wc};"
          f" gas, bit set: {gas[0]} vs {gas[2]}; bit clear: {gas[1]} vs {gas[3]}")
    print("callsub walks ('>' certain, '?' guessed):")
    for r in sorted(rc): print("  " + r)
    print("jump walks:")
    for r in sorted(rj): print("  " + r)
