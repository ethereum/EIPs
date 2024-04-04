---
title: EOF - Prepare for Address Space Extension
description: Update EOF opcodes so addresses are not trimmed durring execution
author: Danno Ferrin (@shemnon)
discussions-to: tbd
status: Draft
type: Standards Track
category: Core
created: 2024-04-03
requires: 3540, 3670, 7069
---

## Abstract

Operations in the Legacy EVM trim off the top 12 bytes of an address operand before evaluation. This
EIP changes the handling of those opcodes within EOF so that no trimming occurs and the top twelve
bytes need to be zero or an exceptional halt is raised.

## Motivation

There have been propsals to extend Ethereum Addresses from 160 bytes to 256, such as one that
would [use the extra bits for state expiry](https://ethereum-magicians.org/t/increasing-address-size-from-20-to-32-bytes/5485).
One issue ground this work to a halt: EVM opcodes that accept Addresses trim all but the lowest 20
bytes out fo the operand before processing. EVM Reference
tests [verify this behavior](https://github.com/ethereum/tests/blob/develop/src/GeneralStateTestsFiller/stBadOpcode/invalidAddrFiller.yml).

The EVM Object Framework presents an opportunity to remove this address masking in a backwards
compatible way, by baking it into the format definition from the start.

Most of the work is already in place. The following 5 operations have already been banned from
EOF: `EXTCODESIZE`, `EXTCODECOPY`, `EXTCODEHASH`, `CALLCODE`, and `SELFDESTRUCT`. Three call
operations, `CALL`, `DELEGATECALL`, and `STATICCALL` are being revamped
in [EIP-7069](./eip-7069.md). That leaves only one operation, `BALANCE`, to be changed.

When future uses of address space extension are specified it is expected that the exeptional halt
behavior will be modified.

## Specification

The `BALANCE` operation, when invoked in code in an EOF container, will reauire the top 12 bytes of
the operand to be zero.

If `BALANCE` is invoked with any of the high 12 bytes set to a non-zero value the operation will
cause an exceptional halt as though the invalid operation (`0xfe`) were processed. All gas will be
consumed.

Any operation that is un-banned from EOF will have the same behavior as `BALANCE` when it comes to
address operations.

## Rationale

There are two alternative ways to handle accounts with high bits set. The specification calls for
exceptional halt, but the alternative was to treat the account as empty. The reason the "empty
account" approach was rejected is twofold: first the warm account list could be required to track
256 bit accounts when an invalid address is accessed. Second, the `EXTCALL` series instructions
could still send balance to those addresses and such accounts would then hold an (inaccessble)
balance that would need to be reflected in the merkle trie.

Because the BALANCE operation already needs to check the warmed account list there is already a good
amount of processing that must go into the operation, so no change to the gas schedule are needed to
prevent abuse of the failures. Such incremental costs will be dominated by costs related to reverts
and address checking for valid accounts.

## Backwards Compatibility

Only one operation shared between legacy and EOF is impacted. All other impacted operations are used
in only one mode.

## Test Cases

Test cases similar to
the [Invalid Address](https://github.com/ethereum/tests/blob/develop/src/GeneralStateTestsFiller/stBadOpcode/invalidAddrFiller.yml)
tests in the standard reference tests will need to be written for the EOF tests.

## Reference Implementation

TBD

## Security Considerations

This EIP only defines a revert behavior for previously stripped addresses. Compilers will need to be
aware of the need to mask addresses coming in from call data. Some of this is already present in
existing Solidity ABI standards but more care should be taken in examining the flow around `BALANCE`
and code for `EXTCALL` operations to ensure that compiled code strips the high bytes.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
