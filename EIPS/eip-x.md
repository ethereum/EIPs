---
title: Ethereum To The Moon!
description: Makes a minimal number of changes that allow Ethereum to be used on the moon
author: Pandapip1 (@Pandapip1)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2023-2-23
---

## Abstract

This EIP makes a minimal number of changes to allow Ethereum to be used on the moon and other potentially habitable bodies in Earth's solar system. It changes the time between blocks, the per-block validator reward, and the number of blocks per epoch.

## Motivation

It is impossible for Ethereum to literally "go to the moon" due to a limitatation in the protocol: the block length. Should validators attempt to validate on the surface of the moon, they would find that the X second communication delay (caused by the speed of light) is greater than the 12-second timer in between blocks. The validators would find themselves slashed on the terrestrial chain, and validating their own fork.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

* The time between blocks MUST be changed from 12 seconds to 10 minutes (50x longer).
* The per-block validator reward MUST be multiplied by 50
* The number of blocks per epoch MUST be reduced from 4 to 2

## Rationale

* The block gas limit is multiplied by 50 to compensate for the time between blocks being multiplied by fifty.
* The per-block validator reward is also multiplied by 50 to copensate for the time between blocks being multiplied by fifty.
* Epochs are changed to be 2 blocks long so that finality can be reached in a reasonable amount of time.

## Backwards Compatibility

Many applications expect mainnet transactions to be included in a short amount of time. This would clearly no longer be the case. Such applications should switch to planetary rollups. Syncing rollups across heavenly bodies is outside the scope of this proposal.

## Test Cases

TODO.

## Security Considerations

Definitely needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
