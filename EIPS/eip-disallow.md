---
eip: <to be assigned>
title: Disallow Deployment of Unused Opcodes
author: Wei Tang (@sorpaas)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2019-01-17
---

## Simple Summary

Hard fork can change existing contract behavior. One of the point can
be raised about adding new opcodes is that it modifies existing unused
opcodes from throwing out of gas to another behavior. While we can
mostly argue that deploying unused opcode is not of much use so no
sane developers would do that, it would be better to just disallow
deployment of unused opcodes.

## Specification

After `HARD_FORK` number, before executing a contract creation
transaction, or adding contract code to the state, do the following
check:

* Iterate over the code bytes one by one.
  * If the code byte is a PUSH(n) opcode, skip next n bytes.
  * If the code byte is a valid opcode or designated invalid
    instruction (`0xfe`), continue.
  * Otherwise, throw out-of-gas.

Note that this check is similar to jump destination checks.

## Copyright

Copyright and related rights waived via
[CC0](https://creativecommons.org/publicdomain/zero/1.0/).
