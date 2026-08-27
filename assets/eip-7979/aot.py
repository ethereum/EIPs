"""Ahead-of-time translation of EIP-8337-validated code to RISC-V.

This is the client-side transformation that validation makes legal.
The input is bytecode that passed EIP-8337 validation; the translator
re-derives what the validator proved — every destination a constant,
every instruction at one static stack offset, every subroutine with
known inputs and net stack effect — and spends those proofs:

  * Dynamic dispatch disappears: JUMP is `j`, JUMPI is `bnez`,
    CALLSUB is `jal`, RETURNSUB is `ret`.  The EVM return stack
    becomes the machine's.
  * The data stack disappears as a runtime object.  Every slot is a
    named location at translation time — a register at 64 bits, a
    fixed frame offset at 256 bits.  POP costs zero instructions.
  * No underflow or destination checks survive into the output,
    because all were proven.  Overflow remains a runtime check, as
    the EIP says it must: one compare per call, none per instruction.

What is NOT counted here: translation itself and validation are
one-time deploy costs (measured in cbench/); this file's output is
the recurring execution the network pays for.

Width "64" maps each stack slot to one register (EVM64 programs);
width "256" keeps slots as 4x64-bit little-endian limb groups in a
memory frame, arithmetic inlined or in shared routines.

Subset: what the yul7979 compiler emits.  A JUMP into a CALLDEST
(call elimination) and reads below the caller's own arguments are
valid EIP-7979 but outside this translator; it raises on them.

Placeholder opcodes as in evm64.py / interp.c.
"""

JUMP, JUMPI, JUMPDEST = 0x56, 0x57, 0x5B
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
PUSH0, PUSH32 = 0x5F, 0x7F
STOP, RETURN, REVERT = 0x00, 0xF3, 0xFD
OUTER = None

# op -> (pops, pushes, term)
INFO = {
    0x00: (0, 0, 1),
    0x01: (2, 1, 0), 0x02: (2, 1, 0), 0x03: (2, 1, 0), 0x04: (2, 1, 0),
    0x06: (2, 1, 0),
    0x10: (2, 1, 0), 0x11: (2, 1, 0), 0x12: (2, 1, 0), 0x13: (2, 1, 0),
    0x14: (2, 1, 0), 0x15: (1, 1, 0), 0x16: (2, 1, 0), 0x17: (2, 1, 0),
    0x18: (2, 1, 0), 0x19: (1, 1, 0), 0x1B: (2, 1, 0), 0x1C: (2, 1, 0),
    0x35: (1, 1, 0), 0x36: (0, 1, 0), 0x50: (1, 0, 0),
    0x51: (1, 1, 0), 0x52: (2, 0, 0),
    JUMP: (1, 0, 1), JUMPI: (2, 0, 0), JUMPDEST: (0, 0, 0),
    CALLSUB: (1, 0, 0), CALLDEST: (0, 0, 0), RETURNSUB: (0, 0, 1),
    RETURN: (2, 0, 1), REVERT: (2, 0, 1),
    0xE0: (1, 1, 0), 0xE1: (1, 1, 0), 0xE2: (2, 0, 0),
}
for _x in (0x01, 0x02, 0x03, 0x04, 0x06, 0x10, 0x11, 0x12, 0x13, 0x14,
           0x15, 0x16, 0x17, 0x18, 0x19, 0x1B, 0x1C):
    INFO[0xC0 + _x] = INFO[_x]
for _i in range(33):
    INFO[0x5F + _i] = (0, 1, 0)
for _i in range(16):
    INFO[0x80 + _i] = (_i + 1, _i + 2, 0)
    INFO[0x90 + _i] = (_i + 2, _i + 2, 0)

TWIN_OF = {0xC0 + x: x for x in (0x01, 0x02, 0x03, 0x04, 0x06, 0x10, 0x11,
                                 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                 0x19, 0x1B, 0x1C)}

GAS_LIMIT = 10_000_000_000


