---
title: CALLSTATUS instruction
description: Instruction that returns whether the last call of the frame succeeded, reverted or halted, and whether a halt occurred below it
author: Stavros Vlachakis (@svlachakis)
discussions-to: https://ethereum-magicians.org/t/TBD
status: Draft
type: Standards Track
category: Core
created: 2026-10-25
---

## Abstract

This EIP adds the `CALLSTATUS` instruction. It pushes the completion status of the most recent `CALL`, `CALLCODE`, `DELEGATECALL`, `STATICCALL`, `CREATE` or `CREATE2` executed in the current frame, as three bits: whether the callee reverted, whether it halted exceptionally or failed consuming its gas, and whether such a failure occurred in a frame below the callee. The values are `0` (success), `1` (reverted or not started), `2` (halted exceptionally, or collided), `4` (succeeded after a halt below) and `5` (reverted after a halt below). A value of `2` or more means that gas forwarded somewhere in the line of the call, if any, was consumed by an exceptional halt or an address collision. The instruction reads a per-frame register, pops nothing, and costs 2 gas.

## Motivation

A contract that continues after a failed call needs to know why the call failed. A failure that the callee signalled with `REVERT` can be recorded as final. A failure caused by too little gas must not be, because the transaction sender controls the gas and can use an underfunded call to make the contract record a false failure, for example to burn a retry or to mark a payment as rejected.

Today the EVM gives the caller no direct evidence of the cause. The caller sees a success flag of `0`, the return data, and the gas it has left. Contracts therefore infer the cause from gas arithmetic: they compare `GAS` after the call with a threshold derived from the gas they forwarded, or they rely on the failure handler itself running out of gas. Such checks hold only under assumptions about the gas schedule: that an exceptional halt consumes all forwarded gas, that no gas returns to the caller before the check, and that the costs of the operations in the handler do not change. Each repricing fork has broken thresholds of this kind, and the separate metering of state creation, with gas that a frame can draw from a transaction-wide reservoir, weakens `GAS` further as evidence of what happened in the callee. Return data does not help either: a `REVERT` with no data and an exceptional halt both leave empty return data, and a wrapper that reverts with a reason after a failed call hides the halt behind the reason.

The EVM knows at every frame boundary whether the frame halted, and it can carry that fact up through the frames above, whether they revert, return, or handle the failure and go on. `CALLSTATUS` exposes it, so that a contract can treat a status of `2` or more as "not final" and stop depending on the gas schedule.

## Specification

### Parameters

| Constant | Value |
|---|---|
| `CALLSTATUS_OPCODE` | `0x4D` |
| `CALLSTATUS_GAS` | `2` |

### Status values

A status is the sum of up to three bits:

| Bit | Value | Meaning |
|---|---|---|
| 0 | `1` | the operation reverted, or was not started and returned its gas |
| 1 | `2` | the operation halted exceptionally, or failed in a way that consumed the gas it would have forwarded |
| 2 | `4` | an operation in a frame below halted exceptionally or had an address collision |

The values that occur are `0`, `1`, `2`, `4` and `5`. Bit 1 is never combined with another bit.

### Per-frame registers

Every frame of execution has a register `call_status`, initialised to `0`, and a flag `halt_seen`, initialised to `false`, when the frame starts. `DELEGATECALL` and `CALLCODE` start a frame of their own, with its own registers, like `CALL`, `STATICCALL`, `CREATE` and `CREATE2`. The registers of a frame are not visible to, and not changed by, the execution of any other frame, except as stated below for the completion of a child frame.

At the completion of each `CALL` (`0xF1`), `CALLCODE` (`0xF2`), `DELEGATECALL` (`0xF4`), `STATICCALL` (`0xFA`), `CREATE` (`0xF0`) and `CREATE2` (`0xF5`) instruction, the executing frame sets `call_status` to:

- `1` if no child frame was started because the operation failed before it, and the gas that would have been forwarded is returned: insufficient balance for the value transfer or the endowment, the call depth limit, or, for `CREATE` and `CREATE2`, a nonce overflow of the creating account.
- `2` if, for `CREATE` and `CREATE2`, no child frame was started because of an address collision, which is checked only after the conditions above. The gas that would have been forwarded is consumed.
- `2` if a child frame was started and halted exceptionally, whatever the cause: out of gas, an invalid instruction, an invalid jump destination, a stack underflow or overflow, a write in a static context, an out-of-bounds return data access, a precompiled contract that fails, and, for `CREATE` and `CREATE2`, a failed code deposit. The gas forwarded to the child frame is consumed.
- `1` if a child frame was started and completed with `REVERT`, and the child's `halt_seen` is `false`.
- `5` if a child frame was started and completed with `REVERT`, and the child's `halt_seen` is `true`.
- `0` if a child frame was started and completed successfully, and the child's `halt_seen` is `false`. Successful completion is `STOP`, `RETURN` or `SELFDESTRUCT`, running past the end of the code, executing no code because the target has none or is delegated to a precompiled contract, or, for a call to a precompiled contract, completing without error. For `CREATE` and `CREATE2`, success includes the code deposit.
- `4` if a child frame was started and completed successfully, and the child's `halt_seen` is `true`.

After setting `call_status`, the executing frame sets `halt_seen` to `true` if `call_status` is `2` or more. `halt_seen` is never set back to `false`.

A child that halted exceptionally reports `2` whatever its own registers hold. A precompiled contract runs no calls, so its `halt_seen` is `false`.

If the instruction halts the executing frame itself, for example a `CALL` with value in a static context, insufficient gas for the memory expansion, or initcode longer than the limit, the frame ends and its registers have no further effect.

No other instruction changes the registers, and `CALLSTATUS` does not reset them.

### The `CALLSTATUS` instruction

`CALLSTATUS` (`0x4D`) pops no value from the stack and pushes the value of the `call_status` register of the executing frame. It charges `CALLSTATUS_GAS`. It is allowed in a static context. It fails with a stack overflow in the usual way.

### Relation to the success flag and the return data

The status values are consistent with what the instructions push: the success flag of `CALL`, `CALLCODE`, `DELEGATECALL` and `STATICCALL` is `1` if and only if bits 0 and 1 of the status are clear, that is, the status is `0` or `4`, and the address that `CREATE` and `CREATE2` push is non-zero if and only if the status is `0` or `4`. The return data buffer is set by the same instructions as before, and `CALLSTATUS` does not change it.

A status of `2` or more means that the gas forwarded to an operation in the line of the call, in the callee or in any frame below it, if any, was consumed by an exceptional halt or by an address collision. A status of `1` is the only code of a failure in whose line no such thing happened. A later proposal that defines further values keeps these two properties, so contracts test `CALLSTATUS >= 2` and not for single values.

## Rationale

### A separate instruction instead of a changed success flag

The success flag of the call instructions cannot carry more than one bit. Deployed code tests it as a boolean, in both directions, so a status code in its place would change the behaviour of existing contracts. [EIP-7069](./eip-7069.md) replaced the flag with status codes in a new set of call instructions. This EIP keeps the legacy instructions unchanged and adds one instruction that reads a register, in the way that `RETURNDATASIZE` exposes the return data of the last call.

### The codes

`0`, `1` and `2` are the codes of [EIP-7069](./eip-7069.md): success, revert, failure. The distinction between `1` and `2` is whether the forwarded gas was consumed. A `REVERT` and an operation that was not started both return the unused gas, so both are `1`. An exceptional halt of any kind, an address collision and a failed code deposit all consume the forwarded gas, so all are `2`. The cause of an exceptional halt is not exposed: the caller cannot verify it, and the response that protects the caller is the same for every cause.

### The halt-below bit

Most contracts are reached through intermediaries: a proxy that delegates to an implementation, a router, a wrapper that calls and checks, a signature checker that returns `false` on any failure of the call it makes, a batch that lets some calls fail. An exceptional halt two or more frames down reaches the caller in whatever form the intermediaries give it: a revert with the empty return data of the halt, a revert with a reason of their own, a revert after a further call, or a successful return that carries `false`. If the status reported only the direct callee's own ending, every one of these shapes would read as a deliberate failure, and the caller would be back to gas arithmetic for the most common call shapes on the network.

The `halt_seen` flag therefore records whether any operation of a frame, or of any frame below it, halted exceptionally or consumed its forwarded gas, and the flag travels up through every frame boundary, whether the frame reverts or returns. A frame that reverts after such a halt reports `5`, and a frame that returns after one reports `4`. The flag is set by a status of `2` or more, so a call to a precompiled contract between the halt and the revert, which compilers and libraries emit for hashing or signature recovery, does not break the chain.

