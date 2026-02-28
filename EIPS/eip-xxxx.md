---
eip: xxxx
title: Engine API Communication Channels
description: A new Engine API method that advertises supported communication protocols and endpoints for improved scalability
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/eip-8160-engine-api-communication-channels/1
status: Draft
type: Standards Track
category: Core
created: 2026-02-27
---

## Abstract

This EIP adds a new Engine API method, `engine_getClientCommunicationChannelsV1`, that returns a list of communication protocols and endpoints supported by the execution layer client. This lets the consensus layer discover and pick a more efficient protocol instead of being stuck with JSON-RPC.

## Motivation

Right now the Engine API only speaks JSON-RPC over HTTP. This works, but JSON is slow. Encoding and decoding large execution payloads — all the transactions, withdrawals, block data — takes real CPU time that adds up. JSON also hex-encodes all binary data (hashes, addresses, calldata), which roughly doubles the size on the wire compared to just sending the raw bytes.

As Ethereum scales — bigger blocks, more transactions, higher throughput — the Engine API becomes a bottleneck. The CL and EL exchange full execution payloads on every block, and doing that through JSON serialization doesn't scale. This is a problem that will only get worse over time.

There are already proposals to move the data itself to SSZ ([EIP-6404](./eip-6404.md), [EIP-7807](./eip-7807.md)), but those don't change the transport layer — you'd still be wrapping SSZ in JSON strings, which kind of defeats the point.

Instead of trying to agree on one replacement protocol right now, this EIP just adds a way for the EL to say "hey, I also speak these other protocols at these endpoints." The CL can then pick whatever works best for it. If the CL doesn't support anything else, it just keeps using JSON-RPC like before — nothing breaks.

This is meant as a first step. Follow-up EIPs can then define how each `engine_*` method maps to a specific alternative protocol (e.g., each JSON-RPC endpoint expressed as an SSZ-REST endpoint with `application/octet-stream`).

## Specification

### `engine_getClientCommunicationChannelsV1`

#### Request

This method takes no parameters.

```json
{
  "jsonrpc": "2.0",
  "method": "engine_getClientCommunicationChannelsV1",
  "params": [],
  "id": 1
}
```

#### Response

Returns a list of `CommunicationChannel` objects describing what the EL supports.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [
    {
      "protocol": "json_rpc",
      "url": "localhost:8551"
    },
    {
      "protocol": "ssz_rest",
      "url": "localhost:6367"
    },
    {
      "protocol": "grpc",
      "url": "localhost:6368"
    }
  ]
}
```

#### `CommunicationChannel` Object

| Field | Type | Description |
|-------|------|-------------|
| `protocol` | `string` | Identifier for the protocol. See [Protocol Identifiers](#protocol-identifiers). |
| `url` | `string` | The endpoint where this protocol is available. |

#### Protocol Identifiers

This EIP defines one protocol identifier:

| Identifier | Description |
|------------|-------------|
| `json_rpc` | JSON-RPC over HTTP, as currently used by the Engine API. |

Follow-up EIPs can define additional identifiers. Some examples:

- `ssz_rest` — SSZ-encoded payloads over REST using `application/octet-stream`.
- `grpc` — gRPC with Protocol Buffers or SSZ serialization.
- `ssz_websocket` — SSZ-encoded payloads over WebSocket.

#### Behavior

1. The EL MUST always include at least one `json_rpc` entry.
2. The EL MAY include additional entries for other protocols it supports.
3. The CL SHOULD call this method on startup to see what's available.
4. The CL MAY switch to any advertised protocol it supports.
5. If the CL doesn't support any of the alternatives, it falls back to `json_rpc`.
6. All protocols MUST use the same JWT authentication as the existing Engine API.

## Rationale

### No hard fork required

This is purely a client-side change. It's just a new Engine API method — no consensus changes, no state transition changes, no new opcodes. Clients can implement it whenever they want and roll it out with a regular release. This makes it low-risk and easy to ship.

### Why discovery instead of config flags?

Hardcoded config is easy to get wrong. If the EL can just tell the CL what it supports, there's less room for human error and it's easier to deploy.

### Why not just pick one protocol?

Because different teams will want different things. Some might like gRPC, others might prefer SSZ-over-REST to stay closer to the Beacon API style. This EIP doesn't pick a winner — it lets clients figure that out themselves. Once something clearly works best, a follow-up EIP can standardize it. The details of each alternative protocol don't need to be figured out now — they can be specified in follow-up EIPs once this discovery mechanism is in place.

### Smooth path to SSZ

The eventual migration to SSZ (as proposed in [EIP-6404](./eip-6404.md) and [EIP-7807](./eip-7807.md)) is a big change. With this EIP in place, the transition becomes much smoother: an EL client can start advertising an `ssz_rest` channel alongside `json_rpc`, and CL clients can switch over at their own pace. There's no flag day where everyone has to cut over at once. Old clients keep using JSON-RPC, new clients can use SSZ — both work at the same time. By the time an SSZ-only future arrives, the infrastructure for protocol negotiation is already there and battle-tested.

## Backwards Compatibility

This just adds a new method. Nothing existing changes. If a client doesn't implement it, the CL just won't get a response and will keep using JSON-RPC as it always has.

## Security Considerations

Alternative protocols need to use the same JWT auth as the current Engine API. The discovery response comes over the already-authenticated JSON-RPC connection, so the trust model stays the same.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