def evm_gas(op):
    """Per-opcode gas as the baseline interpreter charges it: the
    block sums here and the per-op charges there add up the same."""
    return {0x02: 5, 0x04: 5, 0x06: 5, 0x36: 2, 0x50: 2, 0x5B: 1,
            0x5F: 2, 0x56: 8, 0x57: 10, 0xB0: 8, 0xB1: 1, 0xB2: 5,
            0xC2: 5, 0xC4: 5, 0xC6: 5}.get(op, 3)


def block_gas(code, notes):
    """Static gas per basic block: {leader pc -> gas for its block}.
    Leaders are the entry, every destination and CALLDEST, and every
    instruction following a control transfer.  Charging per block is
    legal because validation proved the control flow: a block entered
    is a block completed, or execution halts anyway."""
    pcs = sorted(notes.offset)
    leaders = {0} | notes.dests | {p for p in pcs if code[p] == CALLDEST}
    for pc in pcs:
        if code[pc] in (JUMP, JUMPI, CALLSUB, RETURNSUB):
            leaders.add(pc + size_of(code, pc))
    gas, leader = {}, None
    for pc in pcs:
        if pc in leaders:
            leader = pc
            gas[leader] = 0
        gas[leader] += evm_gas(code[pc])
    return gas


def size_of(code, pc):
    op = code[pc]
    return op - 0x5E if PUSH0 < op <= PUSH32 else 1


class Notes:
    """What annotate() recovers from valid code."""
    def __init__(self):
        self.offset = {}          # pc -> static stack offset before the op
        self.entry = {}           # pc -> entry pc of its subroutine (or OUTER)
        self.inputs = {OUTER: 0}  # entry -> items reached below its base
        self.net = {}             # entry -> net stack effect
        self.maxh = {OUTER: 0}    # entry -> max offset reached in the frame
        self.const = {}           # pc of a PUSH -> its value
        self.folded = set()       # PUSHes consumed by a following branch
        self.dests = set()        # jump destinations
        self.callsite = {}        # pc of CALLSUB -> dest


def annotate(code):
    """One traversal of trusted-valid code; raises on anything outside
    the translator's subset (which would still be valid EIP-7979)."""
    n = Notes()
    pending = {}                       # entry -> [(ret_pc, offset, caller)]
    work = [(0, 0, OUTER, None)]

    def resolve(e, v):
        assert n.net.get(e, v) == v, "net conflict in valid code?"
        if e in n.net:
            return
        n.net[e] = v
        for ret_pc, off, caller in pending.pop(e, ()):
            work.append((ret_pc, off + v, caller, None))

    while work:
        pc, off, entry, push = work.pop()
        if pc >= len(code):
            continue                              # implicit STOP
        op = code[pc]
        if op == CALLDEST and (entry != pc or off != 0):
            raise NotImplementedError("jump or fall into CALLDEST")
        if pc in n.offset:
            assert n.offset[pc] == off and n.entry[pc] == entry
            continue
        n.offset[pc], n.entry[pc] = off, entry
        pops, pushes, term = INFO[op]
        need = pops - off
        if need > n.inputs.get(entry, 0):
            n.inputs[entry] = need
        off += pushes - pops
        if off > n.maxh.get(entry, 0):
            n.maxh[entry] = off
        nxt = pc + size_of(code, pc)

        if PUSH0 <= op <= PUSH32:
            v = int.from_bytes(code[pc + 1:nxt], "big")
            n.const[pc] = v
            work.append((nxt, off, entry, (pc, v)))
        elif op == CALLSUB:
            assert push is not None
            src, dest = push
            n.folded.add(src)
            n.callsite[pc] = dest
            n.inputs.setdefault(dest, 0)
            n.maxh.setdefault(dest, 0)
            work.append((dest, 0, dest, None))
            if dest in n.net:
                work.append((nxt, off + n.net[dest], entry, None))
            else:
                pending.setdefault(dest, []).append((nxt, off, entry))
        elif op == RETURNSUB:
            resolve(entry, off)
        elif op in (JUMP, JUMPI):
            assert push is not None
            src, dest = push
            n.folded.add(src)
            n.dests.add(dest)
            work.append((dest, off, entry, None))
            if op == JUMPI:
                work.append((nxt, off, entry, None))
        elif not term:
            work.append((nxt, off, entry, None))
    return n


