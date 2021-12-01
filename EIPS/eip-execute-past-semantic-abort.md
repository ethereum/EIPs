---
eip: 4511
title: Execute Past Semantic Abort
description: Allow clients to choose to continue to execute instructions after EVM bytecode interpretation would revert
author: Levi Aul (@tsutsu)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2021-11-30
---

## Abstract
Rather than detecting/enforcing *interpreter-abort conditions* (Out-of-Gas, Stack Overflow/Underflow, etc.) on each EVM interpreter step, clients may choose to implement deferred detection/enforcement of these conditions at some higher-level instruction-sequence boundary point in the interpreter, under the condition that all transactions result in the same EVM post-transaction substate as they would with eager, per-interpreter-step *interpreter-abort condition* detection.

In such clients, after the interpreter enters a state where it must revert execution, some unpredictable-but-bounded number of additional instructions from the execution frame will be executed. These instructions, as part of a reverted execution frame, will be *moot* (have no visible side-effects in the state.) However, the execution of these *moot* instructions may still be observed through client execution-tracing APIs.

By removing these checks from the hot loop of EVM bytecode interpretation, these clients become amenable to a number of currently-impractical optimizations.

## Motivation
There are certain "interpreter abort" conditions within the EVM interpreter that are currently checked for on every interpretation step, such as Out-of-Gas, Stack Overflow, etc. When one of these conditions is found to apply, the currently-executing call frame is immediately escaped, with any state modifications made by that call frame and its descendants being reverted, just as if a user-triggered `REVERT` instruction were executed.

EVM formal semantics *make no requirement* to perform these checks for each interpretation step. EVM transaction execution is effectively defined as a black box function upon the substate, where clients are free to implement the *means* by which the resulting substate is computed however they wish. Additionally, the revert on interpreter-abort "masks away" any information that a caller could use to determine what exactly the callee was doing when it aborted, by e.g. always using up all gas given to the callee.

However, checking for interpreter-abort conditions on every interpretation step nevertheless seems to be a universal standard for Ethereum clients, perhaps out of mistaken assumption of this being a formal EVM requirement.

Additionally, some ecosystem tooling may rely on cross-client predictable/deterministic output from client execution-tracing APIs, due to a similar mistaken assumption that the interpretation-step sequence for a given EVM transaction will always look the same.

This implicit pseudo-requirement makes applying runtime optimizations to EVM interpretation, such as Just-In-Time compilation or threaded-code interpretation, mostly pointless, as either every instruction implementation needs to contain/generate redundant copies of these same checks, or trampolines to the interpreter to perform these checks need to be inserted between successive instructions.

Explicitly allowing the deferral of interpreter-abort checks to execute only on arbitrary interpreter-chosen execution steps, removes the implicit constraint to include these checks "inside" or "between" instruction bodies, making these previously-pointless optimizations potentially worthwhile.

## Rationale

### Inspiration: Erlang BEAM VM

This EIP is mostly inspired by looking at gas-tracking / Out-of-Gas detection specifically, and how other systems with similar constraints achieve efficient results.

