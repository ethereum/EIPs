---
title: RESERVOIR Opcode
description: Adds an EVM opcode that exposes the remaining state gas unavailable through GAS.
author: Javad Rajabzadeh (@ja7ad)
discussions-to:
status: Draft
type: Standards Track
category: Core
created: 2026-10-23
requires: 2780, 7702, 8037, 8141
---

## Abstract

This EIP introduces a new opcode, `RESERVOIR` (`0x4d`), that pushes the state gas available to the executing frame which is not included in the value returned by `GAS`. For transactions that use the reservoir model of [EIP-8037](./eip-8037.md) this is the frame's `state_gas_reservoir`. Inside an [EIP-8141](./eip-8141.md) frame transaction it is the frame's `state_gas_left`. Together with `GAS`, the opcode lets contracts read their full remaining budget and measure the gas consumed by a code region or a call, including state-gas consumption that GAS does not report.

## Motivation

EIP-8037 splits the gas of a transaction into `gas_left` and a `state_gas_reservoir` that holds the part of `tx.gas` above `TX_MAX_GAS_LIMIT`. State creation draws from the reservoir first and spills into `gas_left` once the reservoir is empty. The reservoir is passed in full to every child frame, and the `GAS` opcode reports `gas_left` only.

Contracts therefore cannot observe their remaining state-gas budget or measure the state gas consumed by a callee. Protocols that meter sub-calls by subtracting two `gasleft()` readings, such as the [ERC-4337](./eip-4337.md) `EntryPoint`, under-count state gas whenever the reservoir pays for it: a call that creates one storage slot appears 97,920 gas cheaper when the reservoir funds the slot than when `gas_left` does. EIP-8037 points out this limitation and asks such protocols to account for state gas explicitly, but no instruction exposes the quantity they would need.

The same gap affects callers of untrusted code. The `gas` argument of `CALL` bounds only execution gas, so a callee can spend the caller's entire remaining reservoir while `gasleft()` barely moves. Without visibility into the reservoir, the caller cannot notice.

EIP-8141 exposes a comparable value through `TXPARAM(TXPARAM_STATE_GAS_LEFT)`, but its introspection instructions are defined only inside frame transactions and halt elsewhere. Both transaction models will be in use at the same time, and library code rarely knows which one it runs under. A single instruction that returns the state budget in either model lets such code be written once.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Parameters

| Constant | Value |
| --- | --- |
| `RESERVOIR_OPCODE` | `0x4d` |
| `RESERVOIR_GAS_COST` | `2` |

### Behavior

A new instruction `RESERVOIR` is introduced at `RESERVOIR_OPCODE`. It takes no stack input and pushes one value, `state_budget`, defined below.

Execution of `RESERVOIR` MUST:

1. charge `RESERVOIR_GAS_COST` as execution gas to the `gas_left` of the current call frame, as `GAS` does, and halt exceptionally with out-of-gas if `gas_left` is less than `RESERVOIR_GAS_COST`. The charge MUST NOT be drawn from any state gas pool and MUST NOT change any state gas counter;
2. halt exceptionally with a stack overflow if the stack already holds 1024 items;
3. push `state_budget` as an unsigned 256-bit integer.

`RESERVOIR` has no other effect. It MUST be executable in a static context. It MUST NOT be enabled in a fork in which EIP-8037 is not active.

### Definition of `state_budget`

`state_budget` is the state gas available to the executing call frame that is not included in the value returned by `GAS`:

| Execution context | `state_budget` |
| --- | --- |
| Transaction using the EIP-8037 reservoir model | `state_gas_reservoir` of the executing call frame |
| EIP-8141 frame transaction | `state_gas_left` of the currently executing frame, the value `TXPARAM` returns for `TXPARAM_STATE_GAS_LEFT` |
| System call | `state_gas_reservoir` that EIP-8037 places in the system call's budget |

This EIP changes no accounting rule of EIP-8037 or EIP-8141. The values below follow from those rules and are listed to help implementers.

### Values under the reservoir model

Let `G0` and `R0` be the values computed when EIP-8037 initializes the transaction's gas:

```python
evm_gas = tx.gas - intrinsic_gas
G0 = min(TX_MAX_GAS_LIMIT - intrinsic_gas, evm_gas)   # gas_left
R0 = evm_gas - G0                                   # max(0, tx.gas - TX_MAX_GAS_LIMIT)
```