# ----------------------------------------------------------------------
# Shared emission driver
# ----------------------------------------------------------------------

class Translator:
    def __init__(self, code):
        self.code = code
        self.n = annotate(code)
        self.gas = block_gas(code, self.n)
        self.asm = []
        self.uniq = 0

    def L(self, hint):
        self.uniq += 1
        return f".L{hint}_{self.uniq}"

    def e(self, *lines):
        self.asm.extend("\t" + l if not l.endswith(":") and not
                        l.startswith(".") and not l.startswith("\t")
                        else l for l in lines)

    def label(self, text):
        self.asm.append(text + ":")

    def translate(self):
        self.e(".text", ".globl evm_entry")
        self.label("evm_entry")
        self.prelude()
        code, n = self.code, self.n
        for pc in sorted(n.offset):
            op = code[pc]
            if pc in n.dests and op != CALLDEST:
                self.label(f"L{pc}")
            if op == CALLDEST:
                self.label(f"F{pc}")
                self.prologue(pc)
                self.gas_check(self.gas[pc])
                continue
            if pc in self.gas:
                self.gas_check(self.gas[pc])
            if pc in n.folded:
                continue
            self.instr(pc, op)
        self.routines()
        self.traps()
        return "\n".join(self.asm) + "\n"

    def gas_check(self, amount):
        """Charge a basic block's gas: two instructions per block —
        the metering a mainnet AOT cannot omit."""
        assert 0 <= amount < 2048, "block gas exceeds addi immediate"
        self.e(f"addi {self.GASREG}, {self.GASREG}, {-amount}",
               f"bltz {self.GASREG}, __trap_gas")

    def base(self, pc):
        return self.n.inputs[self.n.entry[pc]]

    def instr(self, pc, op):
        n = self.n
        h = n.offset[pc]                # frame offset before the op
        b = self.base(pc)               # inputs of the enclosing subroutine
        if PUSH0 <= op <= PUSH32:
            self.push(b + h, n.const[pc])
        elif 0x80 <= op <= 0x8F:
            self.dup(b + h, op - 0x7F)
        elif 0x90 <= op <= 0x9F:
            self.swap(b + h, op - 0x8F)
        elif op == 0x50:
            pass                        # POP: zero instructions
        elif op == JUMPDEST:
            pass
        elif op == JUMP:
            dest = self.branch_dest(pc)
            self.e(f"j L{dest}")
        elif op == JUMPI:
            dest = self.branch_dest(pc)
            self.jumpi(b + h, f"L{dest}")
        elif op == CALLSUB:
            self.call(pc)
        elif op == RETURNSUB:
            self.epilogue()
        elif op == RETURN:
            self.ret_data(b + h)
        elif op == REVERT:
            self.e("call __rt_revert")
        elif op == STOP:
            self.e("call __rt_stop")
        elif op == 0x36:
            self.cdsize(b + h)
        else:
            self.alu(pc, op, b + h)

    def branch_dest(self, pc):
        # the folded PUSH directly precedes: find it
        for back in range(1, 34):
            if pc - back in self.n.const and pc - back + \
                    size_of(self.code, pc - back) == pc:
                return self.n.const[pc - back]
        raise AssertionError("unfolded branch in valid code?")

    def call(self, pc):
        n = self.n
        dest = n.callsite[pc]
        h = n.offset[pc] - 1            # call-site offset sans folded dest
        b = self.base(pc)
        i = n.inputs[dest]
        k = b + h - i                   # caller regs/words below the args
        assert k >= 0, "call reaches below caller frame: outside subset"
        net = n.net.get(dest)
        self.call_emit(dest, k, i, net)

    def traps(self):
        msgs = (("depth", "return stack overflow"),
                ("ovf", "stack overflow"),
                ("gas", "out of gas"),
                ("mem", "memory out of range"),
                ("unimp", "unimplemented in AOT subset"))
        for name, msg in msgs:
            self.label(f"__trap_{name}")
            self.e(f"la a0, .Lmsg_{name}", "call __rt_trap")
        self.e('.section .rodata')
        for name, msg in msgs:
            self.label(f".Lmsg_{name}")
            self.e(f'.asciz "{msg}"')
        self.e(".text")


