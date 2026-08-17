---
title: Frame Paymaster Web Service
description: Defines a standard paymaster web service and gas estimation flow for frame transactions.
author: Taek Lee (@leekt)
discussions-to: https://ethereum-magicians.org/t/frame-transaction/27617
status: Draft
type: Standards Track
category: Interface
created: 2026-08-17
requires: 8141
---

## Abstract

This EIP defines a standard interface between wallets and paymaster web services for [EIP-8141](./eip-8141.md) frame transactions. It defines two paymaster JSON-RPC methods, `pm_getFramePaymasterStubData` and `pm_getFramePaymasterData`, together with `eth_estimateFrameTransactionGas` for estimating the per-frame execution and state gas limits required by a frame transaction.

The interface separates paymaster-controlled transaction data from gas estimation. A wallet first obtains gas-safe stub data from the paymaster, estimates the complete frame transaction, then asks the paymaster to finalize its authorization without allowing the paymaster to modify sender-controlled transaction fields.

## Motivation

Paymasters are normally exposed to wallets through a web service rather than by requiring the wallet to understand a particular paymaster contract. Existing [ERC-4337](./eip-4337.md) paymaster deployments commonly use a two-stage flow: the paymaster first returns data suitable for gas estimation, and later returns final authorization data once gas and fee fields are fixed.

Frame transactions make payment approval part of the transaction execution model, but they do not remove the need for a wallet-to-paymaster service boundary. In particular:

1. The application may choose who sponsors a transaction, while the wallet constructs and submits the transaction.
2. Paymaster-controlled frames and authorization data contribute to intrinsic gas and can affect validation execution cost.
3. EIP-8141 requires independent execution and state gas limits for each frame, while existing `eth_estimateGas` returns only a single scalar gas estimate.
4. A paymaster should authorize the transaction only after the frames, gas limits, and fee fields it is paying for are fixed.
5. Gas estimation should remain owned by the wallet and its selected node rather than by the paymaster service. Otherwise each paymaster provider can produce different gas values for the same transaction.

Without a standard interface, each paymaster provider would need a provider-specific transaction construction and estimation API. This EIP defines a minimal common flow while leaving sponsorship policy, billing, quotas, and application-specific context to the service provider.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Terminology

A **sender-controlled frame** is a frame constructed by the wallet from the user's requested operation or account validation logic.

A **paymaster-controlled frame** is a frame returned by the paymaster service. This EIP distinguishes:

- `payFrame`: the `VERIFY` frame that approves payment under EIP-8141.
- `postOpFrames`: optional non-`VERIFY` frames executed after the sender-controlled execution frames for settlement or accounting.

A **paymaster-controlled signature** is an EIP-8141 signature entry whose bytes are supplied by the paymaster service.

### Transaction construction

The wallet MUST retain ownership of the outer transaction fields and sender-controlled frames. A paymaster service MUST NOT be allowed to replace the complete transaction object.

The wallet constructs a sponsored frame transaction in the following logical order:

```text
[ sender validation ] [ payFrame ] [ sender execution ] [ postOpFrames ]
```

An `expiry_verify` frame, when used, remains subject to EIP-8141 ordering rules and appears before the sender validation prefix.

A wallet MAY reject paymaster-controlled frames that do not satisfy its local policy even if those frames would be valid under EIP-8141.

### Paymaster service flow

The normal flow is:

```text
 Application              Wallet             Paymaster Service             Node
     |                       |                       |                       |
     | sponsored call       |                       |                       |
     |---------------------->|                       |                       |
     |                       |                       |                       |
     |                       | pm_getFramePaymasterStubData                 |
     |                       |---------------------->|                       |
     |                       |<----------------------|                       |
     |                       |  payFrame stub                                |
     |                       |  postOp stubs                                 |
     |                       |  signature stubs                              |
     |                       |                       |                       |
     |                       | assemble unsigned FrameTx                     |
     |                       |---------------------------------------------->|
     |                       |   eth_estimateFrameTransactionGas             |
     |                       |<----------------------------------------------|
     |                       |   per-frame execution/state limits            |
     |                       |                       |                       |
     |                       | fix frame limits and fee fields               |
     |                       |                       |                       |
     |                       | pm_getFramePaymasterData                      |
     |                       |---------------------->|                       |
     |                       |<----------------------|                       |
     |                       |  final paymaster authorization                |
     |                       |                       |                       |
     |                       | obtain sender signatures                      |
     |                       | submit FrameTx                                |
     |                       |---------------------------------------------->|
```

If `pm_getFramePaymasterStubData` returns `isFinal: true`, the wallet MAY skip `pm_getFramePaymasterData`.

### RPC transaction object

