---
eip: 5659
title: Social Media URI Propagation Event
description: A minimal primitive to emit URI events for social media.
author: Tim Daubenschütz (@TimDaub), Auryn Macmillan (@auryn-macmillan)
discussions-to: https://ethereum-magicians.org/t/social-media-uri-propagation-event/10893
status: Draft
type: Standards Track
category: ERC
created: 2022-09-15
---

## Abstract

We introduce a minimal on-chain primitive to emit URIs using Ethereum's event log infrastructure.

## Motivation

The modern social network's base layer is distributing content behind Universal Resource Identifiers as defined by RFC 3986. Any web resource can be identified by an URI or a URL and so upgrading Ethereum with a standard way of distributing content is useful.

## Specification

```solidity
contract Propagator {
  event NewPost(address indexed author, string indexed uri);
  function submit(string calldata uri) external {
    emit NewPost(msg.sender, uri);
  }
}
```

- We strongly recommend all implementers to expose an additional [EIP-165](./eip-165.md) interface.
- The input `string calldata uri` of `function submit(...)` must be an URI as defined by RFC 3986.

## Rationale

- An `event NewPost(...)` contains the two most vital components of a social media post: `address author` and a `string uri`.
- We deliberately refrain from forcing [EIP-165](./eip-165.md) feature detection but strongly recommend it as an addition to all implementers as an optional extension.
- We refrain from emitting a `string tag` component in `event NewPost(...)`. We expect later standards to add it if necessary.

## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