# ----------------------------------------------------------------------
# 64-bit width: one register per stack slot
# ----------------------------------------------------------------------

REGS64 = ("a0 a1 a2 a3 a4 a5 a6 a7 s3 s4 s5 s6 s7 s8 s9 s10 s11 "
          "t0 t1 t2 t3").split()
# reserved: s0 = height base, s1 = call depth, s2 = gas remaining;
# scratch: t4 t5 t6 (routines save any other register they touch)


class Translate64(Translator):
    GASREG = "s2"

    def r(self, idx):
        assert 0 <= idx < len(REGS64), f"frame needs slot {idx}: too deep"
        return REGS64[idx]

    def prelude(self):
        self.e("li s0, 0", "li s1, 0", f"li s2, {GAS_LIMIT}")

    def prologue(self, pc):
        n = self.n
        room = 1024 - (n.inputs[pc] + n.maxh[pc])
        self.e("addi sp, sp, -8", "sd ra, 0(sp)",
               "addi s1, s1, 1", "li t6, 1024", "bgtu s1, t6, __trap_depth",
               f"li t6, {room}", "bgtu s0, t6, __trap_ovf")

    def epilogue(self):
        self.e("ld ra, 0(sp)", "addi sp, sp, 8", "addi s1, s1, -1", "ret")

    def push(self, at, v):
        self.e(f"li {self.r(at)}, {v}")

    def dup(self, at, depth):
        self.e(f"mv {self.r(at)}, {self.r(at - depth)}")

    def swap(self, at, depth):
        a, bd = self.r(at - 1), self.r(at - 1 - depth)
        self.e(f"mv t6, {a}", f"mv {a}, {bd}", f"mv {bd}, t6")

    def jumpi(self, at, label):
        # dest folded; condition is the next item down
        self.e(f"bnez {self.r(at - 2)}, {label}")

    def cdsize(self, at):
        self.e("la t6, CALLDATA_LEN", f"ld {self.r(at)}, 0(t6)")

    def call_emit(self, dest, k, i, net):
        if k:
            self.e(f"addi sp, sp, {-8 * k}")
            for j in range(k):
                self.e(f"sd {self.r(j)}, {8 * j}(sp)")
            self.e(f"addi s0, s0, {k}")
            for j in range(i):
                self.e(f"mv {self.r(j)}, {self.r(k + j)}")
        self.e(f"jal ra, F{dest}")
        if net is None:
            self.e("j __trap_unimp")    # callee never returns: unreachable
            return
        if k:
            for j in reversed(range(i + net)):
                self.e(f"mv {self.r(k + j)}, {self.r(j)}")
            for j in range(k):
                self.e(f"ld {self.r(j)}, {8 * j}(sp)")
            self.e(f"addi sp, sp, {8 * k}", f"addi s0, s0, {-k}")

    def ret_data(self, at):
        off, ln = self.r(at - 1), self.r(at - 2)
        self.e(f"mv t4, {off}", f"mv t5, {ln}",
               "la a0, MEM", "add a0, a0, t4", "mv a1, t5",
               "call __rt_return")

    def alu(self, pc, op, at):
        base = TWIN_OF.get(op)
        a = self.r(at - 1)                       # top
        pops = INFO[op][0]
        b2 = self.r(at - 2) if pops == 2 else a  # next, when it exists
        r = b2
        if base == 0x01:
            self.e(f"add {r}, {a}, {b2}")
        elif base == 0x02:
            self.e(f"mul {r}, {a}, {b2}")
        elif base == 0x03:
            self.e(f"sub {r}, {a}, {b2}")
        elif base in (0x04, 0x06):
            insn = "divu" if base == 0x04 else "remu"
            skip = self.L("dz")
            done = self.L("dd")
            self.e(f"beqz {b2}, {skip}", f"{insn} {r}, {a}, {b2}",
                   f"j {done}", f"{skip}:", f"li {r}, 0", f"{done}:")
        elif base == 0x10:
            self.e(f"sltu {r}, {a}, {b2}")
        elif base == 0x11:
            self.e(f"sltu {r}, {b2}, {a}")
        elif base == 0x12:
            self.e(f"slt {r}, {a}, {b2}")
        elif base == 0x13:
            self.e(f"slt {r}, {b2}, {a}")
        elif base == 0x14:
            self.e(f"xor t6, {a}, {b2}", f"seqz {r}, t6")
        elif base == 0x15:
            self.e(f"seqz {a}, {a}")
        elif base == 0x16:
            self.e(f"and {r}, {a}, {b2}")
        elif base == 0x17:
            self.e(f"or {r}, {a}, {b2}")
        elif base == 0x18:
            self.e(f"xor {r}, {a}, {b2}")
        elif base == 0x19:
            self.e(f"not {a}, {a}")
        elif base == 0x1B:
            self.e(f"sltiu t6, {a}, 64", f"neg t6, t6",
                   f"sll {r}, {b2}, {a}", f"and {r}, {r}, t6")
        elif base == 0x1C:
            self.e(f"sltiu t6, {a}, 64", f"neg t6, t6",
                   f"srl {r}, {b2}, {a}", f"and {r}, {r}, t6")
        elif op == 0xE0:
            self.e(f"mv t4, {a}", "call __cdload64", f"mv {a}, t4")
        elif op == 0xE1:
            self.e(f"mv t4, {a}", "call __mload64", f"mv {a}, t4")
        elif op == 0xE2:
            self.e(f"mv t4, {a}", f"mv t5, {b2}", "call __mstore64")
        else:
            raise NotImplementedError(f"opcode {op:#x} at 64-bit width")

    def routines(self):
        self.label("__cdload64")
        self.e("addi sp, sp, -16", "sd s2, 0(sp)", "sd s3, 8(sp)",
               "la s3, CALLDATA",
               "la t5, CALLDATA_LEN", "ld t5, 0(t5)",
               "addi t4, t4, 24", "li s2, 0")
        for b in range(8):
            self.e("slli s2, s2, 8",
                   f"addi t6, t4, {b}",
                   "bgeu t6, t5, 1f",
                   "add t6, s3, t6", "lbu t6, 0(t6)", "or s2, s2, t6",
                   "1:")
        self.e("mv t4, s2", "ld s2, 0(sp)", "ld s3, 8(sp)",
               "addi sp, sp, 16", "ret")

        self.label("__mstore64")
        self.e(f"li t6, {(1 << 20) - 32}", "bgtu t4, t6, __trap_mem",
               "la t6, MEM", "add t4, t6, t4")
        for b in range(24):
            self.e(f"sb zero, {b}(t4)")
        for b in range(8):
            self.e(f"srli t6, t5, {8 * (7 - b)}", f"sb t6, {24 + b}(t4)")
        self.e("ret")

        self.label("__mload64")
        self.e(f"li t6, {(1 << 20) - 32}", "bgtu t4, t6, __trap_mem",
               "la t5, MEM", "add t4, t5, t4", "li t5, 0")
        for b in range(8):
            self.e("slli t5, t5, 8", f"lbu t6, {24 + b}(t4)",
                   "or t5, t5, t6")
        self.e("mv t4, t5", "ret")