RPC methods in this EIP encode EIP-8141 frames and signatures as follows:

```typescript
type Frame = {
  mode: `0x${string}`;
  flags: `0x${string}`;
  target: `0x${string}` | null;
  limits: {
    execution: `0x${string}`;
    state: `0x${string}`;
  };
  value: `0x${string}`;
  data: `0x${string}`;
};

type FrameSignature = {
  scheme: `0x${string}`;
  signer: `0x${string}`;
  msg: `0x${string}`;
  signature: `0x${string}`;
};

type FrameTransaction = {
  chainId: `0x${string}`;
  nonce: `0x${string}`;
  sender: `0x${string}`;
  frames: Frame[];
  signatures: FrameSignature[];
  fees: {
    maxPriorityFeePerGas: `0x${string}`;
    maxFeePerGas: `0x${string}`;
    maxFeePerBlobGas: `0x${string}`;
  };
  blobVersionedHashes: `0x${string}`[];
};
```

A stub frame MAY use zero gas limits. The wallet replaces those limits with estimates before finalization.

Paymaster-controlled signature entries returned by the stub method MUST have the same `scheme`, `signer`, and `msg` values that will be used in the final transaction. The final method MAY replace only their `signature` bytes.

### `pm_getFramePaymasterStubData`

Returns the paymaster-controlled transaction components required to construct an unsigned frame transaction for gas estimation.

#### Parameters

```typescript
type GetFramePaymasterStubDataParams = [
  FrameTransaction,
  Record<string, unknown>
];
```

The transaction parameter contains the sender-controlled portion of the transaction. It MUST NOT contain a `payFrame` from another paymaster service.

The `context` object is provider-defined and MAY contain policy identifiers, sponsorship modes, billing references, or other application-specific information.

#### Result

```typescript
type GetFramePaymasterStubDataResult = {
  sponsor?: {
    name: string;
    icon?: string;
  };
  payFrame: Frame;
  postOpFrames?: Frame[];
  signatures?: FrameSignature[];
  isFinal?: boolean;
};
```

`payFrame` MUST be a valid EIP-8141 payment-approval frame shape: it MUST use `VERIFY` mode and its flags MUST request `APPROVE_PAYMENT`.

`postOpFrames`, when returned, MUST NOT use `VERIFY` mode. They are placed after the sender-controlled execution frames.

The service SHOULD validate sponsorship policy during this call and SHOULD reject requests it will not sponsor before the wallet performs gas estimation.

The stub response MUST be gas-safe. For every paymaster-controlled field changed by the final response, the stub MUST provide a representation whose intrinsic calldata gas cost is greater than or equal to the corresponding final representation. The service MUST also ensure that execution of the final paymaster-controlled validation data does not require larger frame gas limits than the stub path unless the wallet performs gas estimation again.

A service MAY return `isFinal: true` only if no paymaster-controlled field that affects the authorization will change after gas and fee fields are finalized.

### `eth_estimateFrameTransactionGas`

EIP-8141 transactions specify separate `execution` and `state` limits for every frame. A scalar `eth_estimateGas` result is therefore insufficient to construct the transaction.

This method estimates frame limits for a complete unsigned frame transaction containing sender-controlled frames, paymaster stubs, and signature stubs.

#### Parameters

```typescript
type EstimateFrameTransactionGasParams = [FrameTransaction];
```

For estimation, signature stubs stand in for signatures that cannot exist until the final transaction fields are fixed. The node MUST account for the intrinsic gas implied by the signature scheme and encoded stub bytes. It MAY skip cryptographic verification of stub signatures, but MUST otherwise execute or directly evaluate the same validation and frame paths needed to obtain safe frame limits.

#### Result

```typescript
type EstimateFrameTransactionGasResult = {
  intrinsicGas: `0x${string}`;
  frames: Array<{
    execution: `0x${string}`;
    state: `0x${string}`;
  }>;
};
```

The `frames` array MUST have the same length and ordering as the input transaction's `frames` array.

The returned limits are estimates, not consensus validity guarantees. Wallets MAY apply additional margins.

### `pm_getFramePaymasterData`

Finalizes paymaster-controlled data after frame limits and fee fields have been fixed.

#### Parameters

```typescript
type GetFramePaymasterDataParams = [
  FrameTransaction,
  Record<string, unknown>
];
```

The transaction MUST contain the paymaster-controlled stub components returned by `pm_getFramePaymasterStubData`, with frame limits filled from gas estimation and with the wallet's final fee fields.

#### Result

```typescript
type GetFramePaymasterDataResult = {
  payFrameData?: `0x${string}`;
  postOpFrameData?: `0x${string}`[];
  signatures?: Array<{
    index: `0x${string}`;
    signature: `0x${string}`;
  }>;
};
```

