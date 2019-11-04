---
eip: 2348
title: Validated EVM Contracts
author: Danno Ferrin (@shemnon)
discussions-to: https://ethereum-magicians.org/t/eip-2348-validated-evm-contracts/3756
status: Draft
type: Standards Track
category: Core
created: 2019-11-01
requires: 1702, 2327
replaces: 615 (in part), 1707 (unpublished, abandoned), 1712 (unpublished)
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
addition of new multi-byte instructions (such as the `PUSHn` series) because the new instructions
could hide a previously valid `JUMPDEST` when evaluated as a new opcode set. To prevent this account
versioning will be used so that contracts can be deployed in a way that is demonstrably validated.

Second there is the issue of improving runtime execution. One example is `JUMPDEST` evaluation.
Because each jump must "land" on a jump dest each client needs to validate that the dest is a valid
opcode location. Clients either need to do the analysis and store the values or re-evaluate the
contract on each execution. Stronger deployment validation will allow clients to presume jump calls
are valid in certain circumstances.

A tertiary motivation is to prepare the way for easily JITable contracts. While the current EVM can
be JIT compiled there are certain analyses that need to be performed to prevent or accommodate some
pathological or uncompilable cases from being compiled. With stricter rules these cases can be
detected at deploy time and rejected allowing EVM clients to make better assumptions about the
contract being compiled.

## Specification

There are three interlocking portions specified in this EIP and two portions from other active EIPs
included in this validation. [EIP-1702] (Generalized Account Versioning Scheme) and [EIP-2327]
(`BEGINDATA` opcode) are specified in their published locations. The portions specified in this EIP
are a versioning header (similar to what was in [EIP-1707]), invalid opcode validation (similar to
[EIP-1712]), and static jump analysis.

### EVM Account Versioning

Starting at `BLOCKNUM` (TBD) `EIP-1702` will be activated, `LATEST_VERSION` will be set to `1`, and
all new and updated accounts will have the account version `1`. The validation phase will apply the
rules described in [Version Header](version-header), [`BEGINDATA`](beindata),
[Invalid Opcode Validation](invalid-opcode-validation), and
[Static Jump Validations](static-jump-validations).

These EIP sections only apply to contracts stored or in the process of being stored in in accounts
with version `1`. This EIP never applies to contracts stored or in the process of being stored in
accounts at version `0`. Future EIPs may increase the set of contract versions this EIP applies to.

### Version Header

For contracts with the first byte from `0x01` to `0xff`, or whose total length is less than 4 bytes,
the contract is treated exactly as through it had been deployed to an account with version `0`. For
these contracts none of the other subsections in this EIP apply.

Whe deploying a contract if a contract starts with `0x00` and has a length 4 or later the first four
bytes form a version header. If a version header is not recognized by the EVM the contract
deployment transaction fails with out-of-gas.

For this EIP, only header version `1` (contracts starting with the byte stream `0x00` `0x00` `0x00`
`0x01`) is defined. Future EIPs may expand on the valid set of headers. This version indicates that
next three validations are applied to the content of the contract, keeping all other semantics of
the current "version 0" EVM contracts, including the same gas schedule.

For purposes of EVM Program Counter calculations the first byte after the version header is location
`0`. The contract header is not part of the accessible contract data. There is no mechanism within
the EVM to retrieve the header values.

### `BEGINDATA`

As described in [EIP-2327] a new opcode `BEGINDATA` (`0xb6`) is added that indicates the remainder
of the contract should not be considered executable code.

### Invalid Opcode Validation

All data between the Version Header and either the `BEGINDATA` marker or the end of the contract if
`BEGINDATA` is not present must represent a valid EVM program at all points of the data. Invalid
opcode validation consists of the following process:

- Iterate over the code bytes one by one.
  - If the code byte is a multi-byte operation, skip the appropriate number of bytes.
  - If the code byte is a valid opcode or designated invalid instruction (`0xfe`), continue.
  - If the code byte is the `BEGINDATA` operation (`0xb6`) stop iterating.
  - Otherwise, throw out-of-gas.

As of the Istanbul upgrade all of the multi-byte operations are the `PUSHn` series of operations
from `0x60` to `0x7f`. Future upgrades may add more multi-byte operations.

