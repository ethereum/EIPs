---
eip: xxxx
title: Static Control Flow in the EVM — Foundational Concepts & Context
description: understanding static control flow and its relation to Ethereum's scaling roadmap
author: Greg Colvin (@gcolvin)
discussions-to:
status: Draft
type: Informational
category: Core
created: 2026-2-16
---
## Abstract

This Informational EIP provides foundational context for understanding static control flow in the EVM and related optimization proposals. It covers the historical development of control flow mechanisms in computing, the technical foundations of control-flow analysis, and the relationship between static control flow and Ethereum's scaling roadmap. This document serves as background material for EIPs including EIP-7979 (Call and Return Opcodes), EIP-8013 (Static Relative Jumps), EIP-3540 (EOF), and discussions around RISC-V migration and ZK verification infrastructure.

## Historical Context

### Babbage, 1833: Jumps and Conditional Jumps

In 1833 Charles Babbage began the design of a steam-powered, mechanical, Turing-complete computer. Programs were to be encoded on punched cards which controlled a system of rods, gears and other machinery to implement storage, arithmetic, jumps, and conditional jumps. Jumps were supported by a cards that shuffled the card deck forwards or backwards a fixed number of the cards. Its first published description was by L. F. Menabre, 1842[^1]. The translator, Ada Augusta, Countess of Lovelace, made extensive notes. The notes include her famous program for recursively computing Bernoulli numbers — arguably the world's first complete computer program — which used conditional jumps to implement the required nested loops.

### Turing, 1945: Calls and Returns

In 1945 Alan Turing proposed his Automatic Computing Engine[^3], where he introduced the concept of calls and returns: _"To start on a subsidiary operation we need only make a note of where we left off the major operation and then apply the first instruction of the subsidiary. When the subsidiary is over we look up the note and continue with the major operation."_

The ACE supported calls directly with a stack of mercury-filled memory crystals holding return addresses. Turing's design was for a 32-bit RISC machine with a vacuum tube integer ALU, floating point microcode, 32 registers, a 1024-entry return stack, and 32K of RAM on a 1 MHz bus. The smaller Pilot ACE was for a while the world's fastest computer.

### Lovelace & Turing: An Aside on Machine Intelligence and Computation

In Lady Lovelace's notes we find her prescient recognition of the Analytic Engine's power:

> "In enabling mechanism to combine together general symbols in successions of unlimited variety and extent, a uniting link is established between the operations of matter and the abstract mental processes of the most abstract branch of mathematical science."[^1]

She also recognized its limits:

> "It can do whatever we know how to order it to perform. It can follow analysis; but it has no power of anticipating any analytical relations or truths. Its province is to assist us in making available what we are already acquainted with."[^1]

In 1950 Alan Turing answered "Lady Lovelace's Objection" with a question of his own in his seminal paper "Computing Machinery and Intelligence":

> "The majority of minds seem to be 'subcritical' ... an idea presented to such a mind will on average give rise to less than one idea in reply. A smallish proportion are supercritical. An idea presented to such a mind that may give rise to a whole 'theory' consisting of secondary, tertiary and more remote ideas... we ask, 'Can a machine be made to be supercritical?'"[^2]

This exchange highlights a fundamental insight: computation is not merely about executing operations, but about structuring operations in ways that enable complex reasoning and hierarchical problem-solving. The call/return mechanism is central to this structure.

### Industry Practice: 1945–present

Call and return facilities of various levels of complexity have proven their worth across a long line of important machines over the last 80 years, including most of the machines I have programmed or implemented:  Physical machines including the Burroughs 5000, CDC 7600, IBM 360, PDP-11, VAX, Motorola 68000 and Intelx86, and virtual machines including  those for Scheme, Forth, Pascal, Java, and WebAssembly.  (Some physical machines do not provide explicit call and return codes, including RISC-V and ARM.  More on this later.)

Especially relevant to the EVM's design are the Java, WebAssembly (Wasm), and CLR (.NET) VMs. They share crucial common properties.  Like the EVM they are represented with portable bytecode that can be directly interpreted.  Unlike the EVM, they have static control flow that be can be validated before runtime and be compiled to machine code in linear time, enabled by explicit call/return mechanisms.

## Technical Foundations

### The Fundamental Problem: EVM's Lack of Call/Return Opcodes

The Ethereum Virtual Machine does _not_ provide explicit facilities for calls and returns. Instead, they must be synthesized using the dynamic `JUMP` instruction, which takes its argument from the stack. This creates two problems:

1. **Code size and efficiency:** Synthesizing calls with jumps wastes space and gas compared to explicit call opcodes.
2. **Analysis complexity:** Dynamic jumps create fundamental challenges for static analysis that are largely absent in VMs with structured call mechanisms.

Dynamic jumps and calls are not a problem for machines which run on physical hardware, but are rare in virtual machines whose code is often the source for downstream tools like JIT compilers.  E.g. a JIT compiler that takes quadratic time is of limited practical value. For this reason, Java, Wasm, and .NET VMs do not support dynamic jumps.