The final method deliberately returns only fields that the paymaster is allowed to finalize.

If `payFrameData` is returned, it replaces only the `data` field of the stub `payFrame`.

If `postOpFrameData` is returned, its length MUST equal the number of stub `postOpFrames`, and each value replaces only the corresponding frame's `data` field.

Each item in `signatures` identifies a paymaster-controlled signature entry introduced by the stub response and replaces only its `signature` field.

The wallet MUST reject a response that attempts to change any other transaction field. In particular, finalization MUST NOT change:

- `chainId`, `nonce`, or `sender`;
- the number, ordering, mode, flags, target, limits, or value of any frame;
- sender-controlled frame data;
- signature `scheme`, `signer`, or `msg` metadata;
- fee fields; or
- blob versioned hashes.

The final data MUST satisfy the gas-safety conditions promised by the stub response. Otherwise the wallet MUST perform gas estimation again before submitting the transaction.

## Rationale

### Why keep a two-stage paymaster flow

Frame transactions make payment approval native to the transaction model, but a remote paymaster still needs to inspect the transaction before agreeing to pay for it. At the same time, the wallet cannot know final per-frame gas limits until paymaster-controlled validation data is present.

A single sponsorship RPC that both estimates gas and returns authorization makes the paymaster service responsible for gas estimation. Existing ERC-4337 paymaster flows have shown why these responsibilities are better separated: the wallet chooses the node and submission path, while the paymaster decides whether it will pay for a transaction with those final limits and fees.

The stub -> estimate -> final split preserves that separation for frame transactions.

### Why the paymaster returns frames instead of opaque data

EIP-8141 does not have a `paymasterAndData` field. Payment approval is represented by a `VERIFY` frame, and optional settlement can be represented by later frames. Returning the paymaster-owned frame fragments preserves the native transaction model and lets the wallet inspect exactly what will execute.

### Why the final response is intentionally narrow

The payer's authorization is normally the last external authorization needed before sender signing and submission. Allowing the final paymaster call to replace a complete transaction would let a sponsor mutate user intent after gas estimation.

The final method therefore permits replacement only of byte fields explicitly reserved for paymaster authorization. All frame structure, limits, fees, sender-controlled calldata, and signature metadata remain fixed.

### Why a new gas estimation RPC is needed

EIP-8141 gives every frame two independent gas limits. Existing `eth_estimateGas` returns one scalar and cannot tell a wallet how to distribute that estimate across frames or between execution and state gas.

`eth_estimateFrameTransactionGas` returns exactly the limits that must be encoded into the frame transaction and keeps estimation on the node side.

### Why stub data must be gas-safe

Paymaster authorization bytes can change intrinsic calldata cost, and the authorization path can affect verification execution cost. If a cheap stub is replaced after estimation by more expensive final data, the completed transaction may be underfunded even though estimation succeeded.

A gas-safe stub gives the wallet an upper-bound representation for paymaster-controlled data before final authorization is available.

### Why sponsorship policy is not standardized

Whether a transaction is sponsored may depend on API credentials, application policy, user quotas, subscriptions, token payments, or offchain billing. These are service-level concerns and do not change EIP-8141 transaction validity. The `context` object therefore remains provider-defined.

## Backwards Compatibility

This EIP introduces new optional JSON-RPC methods and does not change EIP-8141 consensus behavior. Existing wallets, nodes, and paymaster services remain unaffected unless they opt into this interface.

## Security Considerations

### Paymaster mutation of user intent

Wallets MUST construct the final transaction themselves and MUST reject final paymaster responses that mutate fields outside the explicitly paymaster-controlled byte fields. A wallet MUST NOT submit a transaction object returned wholesale by an untrusted paymaster service.

### Stub and final gas mismatch

A malicious or incorrect paymaster can return final data whose intrinsic or execution cost exceeds the stub used for estimation. Wallets MUST enforce the gas-safety rules above and MUST re-estimate whenever those rules cannot be established.

### Untrusted post-operation frames

`postOpFrames` execute as part of the user's transaction. Wallets SHOULD display or policy-check these frames and MUST NOT assume that sponsorship makes them harmless. Paymaster services SHOULD minimize settlement frames and SHOULD avoid granting them authority unrelated to fee settlement.

### Service authentication and API keys

Applications commonly authenticate to paymaster services with credentials that should not be exposed to wallets. Applications MAY proxy the paymaster service through their own backend.

### Authorization expiry

Paymaster services SHOULD bind final authorization to the complete finalized transaction and SHOULD use EIP-8141 expiry mechanisms when authorization is time-limited. Wallets MUST NOT reuse final paymaster data for a materially different transaction.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
