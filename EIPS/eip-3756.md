---
eip: 3756
title: Cap Gas Limit
description: Set an in-protocol cap for the gas limit
author: lightclient (@lightclient)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2021-08-21
---

## Abstract

Sets an in-protocol cap for the gas limit.

## Motivation

A high gas limit increases pressure on the network. In the benign case, it
increases the size of the state and history faster than we can sustain. In the
malicious case, it amplifies the devestation of certain denial-of-service
attacks.

## Specification

As of the fork block `N`, consider blocks with a `gas_limit` greater than
`30,000,000` invalid.

## Rationale

### Why Cap the Gas Limit

The gas limit is currently under the control of block proposers. They have the
ability to increase the gas limit to whatever they value they desire. This
allows them to bypass the All Core Devs process for protocol changes and may
harm the protocol.

### No Fixed Gas Limit

A valuable property of proposers choosing the gas limit is they can scale it
down quickly if the network becomes unstable or is receiving certain types of
attacks. For this reason, we maintain their ability to lower the gas limit
_below_ 15,000,000.

## Backwards Compatibility
No backwards compatibility issues.

## Test Cases
TBD

## Security Considerations
No security considerations.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
