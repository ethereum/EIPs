---
eip: 9999
title: Jump and Call Tables for the EVM
description: JUMPV and CALLSUBV, a multi-way jump and call through a table of destinations in the code
author: Greg Colvin (@gcolvin) <greg@colvin.org>
discussions-to: https://ethereum-magicians.org/t/eip-jump-and-call-tables-for-the-evm/0
status: Draft
type: Standards Track
category: Core
created: 2026-10-20
requires: 7979, 8337
---

## Abstract

Two instructions.  `JUMPV` jumps to one of a table of destinations, chosen by a case on the *data stack*; `CALLSUBV` calls one.  The table is data in the code, and its position is on the stack, so the instructions take no immediate data and behave identically in ordinary and validated code.  In ordinary code they are as dynamic and as checked as `JUMP`; in `MAGIC` code the `PUSH` before them makes the dispatch static, and validation proves every destination before the code is deployed.  They are the multi-way jump and call for which [EIP-7979](./eip-7979.md) reserved `0xBE` and `0xBD`: a switch, a state machine, or a contract's dispatch on its selector becomes one instruction rather than a chain of comparisons.

*Note: Significant assistance from AI is acknowledged, primarily for the reference implementation and its tests.*

## Motivation

Validated code has no computed jumps: [EIP-8337](./eip-8337.md) requires the destination of every jump and call to be a constant in the code, which is what makes its control flow static and its validation linear.  The price is dispatch.  Choosing among *N* destinations by a value takes *N* comparisons and jumps, or a tree of them, where legacy code takes one computed `JUMP` through a table in memory.  Every contract pays this at its entry, dispatching on its selector; interpreters and state machines pay it in their inner loops; and compilers, which lower a `switch` to a jump table on every other machine, cannot here.

A table in the code gives the dispatch back without giving up the proof.  The destinations are constants, so validation checks each of them as it checks any other; a validator or a translator sees every successor of a `JUMPV` and every callee of a `CALLSUBV`, and a `CALLSUBV`'s callees are proven to agree on what they take from the stack and leave on it.  The instruction executes in constant time: a bounds comparison and a table read.

## Specification

> *The key words MUST and MUST NOT in this Specification are to be interpreted as described in RFC 2119 and RFC 8174.*

The *data stack*, the *return stack*, the *PC*, a *return address* and a *subroutine* are as [EIP-7979](./eip-7979.md) defines them; `MAGIC` code, `valid` code, an *instruction*, *reachable*, an *entry*, a *stack offset* and a *net stack effect* are as [EIP-8337](./eip-8337.md) defines them.

A *table* is a *count* byte followed by *count* + 1 *destinations* of two bytes each, big-endian, each a position in the code, counted from its first byte.  A *table* lies anywhere in the code; it is data, and its position is an operand of the instructions below.  The *case* is an item popped from the *data stack*; it chooses *destination* number *case* in the *table*, counting from zero, or the last *destination* when *case* exceeds the *count*.

Neither instruction takes immediate data, so JUMPDEST analysis is unchanged, and both behave identically in ordinary and `MAGIC` code.

### `JUMPV (0xBE)`

Transfers control to one of the *destinations* in a *table*.

1. Pop the position of the *table* from the top of the *data stack*.
2. Pop the *case* from the top of the *data stack*.
3. Set the *PC* to the *destination* the *case* chooses.

If the *table* does not lie within the code, or the *destination* is not a `JUMPDEST` or a `CALLDEST`, execution is in an exceptional halting state.  Jumping to a `CALLDEST` enters the *subroutine* without pushing a *return address*, as `JUMP` does.

The gas cost is *high* (10).

### `CALLSUBV (0xBD)`

Transfers control to one of the *subroutines* whose entries are in a *table*.

1. Pop the position of the *table* from the top of the *data stack*.
2. Pop the *case* from the top of the *data stack*.
3. Push the *return address*, *PC* + 1, to the *return stack*.
4. Set the *PC* to the *destination* the *case* chooses.

If the *table* does not lie within the code, or the *destination* is not a `CALLDEST`, or the *return stack* already holds 1024 items, execution is in an exceptional halting state.

The gas cost is *high* (10).

### Validation

The validation rules of the fork that adopts this EIP extend the constraints of [EIP-8337](./eip-8337.md) to the two instructions, as Constraints 2 and 3 cover `JUMP`, `JUMPI` and `CALLSUB`:

* Every *reachable* `JUMPV` and `CALLSUBV` MUST be immediately preceded by a `PUSH`, whose immediate value is the position of its *table*.
* The *table* MUST lie within the code, and MUST be named by exactly one *instruction*.
* Every *destination* in the *table* of a `JUMPV` MUST be a `JUMPDEST` or a `CALLDEST` *instruction*.  Every *destination* in the *table* of a `CALLSUBV` MUST be a `CALLDEST` *instruction*.  Immediate data is not an *instruction*.
* Each *destination* of a `JUMPV` is a successor of the `JUMPV`, reached at the *stack offset* the `JUMPV` leaves; a `JUMPV` does not fall through.  Each *destination* of a `CALLSUBV` is entered as the *destination* of a `CALLSUB` is, and the *instruction* after the `CALLSUBV` is the return point of every one of them.

Nothing else changes.  In particular, Constraint 4 — one *stack offset* per *instruction* — already requires every *destination* of a `CALLSUBV` to have the same *net stack effect*, since all of them return to one *instruction*; and the sequential scan is the one clients run today, since a *table* is data and not immediate data.

### Costs

*high* (10), the tier of `JUMPI`, for both.  The work is a bounds comparison, a two-byte read from the code, and the destination check `JUMP` makes; `CALLSUBV` adds the push that `CALLSUB` makes.  Benchmarking will be needed to tell if the costs are well-balanced.

## Rationale

### Why is the *table* in the code and its position on the stack?

For the reason [EIP-7979](./eip-7979.md) gave for taking no immediate arguments: backwards compatibility.  An instruction with immediate data changes JUMPDEST analysis, and so changes the meaning of any deployed contract whose bytes happen to contain the new opcode, which is the problem the static relative jumps of [EIP-8013](./eip-8013.md) could not solve outside a container.  A *table* that is data, reached through a position on the stack, changes nothing: the scan is the one clients run today, the instructions are one byte, and a deployed contract that reaches `0xBD` or `0xBE` halts today, as it always did.

The position on the stack is also what makes the dispatch static where it matters.  Constraint 2 of [EIP-8337](./eip-8337.md) requires the `PUSH` immediately before a `JUMP`; the same requirement before a `JUMPV` lets validation read the *table* from the code and prove every *destination*.  In ordinary code the position may be computed, and the instruction is then a dynamic jump with the destination check `JUMP` has.  One `PUSH`, three bytes and three gas, is the cost over an immediate.

### Why is the last *destination* the default?

The `switch` of C has an explicit `default`, and in its successors there is no fall-through between cases; the default is a case the program names.  Here it is the last *destination* in the *table*, and a *case* the *table* does not name takes it, so something is always jumped to or called.  The `RJUMPV` of [EIP-8013](./eip-8013.md) fell through instead, with the default as the code after the instruction.  For a `JUMPV` that would validate; for a `CALLSUBV` it would not, since a path that skipped the call would reach the return point without the callee's *net stack effect*, which Constraint 4 allows only when every callee's net is zero.  One rule for both instructions, and the default costs two bytes rather than a bounds check.

### Why absolute *destinations*?

Because every destination in [EIP-7979](./eip-7979.md) and [EIP-8337](./eip-8337.md) is a position in the code, and a *table* is read by the same validator and the same translators.  [EIP-8013](./eip-8013.md) chose relative offsets for relocatability.  Validated code is relocatable by construction: every destination it contains is the immediate of a `PUSH` or an entry of a *table*, and a linker can find and rewrite all of them.

### Why a *count* of up to 256?

One byte.  A contract's selectors seldom exceed it, and a larger switch is two instructions, a `JUMPV` that selects among `JUMPV`s.  A *destination* is two bytes because code is at most 24576 bytes.

### Where does a *table* go?

Where compilers put data today: after the last *instruction*.  A *table* is scanned like any other bytes, and a *destination* whose byte lies in `0x60`–`0x7F` reads to the scan as a `PUSH`, which would hide up to 32 following bytes from JUMPDEST analysis.  Placed after the last *instruction*, a *table* can hide nothing but other *tables*, which are read by position, not through the scan.  In `MAGIC` code a hidden *destination* fails validation in any case.

### Why may a *table* be named by one *instruction* only?

To keep validation priced.  At run time a `JUMPV` reads one entry whatever the size of its *table*; validation reads them all, since each is an edge of the control-flow graph, and every `JUMPV` naming the *table* would add its edges again.  A *table* of 256 entries is 513 bytes, and a `JUMPV` with its `PUSH` and a case is five: shared, one *table* could cost fifty edges per byte of code, of the order of the worst case [EIP-8337](./eip-8337.md) measured and priced.  Named once, a *table*'s edges are paid for by its own bytes, at most one per two, and the worst case stays what it was.  Nothing is lost: a compiler emits a *table* per switch, and two switches with the same *destinations* in the same order do not occur.  Ordinary code is unaffected, since it is not validated, and the run-time cost is constant either way.

### Why these two and no more?

A multi-way jump and a multi-way call are the two transfers of control that [EIP-7979](./eip-7979.md) left to dynamic jumps: `JUMPI` already chooses between two static destinations, and `CALLSUB` and `RETURNSUB` already call and return.  The five instructions now fill `0xBB` to `0xBF` as one block.

