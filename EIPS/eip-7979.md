---
eip: 7979
title: Call and Return Opcodes for the EVM
description: Three new instructions to support calls and returns.
author: Greg Colvin (@gcolvin) <greg@colvin.org>, Martin Holst Swende (@holiman), Brooklyn Zelenka (@expede), John Max Skaller
discussions-to: https://ethereum-magicians.org/t/eip-7979-call-and-return-opcodes-for-the-evm/24615
status: Draft
type: Standards Track
category: Core
created: 2025-12-17
---

## Abstract

This is a minimal change to the Ethereum Virtual Machine (EVM) to support calls and returns.

This proposal introduces three new control-flow instructions to the EVM:

* `CALLSUB` transfers control to the *destination* on the *data stack*.
* `CALLDEST` marks a subroutine entry: the destination of a `CALLSUB`, or of a `JUMP` that eliminates a call.
* `RETURNSUB` returns to the *PC* after the most recent `CALLSUB`.

These changes are backwards compatible: the instructions behave identically wherever they appear.

*Note: Significant assistance from AI is acknowledged, primarily for the reference implementation and its tests.*

## Motivation

The EVM currently lacks explicit call and return instructions.  Instead, calls and returns must be synthesized using the dynamic `JUMP` instruction, which takes its destination from the stack.  This creates two fundamental problems:

* **Inefficiency**: Synthesizing calls and returns with jumps wastes bytecode space and gas.
* **Complexity**: More important, dynamic jumps obscure the flow of control.  Explicit calls and returns make the call structure of code visible — to people, to tools, to compilers — whereas synthesized jumps bury it.

[EIP-8173](./eip-8173.md), *Foundations of EVM Control Flow*, lays out the problem we need to solve: a synthesized return is a jump whose destination is data, so tools that traverse a program's flow of control must mark every possible destination, which can take quadratic time.  Actually following every path can take exponential time or worse.

For Ethereum, anything worse than linear complexity is a *denial-of-service vulnerability* for any online static analysis, including bytecode validation and ahead-of-time (AOT) compilation at contract creation time, and just-in-time (JIT) compilation at runtime.

Even offline, dynamic jumps (and the lack of calls and returns) can cause static analyses of many contracts to become quadratically impractical, exponentially intractable, or even mathematically impossible, including automated proofs of correctness, formal analysis and more.

## Specification

> *The key words MUST and MUST NOT in this Specification are to be interpreted as described in RFC 2119 and RFC 8174.*

The EVM's machine state includes a *data stack* of 256-bit words, at most 1024 deep, and the program counter, *PC*, whose value is a position in the code — the index of the next instruction to execute.  This EIP adds a *return stack* of return addresses, pushed only by `CALLSUB`, popped only by `RETURNSUB`, and not otherwise accessible to EVM code.

### `CALLSUB (0x..)`

Transfers control to a subroutine.

1. Pop the *destination* from the top of the *data stack*.
2. Push the position *PC* + 1 to the *return stack*.
3. Set the *PC* to the *destination*.

If the *destination* is not a `CALLDEST`, or the *return stack* already
holds 1024 items, execution is in an exceptional halting state.

The gas cost is *mid* (8).

### `CALLDEST (0x..)`

Marks a subroutine entry.  Like `JUMPDEST`, it is otherwise a no-op:
execution falls through.  The *destination* of every `CALLSUB` MUST be a
`CALLDEST`.

A `CALLDEST` is also a valid `JUMP` and `JUMPI` destination.  Jumping to
one enters the subroutine without pushing to the *return stack*, so its
`RETURNSUB` returns to the original caller.

The gas cost is *jumpdest* (1).

### `RETURNSUB (0x..)`

Returns control to the most recent caller.

1. Set the *PC* to the position popped from the *return stack*.

If the *return stack* is empty, execution is in an exceptional halting
state.

The gas cost is *low* (5).

*Notes:*

* *Values popped off the return stack do not need to be checked, since they are alterable only by `CALLSUB` and `RETURNSUB`.*
* *The return stack describes the semantics; its actual state is not observable by EVM code, nor consensus-critical.  An implementer may, for example, push the PC rather than PC + 1, so long as `RETURNSUB` observably returns control to PC + 1.*
* *Opcode values are still to be determined.*

### Costs

A *mid* cost for `CALLSUB` is justified by it taking very little more work than the *mid* cost of `JUMP` — just pushing an integer to the *return stack*.

A *jumpdest* cost for `CALLDEST` is justified by it being, like `JUMPDEST`, a mere label.

