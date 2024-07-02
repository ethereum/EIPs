---
title: EIP-158 deactivation
description: Deactivates EIP-158 in order to avoid conflicts in a context in which statelessness and EIP-7702 are active
author: Guillaume Ballet (@gballet)
discussions-to: https://ethereum-magicians.org/t/eip-158-deactivation/20445
status: Draft
type: Standards Track
category: Core
created: 2024-07-02
requires: 158, 7702
---

## Abstract

Deactivate [EIP-158](./eip-158,md).

## Motivation

After [EIP-6780](./eip-6780.md), the `SELFDESTRUCT` instruction was neutered, so that contracts could no longer be deleted. Contract deletions can still occur, however, via EIP-158. While [EIP-7702](./eip-7702.md) this can not happen, this latter EIP introduces the possibility for an empty EoA to have state. This is causing some issues when interfacing with verkle, for which state deletion is not possible.

EIP-158 was meant as a temporary measure to combat the "Shanghai attacks". Now that this is attack has been mitigated by other means, it can be deactivated.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

|Name|Value|
|----|-----|
|`FORK_TIME`|TBD|

At `block.timestamp > FORK_TIME`, EIP-158 rules no longer apply.

## Rationale

Once stateless ethereum is active, it becomes impossible to delete accounts, since their storage slots are spread over the tree and there is no mapping from an account to its slot numbers. All account deletion methods therefore have to be deactivated.

ETP-158, designed as a temporary solution against a problem that was since mitigated, need to be deactivated as well.

The deactivation should happen in Prague, for alternative methods to [EIP-7612](./eip-7612.md) to be valid. If EIP-7612 is accepted, then nothing opposes its inclusion in Osaka instead.

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

TODO

## Reference Implementation

TODO

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
