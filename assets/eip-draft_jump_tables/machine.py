"""A small EVM interpreter with EIP-7979's instructions and this EIP's.

EIP-7979's run7979.py plus JUMPV and CALLSUBV, with the runtime
semantics this EIP gives them in all code, validated or not: the
table must lie within the code, a case beyond the count takes the
last entry, and the entry must be a JUMPDEST or CALLDEST -- a CALLDEST
for CALLSUBV -- or execution halts, as JUMP and CALLSUB halt.  The
JUMPDEST analysis is the one clients run today: the instructions
carry no immediate data.

Gas follows the Yellow Paper tiers (very low 3, low 5, mid 8, high
10, jumpdest 1) and the proposed costs: CALLSUB 8, CALLDEST 1,
RETURNSUB 5, JUMPV 10, CALLSUBV 10.  Memory expansion is not charged.

execute(code, calldata) -> (status, returndata, gas_used, trace) where
status is "return", "stop", "revert", or a halt reason, and trace has
one row per executed instruction: (pc, name, cost, stack, rstack),
the stacks as they were before the instruction, for the EIP's tables.
"""
from opcodes import CALLSUB, CALLDEST, RETURNSUB, CALLSUBV, JUMPV, table

U256 = (1 << 256) - 1

GAS = {0x00: 0, 0xF3: 0, 0xFD: 0, 0x50: 2, 0x36: 2, 0x5B: 1, CALLDEST: 1,
       0x02: 5, 0x04: 5, 0x05: 5, 0x06: 5, 0x07: 5, 0x0A: 10,
       0x56: 8, 0x57: 10, CALLSUB: 8, RETURNSUB: 5, JUMPV: 10, CALLSUBV: 10}

NAMES = {0x00: "STOP", 0x01: "ADD", 0x02: "MUL", 0x03: "SUB", 0x50: "POP",
         0x56: "JUMP", 0x57: "JUMPI", 0x5B: "JUMPDEST", 0xF3: "RETURN",
         0xFD: "REVERT", CALLSUB: "CALLSUB", CALLDEST: "CALLDEST",
         RETURNSUB: "RETURNSUB", CALLSUBV: "CALLSUBV", JUMPV: "JUMPV",
         0x35: "CALLDATALOAD", 0x52: "MSTORE", 0x36: "CALLDATASIZE"}


def name(code, pc):
    op = code[pc]
    if 0x5F <= op <= 0x7F:
        return f"PUSH{op - 0x5F}"
    if 0x80 <= op <= 0x8F:
        return f"DUP{op - 0x7F}"
    if 0x90 <= op <= 0x9F:
        return f"SWAP{op - 0x8F}"
    return NAMES.get(op, f"0x{op:02X}")


def signed(v):
    return v - (1 << 256) if v >> 255 else v


def jumpdest_analysis(code):
    """The runtime scan, unchanged by this EIP."""
    ok, pc = set(), 0
    while pc < len(code):
        op = code[pc]
        if op in (0x5B, CALLDEST):
            ok.add(pc)
        pc += op - 0x5E if 0x5F < op <= 0x7F else 1
    return ok


