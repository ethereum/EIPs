---
eip: yyyy
title: SSZ-REST Engine API Transport
description: Defines the SSZ-REST communication channel for the Engine API with SSZ-encoded payloads over REST
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/eip-yyyy-ssz-rest-engine-api-transport/1
status: Draft
type: Standards Track
category: Core
created: 2026-03-01
---

## Abstract

This EIP defines the `ssz_rest` communication channel for the Engine API, building on the protocol discovery mechanism introduced by [EIP-XXXX](./eip-xxxx.md). Each JSON-RPC Engine API method is mapped to a REST endpoint using SSZ-encoded request and response bodies with `application/octet-stream` content type.

## Motivation

The current Engine API encodes all data as JSON, which is expensive. Every execution payload contains binary data — transaction bytes, hashes, bloom filters — that gets hex-encoded, roughly doubling the size on the wire. On top of that, JSON parsing is CPU-intensive, especially for large payloads with hundreds of transactions.

SSZ is already the native serialization format on the Consensus Layer. The Beacon API uses SSZ-over-REST for performance-sensitive endpoints. It makes sense for the Engine API to do the same — the CL already knows how to speak SSZ, and the EL already has SSZ support for data structures like blobs and execution requests.

This EIP maps each `engine_*` method to a REST endpoint following the `/engine/v{N}/{method}` convention, matching the style of the Beacon API. Request and response bodies are SSZ-encoded and served with `application/octet-stream`. This avoids the overhead of JSON entirely: no hex encoding, no string parsing, no field name repetition — just raw bytes.

For a typical execution payload (~100 KB JSON), SSZ encoding cuts the size roughly in half and eliminates the parsing overhead. At high throughput — many transactions per block, frequent payload exchanges — this adds up.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Protocol Identifier

This EIP defines the `ssz_rest` protocol identifier for use with the communication channel discovery mechanism. An EL client advertising `ssz_rest` support returns:

```json
{
  "protocol": "ssz_rest",
  "url": "localhost:6767"
}
```

### Transport

1. All endpoints are served over HTTP.
2. Request bodies (where applicable) MUST be SSZ-encoded and sent with `Content-Type: application/octet-stream`.
3. Response bodies MUST be SSZ-encoded and returned with `Content-Type: application/octet-stream`.
4. The SSZ-REST endpoint MUST use the same JWT authentication as the JSON-RPC Engine API.
5. Error responses MUST use standard HTTP status codes with a JSON body containing `code` and `message` fields matching the Engine API error codes (e.g., `-38005: Unsupported fork`).
6. The default port for the SSZ-REST Engine API is `6767`.

### Endpoint Mapping

Each JSON-RPC Engine API method maps to a REST endpoint under the `/engine/v{N}/` prefix, where `{N}` is the method version number.

| JSON-RPC Method | HTTP Method | REST Endpoint |
|----------------|-------------|---------------|
| `engine_newPayloadV4` | POST | `/engine/v4/new_payload` |
| `engine_forkchoiceUpdatedV3` | POST | `/engine/v3/forkchoice_updated` |
| `engine_getPayloadV4` | GET | `/engine/v4/get_payload/{payload_id}` |
| `engine_getPayloadBodiesByHashV2` | POST | `/engine/v2/get_payload_bodies_by_hash` |
| `engine_getPayloadBodiesByRangeV2` | POST | `/engine/v2/get_payload_bodies_by_range` |
| `engine_getBlobsV1` | POST | `/engine/v1/get_blobs` |
| `engine_getClientVersionV1` | GET | `/engine/v1/get_client_version` |
| `engine_exchangeCapabilities` | POST | `/engine/v1/exchange_capabilities` |

New method versions introduced by future forks follow the same pattern: increment the version in the path.

### SSZ Encoding

