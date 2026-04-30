---
title: Generic Relayer Architecture for Smart Accounts
description: A standardized off-chain relayer architecture enabling gasless and token-fee transactions smart accounts.
author: Sean Sing (@seansing), Lucas Lim (@limyeechern), Pedro Cruz (@pedrocrvz), Ben Price (@bennoprice), Luis Schliesske (@gitpusha), Charlie Sibbach (@csibbach), Todd Chapman (@TtheBC01), Nicholas Yong (@yongqjn), Ralph Li (@hsuanmingli), Lyu Min (@rockmin216), Jinzhou Wu (@jinzhou.wu)
status: Draft
type: Standards Track
category: Interface
created: 2025-03-05
requires:
---

## Abstract

This specification proposes a standardized off-chain relayer architecture that enables gasless and sponsored transactions for smart accounts. The standard defines a new set of JSON-RPC methods to support a typical execution flow from account upgrade to intent execution, alongside mechanisms for payment enforcement and an example smart contract interface. These components are designed to support a consistent and modular relayer ecosystem that is easy for wallet developers and dApps to integrate, without requiring changes to the Ethereum base protocol or requiring specific smart account standards.

## Motivation

Smart accounts offer advanced capabilities beyond EOAs, including transaction batching, modular validation, and gas abstraction. Standards such as [EIP-4337](https://eips.ethereum.org/EIPS/eip-4337) and [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) have made these capabilities widely accessible. However, as the ecosystem grows, developers face increasing challenges in coordinating user intent generation, signature handling, and transaction relaying across different implementations.

As transaction relayers become a critical component of the account abstraction ecosystem, the need for a unified JSON-RPC standard has become clear. Such a standard would allow wallets, dApps, and relayers to interoperate seamlessly, reducing integration complexity. Without it, each relayer defines its own endpoints, request formats, and authentication schemes, resulting in fragmentation, inconsistent developer experiences, and additional integration overhead.

To address this, we propose a shared and standardized relayer architecture that can be used with any compatible smart account. The relayer handles both gas sponsorship and transaction submission using existing Ethereum primitives. No changes to protocol-level infrastructure, transaction types, or mempools are required. This makes it easier for wallets and dApps to access smart account features while maintaining flexibility and low integration complexity.

Building on the principles of [EIP-5792](https://eips.ethereum.org/EIPS/eip-5792), the introduction of a new set of `relayer_` RPCs extends the modular execution flow, complementing the existing `wallet_` namespace used between DApps and wallets. With this addition, the full smart account execution path is now clearly delineated: from DApps to wallets, and from wallets to relayers. This refinement lays the foundation for a consistent and standardized experience for relayed transactions regardless of the underlying smart account implementation

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

This specification introduces five new JSON-RPC methods:

- `relayer_getFeeData`: Fetch a token exchange rate.
- `relayer_sendTransaction`: Submit a signed transaction intent to the relayer.
- `relayer_sendTransactionMultichain`: Submit signed transactions to be executed across multiple chains with payment settlement on a single chain.
- `relayer_getCapabilities`: Return the relayer's supported tokens, configuration limits, and fee model.
- `relayer_getStatus`: Check the status of a previously submitted relayed transaction.

### Transaction Lifecycle

An example of sponsored transaction is as follows:

1. A user declares their intent to perform an action (e.g., send tokens or interact with a dApp) via the UI.

2. The wallet or dApp generates the call data and simulates the transaction to estimate gas costs.

3. The wallet or dApp calls `relayer_getCapabilities` to discover supported payment tokens and fee collector addresses, then calls `relayer_getFeeData` to obtain current rates, minimum fees, and quote context with expiry times.

4. Based on the simulation and exchange rate, the wallet calculates the required payment amount and constructs the complete transaction intent (including any required fee transfers to the relayer's fee collector).

5. The user signs the complete intent off-chain.

6. The wallet or dApp submits the signed intent via `relayer_sendTransaction`, receiving a unique task ID for tracking.

7. The relayer validates the signature, verifies payment sufficiency, constructs and submits the appropriate on-chain transaction.

8. Transaction status can be monitored via `relayer_getStatus` using the task ID for its status or errors.

Relayers implementing this architecture will support this general flow pattern, with variations based on their specific capabilities and supported features.

Note: simulation and execution approaches can vary from one smart account and relayer to another. Refer to [Reference Implementation](#reference-implementation) for a sample implementation.

### Key Objects

#### `Payment`

```typescript
type BasePayment = {
  data?: unknown;
};

type TokenPayment = BasePayment & {
  type: "token";
  address: string;
};

type SponsoredPayment = BasePayment & {
  type: "sponsored";
};

type Payment = TokenPayment | SponsoredPayment;
```

```json
{
  "payment": {
    "type": "token",
    "address": "0x036CbD53842c5426634e7929541eC2318f3dCF7e"
  }
}
```

- `type` specifies the paymaster type and it can be `sponsored` or `token`.
- `address` specifies the payment token if `type` is `token` (the zero address denotes the native token).
- `data` optionally specifies arbitrary data to be sent to the relayer (e.g., could be used for authentication).

#### `Status`

```typescript
enum StatusCode {
  Pending = 100,
  Submitted = 110,
  Confirmed = 200,
  Rejected = 400,
  Reverted = 500,
}

type BaseStatus = {
  chainId: string;
  createdAt: number;
};

type PendingStatus = BaseStatus & {
  status: StatusCode.Pending;
};

type SubmittedStatus = BaseStatus & {
  status: StatusCode.Submitted;
  hash: string;
};

type ConfirmedStatus = BaseStatus & {
  status: StatusCode.Confirmed;
  receipt: Receipt;
};

type RejectedStatus = BaseStatus & {
  status: StatusCode.Rejected;
  message: string;
  data?: unknown;
};

type RevertedStatus = BaseStatus & {
  status: StatusCode.Reverted;
  message?: string;
  data: string;
};

type Status =
  | PendingStatus
  | SubmittedStatus
  | ConfirmedStatus
  | RejectedStatus
  | RevertedStatus;

type Receipt = {
  blockHash: string;
  blockNumber: string;
  gasUsed: string;
  logs?: Array<Log> | undefined | null;
  transactionHash: string;
};

type Log = {
  address: string;
  topics: Array<string>;
  data: string;
};
```

#### `TokenDetails`

```typescript
type TokenDetails = {
  address: string;
  decimals: number;
};
```

#### `AuthorizationList`

Signed authorization list as per [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702#set-code-transaction). Authorization list will only be required if the account wishes to upgrade to a smart contract via EIP-7702.

```typescript
type AuthorizationList = Array<{
  address: string;
  chainId: number;
  nonce: number;
  r: string;
  s: string;
  yParity: number;
}>;
```

#### `JSON-RPC`

```typescript
type RpcRequest<TParams> = {
  jsonrpc: "2.0";
  method: string;
  params: TParams;
  id: string | number;
};

type RpcResponse<TResult> = {
  jsonrpc: "2.0";
  id: string | number;
} & RpcResultOrError<TResult>;

type RpcResultOrError<TResult> =
  | {
      result: TResult;
    }
  | {
      error: RpcError;
    };

type RpcError = {
  code: number;
  message: string;
  data?: unknown;
};
```

### Relayer JSON-RPC Methods

#### `relayer_getFeeData`

Fetches the exchange rate in either the chain's native token (denoted by the zero address) or in an specific ERC-20 token. The response includes an `expiry` field indicating when the quote expires. An optional `minFee` may be returned to specify the minimum fee a relayer requires for a transaction. If the simulated gas cost multiplied by the `rate` and `gasPrice` is lower than `minFee`, then `minFee` will be used instead.

Relayers may return an opaque `context` field which SHOULD be included in the call to `relayer_sendTransaction`. This allows the relayer to, for example, return a signature over the quoted rate, gas prices, and expiry. Then when `relayer_sendTransaction` is called, the relayer can simply verify this quote was legitimately signed via the context.

##### RPC Specification

```typescript
type Params = {
  chainId: string;
  token: string;
};

type Result = {
  chainId: string;
  token: TokenDetails;
  rate: number;
  minFee?: string;
  expiry: number;
  gasPrice: string;
  context?: unknown;
};

type Request = RpcRequest<Params>;
type Response = RpcResponse<Result>;
```

##### Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "relayer_getFeeData",
  "params": {
    "chainId": "1",
    "token": "0x036CbD53842c5426634e7929541eC2318f3dCF7e"
  },
  "id": 1
}
```

##### Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "chainId": "1",
    "token": {
      "address": "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
      "decimals": 6
    },
    "rate": 2000.5,
    "minFee": "4.5",
    "expiry": 1755917874,
    "gasPrice": "20000000000" // decimal
  },
  "id": 1
}
```

Using the rate and gasPrice returned by the relayer, the required token payment SHOULD be calculated as below:

$$
\text{tokenFee} = \max\Big(\text{minFee},\; \frac{\text{estimatedGas} \times \text{gasPrice}}{10^{18}} \times \text{rate}\Big)
$$

Where:

- `gasPrice` is the effective gas price returned from the relayer for fee calculation in wei and it is represented in decimals.
- `rate` is a decimal string in token-per-1-native returned from the relayer (e.g., USDC/ETH).
- `minFee` and `tokenFee` are expressed in token units (human-readable).

Using the example response values:

- estimatedGas = 120,000 (by the client)
- gasPrice = 20000000000 (20 gwei or 20,000,000,000 wei)
- rate = 2000.50 (USDC/ETH)
- minFee = "4.5" (USDC)

Token fee calculation:

$$
\text{tokenFee} = \max\Big(4.5,\; \frac{120{,}000 \times 20{,}000{,}000{,}000}{10^{18}} \times 2000.50\Big) = 4.8012\ \text{USDC}
$$

Since the calculated fee (4.8012 USDC) is higher than minFee (4.5 USDC), use the calculated fee.

#### `relayer_sendTransaction`

Submits a signed user intent to the relayer for on-chain execution.

If the `payment.type` is not equal to `sponsored`, the submitted transaction MUST include a transfer of the required fee in an accepted fee token to the relayer's designated fee collector address.

##### RPC Specification

```typescript
type TaskId = string;

type Params = {
  chainId: string;
  payment: Payment;
  to: string; // Target wallet address to execute the transaction on. E.g. User's 7702 EOA address
  data: string; // Encoded executeWithRelayer calldata: batchedCall + validatorData
  context?: unknown;
  authorizationList?: AuthorizationList;
  taskId?: TaskId;
};

type Request = RpcRequest<Params>;
type Response = RpcResponse<TaskId>;
```

##### Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "relayer_sendTransaction",
  "params": {
    "chainId": "1",
    "payment": {
      "type": "token",
      "address": "0x036CbD53842c5426634e7929541eC2318f3dCF7e"
    },
    "to": "0x55f3a93f544e01ce4378d25e927d7c493b863bd7",
    "data": "0x29cb0f49",
    "taskId": "0x0e670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
  },
  "id": 1
}
```

##### Response Example

```json
{
  "jsonrpc": "2.0",
  "result": "0x0e670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",
  "id": 1
}
```

The result is a unique 32 bytes identifier.

##### Task ID Resolution

Clients MAY provide a `taskId` in the request to use as the identifier for the submitted transaction. The relayer MUST resolve the task ID using the following logic:

- If `taskId` is not provided, the relayer MUST generate a new unique task ID.
- If `taskId` is provided but fails format validation (e.g., not a valid 32-byte hex string), the relayer MUST reject the request with error `4213`.
- If `taskId` is provided but a job already exists for it (pending, submitted, or confirmed), the relayer MUST reject the request with error `4214`.
- If `taskId` is provided, passes validation, and has no existing job, the relayer MUST use it as the task identifier.

The following is an example of how a relayer may implement this resolution:

```typescript
function resolveTaskId(
  req: Params,
  idAlreadyExists: (id: string) => boolean,
  isValidId: (id: string) => boolean
): TaskId {
  if (!req.taskId) {
    return generateTaskId();
  }
  if (!isValidId(req.taskId)) {
    throw new RpcError(4213, "Invalid Task ID");
  }
  if (idAlreadyExists(req.taskId)) {
    throw new RpcError(4214, "Duplicate Task ID");
  }
  return req.taskId;
}
```

This allows clients to correlate submitted transactions with their own tracking systems while ensuring uniqueness and validity are always enforced by the relayer.

#### `relayer_sendTransactionMultichain`

Allows a user to submit transactions on multiple chains with settlement occurring on just a single chain. The `params` list in the request MUST contain more than one transaction request.

The first transaction in the list performs the payment. All other transactions MUST specify the sponsored payment type in the `payment` field.

The relayer MUST return a list of transaction IDs each corresponding to its respective transaction request in `params`.

##### RPC Specification

```typescript
type TaskId = string;

type Params = Array<{
  chainId: string;
  payment: Payment;
  to: string;
  data: string;
  context?: unknown;
  authorizationList?: AuthorizationList;
  taskId?: TaskId;
}>;

type Result = Array<TaskId>;

type Request = RpcRequest<Params>;
type Response = RpcResponse<Result>;
```

##### Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "relayer_sendTransactionMultichain",
  "params": [
    {
      "chainId": "1",
      "payment": {
        "type": "token",
        "address": "0x036CbD53842c5426634e7929541eC2318f3dCF7e"
      },
      "to": "0x55f3a93f544e01ce4378d25e927d7c493b863bd7",
      "data": "0x29cb0f49",
      "taskId": "0x0e670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
    },
    {
      "chainId": "8453",
      "payment": {
        "type": "sponsored"
      },
      "to": "0x45f3a93f544e01ce4378d25e927d7c493b863bd7",
      "data": "0x19ca0f49",
      "taskId": "0x0cf041f5929caf14ba166da4a4c5fe929a87cf2673b127b7f5c94167f6d2cd94"
    }
  ],
  "id": 1
}
```

##### Response Example

```json
{
  "jsonrpc": "2.0",
  "result": [
    "0x0e670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",
    "0x0cf041f5929caf14ba166da4a4c5fe929a87cf2673b127b7f5c94167f6d2cd94"
  ],
  "id": 1
}
```

Each item in the result list is a unique 32 bytes identifier.

##### Task ID Resolution

The same task ID resolution logic as `relayer_sendTransaction` applies to each transaction in the request array. If any entry provides a `taskId` that fails format validation, the relayer MUST reject the entire request with error `4213`. If any entry provides a `taskId` for which a job already exists, the relayer MUST reject the entire request with error `4214`.

#### `relayer_getCapabilities`

Returns the relayer's supported payment tokens, gas fee model, and system constraints.

##### RPC Specification

```typescript
type ChainId = string;

type Params = Array<ChainId>;

type Result = Record<
  ChainId,
  {
    feeCollector: string;
    tokens: Array<TokenDetails>;
  }
>;

type Request = RpcRequest<Params>;
type Response = RpcResponse<Result>;
```

##### Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "relayer_getCapabilities",
  "params": ["1"],
  "id": 1
}
```

##### Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "1": {
      "feeCollector": "0x55f3a93f544e01ce4378d25e927d7c493b863bd6",
      "tokens": [
        {
          "address": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
          "decimals": 6
        }
      ]
    }
  },
  "id": 1
}
```

#### `relayer_getStatus`

Fetches the current state of a previously submitted relayed transaction. The relayer MUST return logs in the receipt if the `logs` field is `true` in `Params`. Logs can be disabled to reduce the size of the response object for transactions which emit a large number of logs.

Errors should be tied to the respective reason fields listed in [Status Codes](#status-codes).

##### RPC Specification

```typescript
type Params = {
  id: string;
  logs: boolean;
};

type Request = RpcRequest<Params>;
type Response = RpcResponse<Status>;
```

##### Relayed Status Codes

Relayers MUST use one of the following codes for the `status` field.
Codes categories are similar to [EIP-5792](https://eips.ethereum.org/EIPS/eip-5792) but adapted for relayer-managed intents:

- 1xx: Pending states
- 2xx: Confirmed states
- 4xx: Rejected (Off-chain failures)
- 5xx: Reverted (On-chain failures)

| Code | Category  | Description                                                              |
| ---- | --------- | ------------------------------------------------------------------------ |
| 100  | Pending   | Intent received by the relayer but not yet submitted on-chain.           |
| 110  | Pending   | Transaction submitted on-chain, awaiting confirmation.                   |
| 200  | Confirmed | Transaction included on-chain successfully without reverts.              |
| 400  | Rejected  | Relayer rejected the intent (e.g., invalid signature, insufficient fee). |
| 500  | Reverted  | Transaction reverted completely.                                         |

##### Request Example

The `id` is a unique 64 bytes identifier returned by `relayer_sendTransaction`, as described in [EIP-5792](https://eips.ethereum.org/EIPS/eip-5792).

```json
{
  "jsonrpc": "2.0",
  "method": "relayer_getStatus",
  "params": {
    "id": "0x0e670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",
    "logs": false
  },
  "id": 1
}
```

##### Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "chainId": "1",
    "createdAt": 1755917874,
    "status": 200,
    "receipt": {
      "blockHash": "0x6789b0746d84002f2f258129cfd9714d412e78b4d91b8e61608fac9165988baf",
      "blockNumber": "36314734", // decimals
      "gasUsed": "40178", // decimals
      "transactionHash": "0xd9b01a72502e7f518fb043bfacd1e13b07f24995f404f8cbb60a1212ca8b4c42"
    }
  }
}
```

### Error Codes

Relayers SHOULD use one of the following error codes if a request is rejected. These errors follow the required `code` and `message` fields in the JSON-RPC 2.0 specification for error objects.

| Code   | Message                    | Description                                                                                                                 | Related RPCs                                                                            |
| ------ | -------------------------- | --------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| -32602 | Invalid params             | The relayer cannot parse this request (e.g., missing 0x prefix, leading zeros in chain id, request fails schema validation) | relayer_getFeeData, relayer_sendTransaction, relayer_getCapabilities, relayer_getStatus |
| 4001   | User Rejected Request      | The user rejected submitting the transaction intent (from EIP-1193)                                                         | relayer_sendTransaction                                                                 |
| 4100   | Unauthorized               | The specified address is not connected or not authorized to use this relayer (from EIP-1193)                                | relayer_sendTransaction, relayer_getCapabilities                                        |
| 4200   | Insufficient Payment       | The provided payment amount is insufficient to cover gas costs and relayer fees                                             | relayer_sendTransaction                                                                 |
| 4201   | Invalid Signature          | The signature provided is invalid or does not match the transaction intent                                                  | relayer_sendTransaction                                                                 |
| 4202   | Unsupported Payment Token  | The specified payment token is not supported by this relayer                                                                | relayer_sendTransaction                                                                 |
| 4203   | Rate Limit Exceeded        | The request rate limit has been exceeded for this address or API key                                                        | relayer_getFeeData, relayer_sendTransaction                                             |
| 4204   | Quote Expired              | The provided quote has expired and needs to be refreshed                                                                    | relayer_sendTransaction                                                                 |
| 4205   | Insufficient Balance       | The user's account has insufficient balance to cover the transaction and payment                                            | relayer_sendTransaction                                                                 |
| 4206   | Unsupported Chain          | This relayer does not support the specified chain id                                                                        | relayer_sendTransaction, relayer_getCapabilities                                        |
| 4207   | Transaction Too Large      | The transaction bundle is too large for the relayer to process                                                              | relayer_sendTransaction                                                                 |
| 4208   | Unknown Transaction ID     | This transaction id is unknown or has not been submitted                                                                    | relayer_getStatus                                                                       |
| 4209   | Unsupported Capability     | This relayer does not support a required capability                                                                         | relayer_sendTransaction                                                                 |
| 4210   | Invalid Authorization List | The provided EIP-7702 authorization list is invalid or malformed                                                            | relayer_sendTransaction                                                                 |
| 4211   | Simulation Failed          | The transaction simulation failed and cannot be executed                                                                    | relayer_sendTransaction                                                                 |
| 4212   | Multichain Not Supported   | This relayer does not support multichain transactions                                                                       | relayer_sendTransaction                                                                 |
| 4213   | Invalid Task ID            | The provided `taskId` is not a valid 32-byte hex string                                                                     | relayer_sendTransaction, relayer_sendTransactionMultichain                              |
| 4214   | Duplicate Task ID          | A job for the provided `taskId` has already been created                                                                    | relayer_sendTransaction, relayer_sendTransactionMultichain                              |

### Authentication (Optional)

Relayers MAY require authentication for any `relayer_*` method. This enables controlled or commercial access to relayer services.

- Transport Layer: Authentication SHOULD be implemented via the HTTP Authorization header (RFC 7235).

- Token Format: The header MAY contain any agreed token format. Examples include:

  - Bearer token — Authorization: Bearer \<token\>
  - API key — Authorization: ApiKey \<key\>
  - JSON Web Token (JWT) — Authorization: Bearer eyJhbGciOi...

- Provisioning: The method of issuing or exchanging credentials is out of scope and MAY be handled via methods like developer portals or OAuth flows.

- Applicability:

  - If authentication is required, all relayer\_\* requests MUST include valid credentials.
  - If authentication is not required, clients MAY omit the header.

- Error Handling: If authentication fails or is missing when required, the relayer MUST return:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": 401,
    "message": "Unauthorized"
  },
  "id": 1
}
```

## Rationale

The proposed architecture significantly lowers the barrier for developers to adopt smart accounts by abstracting away the complexities of transaction relaying and gas management. It avoids the need for any base layer protocol changes, special opcodes, or non-standard transaction formats. Instead, it operates entirely within Ethereum's existing call structure and validator logic, making it both cost-efficient and backwards-compatible.

While this architecture was originally motivated by the growing usage of smart accounts enabled through standards like EIP-7702, it is designed to be generic. Any smart account implementation can conform to this standard by exposing the defined contract interfaces and validation logic.

By clearly delineating the responsibilities between the dApp, wallet, and relayer, this architecture promotes modularity and reuse. dApps focus solely on defining user intent, wallets manage authentication and signature collection, and relayers enforce execution and payment on-chain.

## Backwards Compatibility

This standard is fully compatible with any smart account implementation. It does not require the use of EIP-7702 or EIP-4337 specifically. The architecture is entirely off-chain but smart account developers are recommended to develop minimal implementations on the smart account contract for the relayer to simulate and execute.

## Security Considerations

Several safeguards are RECOMMENDED at various roles in the architecture:

- Smart Accounts:

  - **Simulation-Only Reverts**: Relayers may use revert reasons from simulations to inform UX or rejection logic, but these MUST NOT be relied upon for on-chain execution decisions.

  - **Signature Validation**: Validator contracts associated with a smart account are RECOMMENDED to accept and verify EIP-712 compliant signatures.

- Relayers:

  For sponsored transactions, relayers are RECOMMENDED to reject any intents that:

  - Fails to pay them the minimum fees required
  - Lacks valid capability/signature
  - Has malformed or unsafe calls

## Reference Implementation

This section provides an example implementation of how a smart account may expose simulation and execution functions to support relayer-based workflows. It is not part of the formal specification and does not impose any requirements on implementers.

> **Important:**
> Relayers SHOULD NOT have to rely on any particular simulation function existing on a smart contract wallet.
>
> Gas estimation and transaction simulation SHOULD be performed by the wallet, using any preferred method — such as on-chain helper functions, off-chain RPC simulation, or local execution environments.

### Example Smart Account Interface Implementation

```solidity
/**
 * Call as described in EIP-7821
 */
struct BatchedCall {
    Call[] calls;
    uint256 nonce;
}

/**
 * @notice Simulates a sponsored execution, returning gas estimates and error data.
 * @param calls Array of user-defined calls representing the intended actions.
 * @param validatorData Encoded data to calculate validation gas cost. It does not need to be the user's signature.
 */
function simulateExecuteWithRelayer(
        BatchedCall calldata batchedCall,
        address validator,
        bytes calldata validatorData
) external;
```

```solidity
/**
 * @notice Executes a validated user intent along with relayer-defined calls (e.g., fee collection) if any.
 *
 * @param calls Array of user-defined calls representing the intent to execute.
 * @param validatorData Encoded data for the validator.
 */
function executeWithRelayer(
  BatchedCall calldata batchedCall,
  bytes calldata validatorData
) external;
```

#### Step 1: On-Chain Simulation

Before execution, wallets may need to simulate a transaction to estimate gas usage to then calculate the cost of a user's transaction.

There are two primary approaches to achieve this, both serving the same purpose:

##### A. On-Chain Simulation (Optional Helper)

Smart accounts MAY expose a helper such as `simulateExecuteWithRelayer` above that allows wallets or relayers to simulate a full execution path on-chain.

The implementation MAY:

- Run the complete validation process (including relayer logic) to include validation gas cost.

- Always succeed in validation, even if the signature is not from the user, while still requiring a correctly structured signature format.

- Revert with structured diagnostic data, for example:

  - `totalGas` — total estimated gas consumption including validation and relayer logic.
  - `errorData` — revert data or failure diagnostics from user-defined calls.

This approach enables consistent gas estimation using on-chain behavior but remains optional.
Relayers SHOULD NOT depend on this function's existence or output.

##### B. Off-Chain Simulation (Wallet-Managed)

If an on-chain simulation function is not implemented, wallets MAY perform simulation and gas estimation entirely off-chain by simulating the intended call to `executeWithRelayer`.

A typical flow could be:

- The wallet simulates a transaction that calls `executeWithRelayer` locally or via RPC (eg. `eth_call`) to estimate gas and validate execution logic.

- Using the simulation results and the relayer's exchange rate quote, the wallet updates the payment amount or fee parameters within the same `batchedCall`.

- The user then signs the final, updated transaction (which includes any required payment to the relayer) before it is sent to relayer_sendTransaction.

This method gives wallets full flexibility over how gas estimation is performed while maintaining parity with the on-chain simulation helper and the same execution entrypoint.

#### Step 2: Execution

When executing intents, wallets and smart accounts MAY follow the following principles:

- Wallets SHOULD ensure that the calls array passed to `executeWithRelayer` includes any transactions required by the relayer (e.g., token payment for gas). This allows the relayer to decide whether to submit the transaction based on its requirements.

- Smart accounts are RECOMMENDED to execute relayer compensation logic in a non-reverting manner, ensuring user call failures do not revert relayer payments.

- Failures in calls are RECOMMENDED to be caught and surfaced via emitted events or revert messages.

- Validation data are RECOMMENDED to be authorized with an EIP-712 compliant signature.

## Copyright

This work is licensed under the [Creative Commons CC0 1.0 Universal license](https://creativecommons.org/publicdomain/zero/1.0/).
