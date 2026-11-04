---
title: SLOTDURATION Opcode
description: Opcode to get the duration of the current slot, in milliseconds
author: Hadrien Croubois (@amxx)
discussions-to: https://ethereum-magicians.org/t/TODO
status: Draft
type: Standards Track
category: Core
created: 2026-11-04
requires: 7843
---

## Abstract

This EIP adds a new opcode, `SLOTDURATION`, that pushes the duration of the current slot, in milliseconds, onto the stack. The value is the `SLOT_DURATION_MS` parameter in effect in the consensus layer for the block's slot. It is passed from the consensus layer to the execution layer and committed to in the block header.

## Motivation

The slot duration has been a fixed 12 seconds since the Merge, and many contracts hardcode it. They use it to convert between slot counts and wall-clock time, to estimate how many blocks fit in a time window, or to calibrate per-block rate limits and reward rates. Proposals such as [EIP-8198](./eip-8198.md) plan to shorten the slot duration, possibly several times. Each change would silently break every contract that hardcodes it.

Lido's core protocol shows the problem. Its oracle contracts (`HashConsensus`, `AccountingOracle`, `ValidatorsExitBusOracle`) and its `ValidatorExitDelayVerifier` all take `secondsPerSlot` as a constructor argument and store it as an `immutable`. On mainnet it is set to `12`. The value is used to convert between slots and timestamps, using `GENESIS_TIME + slot * SECONDS_PER_SLOT`, and to compute the time elapsed between oracle reports, which feeds the protocol's sanity checks on rewards. A slot duration change would require Lido to:

- deploy new oracle implementations and upgrade their proxies;
- redeploy the consensus and verifier contracts, then repoint the oracles and other contracts to them;
- re-tune governance parameters that were calibrated for 225 epochs per day.

All of this would have to happen at the same time as the fork. Even then, a single linear formula from genesis can no longer give correct timestamps for slots on both sides of the change. Other contracts that reason about beacon chain time, such as staking protocols, restaking systems and beacon proof verifiers, are likely to have the same problem.

[EIP-7843](./eip-7843.md) addresses part of this problem by exposing the slot number through the `SLOTNUM` opcode, so contracts no longer need the slot duration to compute the current slot. Contracts that need the duration itself still have no reliable way to get it:

1. Hardcode the value. This breaks at the next slot duration change.
2. Measure it with `SLOTNUM`, by dividing a timestamp difference by a slot difference. Missed slots do not affect this measurement, but it has other problems:
   - The contract needs a stored observation from an earlier transaction in a different slot. The measurement cannot be done within a single transaction.
   - The result is an average over the interval. If the duration changed during the interval, the result is neither the old nor the new duration. After a change, the result stays wrong until a new observation is recorded.
   - `TIMESTAMP` has one-second resolution. Chains with sub-second blocks need observations many slots apart to get even an approximate value.
3. Prove it against the beacon block root ([EIP-4788](./eip-4788.md)). This is not possible. `SLOT_DURATION_MS` is a consensus layer configuration value, so it is not stored in the `BeaconState` or the beacon block. A contract could prove the `fork` field of the state, but it would still need a hardcoded table that maps each fork to its slot duration, which is the same problem as option 1.

Exposing `SLOT_DURATION_MS` through an opcode lets contracts adapt automatically to slot duration changes, the same way `SLOTNUM` removes the need to derive slot numbers from timestamps.

This EIP does not depend on any slot duration change. It should activate before the first change, such as the one proposed in [EIP-8198](./eip-8198.md). Activating it first gives contracts time to stop hardcoding the duration and use the opcode instead. When the duration does change, those contracts then need no upgrade.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Parameters

| Constant | Value |
| -------- | ----- |
| `SLOTDURATION_OPCODE` | `0x4c` |
| `SLOTDURATION_GAS` | `2` |

### Opcode

A new opcode `SLOTDURATION` is introduced at `SLOTDURATION_OPCODE`. It takes no stack input and pushes one element onto the stack.

#### Output

