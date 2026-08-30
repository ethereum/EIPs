"""Reference validator for EIP-8337 MAGIC code.

This validator proves control flow and stack underflow: every
destination is a proper label, every subroutine entry is a CALLDEST,
every RETURNSUB has a CALLSUB to return to, every instruction is
reached at one static stack offset, and no instruction can find fewer
stack items than it removes.  It does not prove overflow, which
cannot be decided in the presence of recursion: the stacks keep the
runtime bounds checks that all code has today.  The validator that
additionally proves overflow for non-recursive code is kept for
comparison in magic_validator.py.

The traversal visits each reachable instruction once, measuring the
data stack relative to the CALLDEST where the current subroutine
began: return points wait on their callee's net stack effect, and a
jump or fall into a CALLDEST links the two subroutines' nets.  The
combining then propagates each subroutine's demand for caller items
to everyone who calls, or jumps or falls into, it.  Demands only
rise, by whole items, and the stack limit caps them, so the worst
case is O(1024 * n) — linear in the code, since 1024 is the
protocol's constant, and approached only by invalid code built to
pump demands around a recursive cycle (see cbench/ for the measured
costs).

Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
from collections import defaultdict, deque

from magic_validator import opcode_info, push_value

JUMP, JUMPI, JUMPDEST = 0x56, 0x57, 0x5B
CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
PUSH0, PUSH32 = 0x5F, 0x7F

STACK_LIMIT = 1024
OUTER = None          # stands for the entry of top-level code
LABEL = "label"       # destination must be a JUMPDEST or a CALLDEST
ENTRY = "calldest"    # destination must be a CALLDEST


def validate(code, stack_limit=STACK_LIMIT):
    """True iff the code satisfies the five constraints of EIP-8337
    validation: valid opcodes, proven destinations, framed returns,
    no underflow, and one static stack offset per instruction."""
    if len(code) == 0:
        return False

    visited = {}                  # pc -> (offset, entry, framed) at first visit
    required = {}                 # pc -> LABEL or ENTRY, set by jumps and calls
    net_effect = {}               # entry -> its *net stack effect*, once known
    inputs = defaultdict(int)     # entry -> items it needs from its caller
    # Two parent lists with different lifetimes.  parents is permanent
    # and complete — every call and enter — for propagating demands in
    # the combining.  enter_parents holds only arrivals whose entry's
    # net is still unknown; each record is consumed exactly once, when
    # that net is first set.
    parents = defaultdict(list)   # child -> [(parent, offset)]
    enter_parents = defaultdict(list)  # entry -> [(parent, offset)]
    pending = defaultdict(list)   # entry -> return points waiting on its net
    work_items = [(0, 0, OUTER, False, None)]

    def resolve(entry, value):
        """Record an entry's net: release the return points waiting on
        it, and settle the entries that jump or fall into it, whose
        nets follow from this one.  False on a conflict."""
        settle = [(entry, value)]
        while settle:
            e, v = settle.pop()
            if e in net_effect:
                if net_effect[e] != v:
                    return False  # Constraint 5: one net per entry
                continue
            net_effect[e] = v
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
            parents[pc].append((entry, offset))
            if pc in net_effect:      # settled: the arriving net follows
                if not resolve(entry, offset + net_effect[pc]):
                    return False
            else:                     # each record is walked exactly once
                enter_parents[pc].append((entry, offset))
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

        # Constraint 4: items used from below the subroutine's start.
        need = pops - offset
        if need > inputs[entry]:
            if need > stack_limit:
                return False
            inputs[entry] = need
        offset += pushes - pops
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
            parents[dest].append((entry, offset))
            work_items.append((dest, 0, dest, True, None))
            if dest in net_effect:
                # Return point: call-site offset plus the callee's net.
                work_items.append((nxt, offset + net_effect[dest], entry, framed, None))
            else:
                pending[dest].append((nxt, offset, entry, framed))
        elif op == RETURNSUB:
            if not framed:
                return False             # no CALLSUB to return from
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

    # The combining: a subroutine's demand for caller items, less the
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
