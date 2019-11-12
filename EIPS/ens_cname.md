---
eip: <to be assigned>
title: ENS support for canonical names
author: Ilan Olkies (@ilanolkies)
discussions-to: <to be assigned>
status: Draft
type: Standards Track
category: ERC
created: 2019-11-11
---

## Simple Summary
ENS CNAME-like resolver.

## Abstract
This EIP specifies a resolver for canonical name resolution for ENS. This permits identifying the same resource with several names. 

## Motivation
In existing systems, resources often have several names that identify the same resource.  For example, the names *mew.eth* and *myetherwallet.eth* may both identify the same address. Similarly, in the case of mailboxes, many organizations provide many names that actually go to the
same mailbox.

Most of these systems have a notion that one of the equivalent set of names is the canonical or primary name and all others are aliases.

DNS provides such a feature using the canonical name (CNAME) RR. A CNAME RR identifies its owner name as an alias, and specifies the corresponding canonical name in the RDATA section of the RR.

## Specification
A new resolver interface is defined, consisting of the following method:
```
function cname(bytes32 node) public view returns (bytes32)
```

A resolver supporting `cname` interface identifies its name as an alias, and specifies the corresponding canonical name. Expresses support to `cname` using ERC-165 interface detection with interface ID `0x54f6ef71`.

If a `cname` resolution is present at a node, no other data should be present; this ensures that the data for a canonical name and its aliases cannot be different.

Canonical name record cause special action in ENS resolution protocol. When resolving fails to find a desired resolution, it must check if the resolution set consists of a `cname` resolution using ERC-165 interface detection. If so, restart the query at the domain name specified as canonical name.

For example, this is how an `addr` query for the alias *mew.eth* should be performed:

![addr_query_example](addr_query_example.png)

Domain names which point at another name should always point at the primary name and not the alias. This avoids extra indirections in
accessing information.

By the robustness principle, domain resolution should not fail when presented with `cname` chains or loops; `cname` chains should be followed and `cname` loops signalled as an error.

## Rationale
This EIP is strongly based on [RFC 1034 - Domain names - concepts and facilities](https://tools.ietf.org/html/rfc1034).

## Backwards Compatibility
No concerns.


## Implementation

### `cname` resolver

WIP

### Resolution protocol

As an example, the protocol for `addr` resolution can be performed as follows:

```
getAddr(name):
    cname = name
    queried  = []
    resolver = ens.resolver(cname)
    while !resolver.supportsInterface(ADDR):
        if resolver.supportsInterface(CNAME):
            cname = resolver.cname(cname)
            if queried.has(cname): throw(“no loops”)
            queried.push(cname)
            resolver = ens.resolver(cname)
    return resolver.addr(cname)
```

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
