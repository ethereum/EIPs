---
eip: xxxx
title: Engine API Communication Channels
description: Extends engine_exchangeCapabilities to advertise supported communication protocols and endpoints
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/eip-8160-engine-api-communication-channels/1
status: Draft
type: Standards Track
category: Core
created: 2026-02-27
---

## Abstract

This EIP extends the Engine API's `engine_exchangeCapabilities` method into `engine_exchangeCapabilitiesV2`, adding a `supportedProtocols` field to the response. This lets the EL advertise alternative communication protocols (e.g., SSZ-REST, gRPC) and their endpoints alongside the existing JSON-RPC capability exchange.

## Motivation

Right now the Engine API only speaks JSON-RPC over HTTP. This works, but JSON is slow. Encoding and decoding large execution payloads — all the transactions, withdrawals, block data — takes real CPU time that adds up. JSON also hex-encodes all binary data (hashes, addresses, calldata), which roughly doubles the size on the wire compared to just sending the raw bytes.

As Ethereum scales — bigger blocks, more transactions, higher throughput — the Engine API becomes a bottleneck. The CL and EL exchange full execution payloads on every block, and doing that through JSON serialization doesn't scale. This is a problem that will only get worse over time.

There are already proposals to move the data itself to SSZ ([EIP-6404](./eip-6404.md), [EIP-7807](./eip-7807.md)), but those don't change the transport layer — you'd still be wrapping SSZ in JSON strings, which kind of defeats the point.

The `engine_exchangeCapabilities` method already exists for clients to discover what the other side supports. Extending it with protocol information is a natural fit — no new method needed, just a richer handshake. The CL can then pick whatever protocol works best for it. If the CL doesn't support anything else, it just keeps using JSON-RPC like before — nothing breaks.

This is meant as a first step. Follow-up EIPs can then define how each `engine_*` method maps to a specific alternative protocol (e.g., each JSON-RPC endpoint expressed as an SSZ-REST endpoint with `application/octet-stream`).

## Specification

### `engine_exchangeCapabilitiesV2`

This method extends `engine_exchangeCapabilities` (V1) by adding a `supportedProtocols` field to the response.

#### Request

* method: `engine_exchangeCapabilitiesV2`
* params:
    1. `Array of string` — Array of strings, each string is a name of a method supported by the consensus layer client software.

```json
{
  "jsonrpc": "2.0",
  "method": "engine_exchangeCapabilitiesV2",
  "params": [
    [
      "engine_newPayloadV4",
      "engine_forkchoiceUpdatedV3",
      "engine_getPayloadV4"
    ]
  ],
  "id": 1
}
```

#### Response

* result: `object`
    - `capabilities`: `Array of string` — Array of strings, each string is a name of a method supported by the execution layer client software.
    - `supportedProtocols`: `Array of CommunicationChannel` — List of communication protocols the EL supports.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "capabilities": [
      "engine_newPayloadV4",
      "engine_forkchoiceUpdatedV3",
      "engine_getPayloadV4",
      "engine_exchangeCapabilitiesV2"
    ],
    "supportedProtocols": [
      {
        "protocol": "json_rpc",
        "url": "localhost:8551"
      },
      {
        "protocol": "ssz_rest",
        "url": "localhost:6767"
      },
      {
        "protocol": "grpc",
        "url": "localhost:6768"
      }
    ]
  }
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

1. The request format is identical to `engine_exchangeCapabilities` (V1) — an array of method names supported by the CL.
2. The EL MUST always include at least one `json_rpc` entry in `supportedProtocols`.
3. The EL MAY include additional entries for other protocols it supports.
4. The CL SHOULD call this method on startup to discover available protocols.
5. The CL MAY switch to any advertised protocol it supports.
6. If the CL doesn't support any of the alternatives, it falls back to `json_rpc`.
7. All protocols MUST use the same JWT authentication as the existing Engine API.
8. The `engine_exchangeCapabilitiesV2` method MUST NOT appear in the `capabilities` response list (same rule as V1).

### Deprecation of `engine_exchangeCapabilities` (V1)

Once `engine_exchangeCapabilitiesV2` is adopted:

1. CL clients SHOULD prefer calling `engine_exchangeCapabilitiesV2` over the unversioned `engine_exchangeCapabilities`.
2. EL clients MUST continue supporting the unversioned `engine_exchangeCapabilities` for backwards compatibility. If called, it behaves exactly as before — returning a flat array of method names.
3. CL clients that receive a method-not-found error for V2 SHOULD fall back to V1.

## Rationale

### Why extend exchangeCapabilities instead of a new method?

The CL already calls `engine_exchangeCapabilities` on startup to figure out what the EL supports. Adding protocol discovery to the same handshake is a natural extension — one call, all the information. No need for a separate discovery step.

### No hard fork required

This is purely a client-side change. It's just a new version of an existing Engine API method — no consensus changes, no state transition changes, no new opcodes. Clients can implement it whenever they want and roll it out with a regular release. This makes it low-risk and easy to ship.

### Why discovery instead of config flags?

Hardcoded config is easy to get wrong. If the EL can just tell the CL what it supports, there's less room for human error and it's easier to deploy.

### Why not just pick one protocol?

Because different teams will want different things. Some might like gRPC, others might prefer SSZ-over-REST to stay closer to the Beacon API style. This EIP doesn't pick a winner — it lets clients figure that out themselves. Once something clearly works best, a follow-up EIP can standardize it. The details of each alternative protocol don't need to be figured out now — they can be specified in follow-up EIPs once this discovery mechanism is in place.

### Smooth path to SSZ

The eventual migration to SSZ (as proposed in [EIP-6404](./eip-6404.md) and [EIP-7807](./eip-7807.md)) is a big change. With this EIP in place, the transition becomes much smoother: an EL client can start advertising an `ssz_rest` channel alongside `json_rpc`, and CL clients can switch over at their own pace. There's no flag day where everyone has to cut over at once. Old clients keep using JSON-RPC, new clients can use SSZ — both work at the same time. By the time an SSZ-only future arrives, the infrastructure for protocol negotiation is already there and battle-tested.

## Backwards Compatibility

The unversioned `engine_exchangeCapabilities` (V1) continues to work as before. CL clients that don't know about V2 keep calling V1 and get a flat array of method names — no change for them. CL clients that call V2 on an EL that only supports V1 will get a method-not-found error and can fall back gracefully.

The response format changes from a flat array to an object with `capabilities` and `supportedProtocols` fields, so V2 callers must handle the new shape.

## Security Considerations

Alternative protocols need to use the same JWT auth as the current Engine API. The discovery response comes over the already-authenticated JSON-RPC connection, so the trust model stays the same.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
