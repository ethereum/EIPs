"""Bounds-proving validator for EIP-8337 MAGIC code.

This is the validator that proves stack bounds as well as control
flow.  It is kept for comparison — see "Why not prove
overflow?" in the validation EIP.  Its opcode table lives in
opcodes.py, shared with the reference validator, validator.py.

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

from opcodes import (JUMP, JUMPI, JUMPDEST, CALLSUB, CALLDEST, RETURNSUB,
                     PUSH0, PUSH32, opcode_info, push_value)

STACK_LIMIT = 1024
OUTER = None          # stands for the entry of top-level code
LABEL = "label"       # destination must be a JUMPDEST or a CALLDEST
ENTRY = "calldest"    # destination must be a CALLDEST


@dataclass
class StackUse:
    """How one subroutine uses the two stacks.  net is None until a
    frame begun at its entry first returns."""
    net: int | None = None    # items pushed minus popped, entry to the frame's return
    inputs: int = 0           # its demand: items used from the caller's stack
    growth: int = 0           # stack growth above the subroutine's start
    call_depth: int = 0       # return addresses outstanding at once


def validate(code, stack_limit=STACK_LIMIT):
    """True iff the code satisfies the five constraints of EIP-8337."""
    if len(code) == 0:
        return False

    # JUMPDEST analysis: the sequential scan from position 0 that every
    # client runs today.  Its instructions are the only bytes that may
    # be executed or jumped to; PUSH immediate data never qualifies,
    # whatever its values (Constraints 2 and 3).
    instructions = set()
    i = 0
    while i < len(code):
        instructions.add(i)
        i += 1 + (code[i] - PUSH0 if PUSH0 < code[i] <= PUSH32 else 0)

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
        if pc not in instructions:
            return False                 # Constraints 2, 3: immediate data
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