The price is that some deliberate failures carry the bit too: a frame that makes a low-gas probe call that halts, for example to test whether an address has code, and later reverts for a reason of its own, reports `5`. The caller then treats the failure as not final, which is the safe direction, and still has the revert data. A frame that has handled a halt and returns a result reports `4` to its caller; whether the caller finalises on that result is the caller's decision, based on how far it trusts the frame's own handling.

### Why a success with a halt below is visible

A status of `4` tells the caller that the callee reported success although something in its line halted, for example a check that returned `false` because the call it made ran out of gas. A caller that depends on the result can then verify it or treat the operation as not final, instead of taking the `false` as final. Reporting it also keeps the rule simple: the flag travels through every frame boundary in the same way.

### A register rather than a stack value

A register costs nothing for calls whose status is never read, keeps the stack effects of the call instructions unchanged, and gives the value to compilers through one instruction with no arguments. The register starts at `0` so that it has a defined value before the first call of a frame; a contract reads it after a call.

### Opcode number

`0x4D` is in the range of instructions that read information about the environment of the frame, next to `SELFBALANCE`, `BASEFEE` and `BLOBHASH`. The number is tentative and may change to avoid a collision.

### Interaction with multidimensional gas

With state creation metered separately from execution, a frame may draw part of the cost of a new storage slot or account from a reservoir that `GAS` does not show, and gas may return to a reservoir when state is cleared or a frame reverts. Checks that infer the cause of a failure from `GAS` must then account for the reservoir, and a fixed gas budget that was sufficient before a repricing may no longer be. `CALLSTATUS` makes none of this matter to the inference: whatever the schedule, a status of `2` or more means that gas was consumed by a halt in the line of the call. Transaction types that execute several frames may expose the same codes for completed frames; that is left to their specifications.

## Backwards Compatibility

`0x4D` is currently an undefined instruction, so any deployed code that executes it halts exceptionally. No deployed contract can depend on that outcome in a way this EIP changes, as with every instruction added at an undefined opcode. The instruction is not a `PUSH`, so jump destination analysis does not change. The behaviour of the call instructions, their gas costs and the return data buffer are unchanged. The registers are frame-local and need no journaling: a child's registers are read by the parent at the child's completion, and end with the child.

## Test Cases

All cases execute `CALLSTATUS` in the calling frame right after the call and compare the pushed value. Unless stated, calls forward all available gas and transfer no value. "Bubbles" means that the frame reverts with the return data of its last call. "Halting callee" means a contract that executes `INVALID`.

