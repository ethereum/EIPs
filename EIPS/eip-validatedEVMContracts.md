---
eip: <to be assigned>
title: Validated EVM Contracts
author: Danno Ferrin (@shemnon), <TBD>
discussions-to: <TBD>
status: Draft
type: Standards Track
category: Core
created: 2019-11-01 <TBD>
requires: 1702, 2327, <more TBD>
replaces: 1707 (unpublished), 1714 (unpublished), 615 (in part)
---

## Simple Summary

Make minor changes to EVM contract layout and add validation rules to a subset of those contracts.

## Abstract

A set of contract markers and validation rules relating to those markers is proposed. These
validation rules enable forwards compatible evolution of EVM contracts and provide some assurances
to Ethereum clients allowing them to disable some runtime verification steps by moving these
validations to the deployment phase.

## Motivation

There are two major motivations: first the need to make the EVM easier to evolve, and the second is
to provide validations that allow clients to optimize their EVM execution.

First there is the issue of an evolvable EVM. With the current state of EVM contracts literally any
sequence of bytes can be deployed to the blockchain. Some tools take advantage of this situation and
add meta-data to the end of their contract deployment. The real impact is that this precludes the
addition of new multi-byte instructions (such as the PUSHn series) because the new instructions
could hide a previously valid `JUMPDEST` when evaluated as a new opcode set. So invalid contracts
will not be deployable.

Second there is the issue of improving runtime execution. One example is `JUMPDEST` evaluation.
Because each jump must "land" on a jump dest each client needs to validate that the dest is a valid
opcode location. Clients either need to do the analysis and store the values or re-evaluate the
contract on each execution. Stronger deployment validation cal allow clients to presume all jump
calls are valid.

A tertiary motivation is to prepare the way for easily JITable contracts. While the current EVM can
be JIT compiled there are certain analyses that need to be performed to prevent some pathological or
uncompilable cases from being compiled, or to provide the necessary analysis. With stricter rules
these cases can be detected at deploy time and rejected, allowing EVM clients to make better
assumptions about the contract being compiled.

## Specification

There are four interlocking portions, in addition to EIP-1702 (Generalized Account Versioning
Scheme) and EIP-2327 (`BEGINDATA` opcode). They are a versioning header (similar to what was in
EIP-1707), invalid opcode validation, static jump analysis, and same evm limits validation.

### EVM Account Versioning

This EIP only applies to contracts stored or in the process of being stored in in accounts with
version `1`. This EIP never applies to contracts stored or in the process of being stored in
accounts at version `0`. Future EIPs may increase the set of contract versions this EIP applies to.

### Version Header

For contracts with the first byte from `1` to `255`, or whose total length is less than 4 bytes, the
contract is treated exactly as through it had been deployed to an account with version `0`. For
these contracts none of the other subsections in this EIP apply.

Whe deploying a contract if a contract starts with `0`, has a length 4 or later, and has a version
that is not recognized by the EVM the contract deployment transaction fails and consumes all
allocated gas.

For this EIP, only header version '1' (contracts starting with the byte stream 0x00 0x00 0x00 0x01)
is defined. Future EIPs may expand on the valid set of headers.

For purposes of PC calculations the first byte after the version header is `0`. There is no
mechanism within the EVM to retrieve the header values.

### `BEGINDATA`

As described in EIP-2327 a new opcode `BEGINDATA` (0xb6) is added that indicates the remainder of
the contract should not be considered executable code.

### Invalid Opcode Validation

All data between the Version Header and the `BEGINDATA` marker, or the end of the contract if
`BEGINDATA` is not present, must represent a valid EVM program at all points of the data. Invalid
opcode validation consists of the following process:

- Iterate over the code bytes one by one.
  - If the code byte is a multi-byte operation, skip the appropriate number of bytes.
  - If the code byte is a valid opcode or designated invalid instruction (`0xfe`), continue.
  - If the code byte is the `BEGINDATA` operation (`0xb6`) stop iterating.
  - Otherwise, throw out-of-gas.

As of the writing of this spec all of the multibyte operations are the `PUSHn` series of operations
from `0x60` to `0x7f`. Future forks may add more multi-byte operations.

### Static Jump Validations

For every jump operation preceded by a `PUSHn` instruction the value of the data pushed on to the
stack by the `PUSHn` operation must point to a valid `JUMPDEST` operation. Clients may combine this
check with invalid opcode validation.

As of the writing of this spec the jump operations are `JUMP` (0x56) and `JUMPI` (0x57). Future
forks may add more jump operations.

### ?Sane Limits checks? (1985)?

> TODO research if any EIP1985 checks make sense.

## Rationale

The first major feature is the invalid opcode removal. In the case where a contract has an invalid
opcode that later becomes a multibyte opcode followed by a `JUMPDEST` marker that contract would
become invalid after a hard fork because the destination marker would become part of the new
multibyte instruction <TODO - link to FEM post>. If no invalid opcodes can be created then the
possibility of the `JUMPDEST` being absorbed is eliminated.

One complication is that current versions of solidity append the swarm hash of the source code of
the contract in some instances to the end of the generated EVM bytecode. That is what motivated the
addition of the `BEGINDATA` opcode. Solidity can add a fairly simple wrapper function to it's
existing EVM generation.

`JUMPDEST` validation is present to eliminate repeated validation calls for contracts and to reduce
the needed data storage requirements for cached validation. For example, if a client notices a
contract contains only static jumps it could store a cached validation flag that no jump analysis
needs to be performed, alternately they could defer the analysis until the first dynamic jump is
encountered.

## Backwards Compatibility

Almost all existing contract deployments will be able to be deployed with no client changes. The one
exception is contract deployments that start with a zero byte. This should have no impact on
existing contract execution because any contract with a zero byte in the first position is not
executable.

Except for the validation rules and versioning header all other semantics of the EVM are the same.
Gas schedules and opcode tables would be the same between versions and headers.

Existing compilers (such as solidity) can provide support for headers by prepending their output
stream with 0x00, 0x00, 0x00, 0x01 and appending in 0xb6 prior to any non-code data added as part of
the contract.

## Forwards Compatibility

This spec provides forward compatibility in at least two ways.

First, the content of multi byte and jump dest validated opcodes can be increased in future forks.
Contracts that would be valid under new rules would be rejected under old rules, and all older
contracts would still be valid under the new rules. Any newly deployed opcodes would be disabled
unless the code is appropriately validated.

Second, the versioning header can be extended to allow for stricter validations in future hard forks
while keeping the EVM evaluation semantics the same. Such possible stricter validations could
include prohibiting dynamic jumps.

## Test Cases

Incomplete whiteboard list

- Positive
  - no header and invalid opcodes
    - including the case where a `JUMPDEST` gets consumed by a proposed multi-byte operation
  - no header and all valid opcodes
    - includes static jump to invalid destination
  - header and all valid opcodes
    - includes static jump to valid destination
  - header, all valid opcodes, and `BEGINDATA`
  - header, all valid opcodes, `BEGINDATA`, and invalid opcodes in data
  - three byte program, starts with zero
  - four bytes program, header only
  - header and begin data only
- Negative
  - contract with otherwise valid program that starts with zero, 5 bytes or more
  - contract with header and invalid opcodes
  - contract with header, begin data, and invalid opcodes in the middle
  - contract with header, and static jump to bad place
  - contract with header, and 1985 violations (one contract per violation)
  - contract with unrecognized header
  - contract with a static jump into code in BEGINDATA
  - contract with a static jump outside of all data
  - header, and contract code too large
  - header, contract code, begin data, data, and the whole thing is too large

## Implementation

not done yet

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