# ----------------------------------------------------------------------
# 256-bit width: one 32-byte frame slot per stack item, arithmetic on
# four 64-bit limbs, little-endian in memory
# ----------------------------------------------------------------------

# reserved: s0 = frame pointer, s1 = call depth, s2 = frame ceiling,
# s3 = gas remaining; scratch: t0-t6, a0-a7; routines save
# s-registers they touch

class Translate256(Translator):
    GASREG = "s3"

    def at(self, idx, limb=0):
        return f"{32 * idx + 8 * limb}(s0)"

    def prelude(self):
        self.e("la s0, FRAME", "li s1, 0",
               "la s2, FRAME", "li t6, 32768", "add s2, s2, t6",
               f"li s3, {GAS_LIMIT}")

    def prologue(self, pc):
        n = self.n
        self.e("addi sp, sp, -8", "sd ra, 0(sp)",
               "addi s1, s1, 1", "li t6, 1024", "bgtu s1, t6, __trap_depth",
               f"li t6, {32 * (n.inputs[pc] + n.maxh[pc])}",
               "add t6, s0, t6", "bgtu t6, s2, __trap_ovf")

    def epilogue(self):
        self.e("ld ra, 0(sp)", "addi sp, sp, 8", "addi s1, s1, -1", "ret")

    def push(self, at, v):
        if v >> 64:
            for limb in range(4):
                part = (v >> (64 * limb)) & ((1 << 64) - 1)
                self.e(f"li t0, {part}", f"sd t0, {self.at(at, limb)}")
        else:
            self.e(f"li t0, {v}", f"sd t0, {self.at(at, 0)}")
            for limb in range(1, 4):
                self.e(f"sd zero, {self.at(at, limb)}")

    def dup(self, at, depth):
        for limb in range(4):
            self.e(f"ld t0, {self.at(at - depth, limb)}",
                   f"sd t0, {self.at(at, limb)}")

    def swap(self, at, depth):
        for limb in range(4):
            self.e(f"ld t0, {self.at(at - 1, limb)}",
                   f"ld t1, {self.at(at - 1 - depth, limb)}",
                   f"sd t1, {self.at(at - 1, limb)}",
                   f"sd t0, {self.at(at - 1 - depth, limb)}")

    def load_slot(self, at, regs):
        for limb in range(4):
            self.e(f"ld {regs[limb]}, {self.at(at, limb)}")

    def store_slot(self, at, regs):
        for limb in range(4):
            self.e(f"sd {regs[limb]}, {self.at(at, limb)}")

    def store_bit(self, at, reg):
        self.e(f"sd {reg}, {self.at(at, 0)}")
        for limb in range(1, 4):
            self.e(f"sd zero, {self.at(at, limb)}")

    def or_slot(self, at, into):
        self.e(f"ld {into}, {self.at(at, 0)}")
        for limb in range(1, 4):
            self.e(f"ld t6, {self.at(at, limb)}", f"or {into}, {into}, t6")

    def jumpi(self, at, label):
        self.or_slot(at - 2, "t0")
        self.e(f"bnez t0, {label}")

    def cdsize(self, at):
        self.e("la t6, CALLDATA_LEN", "ld t0, 0(t6)")
        self.store_bit(at, "t0")

    def call_emit(self, dest, k, i, net):
        if k:
            self.e(f"addi s0, s0, {32 * k}")
        self.e(f"jal ra, F{dest}")
        if net is None:
            self.e("j __trap_unimp")
            return
        if k:
            self.e(f"addi s0, s0, {-32 * k}")

    def ret_data(self, at):
        self.e(f"ld t4, {self.at(at - 1, 0)}",
               f"ld a1, {self.at(at - 2, 0)}",
               "la a0, MEM", "add a0, a0, t4", "call __rt_return")

    # -- arithmetic ------------------------------------------------------

    A = ("t0", "t1", "t2", "t3")        # top operand
    B = ("a0", "a1", "a2", "a3")        # next operand and result

    def cmp_ladder(self, at, signed, swap):
        """Unsigned/signed less-than of two slots, top < next
        (or swapped), result 0/1 into the result slot."""
        A, B = (self.B, self.A) if swap else (self.A, self.B)
        true, false, out = self.L("lt1"), self.L("lt0"), self.L("ltend")
        if signed:
            same = self.L("sgn")
            self.e(f"srli t4, {A[3]}, 63", f"srli t5, {B[3]}, 63",
                   f"beq t4, t5, {same}", "mv t6, t4", f"j {out}",
                   f"{same}:")
        for limb in (3, 2, 1):
            self.e(f"bltu {A[limb]}, {B[limb]}, {true}",
                   f"bltu {B[limb]}, {A[limb]}, {false}")
        self.e(f"sltu t6, {A[0]}, {B[0]}", f"j {out}",
               f"{true}:", "li t6, 1", f"j {out}",
               f"{false}:", "li t6, 0", f"{out}:")
        self.store_bit(at - 2, "t6")

    def add_chain(self, sub=False):
        """256-bit add or subtract of A (top) and B, result in B."""
        op = "sub" if sub else "add"
        for limb in range(4):
            a, b = self.A[limb], self.B[limb]
            if limb == 0:
                if sub:
                    self.e(f"sltu t4, {a}, {b}", f"sub {b}, {a}, {b}")
                else:
                    self.e(f"add {b}, {a}, {b}", f"sltu t4, {b}, {a}")
            elif limb == 3:
                self.e(f"{op} {b}, {a}, {b}" if not sub else
                       f"sub {b}, {a}, {b}",
                       f"{'sub' if sub else 'add'} {b}, {b}, t4")
            else:
                if sub:
                    self.e(f"sltu t5, {a}, {b}", f"sub {b}, {a}, {b}",
                           f"sltu t6, {b}, t4", f"sub {b}, {b}, t4",
                           "or t4, t5, t6")
                else:
                    self.e(f"add {b}, {a}, {b}", f"sltu t5, {b}, {a}",
                           f"add {b}, {b}, t4", f"sltu t6, {b}, t4",
                           "or t4, t5, t6")

    def alu(self, pc, op, at):
        if op == 0x35:                   # CALLDATALOAD
            self.e(f"addi t4, s0, {32 * (at - 1)}", "call __cdload256")
            return
        if op == 0x52:                   # MSTORE
            self.e(f"ld t4, {self.at(at - 1, 0)}",
                   f"ld t5, {self.at(at - 1, 1)}",
                   f"ld t6, {self.at(at - 1, 2)}", "or t5, t5, t6",
                   f"ld t6, {self.at(at - 1, 3)}", "or t5, t5, t6",
                   "bnez t5, __trap_mem",
                   f"addi t5, s0, {32 * (at - 2)}", "call __mstore256")
            return
        if op == 0x02:                   # MUL
            self.e(f"addi t4, s0, {32 * (at - 1)}",
                   f"addi t5, s0, {32 * (at - 2)}", "call __mul256")
            return
        if op == 0x15:                   # ISZERO
            self.or_slot(at - 1, "t0")
            self.e("seqz t0, t0")
            self.store_bit(at - 1, "t0")
            return
        if op == 0x19:                   # NOT
            for limb in range(4):
                self.e(f"ld t0, {self.at(at - 1, limb)}", "not t0, t0",
                       f"sd t0, {self.at(at - 1, limb)}")
            return

        two_ops = op in (0x01, 0x03, 0x04, 0x06, 0x10, 0x11, 0x12, 0x13,
                         0x14, 0x16, 0x17, 0x18)
        if not two_ops:
            raise NotImplementedError(f"opcode {op:#x} at 256-bit width")
        self.load_slot(at - 1, self.A)
        self.load_slot(at - 2, self.B)
        if op == 0x01:
            self.add_chain()
            self.store_slot(at - 2, self.B)
        elif op == 0x03:
            self.add_chain(sub=True)
            self.store_slot(at - 2, self.B)
        elif op in (0x04, 0x06):
            # fast path only: both operands one limb (all our programs)
            slow = "__trap_unimp"
            done, dz = self.L("divd"), self.L("divz")
            self.e(f"or t4, {self.A[1]}, {self.A[2]}",
                   f"or t4, t4, {self.A[3]}",
                   f"or t4, t4, {self.B[1]}", f"or t4, t4, {self.B[2]}",
                   f"or t4, t4, {self.B[3]}", f"bnez t4, {slow}",
                   f"beqz {self.B[0]}, {dz}",
                   (f"divu t6, {self.A[0]}, {self.B[0]}" if op == 0x04 else
                    f"remu t6, {self.A[0]}, {self.B[0]}"),
                   f"j {done}", f"{dz}:", "li t6, 0", f"{done}:")
            self.store_bit(at - 2, "t6")
        elif op == 0x10:
            self.cmp_ladder(at, signed=False, swap=False)
        elif op == 0x11:
            self.cmp_ladder(at, signed=False, swap=True)
        elif op == 0x12:
            self.cmp_ladder(at, signed=True, swap=False)
        elif op == 0x13:
            self.cmp_ladder(at, signed=True, swap=True)
        elif op == 0x14:
            self.e(f"xor t4, {self.A[0]}, {self.B[0]}")
            for limb in range(1, 4):
                self.e(f"xor t6, {self.A[limb]}, {self.B[limb]}",
                       "or t4, t4, t6")
            self.e("seqz t4, t4")
            self.store_bit(at - 2, "t4")
        else:                            # AND OR XOR
            sym = {0x16: "and", 0x17: "or", 0x18: "xor"}[op]
            for limb in range(4):
                self.e(f"{sym} {self.B[limb]}, {self.A[limb]}, "
                       f"{self.B[limb]}")
            self.store_slot(at - 2, self.B)

    def routines(self):
        # __mul256: t4 = &a (top), t5 = &b and result.  256x256 -> low 256.
        self.label("__mul256")
        self.e("addi sp, sp, -8", "sd t5, 0(sp)")
        for limb in range(4):
            self.e(f"ld a{limb}, {8 * limb}(t4)",
                   f"ld a{4 + limb}, {8 * limb}(t5)")
        for limb in range(4):
            self.e(f"li t{limb}, 0")
        # column accumulation with immediate carry propagation
        def addto(col, reg):
            self.e(f"add t{col}, t{col}, {reg}")
            if col < 3:
                self.e(f"sltu t6, t{col}, {reg}")
                addto(col + 1, "t6")
        for i in range(4):
            for j in range(4 - i):
                a, b = f"a{i}", f"a{4 + j}"
                if i + j < 3:
                    self.e(f"mulhu t5, {a}, {b}")
                self.e(f"mul t4, {a}, {b}")
                addto(i + j, "t4")
                if i + j < 3:
                    addto(i + j + 1, "t5")
        self.e("ld t5, 0(sp)", "addi sp, sp, 8")
        for limb in range(4):
            self.e(f"sd t{limb}, {8 * limb}(t5)")
        self.e("ret")

        # __cdload256: t4 = &index slot, result written back to it.
        self.label("__cdload256")
        self.e("addi sp, sp, -16", "sd s3, 0(sp)", "sd s4, 8(sp)",
               "ld t0, 8(t4)", "ld t6, 16(t4)", "or t0, t0, t6",
               "ld t6, 24(t4)", "or t0, t0, t6",
               "ld t5, 0(t4)",              # index
               "la s3, CALLDATA",
               "la t6, CALLDATA_LEN", "ld s4, 0(t6)")
        far = self.L("far")
        self.e(f"bnez t0, {far}")
        for limb in (3, 2, 1, 0):
            self.e("li t0, 0")
            for b in range(8):
                self.e("slli t0, t0, 8",
                       f"addi t6, t5, {8 * (3 - limb) + b}",
                       "bgeu t6, s4, 1f",
                       "add t6, s3, t6", "lbu t6, 0(t6)", "or t0, t0, t6",
                       "1:")
            self.e(f"sd t0, {8 * limb}(t4)")
        out = self.L("cdout")
        self.e(f"j {out}", f"{far}:")
        for limb in range(4):
            self.e(f"sd zero, {8 * limb}(t4)")
        self.e(f"{out}:", "ld s3, 0(sp)", "ld s4, 8(sp)",
               "addi sp, sp, 16", "ret")

        # __mstore256: t4 = offset (bounded by caller check to one limb),
        # t5 = &value.  Big-endian bytes into MEM.
        self.label("__mstore256")
        self.e(f"li t6, {(1 << 20) - 32}", "bgtu t4, t6, __trap_mem",
               "la t6, MEM", "add t4, t6, t4")
        for limb in (3, 2, 1, 0):
            self.e(f"ld t6, {8 * limb}(t5)")
            base = 8 * (3 - limb)
            for b in range(8):
                self.e(f"srli t0, t6, {8 * (7 - b)}",
                       f"sb t0, {base + b}(t4)")
        self.e("ret")
