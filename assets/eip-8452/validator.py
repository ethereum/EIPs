"""EIP-8337's reference validator, extended with JUMPV and CALLSUBV.

The validator is EIP-8337's, line for line, except where a table
instruction appears.  Like a JUMP or a CALLSUB, a JUMPV or CALLSUBV
must be immediately preceded by a PUSH: its immediate value is the
position of the table, read here from the code.  The table must lie
within the code.  A JUMPV's destinations are its successors, each
required to be a JUMPDEST or CALLDEST, and it does not fall through; a
CALLSUBV's destinations are each required to be a CALLDEST, each is
entered as a call, and the instruction after the CALLSUBV is the
return point of every one of them -- so Constraint 4, one stack offset
per instruction, requires every destination to have the same net
stack effect.  A table is named by exactly one instruction, so its
entries are edges paid for by its own bytes, at most one per two,
and validation stays linear within EIP-8337's measured worst case.
The sequential scan is unchanged: the instructions carry no immediate
data, and a table is ordinary bytes placed, like any data, where
execution does not reach them.

validate(code, start) validates the code from position `start`: the
first byte after the MAGIC header, or 0 for a headerless test vector.
Positions count from the first byte of `code` either way.

Opcodes: CALLDEST=0xBB, CALLSUB=0xBC, CALLSUBV=0xBD, JUMPV=0xBE,
RETURNSUB=0xBF.
"""
from collections import defaultdict, deque

from opcodes import (JUMP, JUMPI, JUMPDEST, CALLSUB, CALLDEST, RETURNSUB,
                     CALLSUBV, JUMPV, PUSH0, PUSH32, opcode_info,
                     push_value, table)

STACK_LIMIT = 1024
OUTER = None          # stands for the entry of top-level code
LABEL = "label"       # destination must be a JUMPDEST or a CALLDEST
ENTRY = "calldest"    # destination must be a CALLDEST