| # | Call | Callee or initcode | Expected `CALLSTATUS` |
|---|---|---|---|
| 1 | none yet | - | `0` |
| 2 | `CALL` | `STOP` | `0` |
| 3 | `CALL` | `RETURN` with 32 bytes | `0` |
| 4 | `CALL` | code that ends without `STOP` | `0` |
| 5 | `CALL` | `SELFDESTRUCT` | `0` |
| 6 | `CALL` to an account with no code, with value | - | `0` |
| 7 | `CALL` to an account delegated to a precompiled contract | - | `0` |
| 8 | `CALL` to an account delegated to a contract | `REVERT` in the delegated code | `1` |
| 9 | `CALL` | `REVERT` with no data | `1` |
| 10 | `CALL` | `REVERT` with data | `1` |
| 11 | `CALL` with gas `0` | `STOP` | `0` |
| 12 | `CALL` with gas `0` | `PUSH1 0` | `2` |
| 13 | `CALL` with gas `1000` | loop until out of gas | `2` |
| 14 | `CALL` with value and gas `0` | `SSTORE` within the stipend | `2` |
| 15 | `CALL` | `INVALID` (`0xFE`) | `2` |
| 16 | `CALL` | `JUMP` to a non-`JUMPDEST` | `2` |
| 17 | `CALL` | `POP` on an empty stack | `2` |
| 18 | `CALL` | `RETURNDATACOPY` past the end of the return data | `2` |
| 19 | `CALL` with value above the caller's balance | - | `1` |
| 20 | `CALLCODE` with value above the caller's balance | - | `1` |
| 21 | `CALL` at depth 1024 | - | `1` |
| 22 | `DELEGATECALL` at depth 1024 | - | `1` |
| 23 | `STATICCALL` | `SSTORE` | `2` |
| 24 | `STATICCALL` | `CALL` with value | `2` |
| 25 | `DELEGATECALL` | `REVERT` | `1` |
| 26 | `CALLCODE` | `STOP` | `0` |
| 27 | `CALL` to the identity precompile (`0x04`) | - | `0` |
| 28 | `CALL` to `ecrecover` (`0x01`) with input that recovers nothing | - | `0` |
| 29 | `CALL` to the `modexp` precompile (`0x05`) with less gas than its cost | - | `2` |
| 30 | `CREATE` | initcode `REVERT` | `1` |
| 31 | `CREATE` | initcode returns `MAX_CODE_SIZE + 1` bytes of code | `2` |
| 32 | `CREATE` | initcode returns code starting with `0xEF` | `2` |
| 33 | `CREATE` | initcode returns code whose deposit cost exceeds the gas left | `2` |
| 34 | `CREATE` to an address that already has a nonce | - | `2` |
| 35 | `CREATE2` to an address that already has code | - | `2` |
| 36 | a `CALL` to `STOP`, then `CREATE2` to an address that already has code | - | `2` |
| 37 | `CREATE` from an account with nonce `2**64 - 1` | - | `1` |
| 38 | `CREATE` with endowment above the creator's balance | - | `1` |
| 39 | `CREATE` | initcode `STOP` | `0` |
| 40 | `CREATE` with initcode longer than `MAX_INITCODE_SIZE` | - | the calling frame halts |
| 41 | `CREATE` in a static context | - | the calling frame halts |
| 42 | `CALL` with value, in a static context | - | the calling frame halts |
| 43 | two calls: halting callee, then `STOP` | - | `0` |
| 44 | two calls: `STOP`, then `REVERT` | - | `1` |
| 45 | `CALL` | callee calls a halting callee, then bubbles | `5` |
| 46 | `CALL` | callee calls a halting callee, then reverts with a reason string | `5` |
| 47 | `CALL` | callee calls a contract that reverts with data, then bubbles | `1` |
| 48 | `CALL` | callee calls a halting callee, then calls `sha256` (`0x02`), then reverts | `5` |
| 49 | `CALL` | callee calls a halting callee, then calls a contract that `STOP`s, then reverts | `5` |
| 50 | `CALL` | callee calls a halting callee, then returns `false` | `4` |
| 51 | `CALL` | callee calls the contract of case 50, reads `false`, and reverts | `5` |
| 52 | `CALL` | callee calls a halting callee, then executes `INVALID` itself | `2` |
| 53 | `CALL` to a proxy | proxy delegates to code that calls a contract which runs out of gas; the implementation bubbles; the proxy bubbles | `5` |
| 54 | `CALL` to a proxy behind a proxy | as 53, one level deeper | `5` |
| 55 | `CREATE` | initcode calls a halting callee, then bubbles | `5` |
| 56 | `CREATE` | initcode calls a halting callee, then returns code | `4` |
| 57 | `CALLSTATUS` in a static context | - | the register value |
| 58 | `CALLSTATUS` on a full stack | - | exceptional halt |

In case 45 the callee observes `2` before it reverts. In case 51 the callee observes `4` before it reverts. In cases 53 and 54 each delegated frame observes `2` or `5` before it reverts. Cases 43 and 48 show that the register reports the last call, while the flag keeps the halt.

## Reference Implementation

Pseudocode in the style of the execution specifications. The call and create logic already distinguishes the outcomes; the change records them in the registers of the calling frame.

```python
CALLSTATUS_GAS = 2

class Evm:
    ...
    call_status: int = 0        # per frame, initialised at frame start
    halt_seen: bool = False     # per frame, initialised at frame start

def call_status(evm: Evm) -> None:
    charge_gas(evm, CALLSTATUS_GAS)
    push(evm.stack, U256(evm.call_status))
    evm.pc += 1

def set_call_status(evm: Evm, status: int) -> None:
    evm.call_status = status
    if status >= 2:
        evm.halt_seen = True

# In the shared call and create logic, where the operation fails before a
# child frame is started and returns its gas (insufficient balance, depth
# limit, nonce overflow):
#     evm.gas_left += forwarded_gas
#     set_call_status(evm, 1)
#     push(evm.stack, U256(0))
#
# In the create logic, on an address collision (no child frame, gas consumed):
#     increment_nonce(...)
#     set_call_status(evm, 2)
#     push(evm.stack, U256(0))
#
# Where a child frame has completed:
def record_child_outcome(evm: Evm, child: Evm) -> None:
    if child.error is None:
        set_call_status(evm, 4 if child.halt_seen else 0)
    elif isinstance(child.error, Revert):
        set_call_status(evm, 5 if child.halt_seen else 1)
    else:
        set_call_status(evm, 2)
```