def execute(code, calldata=b"", gas_limit=10_000_000):
    stack, rstack, memory, trace = [], [], bytearray(), []
    labels = jumpdest_analysis(code)
    pc, gas = 0, 0

    def need(n):
        if len(memory) < n:
            memory.extend(b"\0" * (n - len(memory)))

    def halt(why):
        return (why, b"", gas, trace)

    while pc < len(code):
        op = code[pc]
        cost = GAS.get(op, 3)
        trace.append((pc, name(code, pc), cost, list(stack), list(rstack)))
        gas += cost
        if gas > gas_limit:
            return halt("out of gas")

        if 0x5F <= op <= 0x7F:                     # PUSH0..PUSH32
            n = op - 0x5F
            stack.append(int.from_bytes(code[pc + 1:pc + 1 + n].ljust(n, b"\0"), "big"))
            pc += 1 + n
            continue
        if 0x80 <= op <= 0x8F:                     # DUP
            if len(stack) < op - 0x7F:
                return halt("stack underflow")
            stack.append(stack[0x7F - op])
            pc += 1
            continue
        if 0x90 <= op <= 0x9F:                     # SWAP
            n = op - 0x8F
            if len(stack) < n + 1:
                return halt("stack underflow")
            stack[-1], stack[-n - 1] = stack[-n - 1], stack[-1]
            pc += 1
            continue

        try:
            if op == 0x00:
                return ("stop", b"", gas, trace)
            elif op == 0x01:
                stack.append((stack.pop() + stack.pop()) & U256)
            elif op == 0x02:
                stack.append((stack.pop() * stack.pop()) & U256)
            elif op == 0x03:
                a = stack.pop()
                stack.append((a - stack.pop()) & U256)
            elif op == 0x04:
                a, b = stack.pop(), stack.pop()
                stack.append(a // b if b else 0)
            elif op == 0x06:
                a, b = stack.pop(), stack.pop()
                stack.append(a % b if b else 0)
            elif op == 0x10:
                stack.append(int(stack.pop() < stack.pop()))
            elif op == 0x11:
                stack.append(int(stack.pop() > stack.pop()))
            elif op == 0x14:
                stack.append(int(stack.pop() == stack.pop()))
            elif op == 0x15:
                stack.append(int(stack.pop() == 0))
            elif op == 0x35:
                i = stack.pop()
                stack.append(int.from_bytes(calldata[i:i + 32].ljust(32, b"\0"), "big"))
            elif op == 0x36:
                stack.append(len(calldata))
            elif op == 0x50:
                stack.pop()
            elif op == 0x51:
                i = stack.pop()
                need(i + 32)
                stack.append(int.from_bytes(memory[i:i + 32], "big"))
            elif op == 0x52:
                i, v = stack.pop(), stack.pop()
                need(i + 32)
                memory[i:i + 32] = v.to_bytes(32, "big")
            elif op == 0x56:
                dest = stack.pop()
                if dest not in labels:
                    return halt("bad jump destination")
                pc = dest
                continue
            elif op == 0x57:
                dest, cond = stack.pop(), stack.pop()
                if cond:
                    if dest not in labels:
                        return halt("bad jump destination")
                    pc = dest
                    continue
            elif op == 0x5B:
                pass
            elif op == 0xF3:
                i, n = stack.pop(), stack.pop()
                need(i + n)
                return ("return", bytes(memory[i:i + n]), gas, trace)
            elif op == 0xFD:
                i, n = stack.pop(), stack.pop()
                need(i + n)
                return ("revert", bytes(memory[i:i + n]), gas, trace)
            elif op == CALLSUB:
                dest = stack.pop()
                if dest >= len(code) or code[dest] != CALLDEST:
                    return halt("CALLSUB to non-CALLDEST")
                if len(rstack) >= 1024:
                    return halt("return stack overflow")
                rstack.append(pc + 1)
                pc = dest
                continue
            elif op == CALLDEST:
                pass
            elif op == RETURNSUB:
                if not rstack:
                    return halt("return stack underflow")
                pc = rstack.pop()
                continue
            elif op in (JUMPV, CALLSUBV):
                at, case = stack.pop(), stack.pop()
                dests = table(code, at)
                if dests is None:
                    return halt("table outside code")
                dest = dests[min(case, len(dests) - 1)]   # beyond the count: the last entry
                if op == JUMPV:
                    if dest not in labels:
                        return halt("bad jump destination")
                else:
                    if dest >= len(code) or code[dest] != CALLDEST:
                        return halt("CALLSUBV to non-CALLDEST")
                    if len(rstack) >= 1024:
                        return halt("return stack overflow")
                    rstack.append(pc + 1)
                pc = dest
                continue
            else:
                return halt(f"invalid opcode 0x{op:02X}")
        except IndexError:
            return halt("stack underflow")
        if len(stack) > 1024:
            return halt("stack overflow")
        pc += 1
    return ("stop", b"", gas, trace)                     # ran off the end


def markdown(trace):
    """The trace as the table the EIP's Test Cases use."""
    rows = ["|  PC   |      Op       | Cost |   Stack   |   RStack  |",
            "|-------|---------------|------|-----------|-----------|"]
    for pc, op, cost, stack, rstack in trace:
        s = "[" + ",".join(str(x) for x in stack) + "]"
        r = "[" + ",".join(str(x) for x in rstack) + "]"
        rows.append(f"| {pc:>4}  | {op:>13s} | {cost:>4} | {s:>9s} | {r:>9s} |")
    return "\n".join(rows)