### Control-Flow Graphs and Static Analysis

A **control-flow graph (CFG)** is a directed graph representation of a program where:
- **Nodes** represent blocks of instructions (sequences with one entry and one exit)
- **Edges** represent possible transfers of control between blocks
- **Entry and exit nodes** represent program start and termination

Control-flow analysis —- the process of determining which paths a program can take -- is fundamental to many downstream tasks:

- Validating bytecode before execution
- Translating to other representations (virtual register code, machine code)
- Compiling to efficient target architectures
- Constructing ZK proof systems
- Performing formal security analysis

For a program with static jumps and explicit calls, the number of nodes in the CFG is linear in the number of instructions, and traversing the full graph takes linear time.

### Problems with Dynamic Jumps

With dynamic jumps, however, analysis becomes much harder. Since a dynamic jump can branch to _any_ valid destination in the code, the analyzer must consider every possible branch.

Consider a program with N basic blocks, where each block contains a dynamic jump and the jump destination is determined dynamically:

```
Block 1: JUMPDEST GAS JUMP
Block 2: JUMPDEST GAS JUMP
Block 3: JUMPDEST GAS JUMP
...
Block N: JUMPDEST GAS JUMP
```

At each block's jump instruction, the analyzer cannot know _a priori_ where control will transfer. In the worst case, every block might jump to any other block, creating a fully-connected CFG with O(N²) possible paths. Traversing all paths to verify them requires O(N²) time, and this is not a theoretical worst-case — it's achievable with relatively short pathological programs.

For Ethereum, this quadratic behavior is a **denial-of-service vulnerability** for any online static analysis, including:
- Validating bytecode at contract creation time
- Translating bytecode to other representations
- AOT or JIT compilation at runtime

Even offline, dynamic jumps (and the lack of calls and returns) can cause static analyses of many contracts to become impractical, intractable or even impossible. The following are quotes from the abstracts for just a few recent papers on the problem:

> "Ethereum smart contracts are distributed programs running on top of the Ethereum blockchain. Since program flaws can cause significant monetary losses and can hardly be fixed due to the immutable nature of the blockchain, there is a strong need of automated analysis tools which provide formal security guarantees. Designing such analyzers, however, proved to be challenging and error-prone."[^4]

> "The EVM language is a simple stack-based language ... with one significant difference between the EVM and other virtual machine languages (like Java Bytecode or CLI for .Net programs): the use of the stack for saving the jump addresses instead of having it explicit in the code of the jumping instructions. Static analyzers need the complete control-flow graph (CFG) of the EVM program in order to be able to represent all its execution paths."[^5]

> "Static analysis approaches mostly face the challenge of analyzing compiled Ethereum bytecode... However, due to the intrinsic complexity of Ethereum bytecode (especially in jump resolution), static analysis encounters significant obstacles."[^6]

> "Analyzing contract binaries is vital ... comprising function entry identification and detecting its boundaries... Unfortunately, it is challenging to identify functions ... due to the lack of internal function call statements."[^7]

There is an entire academic literature of complex, incomplete solutions to problems like these that proper control-flow structure render trivial.

### Static Control Flow

**Static control flow** means that the destination of every jump or call is determinable at static analysis time (before execution). This is typically achieved by:

1. Requiring jump destinations to be immediate values (not stack values)
2. Providing explicit call/return opcodes rather than using dynamic jumps for calls
3. Validating that all jump destinations point to valid instruction boundaries

With static control flow:
- The CFG can be constructed in time linear in code size
- Code analysis (security, optimization, verification) becomes tractable
- Compilation to machine code can proceed in a single pass
- Tools for validation and static analysis become practical

## Relationship to Ethereum Scaling

Static control flow is not merely an aesthetic or organizational preference. It has concrete implications for Ethereum's scaling roadmap, particularly around ZK verification, rollups, and future execution layer changes.

### Key Concepts: Traces, Circuits, Witnesses, and Proofs

To understand why static control flow matters for scaling, we need to briefly understand how ZK systems verify computation:

**Execution Traces:** When a transaction executes, it produces an execution trace—a sequence of state changes recording the value of registers, memory, stack, storage, etc. at each step. The trace is a complete record of the computation.

**Circuits:** A circuit is a mathematical model of a computation. For a ZK system, the circuit encodes the rules of the EVM: what states can follow from what prior states, how gas is consumed, which memory accesses are valid, etc. The circuit is a set of polynomial constraints that must all be satisfied.

**Witnesses:** The witness is the data the prover provides to prove that a computation is correct. For an execution trace, the witness includes the trace itself plus auxiliary data that helps prove the constraints are satisfied.

**Proofs:** A ZK proof is a cryptographic proof that the witness satisfies the circuit's constraints, without revealing the witness itself.

The size of the witness (and thus the proof) depends on:
1. The length of the execution trace (how many steps the computation takes)
2. The complexity of the circuit (how many constraints must be checked)