All types use the standard SSZ encoding as defined in the [consensus specs](https://github.com/ethereum/consensus-specs/blob/b5c3b619887c7850a8c1d3540b471092be73ad84/ssz/simple-serialize.md). The mapping from JSON-RPC types to SSZ is:

| JSON-RPC Type | SSZ Type |
|---------------|----------|
| `QUANTITY`, 64 Bits | `uint64` |
| `QUANTITY`, 256 Bits | `uint256` |
| `DATA`, N Bytes | `ByteVector[N]` |
| `DATA` (variable) | `ByteList[MAX_LENGTH]` |
| `BOOLEAN` | `boolean` |
| `Array of T` | `List[T, MAX_LENGTH]` |

### Endpoint Definitions

#### POST `/engine/v4/new_payload`

Equivalent to `engine_newPayloadV4`.

**Request body** — SSZ container:

```python
class NewPayloadRequest(Container):
    execution_payload: ExecutionPayload
    expected_blob_versioned_hashes: List[Bytes32, MAX_BLOB_COMMITMENTS_PER_BLOCK]
    parent_beacon_block_root: Bytes32
    execution_requests: List[ByteList[MAX_REQUEST_BYTES], MAX_REQUEST_TYPES]
```

**Response body** — SSZ container:

```python
class PayloadStatus(Container):
    status: uint8  # 0=VALID, 1=INVALID, 2=SYNCING, 3=ACCEPTED
    latest_valid_hash: Union[None, Bytes32]
    validation_error: ByteList[MAX_ERROR_LENGTH]
```

**Example:**

```
POST /engine/v4/new_payload HTTP/1.1
Host: localhost:6767
Content-Type: application/octet-stream
Authorization: Bearer <jwt-token>

<SSZ-encoded NewPayloadRequest bytes>
```

Response:

```
HTTP/1.1 200 OK
Content-Type: application/octet-stream

<SSZ-encoded PayloadStatus bytes>
```

#### POST `/engine/v3/forkchoice_updated`

Equivalent to `engine_forkchoiceUpdatedV3`.

**Request body** — SSZ container:

```python
class ForkchoiceUpdatedRequest(Container):
    forkchoice_state: ForkchoiceState
    payload_attributes: Union[None, PayloadAttributes]

class ForkchoiceState(Container):
    head_block_hash: Bytes32
    safe_block_hash: Bytes32
    finalized_block_hash: Bytes32

class PayloadAttributes(Container):
    timestamp: uint64
    prev_randao: Bytes32
    suggested_fee_recipient: ByteVector[20]
    withdrawals: List[Withdrawal, MAX_WITHDRAWALS_PER_PAYLOAD]
    parent_beacon_block_root: Bytes32
```

**Response body** — SSZ container:

```python
class ForkchoiceUpdatedResponse(Container):
    payload_status: PayloadStatus
    payload_id: Union[None, ByteVector[8]]
```

#### GET `/engine/v4/get_payload/{payload_id}`

Equivalent to `engine_getPayloadV4`. The `payload_id` is the 8-byte identifier hex-encoded in the URL path.

**Response body** — SSZ container:

```python
class GetPayloadResponse(Container):
    execution_payload: ExecutionPayload
    block_value: uint256
    blobs_bundle: BlobsBundle
    should_override_builder: boolean
    execution_requests: List[ByteList[MAX_REQUEST_BYTES], MAX_REQUEST_TYPES]

class BlobsBundle(Container):
    commitments: List[ByteVector[48], MAX_BLOB_COMMITMENTS_PER_BLOCK]
    proofs: List[ByteVector[48], MAX_BLOB_COMMITMENTS_PER_BLOCK]
    blobs: List[Blob, MAX_BLOB_COMMITMENTS_PER_BLOCK]
```

**Example:**

```
GET /engine/v4/get_payload/0x0301020304050607 HTTP/1.1
Host: localhost:6767
Authorization: Bearer <jwt-token>
```

Response:

```
HTTP/1.1 200 OK
Content-Type: application/octet-stream

<SSZ-encoded GetPayloadResponse bytes>
```

#### POST `/engine/v2/get_payload_bodies_by_hash`

Equivalent to `engine_getPayloadBodiesByHashV2`.

**Request body** — SSZ container:

```python
class GetPayloadBodiesByHashRequest(Container):
    block_hashes: List[Bytes32, MAX_PAYLOAD_BODIES_REQUEST]
```

**Response body** — SSZ container:

```python
class GetPayloadBodiesResponse(Container):
    bodies: List[Union[None, ExecutionPayloadBody], MAX_PAYLOAD_BODIES_REQUEST]

class ExecutionPayloadBody(Container):
    transactions: List[ByteList[MAX_TRANSACTION_LENGTH], MAX_TRANSACTIONS_PER_PAYLOAD]
    withdrawals: List[Withdrawal, MAX_WITHDRAWALS_PER_PAYLOAD]
```

#### POST `/engine/v2/get_payload_bodies_by_range`

Equivalent to `engine_getPayloadBodiesByRangeV2`.

**Request body** — SSZ container:

```python
class GetPayloadBodiesByRangeRequest(Container):
    start: uint64
    count: uint64
```

**Response body** — same `GetPayloadBodiesResponse` as above.

#### POST `/engine/v1/get_blobs`

Equivalent to `engine_getBlobsV1`.

**Request body** — SSZ container:

```python
class GetBlobsRequest(Container):
    versioned_hashes: List[Bytes32, MAX_BLOB_COMMITMENTS_PER_BLOCK]
```

**Response body** — SSZ container:

```python
class GetBlobsResponse(Container):
    blobs: List[Union[None, BlobAndProof], MAX_BLOB_COMMITMENTS_PER_BLOCK]

class BlobAndProof(Container):
    blob: Blob  # ByteVector[131072]
    proof: ByteVector[48]
```

#### GET `/engine/v1/get_client_version`

Equivalent to `engine_getClientVersionV1`.

**Response body** — SSZ container:

```python
class ClientVersion(Container):
    code: ByteVector[2]
    name: ByteList[64]
    version: ByteList[32]
    commit: ByteVector[4]
```

#### POST `/engine/v1/exchange_capabilities`

Equivalent to `engine_exchangeCapabilities`.

**Request body** — SSZ container:

```python
class ExchangeCapabilitiesRequest(Container):
    capabilities: List[ByteList[64], MAX_CAPABILITIES]
```

**Response body** — same structure.

### Error Handling

When the EL encounters an error, it MUST respond with the appropriate HTTP status code and a JSON error body:

| HTTP Status | Engine API Error |
|-------------|-----------------|
| 400 | `-32602: Invalid params` |
| 404 | `-38001: Unknown payload` |
| 409 | `-38002: Invalid forkchoice state`, `-38003: Invalid payload attributes` |
| 413 | `-38004: Too large request` |
| 422 | `-38005: Unsupported fork` |
| 500 | `-32603: Internal error`, `-32000: Server error` |

Error response body:

```json
{
  "code": -38005,
  "message": "Unsupported fork"
}
```

### Versioning

When a new version of an Engine API method is introduced (e.g., `engine_newPayloadV5`), a corresponding new REST endpoint is added (`/engine/v5/new_payload`). The SSZ types for the new version may extend or modify the containers from the previous version.

Old endpoint versions MAY be deprecated following the same rules as the JSON-RPC Engine API.

## Rationale

### Why REST instead of raw SSZ over TCP?

REST is well understood, easy to debug, and infrastructure already exists for it (load balancers, proxies, monitoring). The Beacon API already uses REST with SSZ and it works well. Going lower level (raw TCP, custom framing) adds complexity without a clear benefit for the EL-CL link, which is typically localhost communication.

### Why `application/octet-stream`?

This is the standard content type for binary data. The Beacon API already uses it for SSZ responses. It signals that the body is raw bytes, not text, which is exactly what SSZ is.

### Why map each method individually?

Different methods have different request/response shapes. A generic envelope format would add overhead and complexity. Individual mappings are explicit and easy to implement — each endpoint is a straightforward translation of its JSON-RPC counterpart.

### Why keep JSON for errors?

Errors are small, infrequent, and benefit from human readability. SSZ-encoding error messages would add complexity for minimal gain. JSON errors are easy to log and debug.

## Backwards Compatibility

This EIP introduces a new transport protocol alongside the existing JSON-RPC Engine API. The JSON-RPC API remains fully functional and is always available. Clients that don't implement `ssz_rest` are unaffected.

The CL discovers `ssz_rest` availability through the communication channel discovery mechanism and can fall back to JSON-RPC at any time.

## Security Considerations

The SSZ-REST endpoint MUST use the same JWT authentication mechanism as the JSON-RPC Engine API. All security properties of the existing authentication scheme are preserved.

Implementers MUST validate SSZ-encoded input rigorously. Malformed SSZ data (unexpected lengths, invalid offsets) MUST result in a `400 Bad Request` response and MUST NOT cause crashes or undefined behavior.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