## Backwards Compatibility

`0xBD` and `0xBE` are undefined today: executing either halts exceptionally and consumes all gas, and code that does so was always broken.  [EIP-7979](./eip-7979.md) reserved both values for these instructions.  Neither takes immediate data, so JUMPDEST analysis is unchanged and no deployed contract's destinations change.

## Test Cases

*Note: the bytecode strings in these tests use the opcode values `0xBB`=`CALLDEST`, `0xBC`=`CALLSUB`, `0xBD`=`CALLSUBV`, `0xBE`=`JUMPV`, `0xBF`=`RETURNSUB`.  The Stack and RStack columns show the stacks before the instruction executes.  Every program that runs to completion is also `valid`; the two that halt are not.*

### Execution

#### JUMPV: case 1 of three

Bytecode: `0x60016011BE5B60AA005B60BB005B60CC000200050009000D`

|  PC   |      Op       | Cost |   Stack   |   RStack  |
|-------|---------------|------|-----------|-----------|
|    0  |         PUSH1 |    3 |        [] |        [] |
|    2  |         PUSH1 |    3 |       [1] |        [] |
|    4  |         JUMPV |   10 |    [1,17] |        [] |
|    9  |      JUMPDEST |    1 |        [] |        [] |
|   10  |         PUSH1 |    3 |        [] |        [] |
|   12  |          STOP |    0 |     [187] |        [] |

Consumed gas: `20`

#### JUMPV: a case beyond the count takes the last entry

Bytecode: `0x60076011BE5B60AA005B60BB005B60CC000200050009000D`

|  PC   |      Op       | Cost |   Stack   |   RStack  |
|-------|---------------|------|-----------|-----------|
|    0  |         PUSH1 |    3 |        [] |        [] |
|    2  |         PUSH1 |    3 |       [7] |        [] |
|    4  |         JUMPV |   10 |    [7,17] |        [] |
|   13  |      JUMPDEST |    1 |        [] |        [] |
|   14  |         PUSH1 |    3 |        [] |        [] |
|   16  |          STOP |    0 |     [204] |        [] |

Consumed gas: `20`

#### CALLSUBV: case 0 of two, returning to the instruction after the CALLSUBV

Bytecode: `0x6000600EBD00BB6001BFBB6002BF010006000A`

|  PC   |      Op       | Cost |   Stack   |   RStack  |
|-------|---------------|------|-----------|-----------|
|    0  |         PUSH1 |    3 |        [] |        [] |
|    2  |         PUSH1 |    3 |       [0] |        [] |
|    4  |      CALLSUBV |   10 |    [0,14] |        [] |
|    6  |      CALLDEST |    1 |        [] |       [5] |
|    7  |         PUSH1 |    3 |        [] |       [5] |
|    9  |     RETURNSUB |    5 |       [1] |       [5] |
|    5  |          STOP |    0 |       [1] |        [] |

Consumed gas: `25`

#### JUMPV: the entry is not a JUMPDEST

Bytecode: `0x60006006BE00000005`

|  PC   |      Op       | Cost |   Stack   |   RStack  |
|-------|---------------|------|-----------|-----------|
|    0  |         PUSH1 |    3 |        [] |        [] |
|    2  |         PUSH1 |    3 |       [0] |        [] |
|    4  |         JUMPV |   10 |     [0,6] |        [] |

Error: at PC=4, JUMPV: bad jump destination

#### JUMPV: the table lies outside the code

Bytecode: `0x600060FFBE00`

|  PC   |      Op       | Cost |   Stack   |   RStack  |
|-------|---------------|------|-----------|-----------|
|    0  |         PUSH1 |    3 |        [] |        [] |
|    2  |         PUSH1 |    3 |       [0] |        [] |
|    4  |         JUMPV |   10 |   [0,255] |        [] |

Error: at PC=4, JUMPV: table outside code

### Validation

*The following bytecodes exercise the validator; they carry no header, like [EIP-8337](./eip-8337.md)'s, and are run by `test_tables.py` with `STACK_LIMIT` reduced to 16.  EIP-7979's five runtime test cases validate unchanged under the extended validator.*