Let `P` be the state gas charged in the pre-execution phase of [EIP-2780](./eip-2780.md): `STATE_BYTES_PER_NEW_ACCOUNT × CPSB` for the deployment address of a contract-creation transaction, and the `STATE_BYTES_PER_NEW_ACCOUNT × CPSB` and `STATE_BYTES_PER_AUTH_BASE × CPSB` charges applied to [EIP-7702](./eip-7702.md) authorizations. Since state charges draw from the reservoir first, `RESERVOIR` returns the values below, none of which exceeds `TX_MAX_TOTAL_GAS_LIMIT`:

| Situation | `RESERVOIR` returns |
| --- | --- |
| First instruction of the top-level frame | `max(0, R0 - P)`. At that point `gas_left` is `G0 - max(0, P - R0)` |
| First instruction of a frame entered by `CALL`, `CALLCODE`, `DELEGATECALL`, `STATICCALL`, `CREATE` or `CREATE2` | The caller's whole reservoir at the time of the call, after any account creation charge made by the call. The 63/64 rule does not apply to it |
| Caller, after a child frame succeeds | The child's final reservoir, after the merge step of EIP-8037 |
| Caller, after a child frame reverts or halts exceptionally | The reservoir restored by the rollback rules of EIP-8037 |
| Caller, after a call that fails before the child frame starts | Unchanged |
| After a state charge | Reduced by the part of the charge the reservoir covered, and zero if the charge exceeded it |
| After a state gas refill | Increased by the part of the refill not credited to `gas_left` |

### Values inside frame transactions

Inside a frame transaction, `RESERVOIR` returns the `state_gas_left` of the currently executing frame. All call frames within that frame share the pool, so a child call frame reads the same value as its caller. State charges are paid from this pool only, so a state charge of `c` can succeed only if `RESERVOIR` is at least `c`. A refill of a charge made by an earlier frame is credited to that frame's receipt and not to the current pool, so it does not change the value. After a call frame reverts or halts exceptionally, the value is the one restored by the journaling rules of EIP-8141.

### Relationship to `GAS`

`GAS` is unchanged. In both models, `GAS + RESERVOIR` is the remaining budget of the call frame. Over a code region without sub-calls, its decrease is the execution gas charged plus the net state gas charged, whichever pool paid. Under the reservoir model, the caller's decrease across a call equals the gas the call consumed, including refills made inside the call and the gas burned by a halted child.

`GAS` and `RESERVOIR` are separate instructions, so a combined reading is not atomic. If `GAS` returns `g` and the next instruction, `RESERVOIR`, returns `r`, the budget after `RESERVOIR` is `g - 2 + r`. Measuring a region with a `GAS RESERVOIR` pair at each end adds a fixed overhead of 4 execution gas, plus the cost of any instructions that store the readings.

## Rationale

### Exposing only the state budget

`gas_left` is already observable. The state budget is the only part of a frame's budget that contracts cannot read, so a single instruction returning it completes the picture. Under the reservoir model, state gas that spilled into `gas_left` has already been deducted from `GAS`, and refills return it to a pool that `GAS` or `RESERVOIR` reports. Exposing the spill or the cumulative state gas used would add no information that the use cases need, and it would tie contracts to internal counters that later proposals may change.

### Behavior in frame transactions

Three behaviors were considered for `RESERVOIR` in a frame transaction:

1. Return the frame's `state_gas_left`. This is chosen. In both models it means "state gas available that `GAS` does not report", so code computing `GAS + RESERVOIR`, or checking that a state charge is affordable, works unchanged.
2. Return zero. This would wrongly suggest that no state gas is available beyond `gas_left`, while in a frame transaction state charges cannot be paid from `gas_left` at all.
3. Halt, as the EIP-8141 introspection instructions do outside frame transactions. Code would then need to know the transaction type before reading its own budget, and no instruction would be safe in both models.

With the chosen behavior, `RESERVOIR` and `TXPARAM(TXPARAM_STATE_GAS_LEFT)` return the same value in frame transactions. Whether both instructions should remain once EIP-8141 is adopted is left to coordination with its authors. `TXPARAM` alone is not sufficient, because a library that calls it halts in every transaction that uses the reservoir model. For example, the metering pattern below works in both models only if `reservoir()` compiles to `RESERVOIR`:

```python
before = gasleft() + reservoir()
target.call(data)
used = before - (gasleft() + reservoir())   # may be negative, see Security Considerations
```

### Measurement, not attribution