**Dynamic jumps increase both of these.** They force the prover to consider all possible execution paths, making traces longer and circuits more complex.

### Static Control Flow and ZK Rollups

In a **ZK-Rollup**, a sequencer or prover batches many transactions and constructs a ZK proof that all transactions executed correctly. The proof is then submitted to L1, where it is quickly verified. Key implications:

1. **Trace size:** With dynamic jumps, the prover may need to explore many paths before finding the correct one, making traces longer and less efficient.

2. **Circuit complexity:** A circuit covering dynamic jumps must account for all possible jump destinations at each dynamic jump. This significantly increases constraint count.

3. **Proof generation time:** Larger traces and circuits mean more computation for the prover, directly affecting latency and cost.

4. **Hardware requirements:** More complex circuits and longer traces demand more memory and computation, requiring specialized hardware for rollup operators.

Static control flow enables:
- Predictable trace sizes (linear in execution length, not exponential in jump possibilities)
- Simpler circuits (only actual execution paths need constraints)
- Faster proof generation
- Lower hardware requirements for prover operators

### Static Control Flow and Optimistic Rollups

**Optimistic Rollups** assume transactions are valid but require fraud proofs to dispute invalid state roots. A fraud proof is a proof that a specific transaction executed incorrectly. Key implications:

1. **Bytecode validation:** Cleaner bytecode with static control flow enables easier validation of contract behavior.

2. **Dispute resolution:** When a fraud dispute arises, the dispute system must re-execute the contested transaction and prove correctness (or incorrectness). Static control flow makes this re-execution and proof more tractable.

3. **Interactive verification:** Some optimistic rollup designs use interactive verification games. Clear control flow simplifies the game protocol.

### Static Control Flow and Direct Execution

As already discussed, static control flow enables contracts to be compiled to machine code before execution, just-in-time or ahead-of-time.  This is an obvious win for non-ZK clients, whether on L1, L2, or EVM-compatible chains.

### Static Control Flow and RISC-V Migration

There is ongoing discussion within Ethereum research about potentially replacing the EVM with RISC-V or a RISC-V-based execution environment. RISC-V is a standard instruction set architecture which is seeing increasing use in the ZK community.

One currrent strategy for creating a ZK-EVM is to compile an EVM interpreter like evmone or reth to RISC-V for use in a ZK-VM.
Supporting RISC-V directly eliminates the overhead of the EVM interpreter.

An EVM with static control flow opens up another strategy -- compile the EVM code to RISC-V code.  That does require that the EVM compiler be correct, but we already have solutions for that -- formal specifications like KEVM allow for "correct by construction" compilers.

A missing piece in this puzzle is that RISC-V is a 32-bit or 64-bit architecture, but the current EVM is a 256-bit architecture.  For that purpose we have the EVM64 proposals.

### The Scaling Picture

Static control flow is not a silver bullet for scaling. But it is a **foundational piece** that enables:

- Efficient ZK proof generation for ZK-Rollups
- Cleaner fraud proofs for Optimistic Rollups
- Faster execution via compilation for non-ZK clients
- Future migrations to other execution environments (RISC-V, etc.)
- Better tooling and security analysis for contract developers

By making control flow explicit and enforceable, the EVM becomes compatible with the full ecosystem of optimization and analysis techniques that other VMs and processor designs have leveraged for decades.

## Conclusion

Static control flow has been a cornerstone of efficient computation since Babbage and Turing. The EVM's reliance on dynamic jumps is an anomaly among virtual machines and a significant barrier to analysis, compilation, and scaling. Proposals to introduce explicit call/return opcodes and enforce static jumps (like EIP-7979, EIP-8013, and EOF Functions) bring the EVM in line with industry best practices and unlock a range of optimizations critical to Ethereum's scaling roadmap.

## References

[^1]: Menabre, L.F. Sketch of The Analytical Engine Invented by Charles Babbage. Bibliothèque Universelle de Genève, No. 82, October 1842

[^2]: Turing, A.M. Computing Machinery and Intelligence. Mind, Volume LIX, Issue 236, October 1950

[^3]: Carpenter, B.E. et al. The other Turing machine. The Computer Journal, Volume 20, Issue 3, January 1977

[^4]: Schneidewind, Clara et al. The Good, the Bad and the Ugly: Pitfalls and Best Practices in Automated Sound Static Analysis of Ethereum Smart Contracts. DOI: 10.48550/arXiv.2101.05735

[^5]: Albert, Elvira et al. Analyzing Smart Contracts: From EVM to a sound Control-Flow Graph. DOI: 10.48550/arXiv.2004.14437

[^6]: Contro, Filippo et al. EtherSolve: Computing an Accurate Control-Flow Graph from Ethereum Bytecode. DOI: 10.48550/arXiv.2103.09113

[^7]: He, Jiahao et al. Neural-FEBI: Accurate Function Identification in Ethereum Virtual Machine Bytecode. DOI: 10.48550/arXiv.2301.12695