A *low* cost for `RETURNSUB` is justified by needing only to pop the *return stack* into the *PC* — less work than a jump.

Benchmarking will be needed to tell if the costs are well-balanced.

## Rationale

### Why no immediate arguments or code sections?

Primarily **backwards compatibility**.  Other reasons include:

* *Immediate arguments* — operand bytes following the opcode in the code itself, rather than taken from the stack — would improve performance but increase the complexity of instruction encoding.
* *Code sections* or other structural constraints would impose syntactic restrictions that inhibit optimization.

The EVM Object Format (EOF) took the complementary path — function descriptors in code sections, immediate arguments for relative jumps within sections — and needed special-purpose opcodes to keep important uses of cross-subroutine jumps.

### Why may `JUMP` land on a `CALLDEST`?

So that compilers can eliminate calls.  Where a call would be the last action before a return, a jump does the same work with no return address pushed:

```
f: CALLDEST              f: CALLDEST
   ...                      ...
   PUSH g                   PUSH g
   CALLSUB                  JUMP
   RETURNSUB
g: CALLDEST              g: CALLDEST
   ...                      ...
   RETURNSUB                RETURNSUB
```

On the left, `g` returns to `f`, which returns to its caller.  On the right, `g`'s `RETURNSUB` returns directly to `f`'s caller: one instruction shorter, one return address fewer — and where `g` is `f` itself, or calls back into it, the recursion runs at constant return-stack depth instead of halting at 1024.  Compilers rely on this transformation, for tail calls, mutual recursion, state machines, and shared epilogues (one exit sequence shared by many paths).  And the jump is no wilder than the call it replaces: it lands on the same label.

### Why these three instructions?

This proposal aims to be a minimal change to the EVM.  We introduce two abstract operations — call and return — implemented by three instructions: `CALLSUB`, `CALLDEST`, and `RETURNSUB`.  These suffice to eliminate the need for dynamic jumps.

### Why the return-stack mechanism for calls and returns?

Register machines like x86, ARM, and RISC-V keep return addresses in a link register or push them onto the one stack, mixed with data.  Stack machines like Turing's Automatic Computing Engine (ACE), Forth, the Java Virtual Machine (JVM), WebAssembly (Wasm), and .NET's Common Language Runtime (CLR) use separate data and return stacks.  The EVM is a stack machine, and we adopt the same proven approach: a separate *return stack* isolated from the *data stack*.  Another reason to maintain a separate stack is that *data stack* items are 32 bytes, but jump destinations will not need more than one or two.

#### Safety advantages of the *return stack*

The return addresses, being on their own stack, are not accessible to EVM code.  They cannot be read, modified, or moved by ordinary stack operations.  This eliminates an entire class of vulnerabilities where code could corrupt its own control flow.

Because return addresses are controlled exclusively by `CALLSUB` and `RETURNSUB`, they are intrinsically safe: unlike data-stack values, which may depend on arbitrary computation, return-stack values are guaranteed to be valid *PC* values.

### Are there code size and gas savings?

The difference these instructions make can be seen in this very simple code for calling a routine that squares a number.  The distinct opcodes make it easier for both people and tools to understand the code, and there are modest savings in code size and gas costs as well.

```

SQUARE:                           |       SQUARE:
    jumpdest       ; 1 gas        |           calldest       ; 1 gas
    dup1           ; 3 gas        |           dup1           ; 3 gas
    mul            ; 5 gas        |           mul            ; 5 gas
    swap1          ; 3 gas        |           returnsub      ; 5 gas
    jump           ; 8 gas        |
                                  |
CALL_SQUARE:                      |       CALL_SQUARE:
    jumpdest       ; 1 gas        |           calldest       ; 1 gas
    push RTN_CALL  ; 3 gas        |           push 2         ; 3 gas
    push 2         ; 3 gas        |           push SQUARE    ; 3 gas
    push SQUARE    ; 3 gas        |           callsub        ; 8 gas
    jump           ; 8 gas        |           returnsub      ; 5 gas
RTN_CALL:                         |           stop           ; 0 gas
    jumpdest       ; 1 gas        |
    swap1          ; 3 gas        |
    jump           ; 8 gas        |
    stop           ; 0 gas        |
                                  |
Size in bytes: 17                 |      Size in bytes: 12
Consumed gas:  50                 |      Consumed gas:  34

```

