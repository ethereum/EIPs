---
eip: <to be assigned>
title: Cap Gas Target
description: Set an in-protocol cap for the gas target
author: lightclient (@lightclient)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2021-08-21
---

## Abstract

Sets an in-protocol cap for the gas target.

## Motivation

High gas target increases pressure on the network. In the benign case, it
increases the state and history faster than we can sustain. In the malicious
case, it amplifies the devestation of certain denial-of-service attacks.

## Specification

As of the fork block `N`, consider blocks with a `gas_target` greater than
`15,000,000` invalid.

## Rationale

### Why Cap the Gas Target

The gas target is currently under the control of block proposers. They have the
ability to increase the gas target to whatever they value they desire. This
allows them to bypass the All Core Devs process for protocol changes and may
harm the protocol.

### No Fixed Gas Target

A valuable property of proposers choosing the gas target is they can scale it
down quickly if the network becomes unstable or is receiving certain types of
attacks. For this reason, we maintain their ability to lower the gas target
_below_ 15,000,000.

## Backwards Compatibility
No backwards compatibility issues.

## Test Cases
TBD

## Security Considerations
No security considerations.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