def validate(code, start=0, stack_limit=STACK_LIMIT):
    """True iff the code from `start` satisfies the five constraints of
    EIP-8337 validation, with this EIP's tables: valid opcodes, proven
    destinations, one static stack offset per instruction, framed
    returns, and no underflow."""
    if len(code) <= start:
        return False

    # JUMPDEST analysis: the sequential scan that every client runs
    # today.  Its instructions are the only bytes that may be executed
    # or jumped to; PUSH immediate data never qualifies, whatever its
    # values (Constraints 2 and 3).
    instructions = set()
    i = start
    while i < len(code):
        instructions.add(i)
        i += 1 + (code[i] - PUSH0 if PUSH0 < code[i] <= PUSH32 else 0)

    visited = {}                  # pc -> (offset, entry) at first visit
    required = {}                 # pc -> LABEL or ENTRY, set by jumps and calls
    net_effect = {}               # entry -> its *net stack effect*, once known
    inputs = defaultdict(int)     # entry -> its demand: the items it needs from its caller
    parents = defaultdict(list)   # child -> [(parent, offset)]
    enter_parents = defaultdict(list)  # entry -> [(parent, offset)]
    pending = defaultdict(list)   # entry -> return points waiting on its net
    jump_children = defaultdict(list)  # entry -> entries it jumps or falls into
    returning = set()             # entries that contain a RETURNSUB
    owner = {}                    # table position -> the one instruction naming it
    work_items = [(start, 0, OUTER, None)]

    def resolve(entry, value):
        """Record an entry's net: release the return points waiting on
        it, and settle the entries that jump or fall into it, whose
        nets follow from this one.  False on a conflict."""
        settle = [(entry, value)]
        while settle:
            e, v = settle.pop()
            if e in net_effect:
                if net_effect[e] != v:
                    return False  # Constraint 4: one net per entry
                continue
            net_effect[e] = v
            for ret_pc, offset, caller in pending.pop(e, ()):
                work_items.append((ret_pc, offset + v, caller, None))
            for parent, d in enter_parents[e]:
                settle.append((parent, d + v))
        return True

    def call(dest, offset, entry, ret_pc):
        """A call to dest from entry, returning to ret_pc: the callee is
        entered at offset 0, and the return point waits on its net."""
        if dest >= len(code):
            return False
        if dest in visited and code[dest] != CALLDEST:
            return False
        required[dest] = ENTRY       # a jump's LABEL upgrades to ENTRY
        parents[dest].append((entry, offset))
        work_items.append((dest, 0, dest, None))
        if dest in net_effect:
            # Return point: call-site offset plus the callee's net.
            work_items.append((ret_pc, offset + net_effect[dest], entry, None))
        else:
            pending[dest].append((ret_pc, offset, entry))
        return True

    def jump(dest, offset, entry):
        """A jump to dest: a successor at the same offset."""
        if dest >= len(code):
            return False
        if dest in visited and code[dest] not in (JUMPDEST, CALLDEST):
            return False
        required.setdefault(dest, LABEL)
        work_items.append((dest, offset, entry, None))
        return True

    while work_items:
        pc, offset, entry, push = work_items.pop()
        if pc >= len(code):
            continue                     # implicit STOP: a valid end
        if pc not in instructions:
            return False                 # Constraints 2, 3: immediate data
        op = code[pc]
        size, pops, pushes, term = opcode_info(op)
        if size == 0:
            return False                 # Constraint 1: not a valid opcode

        # A CALLDEST is visited at offset 0, as its own entry; arriving
        # any other way first records the link between the subroutines.
        if op == CALLDEST and (entry != pc or offset != 0):
            parents[pc].append((entry, offset))
            jump_children[entry].append(pc)
            if pc in net_effect:      # settled: the arriving net follows
                if not resolve(entry, offset + net_effect[pc]):
                    return False
            else:                     # each record is consumed exactly once
                enter_parents[pc].append((entry, offset))
            offset, entry = 0, pc

        if pc in visited:
            # Constraint 4: paths must agree.
            if visited[pc] != (offset, entry):
                return False
            continue
        visited[pc] = (offset, entry)

        # Constraints 2 and 3: a required destination type, if any.
        if required.get(pc) == LABEL and op not in (JUMPDEST, CALLDEST):
            return False
        if required.get(pc) == ENTRY and op != CALLDEST:
            return False

        # Constraint 5: items used from below the subroutine's start.
        need = pops - offset
        if need > inputs[entry]:
            if need > stack_limit:
                return False
            inputs[entry] = need
        offset += pushes - pops
        nxt = pc + size

        if op in (JUMPV, CALLSUBV):
            if push is None:
                return False             # Constraints 2, 3: PUSH before the table instruction
            dests = table(code, push)
            if dests is None:
                return False             # the table must lie within the code
            if owner.setdefault(push, pc) != pc:
                return False             # a table is named by one instruction only
            for dest in dests:
                if op == JUMPV:          # every destination is a successor
                    if not jump(dest, offset, entry):
                        return False
                elif not call(dest, offset, entry, nxt):   # every one is called,
                    return False         # all returning to nxt, at one offset
        elif op == CALLSUB:
            if push is None:
                return False             # Constraint 3: PUSH before CALLSUB
            if not call(push, offset, entry, nxt):
                return False
        elif op == RETURNSUB:
            returning.add(entry)
            if not resolve(entry, offset):
                return False
        elif op in (JUMP, JUMPI):
            if push is None:
                return False             # Constraint 2: PUSH before JUMP/JUMPI
            if not jump(push, offset, entry):
                return False
            if op == JUMPI:              # and the fall-through arm
                work_items.append((nxt, offset, entry, None))
        elif not term:                   # everything else falls through
            value = push_value(code, pc) if PUSH0 <= op <= PUSH32 else None
            work_items.append((nxt, offset, entry, value))

    # Constraint 5, framing: the top level is unframed, and so is every
    # entry that an unframed entry jumps or falls into; no unframed entry
    # may contain a RETURNSUB.
    unframed = {OUTER}
    work = [OUTER]
    while work:
        for e in jump_children[work.pop()]:
            if e not in unframed:
                unframed.add(e)
                work.append(e)
    if unframed & returning:
        return False

    # The demand checking: a subroutine's demand for caller items, less the
    # depth already on the stack at the entrance, becomes its parent's
    # demand.  Demands only rise and the limit caps them, so this ends.
    queue = deque(e for e in inputs if inputs[e])
    queued = set(queue)
    while queue:
        e = queue.popleft()
        queued.discard(e)
        for parent, d in parents[e]:
            need = inputs[e] - d
            if need > inputs[parent]:
                if need > stack_limit:
                    return False
                inputs[parent] = need
                if parent not in queued:
                    queue.append(parent)
                    queued.add(parent)

    # Top-level code has no caller to take items from.
    return inputs[OUTER] == 0