`GAS + RESERVOIR` measures the net change of a frame's budget. It does not decide how shared costs are split when independent operations run in one transaction. If one operation creates a storage slot and a later one clears it, the second operation receives the refill and its measured consumption is negative. Bundling protocols such as the ERC-4337 `EntryPoint` get exact measurements from `RESERVOIR`, but charging users for reservoir-funded state gas, and crediting refills of other users' charges, remain policy decisions for those protocols.

### Opcode byte

The `0x40` to `0x4f` range holds block and transaction environment values, which matches the nature of `RESERVOIR`. `0x4a` is `BLOBBASEFEE` ([EIP-7516](./eip-7516.md)) and `0x4b` is `SLOTNUM` ([EIP-7843](./eip-7843.md)). `0x4c` is proposed as `TXINDEX` in [EIP-7793](./eip-7793.md) and has been suggested for a state base fee in [EIP-7999](./eip-7999.md). `0x4e` and `0x4f` are tentatively used by [EIP-8120](./eip-8120.md) and [EIP-7784](./eip-7784.md). `0x4d` is unassigned. There is no free byte next to `GAS` (`0x5a`).

### Gas cost

`RESERVOIR` reads a single value that every frame already holds, like `GAS` and the other environment opcodes priced at the base cost of 2. The charge goes to `gas_left` so that executing `RESERVOIR` does not change the value it reads.

### Keeping `GAS` unchanged

Redefining `GAS` to return `gas_left` plus the reservoir would break its main use, computing the gas argument of `CALL`, since that argument is capped at 63/64 of `gas_left` and cannot name reservoir gas. EIP-8037 keeps `GAS` as `gas_left` for this reason, and [EIP-7999](./eip-7999.md) notes that reinterpreting `GAS` as an aggregate changes the behavior of contracts relying on precise gas observability. A separate instruction leaves deployed contracts as they are.

### Name

The name follows the `state_gas_reservoir` of EIP-8037, which is what most contracts will observe. In frame transactions the value is a frame's state pool rather than a reservoir, and a neutral name such as `STATEGAS` would fit both cases. The name is not part of consensus and can be revisited during review.

### Alternatives

Adding no introspection and waiting for an EVM without gas observability, as discussed in EIP-7999, would not help contracts and `EntryPoint` versions written while EIP-8037 is active. A `CALL` variant that takes a state gas limit would let callers cap a callee's state use in advance; it is a larger change that could build on `RESERVOIR`. Returning both pools from one instruction was rejected to keep the interface aligned with `GAS`. [EIP-2542](./eip-2542.md) proposed similar gas introspection before gas had more than one dimension.

## Backwards Compatibility

`0x4d` is currently an undefined opcode, so executing it halts. Deployed code that executes `0x4d` would behave differently after activation, as with any new opcode. Occurrences of `0x4d` as data, such as `PUSH1` operands, are unaffected. No existing opcode, transaction format or gas rule changes.

## Test Cases

The constants below are those of EIP-8037: a new storage slot costs `64 × 1530 = 97,920` state gas, a new account `120 × 1530 = 183,600` and a delegation indicator `23 × 1530 = 35,190`. Reservoir model cases use `tx.gas = TX_MAX_GAS_LIMIT + R` with `R = 500,000` unless stated otherwise. Frame transaction cases use a `VERIFY` frame followed by `DEFAULT` frames with state budget `S`. All cases are also provided as test fillers for the execution specification tests in the [assets](../assets/eip-draft_reservoir_opcode/README.md) of this EIP.

### Reservoir model

| Case | Expected `RESERVOIR` |
| --- | --- |
| Top-level read | `R` |
| Top-level read with `tx.gas` at most `TX_MAX_GAS_LIMIT` | `0` |
| After creating a storage slot | `R - 97,920` |
| After creating a storage slot with `R = 50,000` | `0` |
| After creating and clearing a storage slot in the same frame | `R` |
| In a child entered by `CALL`, `CALLCODE`, `DELEGATECALL` or `STATICCALL`, and in the caller afterwards | `R`, `R` |
| Child creates a storage slot and returns; child, then caller | `R - 97,920`, `R - 97,920` |
| Child creates a storage slot and reverts; child, then caller | `R - 97,920`, `R` |
| Child creates a storage slot and halts with `INVALID`; caller | `R` |
| Caller after a value-bearing `CALL` with insufficient balance | `R` |
| Caller after a value-bearing `CALL` to a non-existent account | `R - 183,600` |
| Initcode of `CREATE` or `CREATE2` | `R - 183,600` |
| Caller after `CREATE` or `CREATE2` whose initcode creates a slot and deploys 10 bytes | `R - 183,600 - 97,920 - 10 × 1530` |
| Caller after `CREATE` or `CREATE2` whose initcode reverts | `R` |
| Initcode of a contract-creation transaction | `R - 183,600` |
| Delegated code, one authorization for an existing account | `R - 35,190` |
| Delegated code, one authorization for a new account | `R - 218,790` |
| Delegated code, one authorization for an existing account, `R = 10,000` | `0` |
| Delegated code, authorizations for two existing accounts and one new account | `R - 3 × 35,190 - 183,600` |

