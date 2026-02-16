---
title: Reserve `0xAE EXTENSION` opcode
description: Reserve an opcode to be used as an extension prefix in non-Ethereum-L1 EVM chains
author: Bruce Collie (@Baltoli), Piotr Dobaczewski (@pdobacz)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2026-02-13

---

## Abstract

Reserve an opcode `0xAE EXTENSION` which will be guaranteed to not become a valid opcode on Ethereum L1 EVM, but which will be available to be used in other EVMs as a prefix to encode extension instructions.

## Motivation

Currently, non-Ethereum-L1 EVM chains cannot innovate on the EVM by introducing new instructions, because they run a risk of becoming incompatible with the Ethereum L1 EVM and the EVMs on other chains, in the event that these decide to implement new features using overlapping opcodes.

By setting aside a single opcode and agreeing that it will never become a valid instruction on Ethereum L1 EVM, we open up to extensions which can be implemented on other EVM chains. If these extensions prove out to be successful outside of Ethereum L1, then they can be back-ported into Ethereum L1 EVM, to the benefit of the entire EVM ecosystem.

Similarly, making it easier for innovations to happen inside the EVM should generally improve the EVM tooling by strengthening the network effects. In other words, it is beneficial for an innovation X to happen within the EVM, even if not on Ethereum Mainnet.

In particular, the extension opcode might be adopted by Ethereum L2 EVMs, allowing them to specialize and experiment, potentially expanding the catalogue of extensions relevant to the L1.

The extension opcode is designed in such a way to not only have **no impact** on Ethereum L1 EVM behavior, but also to not require any Ethereum Execution Layer Client modifications, except, optionally, for their presentation layer (e.g., traces), which is irrelevant to consensus.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### `0xAE EXTENSION`

Reserve a new opcode `0xAE EXTENSION` which MUST behave exactly like `0xFE INVALID` on all Ethereum L1 chains (Ethereum Mainnet, Testnets, etc.). In particular:

1. Executing `0xAE` MUST cause an exceptional halt (exit current execution frame and consume all gas, same as `0xFE INVALID`).
2. `0xAE` byte in the bytecode MUST NOT impact `JUMPDEST` analysis in any way, i.e. all jump destinations' validity MUST NOT be affected.
3. Any validation, static analysis, or preprocessing of bytecode, if introduced, MUST NOT be affected by the `0xAE` byte in the bytecode in any way other than how `0xFE INVALID` would affect it.

### Chain Specifics

Outside of Ethereum L1, `0xAE` MAY have meaningful behavior during execution, but it is up to the particular EVM implementations to decide.

However, in these EVMs which execute `0xAE`, the `JUMPDEST` analysis MUST still be unaffected by `0xAE`, i.e. the set of valid jump destinations MUST be identical to that obtained on Ethereum L1.

The particular behavior of the `0xAE` instruction on non-Ethereum-L1 EVMs adopting it MUST be determined by bytes following the `0xAE` as immediate args. If such immediate args contain any `0x5B` byte which remains a valid jump destination, execution MUST result in an exceptional halt.

The non-Ethereum-L1 EVM implementers SHOULD coordinate via the discussion thread of this EIP on their specific usage of `0xAE`.

## Rationale

### No effect on `JUMPDEST` analysis

An alternative considered was to have `0xAE`:
- invalidate `0x5B JUMPDEST` as a jump destination following it and
- skip over `PUSHx` instructions following it
however that would require this EIP to prescribe the size of the immediate arguments.

It would also run into conflict with any opcodes with immediate arguments introduced in the EVM via other EIPs.

Lastly, it could cause different jump destination validity for same bytecode when analyzed on and outside Ethereum L1 EVM, causing code to not be portable between chains.

It is therefore presumed that a `0xAE5B` sequence cannot be a valid extension instruction and its second byte will be a valid jump destination. `0xAE60`-`0xAE7F` byte sequences will not be valid extension instructions, unless the `0x60`-`0x7F` byte (`PUSH1`-`PUSH32`) is used to introduce `JUMPDEST`-neutral immediate arguments (since `PUSHx` instruction data is already skipped during `JUMPDEST` analysis).

| Bytecode sequence | `JUMPDEST` validity | Possible extension opcode execution                               |  
|-------------------|---------------------|----------------------------------------------------------------------|
| `0xAE5B...`       | valid               | Invalid extension                                                  |
| `0xAE015B...`     | valid               | Valid extension with `0x01` argument                              |
| `0xAE60`          | N/A                 | Invalid extension (truncated)                                      |
| `0xAE605B...`     | invalid             | Valid extension with `0x5B` argument encoded in `PUSH1` data        |
| `0xAE60605B...`   | valid               | Valid extension with `0x60` argument encoded in `PUSH1` data        |
| `0xAE61605B...`   | invalid             | Valid extension with `0x605B` argument encoded in `PUSH2` data      |
| `0xAE615B`        | invalid             | Invalid extension (truncated)                                          |

### Lack of definition of a particular encoding scheme

This EIP chooses to not define any extension encoding scheme, which would have meaningful behavior on the Ethereum L1 EVM. If one is desired in the future, it should be implemented using a prefix other than `0xAE`.

### Porting extension instructions back to Ethereum L1

In the event a feature implemented using `0xAE` needs to be ported back, a distinct opcode is chosen in a separate EIP. Once that EIP is in turn adopted in the originator EVM, that EVM will operate with two alternative ways to access the feature.

## Backwards Compatibility

The opcode `0xAE` is currently invalid in Ethereum, and it doesn't impact `JUMPDEST` analysis, thus no code containing it will change behavior.

## Test Cases

Will be provided in the Ethereum Execution Layer Specs format.

## Reference Implementation

None, Ethereum Execution Layer clients' behavior does not change.

## Security Considerations

None, Ethereum Execution Layer clients' behavior does not change.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