One element, `slotDurationMs`, is pushed onto the stack. It is the duration of the slot of the current block, in milliseconds, as given by the block header's `slotDurationMs` field. It is a `uint64`, left-padded to 32 bytes.

#### Gas cost

`SLOTDURATION` has a fixed cost of `SLOTDURATION_GAS`.

### Block header

The block header is extended with a new field, `slotDurationMs`, of type `uint64`. It is appended after the `slotNumber` field introduced by [EIP-7843](./eip-7843.md).

The consensus layer sets this field to the slot duration, in milliseconds, that is in effect for the block's slot. While the slot duration is fixed, this is the `SLOT_DURATION_MS` configuration value. Chains without a beacon chain, such as layer 2 networks, set `slotDurationMs` to their target block interval. Some chains do not produce blocks at regular intervals, such as development chains that create a block whenever a transaction is submitted. These chains set `slotDurationMs` to `0`, which means that no regular block interval exists. On chains with a beacon chain, the consensus layer always provides a non-zero value. The execution layer does not validate the value.

### Engine API

The consensus layer passes `slotDurationMs` to the execution layer through the Engine API, in the same way as `slotNumber` in [EIP-7843](./eip-7843.md):

- A `slotDurationMs` field of type `QUANTITY` (64 bits) is added to new versions of the `ExecutionPayload` and `PayloadAttributes` objects.
- New versions of `engine_newPayload`, `engine_getPayload` and `engine_forkchoiceUpdated` are introduced to use these objects.
- When building a payload, the execution layer copies `PayloadAttributes.slotDurationMs` into the header. When validating a payload, the consensus layer checks that `ExecutionPayload.slotDurationMs` equals the slot duration in effect for the payload's slot.

## Rationale

### Milliseconds

The consensus layer already expresses slot duration as `SLOT_DURATION_MS`. Using the same unit avoids conversion and rounding errors. [EIP-8198](./eip-8198.md) currently requires slot durations to be multiples of 1000 ms. Using milliseconds means a later change that drops this requirement would not require a change to the opcode. It also lets chains with much shorter block times adopt the opcode as specified. Some layer 2 networks produce blocks every 100–250 ms. Seconds cannot express these durations, but milliseconds can.

### Source of truth in the consensus layer