Note that on the left even the caller must synthesize its own return: the final `swap1` and `jump`.  That's 29% fewer bytes and 32% less gas using `CALLSUB` versus using `JUMP`.  So we can see that these instructions provide a simpler, more efficient mechanism.  As code becomes larger and better optimized the gains become smaller, but code using `CALLSUB` always takes less space and gas than equivalent code without it.

### Are there real-time performance gains?

Some real-time interpreter performance gains are reflected in the lower gas costs.  But larger gains come from AOT and JIT compilers.  In code that forgoes dynamic jumps, a single pass can check that the depth of the *data stack* at each instruction is the same on every execution — and code that passes is code a JIT can compile on the fly, and an AOT can compile to better machine code in linear time.  (The JVM, Wasm, and the CLR share this property.)

The EVM is a stack machine, but most real machines are register machines.  Both routes — an interpreted register code, and ahead-of-time compilation to machine code — are measured in [this proposal's assets](../assets/eip-7979/riscv/): executed RISC-V instructions — counted exactly, rounded here — on two kernels that bracket the workload space — *call tree*, a recursive tree of calls that computes almost nothing; *mul chain*, a loop of dependent multiplies, nearly pure arithmetic.  Lower is better, and the parentheses give each cell's gain over the status quo: interpreted bytecode at today's 256-bit word width.  The right-hand pair of columns uses proposed 64-bit arithmetic opcodes.  Read *down* for what static control flow buys — each row is a cheaper execution tier the proofs permit.  Read *across* for what the 64-bit opcodes buy.  The bottom-right corner is both at once: 51x.

|                      | call tree, 256 | mul chain, 256 | call tree, 64 | mul chain, 64 |
|----------------------|---------------:|---------------:|--------------:|--------------:|
| interpreted bytecode | 8M | 6M | 7M (1x) | 4M (1x) |
| register IR          | 4M (2x) | 4M (2x) | 2M (3x) | 2M (3x) |
| compiled (AOT)       | 1M (7x) | 1M (5x) | 406K (19x) | 121K (51x) |

The first row is the status quo: legacy bytecode, interpreted.  Adding 64-bit arithmetic instructions barely shows there — dispatch dominates an interpreter.  The second row interprets a register intermediate code — the table's "register IR" — translated once at deploy from code that forgoes dynamic jumps: stack slots become numbered registers, `PUSH`-and-jump pairs become single branch instructions, no destination checks or underflow bookkeeping survive.  This is the path for clients that will never JIT, and its gains any EVM-compatible chain collects without RISC-V.  The last row compiles that same code ahead of time to RISC-V, removing the dispatch as well; composed with the 64-bit instructions this beats the product of the two gains alone, because a stack slot becomes a machine register only when its offset is proven static *and* its value fits the register.  The gains do not merely add; they compound.  Every cell meters gas — per operation when interpreting bytecode, per basic block after translation — and keeps the runtime overflow and depth checks.  These are floors, from deliberately naive translators.

However, for most transactions, storage dominates execution time — it is outside these kernels — and gas counting and other overhead always take their toll.  So such gains would be most visible in those contexts where overhead can be minimal, such as some layer 1 (L1) precompiles, layer 2 (L2) chains, and EVM-compatible chains.

### Does ZK-rollup efficiency improve?

Yes, measurably.  A zero-knowledge (ZK) rollup executes transactions, then proves to L1 that the execution was correct.  Generating that proof is the expensive part, and the ZK virtual machines (zkVMs) that dominate current practice generate proofs of RISC-V programs.  The cost is per instruction: every RISC-V instruction the program executes is one more step the prover must prove.  Fewer instructions, cheaper proof.

Today these zkVMs run the EVM as an EVM interpreter, compiled to RISC-V.  That is the first row of the table above.  Validated code offers an alternative: compile the EVM code itself to RISC-V.  That is the last row of the table.

To confirm that the instruction counts above are what a prover actually pays, we ran the same programs in Zisk, Polygon's RISC-V zkVM.  Every program cost the prover exactly its executed-instruction count, plus 444 steps of fixed startup.  So the ratios in the table are ratios of proving costs: the same contract is 5x to 51x cheaper to prove compiled than interpreted.  Details and reproduction in [the assets](../assets/eip-7979/riscv/).

## Backwards Compatibility

These changes are backwards compatible.  The new opcodes behave identically wherever they appear, and there are *no changes* to the semantics of existing EVM code.  (With the caveat that code with unspecified behavior might behave in different, unspecified ways.  Such code was always broken.)  Implementation can come down to a push and a jump to call, and a pop and another jump to return.

These changes do not preclude running the EVM in zero knowledge; neither do they foreclose EOF, RISC-V, or other changes.

## Test Cases

*Note: the bytecode strings in these tests use placeholder opcode values
`0xB0`=`CALLSUB`, `0xB1`=`CALLDEST`, `0xB2`=`RETURNSUB`, which are to be
confirmed when final opcode assignments are made.  The traces, gas totals,
and pass/fail outcomes are correct for the semantics defined in this EIP.*

*The Stack column shows the data stack before the instruction executes.
The RStack column shows the return stack before the instruction executes.*

### Simple routine

This should call a subroutine, return from it, and stop.

Bytecode: `0x6004B000B1B2` (`PUSH1 0x04, CALLSUB, STOP, CALLDEST, RETURNSUB`)

```
PC=0: PUSH1  imm=0x04   size=2
PC=2: CALLSUB            size=1
PC=3: STOP               size=1
PC=4: CALLDEST           size=1
PC=5: RETURNSUB          size=1
```

|  PC   |      Op     | Cost |   Stack   |   RStack  |
|-------|-------------|------|-----------|-----------|
|    0  |      PUSH1  |    3 |        [] |        [] |
|    2  |    CALLSUB  |    8 |       [4] |        [] |
|    4  |    CALLDEST |    1 |        [] |       [3] |
|    5  |  RETURNSUB  |    5 |        [] |       [3] |
|    3  |       STOP  |    0 |        [] |        [] |

Output: 0x
Consumed gas: `17`

### Two levels of subroutines

This should execute fine, going into two depths of subroutines.

Bytecode: `0x6004B000B16009B0B2B1B2` (`PUSH1 0x04, CALLSUB, STOP, CALLDEST, PUSH1 0x09, CALLSUB, RETURNSUB, CALLDEST, RETURNSUB`)

```
PC=0:  PUSH1  imm=0x04   size=2
PC=2:  CALLSUB            size=1
PC=3:  STOP               size=1
PC=4:  CALLDEST           size=1
PC=5:  PUSH1  imm=0x09   size=2
PC=7:  CALLSUB            size=1
PC=8:  RETURNSUB          size=1
PC=9:  CALLDEST           size=1
PC=10: RETURNSUB          size=1
```

|  PC   |      Op     | Cost |   Stack   |   RStack  |
|-------|-------------|------|-----------|-----------|
|    0  |      PUSH1  |    3 |        [] |        [] |
|    2  |    CALLSUB  |    8 |       [4] |        [] |
|    4  |    CALLDEST |    1 |        [] |       [3] |
|    5  |      PUSH1  |    3 |        [] |       [3] |
|    7  |    CALLSUB  |    8 |       [9] |       [3] |
|    9  |    CALLDEST |    1 |        [] |      [3,8] |
|   10  |  RETURNSUB  |    5 |        [] |      [3,8] |
|    8  |  RETURNSUB  |    5 |        [] |       [3] |
|    3  |       STOP  |    0 |        [] |        [] |

Consumed gas: `34`

### Failure 1: invalid destination

This should fail because the destination is outside the code range.

Bytecode: `0x60FFB000B1B2` (`PUSH1 0xFF, CALLSUB, STOP, CALLDEST, RETURNSUB`)

```
PC=0: PUSH1  imm=0xFF   size=2   ← destination 255, code is only 6 bytes
PC=2: CALLSUB            size=1
PC=3: STOP               size=1
PC=4: CALLDEST           size=1
PC=5: RETURNSUB          size=1
```

|  PC   |      Op     | Cost |   Stack   |   RStack  |
|-------|-------------|------|-----------|-----------|
|    0  |      PUSH1  |    3 |        [] |        [] |
|    2  |    CALLSUB  |    8 |    [0xFF] |        [] |

Error: at pc=2, op=CALLSUB: invalid destination

### Failure 2: empty return stack

This should fail at the first opcode because the *return stack* is empty.

Bytecode: `0xB2` (`RETURNSUB`)

|  PC   |      Op     | Cost |   Stack   |   RStack  |
|-------|-------------|------|-----------|-----------|
|    0  |  RETURNSUB  |    5 |        [] |        [] |

Error: at pc=0, op=RETURNSUB: empty return stack

### Subroutine at end of code

In this example, `CALLSUB` is the last byte of code.  When the subroutine
returns, it should hit the implicit STOP after the bytecode and not exit
with error.

Bytecode: `0x600556B1B25B6003B0` (`PUSH1 0x05, JUMP, CALLDEST, RETURNSUB, JUMPDEST, PUSH1 0x03, CALLSUB`)

```
PC=0: PUSH1    imm=0x05   size=2
PC=2: JUMP                size=1
PC=3: CALLDEST            size=1
PC=4: RETURNSUB           size=1
PC=5: JUMPDEST            size=1
PC=6: PUSH1    imm=0x03   size=2
PC=8: CALLSUB             size=1  ← last byte; returns to PC=9 (past end → implicit STOP)
```

|  PC   |      Op         | Cost |   Stack   |   RStack  |
|-------|-----------------|------|-----------|-----------|
|    0  |          PUSH1  |    3 |        [] |        [] |
|    2  |           JUMP  |    8 |       [5] |        [] |
|    5  |       JUMPDEST  |    1 |        [] |        [] |
|    6  |          PUSH1  |    3 |        [] |        [] |
|    8  |        CALLSUB  |    8 |       [3] |        [] |
|    3  |       CALLDEST  |    1 |        [] |       [9] |
|    4  |     RETURNSUB   |    5 |        [] |       [9] |
|    9  | (implicit STOP) |    0 |        [] |        [] |

Consumed gas: `29`

## Reference Implementation

The following is expressed against the Ethereum Execution Layer Specifications (EELS) — the Python execution specification — following its conventions.  `GAS_MID` (8), `GAS_LOW` (5), and `GAS_JUMPDEST` (1) are EELS's existing constants; `ReturnStackOverflowError` and `ReturnStackUnderflowError` are new `ExceptionalHalt` subclasses, paralleling the existing `StackOverflowError` and `StackUnderflowError`.

The machine state gains one field, the `return_stack`, and JUMPDEST analysis gains one set, the `valid_call_destinations`:

```python
@dataclass
class Evm:
    ...
    return_stack: List[Uint]   # pushed only by CALLSUB, popped only by RETURNSUB

RETURN_STACK_LIMIT = Uint(1024)

def get_valid_destinations(code: Bytes) -> Tuple[Set[Uint], Set[Uint]]:
    """One pass, extending get_valid_jump_destinations: JUMPDEST and
    CALLDEST positions, skipping PUSH immediate data.  A CALLDEST is
    also a valid jump destination, so it lands in both sets."""
    valid_jump_destinations = set()
    valid_call_destinations = set()
    pc = Uint(0)
    while pc < ulen(code):
        current_opcode = Ops(code[pc])
        if current_opcode == Ops.JUMPDEST:
            valid_jump_destinations.add(pc)
        elif current_opcode == Ops.CALLDEST:
            valid_call_destinations.add(pc)
            valid_jump_destinations.add(pc)
        elif Ops.PUSH1.value <= current_opcode.value <= Ops.PUSH32.value:
            pc += Uint(current_opcode.value - Ops.PUSH1.value + 1)
        pc += Uint(1)
    return valid_jump_destinations, valid_call_destinations
```

The three new instructions:

```python
def callsub(evm: Evm) -> None:
    # STACK
    destination = Uint(pop(evm.stack))
    # GAS
    charge_gas(evm, GAS_MID)
    # OPERATION
    if destination not in evm.valid_call_destinations:
        raise InvalidJumpDestError
    if len(evm.return_stack) == RETURN_STACK_LIMIT:
        raise ReturnStackOverflowError
    evm.return_stack.append(evm.pc + Uint(1))
    # PROGRAM COUNTER
    evm.pc = destination


def calldest(evm: Evm) -> None:
    # GAS
    charge_gas(evm, GAS_JUMPDEST)
    # OPERATION: no-op, like JUMPDEST
    # PROGRAM COUNTER
    evm.pc += Uint(1)


def returnsub(evm: Evm) -> None:
    # GAS
    charge_gas(evm, GAS_LOW)
    # OPERATION
    if len(evm.return_stack) == 0:
        raise ReturnStackUnderflowError
    # PROGRAM COUNTER
    evm.pc = evm.return_stack.pop()
```

`jump` and `jumpi` need no change: the scan already places every `CALLDEST` in `valid_jump_destinations`, since a `CALLDEST` is also a valid jump destination.

## Security Considerations

Return addresses live on their own stack, inaccessible to EVM code: they cannot be read, modified, or moved, which eliminates an entire class of vulnerabilities where code corrupts its own control flow.  The remaining hazards are checked at run time, as the instruction definitions specify: `CALLSUB` halts unless its destination is a `CALLDEST`, `RETURNSUB` halts on an empty *return stack*, and a `CALLSUB` that would exceed 1024 return addresses halts.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
