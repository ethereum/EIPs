---
eip: <to be assigned>
title: Create `eth_symbol` method for JSON-RPC
author: Peter Grassberger (@PeterTheOne)
discussions-to: https://github.com/ethereum/EIPs/issues/3012
status: Draft
type: Standards Track
category : Interface
created: 2020-09-30
---

## Simple Summary
Add `eth_symbol` method to the JSON-RPC that returns the symbol of the native coin of the network.

## Abstract
Wallets (Metamask, Mobile Wallets, Web Wallets, etc.) that deal with multiple networks need some basic information for every blockchain that they connect to. One of those things is the symbol of the native coin of the network. Instead of requiring the user to research and manually add the symbol it could be provided to the wallet via this proposed JSON-RPC endpoint and used automatically.

## Motivation
<!-- The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright. -->
User action is required when adding another to a wallet. There are lists of networks with symbols like https://github.com/ethereum-lists/chains where a user can manually look up the correct values. But this information could easily come from the network itself.

## Specification
<!-- The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)). -->

Method: `eth_symbol`.

Params: none.

Returns: `result` - the native coin symbol, string

Example:

```
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_symbol","params":[],"id":1}'

// Result
{
  "id": 1,
  "jsonrpc": "2.0",
  "result": "ETH"
}
```

## Rationale
<!-- The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion. -->
(Similar to https://eips.ethereum.org/EIPS/eip-695 and symbol from https://eips.ethereum.org/EIPS/eip-20)

todo

## Security Considerations
<!-- All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers. -->
It is a read only endpoint. The information is only as trusted as the JSON-RPC node itself, it could supply wrong information and thereby trick the user in beleaving he/she is dealing with another native coin.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