The slot duration is a beacon chain parameter. The consensus layer is the source of truth for this value and passes it to the execution layer. Today this value is the constant `SLOT_DURATION_MS`. Once slot durations can change, the consensus layer already has the value for any epoch. For example, the consensus specification for [EIP-8198](./eip-8198.md) defines `get_slot_duration_ms(epoch)` ([`specs/_features/eip8198/beacon-chain.md`](https://github.com/ethereum/consensus-specs/blob/204fb4a19774eabb7a2e91505365deed6b8afef8/specs/_features/eip8198/beacon-chain.md)), and the header field would then be set to `get_slot_duration_ms(compute_epoch_at_slot(slot))`. The execution layer therefore needs no copy of the schedule, and the two layers cannot disagree about it.

### Execution layer awareness of the slot duration

[EIP-8198](./eip-8198.md) deliberately keeps the execution layer unaware of the slot duration configuration. Where the execution layer needs the duration, such as in the base fee rule, it derives it from the spacing of header timestamps. This EIP keeps that separation of concerns:

- The execution layer holds no slot duration configuration and computes nothing from it. It copies the value it receives from the consensus layer into the header and exposes it to the EVM. This is the same treatment [EIP-7843](./eip-7843.md) gives `slotNumber`.
- No execution client logic depends on the value. A future slot duration change still needs no execution layer configuration update for this opcode.

Contracts cannot easily use the execution layer's approach. They only see the current block's header. To measure the spacing between headers, they must store an earlier timestamp and slot number, as described in the [Motivation](#motivation). That gives an average over the interval, which is wrong when the interval contains a duration change, and lags after each change. With the header field, contracts read the current duration directly and do not have to measure it themselves.

### Alternative: execution layer schedule with historical lookup

An alternative design keeps the full slot duration schedule in the execution layer configuration, similar to the blob schedule in [EIP-7840](./eip-7840.md). Each entry would give the first slot at which a duration applies. This design needs no new header field and no Engine API change. It duplicates consensus layer parameters in the execution layer, and client configurations must stay in sync with the consensus layer schedule.

Because the execution layer would know the whole schedule, the opcode could take an argument:

- **Input:** one stack element, `slot`.
- **Output:** the `SLOT_DURATION_MS` that applied to `slot`. If `slot` is greater than the current slot number (as returned by `SLOTNUM`), the output is `0`.

`SLOTNUM SLOTDURATION` then returns the duration of the current slot, which is the same result as the design specified above.

Historical lookup fixes the main pitfall described in [Security Considerations](#security-considerations). A contract that needs the wall-clock length of an interval between two slots can find the duration in effect at each end of the interval, and detect that a schedule boundary was crossed. A contract that only reads the current duration cannot tell that the duration changed while it was not looking. A full solution would also need to know the slot at which each change happened. A companion lookup, or a binary search over `SLOTDURATION` calls, could find it.

Slots in the future return `0` instead of a value from the configured schedule. Entries for future slots can still be changed or removed before they activate, for example if a fork is rescheduled. Returning such a value would let contracts depend on a duration that may never take effect. `0` can never be a real slot duration, so contracts can tell it apart from a real result. `0` has the same meaning as on chains without a regular block interval: no duration is known.

In this variant, the cost of the opcode depends on the size of the schedule. Each slot duration change adds one entry, so a binary search stays cheap, and the opcode could be priced at `W_verylow` (`3`) to account for the stack input. The schedule must stay in client configuration forever, and every client must implement the exact slot-to-duration mapping, including the slots before the first schedule entry (12000 ms from the beacon chain genesis).

### Header field

Putting the value in the block header keeps blocks self-contained for re-execution and ZK proving. Executing a block needs no input from outside the block. The cost is 8 bytes per header (a little more after RLP encoding). The value rarely changes, so it compresses well.

### Gas cost

The opcode reads one block-context value, like `TIMESTAMP`, `NUMBER` and `SLOTNUM`. It is priced at `W_base` like those opcodes.

### Opcode value

`0x4c` is in the block information range `0x40`–`0x4f`, directly after `SLOTNUM` (`0x4b`). Placing it there keeps the two slot-related opcodes next to each other.

## Backwards Compatibility

This EIP introduces a new opcode. Before activation, executing `SLOTDURATION_OPCODE` causes an exceptional halt. No deployed contract can rely on the new behavior.

The block header and Engine API changes need coordinated upgrades of consensus and execution clients at the fork.

## Test Cases

- With `SLOT_DURATION_MS = 12000`, `SLOTDURATION` pushes `12000` (`0x2ee0`) and consumes 2 gas.
- With a slot duration of 10000 ms, `SLOTDURATION` pushes `10000` (`0x2710`).
- When a block is in the first slot of an epoch where the slot duration changes from 12000 to 10000, `SLOTDURATION` returns `10000` for that block. It returns `12000` for the block in the preceding slot.
- On a chain without a regular block interval, `SLOTDURATION` pushes `0`.

## Security Considerations

`SLOTDURATION` returns the nominal duration of the current slot. It does not measure time elapsed since the parent block, which can span several slots if slots were missed. Contracts that need elapsed time should use `TIMESTAMP` differences.

The value can change at a fork or slot schedule boundary. Contracts SHOULD read it each time they need it and SHOULD NOT cache it in storage. Contracts that accumulate values over time, such as interest or vesting at a per-slot rate, should account for the duration changing between two observations. A naive `slots × currentDuration` product misprices any interval that crosses a schedule boundary.

Contracts SHOULD NOT assume the value is a whole number of seconds or that it only decreases.

`SLOTDURATION` returns `0` on chains without a regular block interval, such as local development chains. Contracts that divide by the value MUST handle `0` explicitly. In the EVM, `DIV` by zero returns `0` silently, and Solidity's checked division reverts. This matters most because local development chains, where contracts are usually tested, are exactly the chains that return `0`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