A failed code deposit is an exceptional halt of the create frame in the execution specifications, so it sets `2` through `record_child_outcome`. A precompiled contract is a child with `halt_seen` equal to `false`, so it sets `0` or `2`.

## Security Considerations

### What the status tells, and what it does not

The status reports outcomes, not causes. A status of `2` or more means that the gas forwarded somewhere in the line of the call, if any, was consumed by an exceptional halt or an address collision. It does not say whether the halt was caused by the gas the transaction sender supplied, by a gas budget that the caller chose, or by the callee on purpose.

With `CALLSTATUS`, a transaction sender, who controls only the gas, cannot make a caller see `1` for a failure whose line contains a halt, whether the halted frame is the caller's direct callee or a frame behind proxies, wrappers, handlers or checks that swallow failures. Two gas-dependent outcomes stay under the sender's control, because no halt occurs in them: a callee whose revert depends on the gas it had, for example because it read `GAS` and reverted on purpose, or because an arithmetic check on `GAS` failed, and a callee that returns a result that depends on the gas it had. A gas guard that wants its outcome reported as a halt should halt, with `INVALID`, rather than revert. A caller that depends on a returned value should treat a status of `4` as a reason to verify the value or to treat the operation as not final.

### What the status does not change for a caller with a fixed budget

A caller that forwards a fixed gas budget and observes `2` or more learns that the budget did not suffice for the work, or that the callee halted on purpose. It does not learn whether the budget was adequate. A fixed budget that was sufficient under a previous gas schedule may be insufficient under the current one. Such a caller should check before the call that it can forward the full budget, and should decide what a halt means under the current schedule. A caller that forwards all available gas and observes `2` or more knows that the gas it had was consumed, and that the sender could have supplied more; treating the failure as not final is the safe response.

### Finality and liveness

A callee can produce `2` on purpose with `INVALID`, and a frame below it can produce `4` or `5` at the caller with one cheap halting call. The gas consumed is paid by the transaction sender, so a callee could already make a failure look like out of gas at no cost to itself; the instruction gives a callee no new ability. It does make "not final" cheap to signal. Contracts should therefore decide finality so that neither party can keep an item pending for ever or burn its retries:

- A batch that skips failed items should not revert the whole batch on a status of `2` or more; it should mark the item as retryable.
- A bound on retries should be a deadline, in time or blocks, after which the item is finalised as failed, not a counter of attempts, because a sender can produce any number of attempts that end in `2` or more by choosing the gas.
- A failure whose line contains no halt, status `1`, can be finalised at once.

### Intermediaries and probes

For a chain of calls A -> B -> C where C halts exceptionally, B observes `2`. If B reverts at any later point without halting, A observes `5`. If B returns, A observes `4`. If B halts exceptionally itself, A observes `2`. B cannot report `1` or `0` to A after C's halt, whatever it does in between. A B that has handled the halt returns a result, and A sees `4`; A finalises on that result only as far as it trusts B's handling.

A frame that makes a deliberate low-gas probe call that halts, and later reverts for a reason of its own, reports `5` to its caller. The caller then treats the failure as not final, which is the safe direction, and still has the revert data. Contracts that make such probes should prefer forms that do not halt, such as `EXTCODESIZE`, or a call with enough gas for the target to complete or to revert cleanly, when the information they need allows it.

### Gas and consensus

The instruction does not change how much gas a call needs. A caller that forwards too little gas still fails and observes `2`; the status only tells it so. The registers add one word and one bit per frame, no persistent state, and no journaling, because they end with the frame that holds them. Every client sets them at the same points, including the operations that start no child frame: the failures that return the gas and the address collision of `CREATE` and `CREATE2`. A client that set the register only at the completion of a child frame would leave a stale value in those cases and diverge.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