| Test | Bytecode | Valid |
|------|----------|-------|
| JUMPV to two JUMPDESTs | `0x60006009BE5B005B000100050007` | yes |
| JUMPV to a CALLDEST | `0x60006009BE5B00BB000100050007` | yes |
| JUMPV, arms agree | `0x60006011BE5B6001600E565B60025B5000010005000B` | yes |
| JUMPV, arms disagree | `0x6000600EBE5B6001600C565B5B00010005000B` | no |
| JUMPV not preceded by PUSH | `0x6000600835BE5B00000006` | no |
| JUMPV to a non-label | `0x60006006BE00000005` | no |
| JUMPV into PUSH data | `0x60006008BE605B00000007` | no |
| JUMPV into its own table | `0x60006006BE00000006` | no |
| JUMPV destination outside code | `0x60006006BE000000FF` | no |
| JUMPV table outside code | `0x600060FFBE00` | no |
| JUMPV table truncated | `0x60006007BE5B00010005` | no |
| JUMPV with one item on the stack | `0x6005BE5B00000003` | no |
| JUMPV does not fall through | `0x60006008BE015B00000006` | yes |
| CALLSUBV to two subroutines | `0x6000600FBD5000BB6001BFBB6002BF010007000B` | yes |
| CALLSUBV, nets differ | `0x6000600DBD5000BB6001BFBBBF010007000B` | no |
| CALLSUBV to a JUMPDEST | `0x60006008BD005BBF000006` | no |
| CALLSUBV, one destination not a CALLDEST | `0x6000600ABD00BBBF5BBF0100060008` | no |
| CALLSUBV not preceded by PUSH | `0x6000600935BD00BBBF000007` | no |
| CALLSUBV subroutine consumes a caller item | `0x60076000600BBD00BB50BF000008` | yes |
| CALLSUBV subroutine underflows | `0x60006009BD00BB50BF000006` | no |
| CALLSUBV recursion | `0x6000600DBD00BB60006010BDBF000006000006` | yes |
| two instructions name one table | `0x6000600DBE5B6001600DBE5B00010005000B` | no |
| CALLSUBV, 256 destinations | 256 calls of one subroutine, in `test_tables.py` | yes |

## Reference Implementation

Three files accompany this EIP.  `validator.py` is [EIP-8337](./eip-8337.md)'s reference validator with the two instructions: a `PUSH` before each names the *table*, a `JUMPV`'s *destinations* are its successors, and a `CALLSUBV`'s are called with one shared return point.  `machine.py` is [EIP-7979](./eip-7979.md)'s interpreter with the two instructions.  `test_tables.py` runs the vectors above and generates the tables.

Against the Ethereum Execution Layer Specifications (EELS), following its conventions:

```python
class GasCosts:
    ...
    OPCODE_JUMPV: Final[ExecutionGas] = HIGH
    OPCODE_CALLSUBV: Final[ExecutionGas] = HIGH

class TableOutOfBoundsError(ExceptionalHalt):
    """Raised when a table does not lie within the code."""

def table_destination(evm: Evm, at: U256, case: U256) -> Uint:
    """The destination the case chooses in the table at `at`: entry
    number case, or the last entry when case exceeds the count."""
    if at >= ulen(evm.code):
        raise TableOutOfBoundsError
    count = Uint(evm.code[at])
    end = Uint(at) + Uint(3) + Uint(2) * count
    if end > ulen(evm.code):
        raise TableOutOfBoundsError
    entry = min(Uint(case), count)
    start = Uint(at) + Uint(1) + Uint(2) * entry
    return Uint.from_be_bytes(evm.code[start : start + Uint(2)])

def jumpv(evm: Evm) -> None:
    # STACK
    at = pop(evm.stack)
    case = pop(evm.stack)
    # GAS
    charge_gas(evm, GasCosts.OPCODE_JUMPV)
    # OPERATION
    destination = table_destination(evm, at, case)
    if destination not in evm.valid_jump_destinations:
        raise InvalidJumpDestError
    # PROGRAM COUNTER
    evm.pc = destination

def callsubv(evm: Evm) -> None:
    # STACK
    at = pop(evm.stack)
    case = pop(evm.stack)
    # GAS
    charge_gas(evm, GasCosts.OPCODE_CALLSUBV)
    # OPERATION
    destination = table_destination(evm, at, case)
    if destination not in evm.valid_call_destinations:
        raise InvalidJumpDestError
    if ulen(evm.return_stack) >= RETURN_STACK_LIMIT:
        raise ReturnStackOverflowError
    evm.return_stack.append(evm.pc + Uint(1))
    # PROGRAM COUNTER
    evm.pc = destination
```

`get_valid_destinations` needs no change: the instructions carry no immediate data.

## Security Considerations

At run time the instructions check what `JUMP` and `CALLSUB` check — that the *destination* is a `JUMPDEST` or `CALLDEST`, and that the *return stack* has room — and one thing more, that the *table* lies within the code.  A *table* is read at one entry, chosen by the *case*, whatever its size, and reading the code is reading what the client already holds.  Neither instruction can transfer control anywhere a `JUMP` or `CALLSUB` could not.

Validation remains linear, within the worst case [EIP-8337](./eip-8337.md) priced: a *table* of *k* entries is 2*k* + 1 bytes and, named by one *instruction*, adds at most *k* edges to the traversal — one edge per two bytes of code.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
