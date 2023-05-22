---
eip: nnnn
title: Revamped CALL instructions
description: Introduce CALL2, DELEGATECALL2 and STATICCALL2 with simplified semantics
author: Alex Beregszaszi (@axic), Paweł Bylica (@chfast), Danno Ferrin (@shemnon)
discussions-to:
status: Draft
type: Standards Track
category: Core
created: 2023-05-05
requires: 150, 211, 214, 2929
---

## Abstract

Introduce three new call instructions, `CALL2`, `DELEGATECALL2` and `STATICCALL2`, with simplified semantics. The existing call instructions remain unchanged.

The new instructions do not allow specifying a gas limit, but rather rely on the "63/64th rule" ([EIP-150](./eip-150.md)) to limit gas. An important improvement is the rules around the "stipend" are simplified, and callers do not need to perform special calculation whether the value is sent or not. 

Furthermore, the obsolete functionality of specifying output buffer address is removed, because it is predominantly unused and implementers prefer to use `RETURNDATACOPY` instead. One exception is the case when the expected return size is known (i.e. non-dynamic return values), Solidity still uses the output buffer.

Lastly, instead of returning a boolean for execution status, an extensible list of status codes is returned: `0` for success, `1` for revert, `2` for failure.

We expect most new contracts to rely on the new instructions (for simplicity and in order to save gas), and some specific contracts where gas limiting is required to keep using the old instructions (e.g. [EIP-4337](./eip-4337.md)).

## Motivation

Observability of gas has been a problem for very long. The system of gas has been (and likely must be) flexible in adapting to changes to both how Ethereum is used as well as changes in underlying hardware.

Unfortunately, in many cases compromises or workarounds had to be made to avoid affecting call instructions negatively, mostly due to the complex semantics and expectations of them.

This change aims to remove gas observability from the new instructions and opening the door of new classes of contracts who are not affected by repricings. Furthermore, once the EVM Object Format (EOF) is introduced, the legacy call instructions can be rejected within EOF contracts, making sure they are mostly unaffected by changes in gas prices. *Because these operations are requierd for removing gas observability they will be required for EOF in lieu of the existing instructions.*

>*Since the removal of gas observability was posed as a requirement for EOF, this turns this EIP as a prerequisite for it.*
> Do we want the last sentence? or the one in itallics?

It is important to note that starting Solidity 0.4.21, the compiler already passes all remaining gas to calls (using `call(gas(), ...`), unless the developer uses the explicit override (`{gas: ...}`) in the language. This suggests most contracts don't rely on controlling gas.
> https://github.com/ethereum/solidity/pull/3599

Besides the above, this change introduces a convenice feature of returning more detailed status codes: success (0), revert (1), failure (2). This moves from the boolean option to codes, which are extensible in the future.

Lastly, the introduction of the `RETURNDATA*` instructions ([EIP-214](./eip-214.md)) have obsoleted the output parameters of calls, mostly rendering them unused. An interesting problem to mention is the case of [ERC-20](./eip-20.md) where conflicting implementations caused a lot of trouble, where some would return something, while others wont.

## Specification

> TODO: Add a table for gas numbers here.

| Name | Value | Comment |
|------|-------|---------|
| WARM_STORAGE_READ_COST | 100 | From [EIP-2929]() |
| COLD_ACCOUNT_ACCESS | 2600 | From [EIP-2929]() |
| ACCOUNT_CREATION_COST | 25000 | |
| RETAINED_GAS | 5000 | |
| STIPEND | 2300 | |

We introduce three new instructions:
- `CALL2` (`0xf8`) with arguments `(target_address, input_offset, input_size, value)` 
- `DELEGATECALL2` (`0xf9`) with arguments `(target_address, input_offset, input_size)`
- `STATICCALL2` (`0xfb`) with arguments `(target_address, input_offset, input_size)`

Execution semantics:
1. Charge `WARM_STORAGE_READ_COST` (100) gas.
2. Pop required inputs from stack, fail with error on stack underflow.
3. If `value` is non-zero:
    3a. Fail with error if the current frame is in `static-mode`.
    3b. Fail with error if the balance of the current account is less than `value`.
4. Peform (and charge for) memory expansion using `[input_offset, input_size]`.
5. If `target_address` is not in the `warm_account_list`, charge `COLD_ACCOUNT_ACCESS - WARM_STORAGE_READ_COST` (2500) gas.
6. If `target_address` is not in the state and the call configuration would result in account creation, charge `ACCOUNT_CREATION_COST` (25000) gas.
    - The only such case in this EIP is if `value` is non-zero.
