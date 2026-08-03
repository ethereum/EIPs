"""Bounds-proving validator for EIP-8337 MAGIC code.

This is the validator that proves stack bounds as well as control
flow.  It is kept for comparison — see "Why not prove stack bounds?"
in the validation EIP — and as the opcode table used by the reference
validator, minimal_validator.py.

validate(code) returns True exactly when the code satisfies the five
constraints of the bounds-proving draft.  It works in two phases.

Phase 1, the traversal, visits every reachable instruction once, the way
execution would, except that it follows both arms of every JUMPI.
Stack depth is measured relative to the CALLDEST where the current
subroutine began, so a subroutine is checked once, no matter how many
call sites invoke it or how deep their stacks are when they do.  Along
the way each subroutine is reduced to its stack use, a StackUse
record of four numbers:

    net         how a frame begun at the entry leaves the stack:
                items pushed minus popped, entry to the frame's return
    inputs      how many items it uses from its caller's stack
    growth      how far it grows the stack above its own start
    call_depth  how many return addresses it can have outstanding

Phase 2, the combining, folds each subroutine's stack use into everyone
who calls — or jumps or falls into — it: a caller inherits its
callee's stack use, shifted by the stack depth at the call site.  In the
end, top-level code must need no caller items at all, and — when there
is no recursion — everything must fit the 1024-item stack limits.

The instruction after a CALLSUB is reached when the frame begun at
the callee returns, at a depth set by the callee's net.  Return
points therefore wait on a pending list until that net is first fixed
— by a RETURNSUB reached from the callee's entry, in whatever
subroutine it lies.  If a callee never returns, its return points are
never visited.  That is correct: they are unreachable.

Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
from collections import defaultdict, deque
from dataclasses import dataclass

JUMP, JUMPI, JUMPDEST = 0x56, 0x57, 0x5B
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
PUSH0, PUSH32 = 0x5F, 0x7F

STACK_LIMIT = 1024
OUTER = None          # stands for the entry of top-level code
LABEL = "label"       # destination must be a JUMPDEST or a CALLDEST
ENTRY = "calldest"    # destination must be a CALLDEST


@dataclass
class StackUse:
    """How one subroutine uses the two stacks.  net is None until a
    frame begun at its entry first returns."""
    net: int | None = None    # items pushed minus popped, entry to the frame's return
    inputs: int = 0           # items used from the caller's stack
    growth: int = 0           # stack growth above the subroutine's start
    call_depth: int = 0       # return addresses outstanding at once


def validate(code, stack_limit=STACK_LIMIT):
    """True iff the code satisfies the five constraints of EIP-8337."""
    if len(code) == 0:
        return False

    # ------------------------------------------------------------------
    # Phase 1, the traversal: visit every reachable instruction once.
    # A work item is (pc, offset from the subroutine's start, entry —
    # the CALLDEST pc or OUTER, framed — an unreturned CALLSUB on the
    # path, and the value of the immediately preceding PUSH, or None).
    # ------------------------------------------------------------------
    visited = {}                  # pc -> (offset, entry, framed) at first visit
    required = {}                 # pc -> LABEL or ENTRY, set by jumps and calls
    stack_use = defaultdict(StackUse)  # entry -> that subroutine's use
    edges = []                    # (parent, offset, child, is_call): parent
                                  # calls, or jumps or falls into, child
    enter_parents = defaultdict(list)  # entry -> [(parent, offset)] for
                                  # the arrivals that were not calls
    pending = defaultdict(list)   # entry -> return points waiting on its
                                  # net
    work_items = [(0, 0, OUTER, False, None)]

    def resolve(entry, value):
        """Record an entry's net: release the return points waiting on
        it, and settle the entries that jump or fall into it, whose
        nets follow from this one.  False on a conflict."""
        settle = [(entry, value)]
        while settle:
            e, v = settle.pop()
            if stack_use[e].net is not None:
                if stack_use[e].net != v:
                    return False  # Constraint 5: one net per entry
                continue
            stack_use[e].net = v
            for ret_pc, offset, caller, framed in pending.pop(e, ()):
                work_items.append((ret_pc, offset + v, caller, framed, None))
            for parent, d in enter_parents[e]:
                settle.append((parent, d + v))
        return True

    while work_items:
        pc, offset, entry, framed, push = work_items.pop()
        if pc >= len(code):
            continue                     # implicit STOP: a valid end
        op = code[pc]
        size, pops, pushes, term = opcode_info(op)
        if size == 0:
            return False                 # Constraint 1: not a valid opcode

        # A CALLDEST is visited at offset 0, as its own entry; arriving
        # any other way first records the link between the subroutines.
        if op == CALLDEST and (entry != pc or offset != 0):
            enter_parents[pc].append((entry, offset))
            edges.append((entry, offset, pc, False))
            if stack_use[pc].net is not None and not resolve(entry, offset + stack_use[pc].net):
                return False
            offset, entry = 0, pc

        if pc in visited:
            # Constraint 5: paths must agree.
            if visited[pc] != (offset, entry, framed):
                return False
            continue
        visited[pc] = (offset, entry, framed)

        # Constraints 2 and 3: a required destination type, if any.
        if required.get(pc) == LABEL and op not in (JUMPDEST, CALLDEST):
            return False
        if required.get(pc) == ENTRY and op != CALLDEST:
            return False

        # Constraint 4: items used below the start; growth above it.
        u = stack_use[entry]
        u.inputs = max(u.inputs, pops - offset)
        if u.inputs > stack_limit:
            return False
        offset += pushes - pops
        u.growth = max(u.growth, offset)
        nxt = pc + size

        if op == CALLSUB:
            if push is None:
                return False             # Constraint 3: PUSH before CALLSUB
            dest = push
            if dest >= len(code):
                return False
            if dest in visited and code[dest] != CALLDEST:
                return False
            required[dest] = ENTRY       # a jump's LABEL upgrades to ENTRY
            edges.append((entry, offset, dest, True))
            work_items.append((dest, 0, dest, True, None))
            if stack_use[dest].net is not None:
                # Return point: call-site offset plus the callee's net.
                work_items.append((nxt, offset + stack_use[dest].net, entry, framed, None))
            else:
                pending[dest].append((nxt, offset, entry, framed))
        elif op == RETURNSUB:
            if not framed:
                return False             # Constraint 4: no CALLSUB to return from
            if not resolve(entry, offset):
                return False
        elif op in (JUMP, JUMPI):
            if push is None:
                return False             # Constraint 2: PUSH before JUMP/JUMPI
            dest = push
            if dest >= len(code):
                return False
            if dest in visited and code[dest] not in (JUMPDEST, CALLDEST):
                return False
            required.setdefault(dest, LABEL)
            work_items.append((dest, offset, entry, framed, None))
            if op == JUMPI:              # and the fall-through arm
                work_items.append((nxt, offset, entry, framed, None))
        elif not term:                   # everything else falls through
            value = push_value(code, pc) if PUSH0 <= op <= PUSH32 else None
            work_items.append((nxt, offset, entry, framed, value))

    # ------------------------------------------------------------------
    # Phase 2, the combining: fold each subroutine's stack use into
    # everyone who calls or enters it.
    # ------------------------------------------------------------------
    by_child = defaultdict(list)   # child -> [(parent, offset, is_call)]
    unfinished = defaultdict(int)  # parent -> children not yet processed
    nodes = {OUTER}
    for parent, offset, child, is_call in edges:
        by_child[child].append((parent, offset, is_call))
        unfinished[parent] += 1
        nodes |= {parent, child}

    # Children before parents: without recursion, one exact pass.
    ready = [n for n in nodes if unfinished[n] == 0]
    finished = 0
    while ready:
        node = ready.pop()
        finished += 1
        for parent, offset, is_call in by_child[node]:
            u, p = stack_use[node], stack_use[parent]
            p.inputs = max(p.inputs, u.inputs - offset)
            if p.inputs > stack_limit:
                return False
            p.growth = max(p.growth, offset + u.growth)
            p.call_depth = max(p.call_depth, u.call_depth + is_call)
            unfinished[parent] -= 1
            if unfinished[parent] == 0:
                ready.append(parent)

    if finished == len(nodes):
        # No recursion: reject code that must overflow a stack.
        if stack_use[OUTER].growth > stack_limit or stack_use[OUTER].call_depth > stack_limit:
            return False
    else:
        # Recursion: overflow is left to the runtime checks.  Repeat
        # the inheritance step until no inputs rise; inputs only rise,
        # by whole items, and are capped, so this ends.
        queue, queued = deque(nodes), set(nodes)
        while queue:
            node = queue.popleft()
            queued.discard(node)
            for parent, offset, _ in by_child[node]:
                needed = stack_use[node].inputs - offset
                if needed > stack_use[parent].inputs:
                    if needed > stack_limit:
                        return False
                    stack_use[parent].inputs = needed
                    if parent not in queued:
                        queue.append(parent)
                        queued.add(parent)

    # Top-level code has no caller to take items from.
    return stack_use[OUTER].inputs == 0


# ---------------------------------------------------------------------------
# The opcode table
# ---------------------------------------------------------------------------

def opcode_info(op):
    """Return (size, pops, pushes, is_terminator); size 0 is invalid.
    A terminator cannot fall through to the next instruction."""
    if PUSH0 <= op <= PUSH32:                # PUSH0..PUSH32
        return op - PUSH0 + 1, 0, 1, False
    if 0x80 <= op <= 0x8F:                   # DUP1..DUP16
        n = op - 0x7F
        return 1, n, n + 1, False
    if 0x90 <= op <= 0x9F:                   # SWAP1..SWAP16
        n = op - 0x8F
        return 1, n + 1, n + 1, False
    if 0xA0 <= op <= 0xA4:                   # LOG0..LOG4
        return 1, op - 0xA0 + 2, 0, False
    if op in TABLE:
        pops, pushes, term = TABLE[op]
        return 1, pops, pushes, term
    return 0, 0, 0, False


# (pops, pushes, is_terminator) for the remaining opcodes, current
# through the Prague fork, plus this EIP's three.
TABLE = {
    0x00: (0, 0, True),                                       # STOP
    **{op: (2, 1, False) for op in (                          # binary operations:
        *range(0x01, 0x08), 0x0A, 0x0B,                       #   ADD..SMOD, EXP, SIGNEXTEND
        *range(0x10, 0x15), 0x16, 0x17, 0x18,                 #   LT..EQ, AND, OR, XOR
        *range(0x1A, 0x1E), 0x20)},                           #   BYTE..SAR, KECCAK256
    0x08: (3, 1, False), 0x09: (3, 1, False),                 # ADDMOD, MULMOD
    **{op: (1, 1, False) for op in (                          # unary operations:
        0x15, 0x19, 0x31, 0x35, 0x3B, 0x3F,                   #   ISZERO, NOT, BALANCE, CALLDATALOAD, EXTCODESIZE, EXTCODEHASH
        0x40, 0x49, 0x51, 0x54, 0x5C)},                       #   BLOCKHASH, BLOBHASH, MLOAD, SLOAD, TLOAD
    **{op: (0, 1, False) for op in (                          # push one item:
        0x30, 0x32, 0x33, 0x34, 0x36, 0x38, 0x3A, 0x3D,       #   ADDRESS..RETURNDATASIZE
        *range(0x41, 0x49), 0x4A, 0x58, 0x59, 0x5A)},         #   COINBASE..BASEFEE, BLOBBASEFEE, PC, MSIZE, GAS
    **{op: (3, 0, False) for op in (0x37, 0x39, 0x3E, 0x5E)}, # CALLDATACOPY, CODECOPY, RETURNDATACOPY, MCOPY
    0x3C: (4, 0, False),                                      # EXTCODECOPY
    0x50: (1, 0, False),                                      # POP
    **{op: (2, 0, False) for op in (0x52, 0x53, 0x55, 0x5D)}, # MSTORE, MSTORE8, SSTORE, TSTORE
    JUMP: (1, 0, True), JUMPI: (2, 0, False), JUMPDEST: (0, 0, False),
    CALLSUB: (1, 0, True), CALLDEST: (0, 0, False), RETURNSUB: (0, 0, True),
    0xF0: (3, 1, False), 0xF5: (4, 1, False),                 # CREATE, CREATE2
    0xF1: (7, 1, False), 0xF2: (7, 1, False),                 # CALL, CALLCODE
    0xF4: (6, 1, False), 0xFA: (6, 1, False),                 # DELEGATECALL, STATICCALL
    0xF3: (2, 0, True), 0xFD: (2, 0, True),                   # RETURN, REVERT
    0xFE: (0, 0, True), 0xFF: (1, 0, True),                   # INVALID, SELFDESTRUCT
}


def push_value(code, pc):
    """Immediate value of the PUSH at pc, zero-padded past end of code."""
    n = code[pc] - PUSH0
    return int.from_bytes(code[pc + 1:pc + 1 + n].ljust(n, b"\0"), "big")
