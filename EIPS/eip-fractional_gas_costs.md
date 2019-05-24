---
eip: 2045
title: Fractional gas costs for EVM opcodes
author: Casey Detrio (@cdetrio)
discussions-to: https://ethereum-magicians.org/t/eip-2045-fractional-gas-costs/3311
status: Draft
type: Standards Track
category Core
created: 2019-05-17
---

## Abstract
According to recent benchmarks, EVM opcodes for computation (ADD, SUB, MUL, etc.) are generally overpriced relative to opcodes for storage I/O (SLOAD, SSTORE, etc.). Currently the minimum gas cost is 1 (i.e. one unit of gas), and most computational opcodes have a cost near to 1 (e.g. 3, 5, or 8), so the range in possible cost reduction is limited. A new minimum unit of gas, called a "particle", which is a fraction of 1 gas, would expand the range of gas costs and thus enable reductions below the current minimum.

## Motivation
The transaction capacity of an Ethereum block is determined by the gas cost of transactions relative to the block gas limit. One way to boost the transaction capacity is to raise the block gas limit. Unfortunately, raising the block gas limit would also increase the rate of state growth, unless the costs of state-expanding storage opcodes (SSTORE, CREATE, etc.) are simultaneously increased to the same proportion. Increasing the cost of storage opcodes may have adverse side effects, such as shifting the economic assumptions around gas fees of deployed contracts, or possibly breaking invariants in current contract executions (as mentioned in EIP-2035 [REF/LINK HERE], more research is needed on the potential effects of increasing the cost of storage opcodes).

Another way to boost the transaction capacity of a block is to reduce the gas cost of transactions. Reducing the gas costs of computational opcodes while keeping the cost of storage opcodes the same, is effectively equivalent to raising the block gas limit and simultaneously increasing the cost of storage opcodes. However, reducing the cost of computational opcodes might avoid the adverse side effects of an increase in cost of storage opcodes (again, more research is needed on this topic).

Currently, computational opcode costs are already too close to the minimum unit of 1 gas to achieve the large degree of cost reductions that recent benchmarks<sup>[1](#evmbenchmarks)</sup> indicate would be needed to tune opcode gas costs to the performance of optimized EVM implementations. A smaller minimum unit called a "particle"<sup>[2](#particle)</sup>, which is a fraction of 1 gas, would enable large cost reductions.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

A new gas counter `particlesUsed` is added to the EVM, in addition to the existing gas counter `gasUsed`. The unit 1 gas is equal to 10000 particles (`PARTICLES_PER_GAS`). The `particlesUsed` counter is only increased for opcodes priced in particles (i.e. opcodes that cost less than 1 gas). If `particlesUsed` exceeds 1 gas, then 1 gas is added to `gasUsed` (and deducted from `particlesUsed`).

Where the current gas logic looks like this:
```
def vm_execute(ext, msg, code):
    # Initialize stack, memory, program counter, etc
    compustate = Compustate(gas=msg.gas)
    codelen = len(code)

    while compustate.pc < codelen:
        opcode = code[compustate.pc]
        compustate.pc += 1

        compustate.gasUsed += opcode.gas_fee

        # out of gas error
        if compustate.gasUsed > compustate.gasLimit:
            return vm_exception('OUT OF GAS')

        if op == 'STOP':
            return peaceful_exit()
        elif op == 'ADD':
            stk.append(stk.pop() + stk.pop())
        elif op == 'SUB':
            stk.append(stk.pop() - stk.pop())
        elif op == 'MUL':
            stk.append(stk.pop() * stk.pop())

.....
```

The new gas logic using particles might look like this:
```
PARTICLES_PER_GAS = 10000

def vm_execute(ext, msg, code):
    # Initialize stack, memory, program counter, etc
    compustate = Compustate(gas=msg.gas)
    codelen = len(code)

    while compustate.pc < codelen:
        opcode = code[compustate.pc]
        compustate.pc += 1

        if opcode.gas_fee:
            compustate.gasUsed += opcode.gas_fee
        elif opcode.particle_fee:
            compustate.particlesUsed += opcode.particle_fee
            if compustate.particlesUsed >= PARTICLES_PER_GAS:
                # particlesUsed will be between 1 and 2 gas (over 10000 but under 20000)
                compustate.gasUsed += 1
                # remainder stays in particle counter
                compustate.particlesUsed = compustate.particlesUsed % PARTICLES_PER_GAS

        # out of gas error
        if compustate.gasUsed > compustate.gasLimit:
            return vm_exception('OUT OF GAS')

        if op == 'STOP':
            return peaceful_exit()
        elif op == 'ADD':
            stk.append(stk.pop() + stk.pop())
        elif op == 'SUB':
            stk.append(stk.pop() - stk.pop())
        elif op == 'MUL':
            stk.append(stk.pop() * stk.pop())

.....
```

The above pseudocode is written for clarity. A more performant implementation might instead keep a single `gasUsed` counter, multiply opcode costs by 10000 and the `gasLimit` by 10000, and only compare the higher-order bits when checking if `gasUsed` is less than `gasLimit`. It may also be more performant to use a `PARTICLES_PER_GAS` ratio that is a power of 2 (such as 8192 or 16384) instead of 10000; the spec above is a draft and updates in response to feedback are expected.

#### Opcode cost changes
Many computational opcodes will undergo a cost reduction, with new costs suggested by benchmark analyses. For example, the cost of DUP and SWAP are reduced from 3 gas to 3000 particles. The cost of `ADD` and `SUB` are reduced from 3 gas to 6000 particles. The cost of `MUL` is reduced from 5 gas to 5000 particles.

## Rationale
Adoption of fractional gas costs should only be an implementation detail inside the EVM, and not alter the current user experience around transaction gas limits and block gas limits. The concept of `particles` need not be exposed to Ethereum users nor most contract authors, but only to EVM implementers and contract developers concerned with optimized gas usage. Furthermore, only the EVM logic for charging gas per opcode executed should be affected by this change. All other contexts dealing with gas and gas limits, such as block headers and transaction formats, should be unaffected.

## Backwards Compatibility
This change is not backwards compatible and requires a hard fork to be activated.

## Test Cases
TODO

## Implementation
TODO

## References
<a name="evmbenchmarks">1</a>. https://github.com/ewasm/benchmarking

<a name="particle">2</a>. The term "particle" was inspired by a proposal for [Ewasm gas costs](https://github.com/ewasm/design/blob/e77d8e3de42784f40a803a23f58ef06881142d9f/determining_wasm_gas_costs.md).


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