> Clarify what happens on value transfer, i.e. account modification cost. Was 9000 in the old calls (but included the stipend). [name=alex]
> If we don't charge for value transfer it addresses some of the needs of [EIP-5920](./eip-5920.md) PAY Opcode if the operations are in legacy.  Lets start with it out. Added a note at the end to call this out. [name=drf]
> Hm I would still try to charge a reasonable cost (such as 5000 gas i.e. sstore but should follow 2929 cost strucures), because otherwise this could become a DoS vector. [name=alex]
7. Reduce the available gas by `max(ceil(gas/64), RETAINED_GAS)` (`RETAINED_GAS` is 5000).
8. Fail with error if the available gas at this point is less than `STIPEND` (2300).
10. Perform the call with the available gas and configuration.
11. Push a status code on the stack:
    11a. `0` if the call was successful.
    11b. `1` if the call has reverted.
    11c. `2` if the call has failed.
12. Gas not used by the callee is returned to the caller.

Note: Unlike `CALL` there is no extra charge for value bearing calls.

## Rationale

### Removing gas selectability

On major change from the original `CALL` series of instructions is that the caller has no conrol over the amount of gas passed in as part of the call. The number of cases where such a feature is essential are probably better served by direct protocol integration.

Removing gas selectability also introduces a valuable property that future revisions to the gas schedule will benefit from: you can always overcome Out of Gas errors by sending more gas as part of the transaction (subject to the block gas limit). Previously when raising storage costs ([EIP-1884](./eip-1884.md)) some contracts that sent only a limited amount of gas to their calls were broken by the new costing.

Hence some contracts had a gas ceiling they were sending to their next call, permanently limiting the amount of gas they could spend. No amount of extra gas could fix the issue as the call would limit the amount sent.  The notion of a stipend floor is retained in this spec. This floor can be changed independent of the smart contracts and still preserve the feature that OOG halts can be fixed by sending more gas as part of the transaction.

### Stipend and 63/64th rule

The purpose of the stipend is that a callee in case of being a "contract wallet" to have enough gas to emit logs (i.e. perform non-state-changing operations). The stipend is only added when the target has code and the call value is non-zero.

The 63/64th rule has multiple purposes:
a) to limit call depth, 
b) to ensure the caller has gas left to make state changes after a callee returns.

Additionally there is a call depth counter, and calls fail if the depth would exceed 1024.

Before the 63/64th rule was introduced, it was required to calculate available gas semi-accurately on caller side. Solidity has a complicated ruleset where it tries to estimate how much it will cost on the caller side to perform the call itself, in order to set a reasonable gas value.

We have changed the ruleset:
1) Removed the call depth check.
2) Use the 63/64th rule, but
    2a) ensure that at least 5000 gas is retainted prior to executing the callee,
    2b) ensure that at least 2300 gas is available to the callee.

> Which is better? 63/64th or keeping call depth check?
> Are these stipend rules good?

### Status codes

Current call instructions return a boolean value to signal success: 0 means failure, 1 means success. The Solidity compiler assumed this value is a boolean and thus uses the value as branch condition to status (`if iszero(status) { /* failure */ }`). This prevents us from introducing new status codes without breaking existing contracts. At the time of the design of [EIP-211](./eip-211.md) the idea of return a specific code for revert was discussed, but ultimately abandoned for the above reason.

We change the value from boolean to a status code, where `0` signals success and thus it will be possible to introduce more non-success codes in the future, if desired.

### Opcode encoding

Instead of introducing three new opcodes we have discussed a version with an immediate configuration byte (flags). There are two main disadvantages to this:
1) Some combination of flags may not be useful/be invalid, and this increases the testing/implementation surface.
2) The instruction could take variable number of stack items (i.e. `value` for `CALL2`) would be a brand new concept no other instruction has.

It is also useful to have these as new opcodes instead of modifying the exiting CALL series inside of EOF. This creates an "escape hatch" in case gas observability needs to be restored to EOF contracts. This is done by adding the GAS and original CALL series opcodes to the valid EOF opcode list.

### `CALLCODE`

Since `CALLCODE` is deprecated, we do not introduce a counterpart here.

## Backwards Compatibility

No existing instructions are changed and so we do not think any backwards compatibility issues can occur.

> Do we call out the inversion of the return status explicitly as an inversion?
> If we don't charge for value transfer, should we call out CALL2 is a cheaper value transfer? - DRF

> I'd argue these are not backwards compatibility issues because these are not new instructions. The status code change could be higlighted, but again it is not backwards incompatibility imho.

## Security Considerations

It is expected that the attack surface will not grow. All of these operations can be modeled by existing operations with fixed gas (all available) and output range (zero length at zero memory).

> Some of the changes around stipend could be argued. Need to check some specific cases, such as stipend-less transfer to account code.

When implemented in EOF (where the GAS opcode and the original CALL operations are removed) existing out of gas attacks will be slightly more difficult, but not entirely prevented. Transactions can still pass in arbitrary gas values and clever contract construction can still result in specific gas values being passed to specific calls. It is expected the same surface will remain in EOF, but the ease of explitation will be reduced.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
