---
title: Extension of EIP-778 for "client" ENR Entry
description: Add an additional "client" entry in ENRs to improve network health.
author: James Kempton (@JKincorperated)
discussions-to: TBD
status: Draft
type: Standards Track
category: Networking
created: 2024-02-25
requires: 778
---

## Abstract

The Ethereum network consists of nodes running various client implementations. Each client has its own set of features, optimizations, and unique behaviors. Introducing a standardized way to identify client software and its version in the ENR allows for more effective network analysis, compatibility checks, and troubleshooting. This EIP proposes the addition of a "client" field to the ENR.

## Motivation

Understanding the landscape of client software in the Ethereum network is crucial for developers, nodes, and network health assessment. Currently, there is no standardized method for nodes to announce their software identity and version, which can lead to compatibility issues or difficulty in diagnosing network-wide problems. Adding this to the ENR allows clients to audit network health only using discv5.

## Specification

The "client" entry is proposed to be added to ENR following the specifications in EIP-778. This entry is optional and can be omitted by clients that choose not to disclose such information. The key for this entry is `"client"`.

The value for this entry follows the structured string format:
```
Client Name / Version [/Build Version]
```
- `Client Name`: A string identifier for the client software. It should be concise, free of spaces, and representative of the client application.
- `Version`: A string representing the version of the client software in a human-readable format. It is recommended to follow semantic versioning.
- `Build Version`: An optional string representing the build or commit version of the client software. This can be used to identify specific builds or development versions.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.


## Rationale

The choice of a structured string for the "client" entry balances between flexibility, ease of parsing, and providing sufficient detail for practical use cases. Including both human-readable and build-specific versions enables not only identification of the software but also facilitates tracking of bugs or incompatibilities down to specific builds.

## Backwards Compatibility

This EIP is fully backwards compatible as it extends the ENR specification by adding an optional entry. Existing implementations that do not recognize the "client" entry will ignore it without any adverse effects on ENR processing or network behavior.

## Test Cases

A node running Geth version 1.10.0 on the mainnet might have an ENR `client` entry like:
```
Geth/1.10.0
```

A node running an experimental build of Nethermind might include:
```
Nethermind/1.9.53/7fcb567
```

## Security Considerations

Introducing identifiable client information could potentially be used for targeted attacks against specific versions or builds known to have vulnerabilities. It is crucial for clients implementing this EIP to consider the implications of disclosing their identity and version. Users or operators should have the ability to opt-out or anonymize this information if desired.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