A child given exactly 2 execution gas can execute `RESERVOIR`, and one given 1 halts. `RESERVOIR` with 1023 items on the stack succeeds, and with 1024 items it halts.

### Frame transactions

| Case | Expected `RESERVOIR` |
| --- | --- |
| First read in a frame, and `TXPARAM(TXPARAM_STATE_GAS_LEFT)` at the same point | `S`, `S` |
| After creating a storage slot | `S - 97,920` |
| Child call frame that creates a slot, then the caller | `S - 97,920`, `S - 97,920` |
| Frame creates a slot; child creates and clears a slot, creates another and reverts; child after the refill, child before reverting, caller afterwards | `S - 97,920`, `S - 195,840`, `S - 97,920` |
| Frame 1 with budget `S1` creates a slot; frame 2 with budget `S2` clears it; frame 1, then frame 2 | `S1 - 97,920`, `S2` |

### Both models

A contract calls one library that returns `TXPARAM(TXPARAM_STATE_GAS_LEFT)` and another that returns `RESERVOIR`. In a reservoir model transaction the first call halts and the second returns `R`. In a frame transaction both return `S`.

A bundler measures two calls with `GAS + RESERVOIR`. The first call creates a slot in a shared contract and the second clears it. When the reservoir funds the slot, the reservoir component of the first measurement is 97,920; with `R = 0` it is zero. In both cases the second measurement is negative.

## Reference Implementation

The following change to the Bogota fork of the [execution specifications](https://github.com/ethereum/execution-specs/tree/c9781fa5ac92b3e22becdf05b734917e685d47f8/src/ethereum/forks/bogota) implements the opcode. The full patch, including the test fillers, and an equivalent change to go-ethereum for the reservoir model are in the assets of this EIP.

```python
def state_gas_budget(evm: Evm) -> None:
    # GAS
    charge_gas(evm, GasCosts.OPCODE_RESERVOIR)

    # OPERATION
    frame_context = evm.tx_env.frame_context
    if frame_context is not None:
        value = U256(frame_context.state_gas_left)
    else:
        value = U256(evm.gas_meter.reservoir.state_gas_left)
    push(evm.stack, value)

    # PROGRAM COUNTER
    evm.pc += Uint(1)
```

## Security Considerations

The value returned by `RESERVOIR` is controlled by the caller, like the value returned by `GAS`. The sender sets the reservoir through `tx.gas`, and within a bundle it depends on the operations that ran before. Contracts should only use it to measure their own consumption or to check that an operation is affordable, and should not treat it as a trusted input.

Measurements can be negative. A region that clears state created earlier in the transaction receives a refill larger than its own charges, so code that subtracts two readings needs to handle a negative result instead of relying on checked arithmetic or wrapping. Under the reservoir model, an affordability check needs `GAS` for the execution part and `GAS + RESERVOIR` for the total, because charges beyond the reservoir are paid from `gas_left`; a check on `RESERVOIR` alone is not enough. A caller that wants to detect a callee spending its state budget can compare `RESERVOIR` before and after the call and revert on an unexpected decrease.

State gas prices and the split between execution and state gas may change in later forks. Contracts should measure consumption rather than hard-code expected state gas amounts. As with `GAS`, contracts whose success depends on `RESERVOIR` can make the set of sufficient `tx.gas` values non-monotonic, which affects gas estimation.

`RESERVOIR` depends on the inclusion context in the same way `GAS` does. ERC-4337 validation rules ([ERC-7562](./eip-7562.md)) restrict `GAS` during validation, and should restrict `RESERVOIR` in the same way.

Delegated code under EIP-7702 runs in the frame of the authority and reads that frame's value. Authorization charges are applied before the first frame starts and are not refilled by a top-level revert, so delegation offers no way to observe an inflated value.

Clients have to return the reservoir counter itself, not the reservoir plus the state gas spilled into `gas_left`, and must read it after the merge step when a call returns. A difference between clients here would split consensus. The test cases cover call, revert, halt, merge and refill paths for this reason.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