There exists a system very similar to gas-tracking, called [reduction counting](https://blog.stenmans.org/theBeamBook/#_scheduling_non_preemptive_reduction_counting), used in the programming language Erlang's virtual machine BEAM. Like an individual EVM bytecode execution, an individual BEAM actor-process is allocated a certain amount of an abstract compute resource ("reductions" in their terminology) when it begins interpretation; like EVM bytecode instructions, each BEAM bytecode instruction implementation subtracts some static+dynamic amount from the actor process's remaining-resource counter register; and like an EVM interpreter, a BEAM actor-process has checks that allow it to interrupt itself when it runs its remaining-resource counter register down to zero.

However, unlike in the EVM, individual BEAM actor-processes are never interrupted during execution of straight-line code. The BEAM "out-of-reductions" check-and-branch is not implemented into the run-loop of the bytecode interpreter itself; but rather, it is a (sometimes-inlined) subroutine implemented into the implementations of two types of instructions: subroutine call/ret instructions, and cross-actor messaging instructions.

Because of this, BEAM bytecode is highly amenable to optimization techniques such as threaded-code interpretation and Just-In-Time compilation. The codegen for individual bytecode instructions can often be as simple as two host-ISA instructions: one to do the required math/stack manip/etc., and the other to subtract an appropriate amount from the reduction counter.

Even better, after codegen, peephole optimization can be applied to hoist all these reduction-counter decrements (which only depend on each-other) out of the basic block they're embedded in, and replace them with a single reduction-counter decrement of the aggregate value from the individual operations, drastically reducing generated code size, and enabling other optimizations due to the code now forming clear "runs" of dependent instructions, without any interruptions from "bookkeeping" code.

### Considerations in Borrowing the BEAM Approach

Note that branching instructions are not included in the set of BEAM instructions that check the reduction counter. This is because the Erlang (and other BEAM language) compilers are careful to never generate branches that represent *back edges* in a Control Flow Graph. Because of this, despite primitive looping constructs being theoretically possible in BEAM bytecode, they're never emitted in practice.

Instead, Erlang and other BEAM languages expose Tail-Call-Optimized (TCOed) recursion as a primitive, and looping constructs are implemented in terms of that primitive. As recursive tail-calls use the "subroutine call" BEAM instruction, these calls always flow through the Out-of-Reductions check-and-branch logic built into that instruction's implementation.

Because of this, BEAM VM languages are free to use *forward* branch instructions to implement non-loop control-structures, e.g. `if/else`, `case`, clause-head pattern matching, `goto fail`-type internal error handling, etc., without paying any bookkeeping overhead cost for these instructions. The instruction implementations for forward-branches remain just as simple as the instruction implementations for math ops *et al*, and so become amenable to optimization (e.g. branchless-code reduction) themselves.

The EVM, as a trustless-multitenant runtime, cannot rely on the developer or compiler kindly limiting themselves to only deploying code that uses a subset of possible instruction sequences, the way BEAM compilers do. The EVM must ensure that Out-of-Gas conditions are checked at least once for each iteration of EVM-primitive branching loops.

## Specification

### Definitions
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

An **execution frame** is the set of EVM registers and trie state associated with the interpretation of a particular contract message-call or contract-deployment constructor. When one contract calls another, a distinct child *execution frame* is created.

An **interpreter abort** is an EVM operation that results in the revert of the current *execution frame*, and the consumption of all gas passed to the current *execution frame*.

An **interpreter-abort condition** is any property of an *execution frame*, which, being true at any point during execution, implies that the associated *execution frame* is no longer valid, and must be resolved through an *interpreter abort*.

An *interpreter-abort condition* **pertains** from the first moment at which the property becomes true for a given execution-frame, until the condition is *handled* via an *interpreter abort*. An interpreter-abort condition **pertains** regardless of whether the EVM implementation has *detected* the condition. An interpreter-abort condition continues to **pertain** even if the property is no longer true of the current execution-frame (e.g. if the stack overflowed, but the stack size has since been reduced.)

The time during which an interpreter-abort condition *pertains* is its **pertinence interval**.

An **eager-aborting** interpreter is an interpreter that attempts to detect and handle *interpreter-abort conditions* as soon as they *pertain*. All current EVM implementations are *eager-aborting*.

A **lazy-aborting** interpreter is an interpreter that defers detection and/or handling of at least one *interpreter-abort condition* past the start of its *pertinence interval*.

**Moot interpretation** is any interpreter logic executed during an *interpreter-abort condition*'s *pertinence interval* **other than** the handling of the condition via an *interpreter abort*.

An interpreter-step is **trace-observable** if that interpreter-step's outcome will have an impact on an execution trace reported through a client's execution-tracing API.

**Ecosystem tooling** is any software built to interact with client RPC APIs.

### Requirements for Clients
Clients MAY detect and enforce *interpreter-abort conditions* at whatever level of execution granularity they wish, allowing for arbitrary amounts of *moot interpretation* (*trace-observable* or not) to occur, under the condition that the produced transaction substate or caller-returned state is indistinguishable from that produced by an *eager-aborting* interpreter.

To minimize wasted CPU cycles, it is RECOMMENDED that clients detect and enforce *interpreter-abort conditions* within the implementations of branching and `CALL`-class opcodes.

It is RECOMMENDED that clients with execution-tracing APIs, offer some facility in those APIs to request that trace events originating from *execution frames* that result in an *interpreter abort* (and any children of said *execution frames*) be filtered out of the returned execution traces.

Clients with execution-tracing APIs SHOULD NOT offer any facility to request that *moot interpretation* specifically be filtered out of the returned execution results. (Doing so would re-introduce all current interpreter optimization problems.)

### Requirements for Ecosystem Tooling
Ecosystem tooling relying on client execution-tracing APIs MUST NOT assume that clients will use *eager-aborting* interpreters.

Ecosystem tooling that consumes execution traces MUST be able to handle a potentially-unbounded number of *trace-observable moot interpretation* trace events being returned as a part of an execution trace.

Ecosystem tooling MUST NOT assume that an execution trace's size will be predictable given e.g. the amount of gas the transaction was recorded to have spent.

Ecosystem tooling MUST NOT assume a standard formal semantics for *moot interpretation* execution traces. Clients are not constrained in how they handle *moot interpretation*, and so *moot interpretation* trace events may have large differences due to client EVM implementation. (For example, one client's traces may report negative gas-remaining, while another client's traces may report gas-remaining with a uint64 wraparound.)

## Backwards Compatibility
The only practical backwards-incompatibilities introduced here would be to *ecosystem tooling* that makes use of client execution-tracing APIs. These APIs—and especially their outputs—have not yet seen any standardization, and so there is no explicit stability guarantee being broken here. Instead, there is only a "guarantee of no standardization" being introduced with respect to the existence, shape, and properties of *moot interpretation* event traces.

There would be no immediate changes required by this EIP, as *eager-aborting* clients would be considered conformant with this EIP.

## Security Considerations

### Out-of-Gas Detection
The key consideration in deferring Out-of-Gas detection specifically, is the prevention of unbounded amounts of miner-side computation. If *moot interpretation* were allowed to include calls, back-edge branching jumps, and other such instructions with above-`O(1)` computational complexity, then *lazy-aborting* clients would potentially be *far less* computationally-efficient than *eager-aborting* clients—especially in the presence of malicious contract executions designed to generate as much *moot interpretation* as possible.

As long as all potential above-`O(1)` instructions cause Out-of-Gas detection to run (ala the outlined BEAM VM approach), this potential pitfall should be entirely avoided.

### Stack Overflow Detection
Because contract code size is bounded, the number of contiguous non-yield-point instructions in a contract is also bounded. The worst-case scenario here, then, is that a malicious actor would construct a contract to execute the maximal number of contiguous non-yield-point instructions given the contract size limit; where each instruction in turn is chosen to increase the stack size as much as possible. As long as the EVM's stack-slot pool has enough free slots to (temporarily) handle this worst-case situation, the underlying stack won't actually overflow physically, only semantically.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
