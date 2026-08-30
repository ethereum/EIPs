"""A small EVM interpreter with the EIP-7979 instructions.

Enough of the EVM to execute what compile.py emits, plus CALLSUB,
CALLDEST, and RETURNSUB with the runtime semantics of EIP-7979: a
return stack capped at 1024, a halt if CALLSUB's destination is not
a CALLDEST, a halt if RETURNSUB finds the return stack empty.
Legacy code runs too: JUMPDEST analysis marks the valid destinations
of dynamic jumps, exactly as clients do today.

Gas follows the Yellow Paper tiers (very low 3, low 5, mid 8, high
10, jumpdest 1) and the EIP's proposed costs (CALLSUB 8, CALLDEST 1,
RETURNSUB 5).  Memory expansion is not charged: the comparisons this
supports are between two compilations of the same program, whose
memory use is identical.

execute(code, calldata) -> (status, returndata, gas_used) where
status is "return", "stop", "revert", or a halt reason.
"""
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
U256 = (1 << 256) - 1


def signed(v):
    return v - (1 << 256) if v >> 255 else v


def jumpdest_analysis(code):
    """The runtime scan validated code no longer needs."""
    ok, pc = set(), 0
    while pc < len(code):
        op = code[pc]
        if op in (0x5B, CALLDEST):
            ok.add(pc)
        pc += op - 0x5E if 0x5F < op <= 0x7F else 1
    return ok

GAS = {0x00: 0, 0xF3: 0, 0xFD: 0, 0x50: 2, 0x36: 2, 0x5B: 1, CALLDEST: 1,
       0x02: 5, 0x04: 5, 0x05: 5, 0x06: 5, 0x07: 5, 0x0A: 10,
       0x56: 8, 0x57: 10, CALLSUB: 8, RETURNSUB: 5}


def execute(code, calldata=b"", gas_limit=10_000_000):
    stack, rstack, memory = [], [], bytearray()
    labels = jumpdest_analysis(code)
    pc, gas = 0, 0

    def need(n):
        if len(memory) < n:
            memory.extend(b"\0" * (n - len(memory)))

    while pc < len(code):
        op = code[pc]
        gas += GAS.get(op, 3)
        if gas > gas_limit:
            return ("out of gas", b"", gas)

        if 0x5F <= op <= 0x7F:                     # PUSH0..PUSH32
            n = op - 0x5F
            stack.append(int.from_bytes(code[pc + 1:pc + 1 + n].ljust(n, b"\0"), "big"))
            pc += 1 + n
            continue
        if 0x80 <= op <= 0x8F:                     # DUP
            if len(stack) < op - 0x7F:
                return ("stack underflow", b"", gas)
            stack.append(stack[0x7F - op])
            pc += 1
            continue
        if 0x90 <= op <= 0x9F:                     # SWAP
            n = op - 0x8F
            if len(stack) < n + 1:
                return ("stack underflow", b"", gas)
            stack[-1], stack[-n - 1] = stack[-n - 1], stack[-1]
            pc += 1
            continue

        try:
            if op == 0x00:
                return ("stop", b"", gas)
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
            elif op == 0x05:
                a, b = signed(stack.pop()), signed(stack.pop())
                stack.append((abs(a) // abs(b) * (1 if (a < 0) == (b < 0) else -1)
                              if b else 0) & U256)
            elif op == 0x06:
                a, b = stack.pop(), stack.pop()
                stack.append(a % b if b else 0)
            elif op == 0x07:
                a, b = signed(stack.pop()), signed(stack.pop())
                stack.append((abs(a) % abs(b) * (1 if a >= 0 else -1)
                              if b else 0) & U256)
            elif op == 0x0A:
                a, b = stack.pop(), stack.pop()
                stack.append(pow(a, b, 1 << 256))
            elif op == 0x10:
                stack.append(int(stack.pop() < stack.pop()))
            elif op == 0x11:
                stack.append(int(stack.pop() > stack.pop()))
            elif op == 0x12:
                stack.append(int(signed(stack.pop()) < signed(stack.pop())))
            elif op == 0x13:
                stack.append(int(signed(stack.pop()) > signed(stack.pop())))
            elif op == 0x14:
                stack.append(int(stack.pop() == stack.pop()))
            elif op == 0x15:
                stack.append(int(stack.pop() == 0))
            elif op == 0x16:
                stack.append(stack.pop() & stack.pop())
            elif op == 0x17:
                stack.append(stack.pop() | stack.pop())
            elif op == 0x18:
                stack.append(stack.pop() ^ stack.pop())
            elif op == 0x19:
                stack.append(stack.pop() ^ U256)
            elif op == 0x1A:
                i, x = stack.pop(), stack.pop()
                stack.append((x >> (8 * (31 - i))) & 0xFF if i < 32 else 0)
            elif op == 0x1B:
                s, v = stack.pop(), stack.pop()
                stack.append((v << s) & U256 if s < 256 else 0)
            elif op == 0x1C:
                s, v = stack.pop(), stack.pop()
                stack.append(v >> s if s < 256 else 0)
            elif op == 0x1D:
                s, v = stack.pop(), signed(stack.pop())
                stack.append((v >> min(s, 255)) & U256)
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
            elif op == 0x53:
                i, v = stack.pop(), stack.pop()
                need(i + 1)
                memory[i] = v & 0xFF
            elif op == 0x56:
                dest = stack.pop()
                if dest not in labels:
                    return ("bad jump destination", b"", gas)
                pc = dest
                continue
            elif op == 0x57:
                dest, cond = stack.pop(), stack.pop()
                if cond:
                    if dest not in labels:
                        return ("bad jump destination", b"", gas)
                    pc = dest
                    continue
            elif op == 0x5B:
                pass
            elif op == 0xF3:
                i, n = stack.pop(), stack.pop()
                need(i + n)
                return ("return", bytes(memory[i:i + n]), gas)
            elif op == 0xFD:
                i, n = stack.pop(), stack.pop()
                need(i + n)
                return ("revert", bytes(memory[i:i + n]), gas)
            elif op == CALLSUB:
                dest = stack.pop()
                if dest >= len(code) or code[dest] != CALLDEST:
                    return ("CALLSUB to non-CALLDEST", b"", gas)
                if len(rstack) >= 1024:
                    return ("return stack overflow", b"", gas)
                rstack.append(pc + 1)
                pc = dest
                continue
            elif op == CALLDEST:
                pass
            elif op == RETURNSUB:
                if not rstack:
                    return ("return stack underflow", b"", gas)
                pc = rstack.pop()
                continue
            else:
                return (f"invalid opcode 0x{op:02X}", b"", gas)
        except IndexError:
            return ("stack underflow", b"", gas)
        if len(stack) > 1024:
            return ("stack overflow", b"", gas)
        pc += 1
    return ("stop", b"", gas)                     # ran off the end