As of the Istanbul upgrade the invalid opcodes are `0x0c` to `0x0f`, `0x1e`, `0x1f`, `0x21` to
`0x2f`, `0x46` to `0x4f`, `0x5c` to `0x5f`, `0xa5` to `0xaf`, `0xb3` to `0xef`, `0xf6` to `0xf9`,
`0xfb`, `0xfc`, and `0xfe`. Future upgrades will remove items from this list. Note that `0xb6` is
referenced in this spec as the `BEGINDATA` marker, but is not part of any deployed upgrade. Also
note that `0xfe` would remain as a reserved 'invalid instruction' that will still be permitted.

### Static Jump Validations

For every jump operation preceded by a `PUSHn` instruction the value of the data pushed on to the
stack by the `PUSHn` operation must point to a valid `JUMPDEST` operation. If this validation fails
then the contract creation fails with out-of-gas.

As of the Istanbul upgrade the jump operations are `JUMP` (`0x56`) and `JUMPI` (`0x57`). Future
upgrades may add more jump operations.

As a client optimization this check may be performed during invalid opcode validation, or it may be
performed separately at contract deployment time.

## Rationale

The first major feature is the invalid opcode removal. In the case where a contract has an invalid
opcode that later becomes a multi-byte opcode followed by a `JUMPDEST` marker that contract would
become invalid after an upgrade because the destination marker would become part of the new
multi-byte instruction, as described in the [EIP-663 discussion]. If no invalid opcodes can be
deployed then the possibility of the `JUMPDEST` being absorbed by new multi-byte instructions is
eliminated.

One complication is that current versions of solidity append the swarm hash of the source code of
the contract in some instances to the end of the generated EVM bytecode. That is what motivated the
addition of the `BEGINDATA` opcode. Solidity can add a fairly simple wrapper function to it's
existing EVM generation. This option was chosen for its simplicity over other options such as
encoding the data in uncalled `PUSNn` instructions.

`JUMPDEST` validation is present to eliminate repeated validation calls for contracts and to reduce
the needed data storage requirements for cached validation. For example, if a client notices a
contract contains only static jumps it could store a cached validation flag that no jump analysis
needs to be performed, alternately they could defer the analysis until the first dynamic jump is
encountered.

## Backwards Compatibility

Almost all existing contract deployments will be able to be deployed with no client changes. The one
exception is contract deployments that start with `0x00`. This should have no impact on existing
contract execution because any contract with a `0x00` in the first position would immediately halt
because `0x00` maps to the `STOP` instruction, the utility and value of those contracts is minimal
at best. If this is not desirable a different header signaling byte that does not map to an existing
opcode (such as `0xEF`) can be used.

Except for the validation rules and versioning header all other semantics of the EVM are the same.
Gas schedules and opcode tables would be the same between account versions and wether or not the
contract was deployed with headers. Future EIPs may add opcodes that are only valid with a contract
that is deployed with a version header. Because of the version header validation rules multi-byte
contracts can be deployed.

Existing compilers (such as solidity) can provide support for headers by prepending their output
stream with `0x00`, `0x00`, `0x00`, `0x01` and appending `0xb6` prior to any non-code data added as
part of the contract.

## Forwards Compatibility

This spec provides forward compatibility in at least two ways.

First, the content of multi byte and jump dest validated opcodes can be increased in future
upgrades. Contracts that would be valid under new rules would be rejected under old rules, and all
older contracts would still be valid under the new rules. Any newly deployed opcodes would be
disabled unless the code is appropriately validated.

Second, the versioning header can be extended to allow for stricter validations in future upgrades
while keeping the EVM evaluation semantics the same. Such possible stricter validations could
include prohibiting dynamic jumps.

## Test Cases

This is an incomplete list, but provides insight as to the scope of the required testing. Each test
would need to be written 3 times, once for normal contract deployment, once for `CREATE`, and once
again for `CREATE2`.

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
  - contract with unrecognized header
  - contract with a static jump into code in `BEGINDATA`
  - contract with a static jump outside of all data
  - header, and contract code+header to large by less than 4 bytes
  - header, and contract code+header to large by more than 4 bytes
  - header, contract code, begin data, data, and the whole thing is too large
  - One test for each invalid opcode: no header, with header, and with header and `BEGINDATA`

## Implementation

No implementation yet.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[eip-615]: https://eips.ethereum.org/EIPS/eip-615
[eip-1702]: https://eips.ethereum.org/EIPS/eip-1702
[eip-1707]: https://github.com/ethereum/EIPs/pull/1707
[eip-1712]: https://github.com/ethereum/EIPs/pull/1712
[eip-2327]: https://github.com/ethereum/EIPs/pull/2327
[eip-663 discussion]:
  https://ethereum-magicians.org/t/eip-663-unlimited-swap-and-dup-instructions/3346/11?u=shemnon
