---
title: Auditable JSON-RPC API Specification
description: Extending the existing RPC specification to be auditable at the request-response lifecycle.
author: Joe Habel (@blockjoe), Cristopher Ortega (@crisog), Pablo Ocampo (@pablocampogo)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Interface
created: 2024-07-23
---

## Abstract

We introduce 8 additional RPC methods and a consumer facing attestation scheme
to make the existing Ethereum RPC Specification auditable at the
request-response life cycle.

## Motivation

Ethereum's RPC is used as the communication layer between an existing Ethereum
execution client and any other external party. This can range from remotely
interacting with a personally hosted node, to working with a commercial
distribution platform. While this commercial distribution is outside of the
scope of core development, and shouldn't directly influence the specification
design, it has become the organic method of application developers looking to
connect web and mobile users to the Ethereum blockchain.

The need for this proposal comes from a myriad of injection attack patterns
that were discovered and disclosed to the Ethereum Foundation in December 2022.
A commonality for these injection patterns comes from the reliance of reading
on-chain data and then using that data to construct future transactions. A few
examples as well as the ecosystem impact will be included in this section, but
the original disclosure will be included as an attached asset for those looking
to deeper explore the full scope and impact of these patterns.

### ENS Redirection Pattern

The first, and most illustrative example of an injection attack that can result
in the full loss of user funds comes from an RPC node being able to specifically
listen for an ENS resolver lookup, and responding to the address call with a
different address.

To illustrate, from the perspective of an RPC node provider, the steps
are as follows:

1. Listen for an `eth_call` method where the `to` field of the transaction
   matches that of an ENS Resolver, `0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63`
   for example.
2. From there, inspect the underlying call data, if it is `0x3b3b57`, then the
   caller is requesting the underlying address.
3. Simply replace the `result` field of the corresponding JSON-RPC request with
   the address of your choice.

Similarly, `*.eth` hosted IPFS interfaces can be redirected to phishing
frontends by listening for the call data to start with `0xb636f6e74656e7448617368`.
From there, simply replace the `result` field with the content hash of a phishing
frontend deployed onto IPFS.

### Smart Contract Registry Redirection Pattern

Similarly to the ENS redirection, a number of DeFi protocols rely on an on-chain
registry pattern to resolve the corresponding contracts that should be available
for user interaction in the frontend. As to avoid singling out a single application
in this example, we'll keep this pattern abstract.

1. Identify a DeFi protocol whose frontend loads its list of pool contracts
   from a registry.
2. Deploy contract(s) that proxy their views back to the actual pool contract,
   but otherwise have the `approve`/`permit` methods give permission to a contract
   that is not the pool.
3. Listen for the `eth_call` corresponding to reading from/the entire registry
   of supported DeFi contracts for a given DeFi application.
4. Replace the underlying address from that registry lookup with the address
   of the contract(s) deployed in 2.

The crux of these injection patterns is that the Ethereum RPC architecture was
inspired by the initial Bitcoin RPC interface between a node and an external
source. The original intention of course being that every participating actor
would be running their own node, and that the RPC interface provided a way for
communicating with that node remotely. This design was based on a trusted
assumption between the RPC source and the underlying consumer. Currently there
is no efficient way for an end RPC consumer to be able to understand if these
injections have actually happened, either in real time or historically.

From the perspective of either a frontend application who can only have a
history of its request-response lifecycle, the majority of requests will have
occurred at the default `"latest"` blog tag for all `eth_call` operations. The
corresponding result of that `eth_call` is simply the resulting hex encoded
data from the execution. As this operation will change based on the state of
the contract, there is currently no way to historically understand if the
difference between 2 identical `eth_call` operations result in different
results because of state changes, or from injection patterns.

All of the proposed changes in this EIP are focused only on making sure that
**AT MINIMUM** any RPC network interaction can be at least replayed against a
trusted node. While this pattern does unlock many new means of more trust
minimized interactions at the consumer RPC level, this foundation of being
able to easily cross-reference prior RPC interactions is beneficial without
waiting for full adoption of trustless light client.

An immediate benefit to the ecosystem as a whole is enabling an evolution of
existing RPC leaderboard tools such as Chainlist to give developers tools to
not just monitor the availability and latency of a potential RPC source, but
also initial tools to start watching for fraudulent behavior. The organic
demand for decentralizing the RPC layer has resulted in normalizing access from
both Chainlist and other "DePIN" networks, where users don't have full
transparency or the information needed to assess if the random node that is
serving their request is actually providing the expected blockchain data,
either in real-time, or historically. This also highlights that "Decentralized
RPC" networks haven't had a means for properly enforcing the correctness of
their node operations up to this point.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 and RFC 8174.

### Additional RPC Methods

The following RPC methods MUST be introduced into the existing Ethereum RPC API specification.

1. [`eth_callAndBlockNumber`](#eth_callandblocknumber)
2. [`eth_getBalanceAndBlockNumber`](#eth_getbalanceandblocknumber)
3. [`eth_getStorageAtAndBlockNumber`](#eth_getstorageatandblocknumber)
4. [`eth_getTransactionCountAndBlockNumber`](#eth_gettransactioncountandblocknumber)
5. [`eth_getCodeAndBlockNumber`](#eth_getcodeandblocknumber)
6. [`eth_getBlockTransactionCountAndBlockNumberByNumber`](#eth_getblocktransactioncountandblocknumberbynumber)
7. [`eth_getUncleCountAndBlockNumberByBlockNumber`](#eth_getunclecountandblocknumberbyblocknumber)
8. [`eth_getLogsAndBlockRange`](#eth_getlogsandblockrange)

All of them follow the same core pattern:

1. Their request parameters are identical to their non-AndBlockNumber method's
   request parameters.
2. Their responses include a named field which corresponds to their
   non-AndBlockNumber method's response, and a `blockNumber` field.

The `blockNumber` field will always be the number that a given block tag
resolves to, or the number as directly passed in.

### `eth_callAndBlockNumber`

Request structure identical to `eth_call`.

Response structure:

```
{
    "result": "eth_call Result"
    "blockNumber": "hex string"
}
```

### `eth_getBalanceAndBlockNumber`

Request structure identical to `eth_getBalance`.

Response structure:

```
{
    "balance": "eth_getBalance Result"
    "blockNumber": "hex string"
}
```


### `eth_getStorageAtAndBlockNumber`

Request structure identical to `eth_getStorageAt`

Response structure:

```
{
    "storage": "eth_getStorageAt Result"
    "blockNumber": "hex string"
}
```

### `eth_getTransactionCountAndBlockNumber`

Request structure identical to `eth_getTransactionCount`

Response structure:

```
{
    "storage": "eth_getTransactionCount Result"
    "blockNumber": "hex string"
}
```

### `eth_getCodeAndBlockNumber`

Request structure identical to `eth_getCode`

Response structure:

```
{
    "code": "eth_getCode Result"
    "blockNumber": "hex string"
}
```

### `eth_getBlockTransactionCountAndBlockNumberByNumber`

Request structure identical to `eth_getBlockTransactionCountByNumber`

Response structure:

```
{
    "transactionCount": "eth_getBlockTransactionCountByNumber Result"
    "blockNumber": "hex string"
}
```

### `eth_getUncleCountAndBlockNumberByBlockNumber`

Request structure identical to `eth_getUncleCountByBlockNumber`

Response structure:

```
{
    "uncleCount": "eth_getUncleCountByBlockNumber Result"
    "blockNumber": "hex string"
}
```

### `eth_getLogsAndBlockRange`

Request structure identical to `eth_getLogs`

Response structure:

```
{
    "logs": "eth_getLogs Result"
    "startingBlock": "hex string"
    "endingBlock": "hex string"
}
```

### RPC Level Attestations

Additionally, RPC nodes SHOULD expose request and response attestation
signatures to the underlying JSON-RPC data. This feature SHOULD be made
available by an optional point of configuration, such as an environment
variable, or command line parameter. Walking through the specification from the
point an RPC request and the response is available:

1. The API server MUST ensure the JSON data of the corresponding request and
   response JSON ordering is consistent. The two key operations are first
   ordering of keys alphabetically, the second is removing any whitespace
   characters.
2. The client MUST then hash the ordered JSON data, for both the request and
   response data packets as individual messages. The hashing algorithm is
   RECOMMENDED as SHA256.
3. The client MUST then sign the corresponding hashed data for each individual
   message. The signing key algorithm is RECOMMENDED as secp256k1. The signed
   data MUST then be encoded as hex strings.
4. Finally, the signed data MUST be packaged alongside the following metadata,
   following the given JSON structure, and SHOULD be packaged along as an
   additional "attestation" field at the root level of the raw JSON response
   object.

```json
{
     "signatureFormat": "secp256k1",
     "hashAlgo":        "sha256",
     "resSignature":    "0xabcdef",
     "reqSignature":    "0xfedcba",
}
```

## Rationale

There are 3 groups of core design choices made:

1. [`*AndBlockNumber` Naming](#andblocknumber-naming)
2. [Re-using the existing ECDSA key for RPC attestations](#reusing-edcsa)
3. [Hashing and Signature Packet Structure](#hashing-and-packet-structure)

These choices have currently been made with backwards compatibility and
flexibility of migrating legacy operations in mind. The initial specification
has attempted to main as modular and neutral as possible in its initial
proposal, but more opinionated implementation choices are welcome.

### AndBlockNumber Naming

We chose this convention simply to illustrate that these methods need to be
present in the existing specification. Some other conventions that we considered:

#### Leveraging `extraData` for exposing the Block Number

The reason we chose to avoid this was from the lack of standardization in
the consumer library ecosystem. While additional JSON fields should be
expected in typing, we couldn't guarantee this data not being dropped
when provided alongside of method types that typically responded with a
single field.

#### Changing the output type of the existing 8 methods

The reason we didn't propose changing the underlying existing methods
was to not cause any issues with backwards compatibility. While these
changes are needed, the cost of migrating all frontends to adopt new
access patterns is too significant of a milestone to overcome.

#### Making a `/v2`route handler

The reason for not proposing this is because we wanted to avoid opening
a door to deeper conversations about what should be happening at this
API interface level moving forward. EIPs on the interface track are rare,
and because of that, there's been a lot of learnings and great ideas for
where the future of Ethereum API access should be moving forward.

We avoided this because we are adamant that **these changes are needed
as a security measure, and not as a quality of life improvement.**

We'd love if this EIP opens up new dialogue for what can happen at the API
interface level, but wanted to keep the scope and importance of this very
narrow.

### Reusing EDCSA

The rationale for including the attestations in general is simply to allow
for an SSL equivalent of the underlying RPC data. Allowing for some ability
to have an evidence trail against a signer of inappropriate behavior when
observed from a pool of other sources.

We chose to reuse the secp256k1 key scheme as it introduced no additional
dependencies for existing client developers, and any existing ecosystem
libraries.

### Hashing and Packet Structure

The current hashing package structure possibly has room for optimizations.
We currently include the `hashAlgo` and `signatureFormat` fields under the
assumption that other hashing algorithms or signature schemes would be
desirable. We chose not to be the ones to make this opinionated choice.
However, making an authoritative choice, say for keccak and secp256k1,
would eliminate the need for these string fields in every response.

Similarly, we're keeping the request and response signatures separate,
but only because of a lack of opinionated choice over the hashing/encoding
scheme of the underlying data.

Having both signatures is important because it creates an accountability
trail, regardless if they're encoded together in a single signature.

The request signature is important because it forces the node operator
to specifically attest that this is the request they are claiming to
serve. A consumer should immediately reject any packet with a non-matching
request signature, as it would indicate trying force in results that
are non-matching in the response.

The response signature allows for a historic trail to compare other
sourced data sources against the request-response pair historically.
Given the evidence of a signed request by the party, an independent
committee would be able to give historic checks to the underlying
response with the additional "blockNumber" context.

## Backwards Compatibility

The proposed improvement maintains full backwards compatibility with the
existing Ethereum RPC API specification and tooling.

## Test Cases


### `eth_getBlockTransactionCountAndBlockNumberByNumber`

Request

```json
{
    "jsonrpc": "2.0",
    "method": "eth_getBlockTransactionCountAndBlockNumberByNumber",
    "params": [
        "latest"
    ],
    "id": 1
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "transactionCount": "0x62",
        "blockNumber": "0x000000000136d74c"
    },
    "attestations": [
        {
            "signature": "f44843e8e48647f2da412c31b3f0c5fdcec46a82536531a3df42156dc74f37b54f7df44c8d5bec156d037b48578f072130b1cd5fc59f6cbae44e640a74464003",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "beb96388c3db94f378b2067943210c72e56d558fef1e0f4d87d10ce6ae5a8372",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```

### `eth_getBalanceAndBlockNumber`

Request

```json
{
    "jsonrpc": "2.0",
    "method": "eth_getBalanceAndBlockNumber",
    "params": [
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f",
        "latest"
    ],
    "id": 1
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "balance": "0x186ba5e0c6783",
        "blockNumber": "0x000000000136d75f"
    },
    "attestations": [
        {
            "signature": "8bf87a45dbfbaf9c0457950376fd5756097e1a2251144ad6c0cc4e43ccc576b53f88c4c2b23e25217e18c8e85bc860da71597ab773cb960ac9c54d0b5bfcd50a",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "1b575e0751f44184bc35e6ab4a2dcc590846a1a8b2c99e441d43733d011b2a08",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```

### `eth_getTransactionCountAndBlockNumber`

Request

```json
{
    "jsonrpc": "2.0",
    "method": "eth_getTransactionCountAndBlockNumber",
    "params": [
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f",
        "0x5bad55"
    ],
    "id": 1
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "transactionCount": "0x1a",
        "blockNumber": "0x00000000005bad55"
    },
    "attestations": [
        {
            "signature": "c119c6b411b2b2f7b941554dedf0084908ef702fb5b7f0ffbdb036f2564048ee3a80577fd7e78bad3755ba2a625cd7b731395b3d8f3d9faba096a1d219e0a705",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "8027d9b1a4628b6217b453921505c192fced7ef7b511a013602103b9aaeb1e72",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```

### `eth_getUncleCountAndBlockNumberByBlockNumber`

Request

```json
{
    "jsonrpc": "2.0",
    "method": "eth_getUncleCountAndBlockNumberByBlockNumber",
    "params": [
        "0x5bad55"
    ],
    "id": 1
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "uncleCount": "0x1",
        "blockNumber": "0x00000000005bad55"
    },
    "attestations": [
        {
            "signature": "2a015891a729fd4cf38dc9deebead24c8b87ea8e80aa78e41662e82ed5475b97db7d7ae82874f800239a80c4bae9785da031862747247b3cf295818a7e81300d",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "93c97e52d8814fd909ac17104868f9c3d37ed14b1543f8b7426eb828bae983ae",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```

### `eth_getStorageAtAndBlockNumber` [BUG]

Request

```json
{
    "jsonrpc": "2.0",
    "method": "eth_getStorageAtAndBlockNumber",
    "params": [
        "0x295a70b2de5e3953354a6a8344e616ed314d7251",
        "0x6661e9d6d8b923d5bbaab1b96e1dd51ff6ea2a93520fdc9eb75d059238b8c5e9",
        "0x65a8db"
    ],
    "id": 1
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "attestations": [
        {
            "signature": "f06a7e7c27f9cdba84d984012fce17a12aba2d0669c41b9e8f3b33609d4505055cfd268d03a32049937a29ac471712c2afa3f5858efe26eae8b4a4866c866b0b",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "74234e98afe7498fb5daf1f36ac2d78acc339464f950703b8c019892f982b90b",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```


### `eth_getCodeAndBlockNumber`

Request

```json
{
    "jsonrpc": "2.0",
    "method": "eth_getCodeAndBlockNumber",
    "params": [
        "0x06012c8cf97bead5deae237070f9587f8e7a266d",
        "0x65a8db"
    ],
    "id": 1
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "code": "0x",
        "blockNumber": "0x000000000136d78f"
    },
    "attestations": [
        {
            "signature": "cee8c5bf9401b22188ab79c933db2b9013701f8e38d05197f63e6d1e112626e1f0774cd4f2b78ac6f93fa6d0a154594982778e0a46f1e35fccd51cecbf83eb0c",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "b125de5d198cf4ddf75dfe07acff68e34183220e89d8bcd9f972fefd4776f697",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```


### `eth_callAndBlockNumber`

Request

```json
{
    "method": "eth_callAndBlockNumber",
    "params": [
        {
            "from": null,
            "to": "0x6b175474e89094c44da98b954eedeac495271d0f",
            "data": "0x70a082310000000000000000000000006E0d01A76C3Cf4288372a29124A26D4353EE51BE"
        },
        "latest",
        {
            "0x1111111111111111111111111111111111111111": {
                "balance": "0xFFFFFFFFFFFFFFFFFFFF"
            }
        }
    ],
    "id": 1,
    "jsonrpc": "2.0"
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "result": "0x0000000000000000000000000000000000000000000000000858898f93629000",
        "blockNumber": "0x000000000136d784"
    },
    "attestations": [
        {
            "signature": "b610685005ac2d27b90c6d640f0a031108f0871c514f3e450d523c5894bf78096bcf89891e569f31f64b14750d9a91f1242bf94d9a3a0b66b9741db6235d1f07",
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msg": "e0bc93c8367e5a7afcaae837b91623bf85d3d152ef185e971bde25af99f2169c",
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```

### `eth_getLogsAndBlockRange`

Request

```json
{
  "id": 1,
  "jsonrpc": "2.0",
  "method": "eth_getLogsAndBlockRange",
  "params": [
    {
      "address": [
        "0xb59f67a8bff5d8cd03f6ac17265c550ed8f33907"
      ],
      "fromBlock": "0x429d3b",
      "toBlock": "latest",
      "topics": [
        "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        "0x00000000000000000000000000b46c2526e227482e2ebb8f4c69e4674d262e75",
        "0x00000000000000000000000054a2d42a40f51259dedd1978f6c118a0f0eff078"
      ]
    }
  ]
}
```

Response

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "Logs": [
            {
                "address": "0xb59f67a8bff5d8cd03f6ac17265c550ed8f33907",
                "topics": [
                    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
                    "0x00000000000000000000000000b46c2526e227482e2ebb8f4c69e4674d262e75",
                    "0x00000000000000000000000054a2d42a40f51259dedd1978f6c118a0f0eff078"
                ],
                "data": "0x000000000000000000000000000000000000000000000000000000012a05f200",
                "blockNumber": "0x429d3b",
                "transactionHash": "0xab059a62e22e230fe0f56d8555340a29b2e9532360368f810595453f6fdd213b",
                "transactionIndex": "0xac",
                "blockHash": "0x8243343df08b9751f5ca0c5f8c9c0460d8a9b6351066fae0acbd4d3e776de8bb",
                "logIndex": "0x56",
                "removed": false
            }
        ],
        "StartingBlock": "0x0000000000429d3b",
        "EndingBlock": "0x000000000136d78b"
    },
    "attestations": [
        {
            "signatures": [
                "a0c72482bb75a6c798a9247498ead875d9812fc4ff88af68b037bd5eba516fff9f020e62d8b3518873e0385c839d03c28b520efba81fbbe9c08fdd2cabb7320f",
                "0923b08453c334ab00401e6cbc573b95cedcb56c4d32d0cb88a21266d6b6f581b1452da349e9ff5ec70a1cef1189e4ffc1f48f1c659dadaa41ad67666044fc08"
            ],
            "signatureFormat": "ssh-ed25519",
            "hashAlgo": "sha256",
            "msgs": [
                "924a8b0437875e43761ae7e6118594311bf9dea457f8961699d215ae3789ec59",
                "092f12c1bb4491987eb369f33777d4576e5673b01511287a2979664449e0c0e5"
            ],
            "identity": "https://stateless.bargsystems.com"
        }
    ]
}
```

## Reference Implementation

```go
// BlockNumber Rewriting Module
package main

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/rpc"
)

type callResultAndBlockNumber struct {
	Result      interface{} `json:"result"`
	BlockNumber string      `json:"blockNumber"`
}

type balanceAndBlockNumber struct {
	Balance     interface{} `json:"balance"`
	BlockNumber string      `json:"blockNumber"`
}

type storageAndBlockNumber struct {
	Storage     interface{} `json:"storage"`
	BlockNumber string      `json:"blockNumber"`
}

type transactionCountAndBlockNumber struct {
	TransactionCount interface{} `json:"transactionCount"`
	BlockNumber      string      `json:"blockNumber"`
}

type codeAndBlockNumber struct {
	Code        interface{} `json:"code"`
	BlockNumber string      `json:"blockNumber"`
}

type blockTransactionCountAndBlockNumber struct {
	TransactionCount interface{} `json:"transactionCount"`
	BlockNumber      string      `json:"blockNumber"`
}

type uncleCountAndBlockNumber struct {
	UncleCount  interface{} `json:"uncleCount"`
	BlockNumber string      `json:"blockNumber"`
}

type logsAndBlockRange struct {
	Logs          interface{} `json:"logs"`
	StartingBlock string      `json:"startingBlock"`
	EndingBlock   string      `json:"endingBlock"`
}

var (
	blockNumberToRegular = map[string]string{
		"eth_callAndBlockNumber":                                   "eth_call",
		"eth_getBalanceAndBlockNumber":                             "eth_getBalance",
		"eth_getStorageAtAndBlockNumber":                           "eth_getStorageAt",
		"eth_getTransactionCountAndBlockNumber":                    "eth_getTransactionCount",
		"eth_getCodeAndBlockNumber":                                "eth_getCode",
		"eth_getBlockTransactionCountAndBlockNumberByNumber":       "eth_getBlockTransactionCountByNumber",
		"eth_getUncleCountAndBlockNumberByBlockNumber":             "eth_getUncleCountByBlockNumber",
		"eth_getLogsAndBlockRange":                                 "eth_getLogs",
	}

	methodToPos = map[string]int{
		"eth_callAndBlockNumber":                                   1,
		"eth_getBalanceAndBlockNumber":                             1,
		"eth_getStorageAtAndBlockNumber":                           2,
		"eth_getTransactionCountAndBlockNumber":                    1,
		"eth_getCodeAndBlockNumber":                                1,
		"eth_getBlockTransactionCountAndBlockNumberByNumber":       0,
		"eth_getUncleCountAndBlockNumberByBlockNumber":             0,
		"eth_getLogsAndBlockRange":                                 0,
	}

	JSONRPCErrorInternal = -32000

	ErrInternalBlockNumberMethodNotMap = &RPCErr{
		Code:          JSONRPCErrorInternal - 23,
		Message:       "block number response is not a map",
		HTTPErrorCode: 500,
	}

	ErrInternalBlockNumberMethodNotNumberEntry = &RPCErr{
		Code:          JSONRPCErrorInternal - 24,
		Message:       "block number response does not have number entry",
		HTTPErrorCode: 500,
	}

	ErrParseErr = &RPCErr{
		Code:          -32700,
		Message:       "parse error",
		HTTPErrorCode: 400,
	}

	ErrInternal = &RPCErr{
		Code:          JSONRPCErrorInternal,
		Message:       "internal error",
		HTTPErrorCode: 500,
	}
)

func remarshalBlockNumberOrHash(current interface{}) (*rpc.BlockNumberOrHash, error) {
	jv, err := json.Marshal(current)
	if err != nil {
		return nil, err
	}

	var bnh rpc.BlockNumberOrHash
	err = bnh.UnmarshalJSON(jv)
	if err != nil {
		return nil, err
	}

	return &bnh, nil
}

func remarshalTagMap(m map[string]interface{}, key string) (*rpc.BlockNumberOrHash, error) {
	if m[key] == nil || m[key] == "" {
		return nil, nil
	}

	current, ok := m[key].(string)
	if !ok {
		return nil, errors.New("expected string")
	}

	return remarshalBlockNumberOrHash(current)
}

func getBlockNumbers(req *RPCReq) ([]*rpc.BlockNumberOrHash, error) {
	_, ok := blockNumberToRegular[req.Method]
	if ok {
		pos := methodToPos[req.Method]

		if req.Method == "eth_getLogsAndBlockRange" {
			var p []map[string]interface{}
			err := json.Unmarshal(req.Params, &p)
			if err != nil {
				return nil, err
			}

			if len(p) <= pos {
				return nil, ErrParseErr
			}

			block, err := remarshalTagMap(p[pos], "blockHash")
			if err != nil {
				return nil, err
			}
			if block != nil && block.BlockHash != nil {
				return []*rpc.BlockNumberOrHash{block}, nil // if block hash is set fromBlock and toBlock are ignored
			}

			fromBlock, err := remarshalTagMap(p[pos], "fromBlock")
			if err != nil {
				return nil, err
			}
			if fromBlock == nil || fromBlock.BlockNumber == nil {
				b := rpc.BlockNumberOrHashWithNumber(rpc.EarliestBlockNumber)
				fromBlock = &b
			}
			toBlock, err := remarshalTagMap(p[pos], "toBlock")
			if err != nil {
				return nil, err
			}
			if toBlock == nil || toBlock.BlockNumber == nil {
				b := rpc.BlockNumberOrHashWithNumber(rpc.LatestBlockNumber)
				toBlock = &b
			}
			return []*rpc.BlockNumberOrHash{fromBlock, toBlock}, nil // always keep this order
		}

		var p []interface{}
		err := json.Unmarshal(req.Params, &p)
		if err != nil {
			return nil, err
		}
		if len(p) <= pos {
			return nil, ErrParseErr
		}

		bnh, err := remarshalBlockNumberOrHash(p[pos])
		if err != nil {
			s, ok := p[pos].(string)
			if ok {
				block, err := remarshalBlockNumberOrHash(s)
				if err != nil {
					return nil, ErrParseErr
				}
				return []*rpc.BlockNumberOrHash{block}, nil
			} else {
				return nil, ErrParseErr
			}
		} else {
			return []*rpc.BlockNumberOrHash{bnh}, nil
		}
	}

	return nil, nil
}

func getBlockNumberMap(rpcReqs []*RPCReq) (map[string][]*rpc.BlockNumberOrHash, error) {
	bnMethodsBlockNumber := make(map[string][]*rpc.BlockNumberOrHash, len(rpcReqs))

	for _, req := range rpcReqs {
		bn, err := getBlockNumbers(req)
		if err != nil {
			return nil, err
		}
		if bn != nil {
			bnMethodsBlockNumber[string(req.ID)] = bn
		}
	}

	return bnMethodsBlockNumber, nil
}

func addBlockNumberMethodsIfNeeded(rpcReqs []*RPCReq, bnMethodsBlockNumber map[string][]*rpc.BlockNumberOrHash) ([]*RPCReq, map[string]string, error) {
	idsHolder := make(map[string]string, len(bnMethodsBlockNumber))

	for _, bns := range bnMethodsBlockNumber {
		for _, bn := range bns {
			if bn.BlockNumber != nil && bn.BlockHash != nil {
				return nil, nil, ErrParseErr
			}

			if bn.BlockHash != nil {
				bH := bn.BlockHash.String()
				_, ok := idsHolder[bH]
				if !ok {
					id, err := generateRandomNumberStringWithRetries(rpcReqs, 12)
					if err != nil {
						return nil, nil, err
					}
					idsHolder[bH] = id
					rpcReqs = append(rpcReqs, buildGetBlockByHashReq(bH, id))
				}
				continue
			}

			switch *bn.BlockNumber {
			case rpc.PendingBlockNumber:
				_, ok := idsHolder["pending"]
				if !ok {
					id, err := generateRandomNumberStringWithRetries(rpcReqs, 12)
					if err != nil {
						return nil, nil, err
					}
					idsHolder["pending"] = id
					rpcReqs = append(rpcReqs, buildGetBlockByNumberReq("pending", id))
				}
			case rpc.EarliestBlockNumber:
				_, ok := idsHolder["earliest"]
				if !ok {
					id, err := generateRandomNumberStringWithRetries(rpcReqs, 12)
					if err != nil {
						return nil, nil, err
					}
					idsHolder["earliest"] = id
					rpcReqs = append(rpcReqs, buildGetBlockByNumberReq("earliest", id))
				}
			case rpc.FinalizedBlockNumber:
				_, ok := idsHolder["finalized"]
				if !ok {
					id, err := generateRandomNumberStringWithRetries(rpcReqs, 12)
					if err != nil {
						return nil, nil, err
					}
					idsHolder["finalized"] = id
					rpcReqs = append(rpcReqs, buildGetBlockByNumberReq("finalized", id))
				}
			case rpc.SafeBlockNumber:
				_, ok := idsHolder["safe"]
				if !ok {
					id, err := generateRandomNumberStringWithRetries(rpcReqs, 12)
					if err != nil {
						return nil, nil, err
					}
					idsHolder["safe"] = id
					rpcReqs = append(rpcReqs, buildGetBlockByNumberReq("safe", id))
				}
			case rpc.LatestBlockNumber:
				_, ok := idsHolder["latest"]
				if !ok {
					id, err := generateRandomNumberStringWithRetries(rpcReqs, 12)
					if err != nil {
						return nil, nil, err
					}
					idsHolder["latest"] = id
					rpcReqs = append(rpcReqs, buildGetBlockByNumberReq("latest", id))
				}
			}
		}
	}

	return rpcReqs, idsHolder, nil
}

func buildGetBlockByHashReq(hash, id string) *RPCReq {
	return &RPCReq{
		JSONRPC: "2.0",
		Method:  "eth_getBlockByHash",
		ID:      json.RawMessage(id),
		Params:  json.RawMessage(fmt.Sprintf(`["%s",false]`, hash)),
	}
}

func buildGetBlockByNumberReq(tag, id string) *RPCReq {
	return &RPCReq{
		JSONRPC: "2.0",
		Method:  "eth_getBlockByNumber",
		ID:      json.RawMessage(id),
		Params:  json.RawMessage(fmt.Sprintf(`["%s",false]`, tag)),
	}
}

func changeBlockNumberMethods(rpcReqs []*RPCReq) map[string]string {
	changedMethods := make(map[string]string, len(rpcReqs))

	for _, rpcReq := range rpcReqs {
		regMethod, ok := blockNumberToRegular[rpcReq.Method]
		if !ok {
			continue
		}

		changedMethods[string(rpcReq.ID)] = rpcReq.Method
		rpcReq.Method = regMethod
	}

	return changedMethods
}

func generateRandomNumberStringWithRetries(rpcReqs []*RPCReq, n int) (string, error) {
	retries := 0
	maxRetries := 5
	id := ""
	var err error

	for retries < maxRetries {
		id, err = generateRandomNumberString(12)
		if err != nil {
			return "", ErrInternal
		}

		// Check if the generated ID is repeated in the slice
		if !isIDRepeated(id, rpcReqs) {
			break
		}

		retries++
	}

	if retries == maxRetries {
		return "", ErrInternal
	}

	return id, nil
}

func generateRandomNumberString(n int) (string, error) {
	// The maximum value for a random number with n digits
	max := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(n)), nil)

	// Generate a random number
	randomNumber, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}

	return randomNumber.String(), nil
}

func isIDRepeated(id string, rpcReqs []*RPCReq) bool {
	for _, rpcReq := range rpcReqs {
		if string(rpcReq.ID) == id {
			return true
		}
	}
	return false
}

func getBlockHolder(responses []*RPCResJSON, idsHolder map[string]string) (map[string]string, []*RPCResJSON, error) {
	bnHolder := make(map[string]string, len(idsHolder))
	var responsesWithoutBN []*RPCResJSON

	for _, res := range responses {
		var bnMethod bool
		for content, id := range idsHolder {
			if string(res.ID) == id {
				resMap, ok := res.Result.(map[string]interface{})
				if !ok {
					return nil, nil, ErrInternalBlockNumberMethodNotMap
				}

				block, ok := resMap["number"].(string)
				if !ok {
					return nil, nil, ErrInternalBlockNumberMethodNotNumberEntry
				}

				bnHolder[content] = block
				bnMethod = true
			}
		}
		if !bnMethod {
			responsesWithoutBN = append(responsesWithoutBN, res)
		}
	}

	return bnHolder, responsesWithoutBN, nil
}

func changeBlockNumberResponses(responses []*RPCResJSON, changedMethods, idsHolder map[string]string, bnMethodsBlockNumber map[string][]*rpc.BlockNumberOrHash) ([]*RPCResJSON, error) {
	bnHolder, cleanRes, err := getBlockHolder(responses, idsHolder)
	if err != nil {
		return nil, err
	}

	for _, res := range cleanRes {
		originalMethod, ok := changedMethods[string(res.ID)]
		if !ok {
			continue
		}

		err := changeResultToBlockNumberStruct(res, bnHolder, bnMethodsBlockNumber, originalMethod)
		if err != nil {
			return nil, err
		}
	}

	return cleanRes, nil
}

func getBlockNumber(res *RPCResJSON, bnHolder map[string]string, bnMethodsBlockNumber map[string][]*rpc.BlockNumberOrHash) []string {
	bns := bnMethodsBlockNumber[string(res.ID)]

	var blocks []string
	for _, bn := range bns {
		if bns[0].BlockHash != nil {
			blocks = append(blocks, bnHolder[bn.BlockHash.String()])
			break // block hash can just be one per ID
		}
		bnString := bn.BlockNumber.String()
		tagBlock, ok := bnHolder[bnString]
		if ok {
			blocks = append(blocks, tagBlock)
			continue
		}
		blocks = append(blocks, bnString)
	}

	return blocks
}

func changeResultToBlockNumberStruct(res *RPCResJSON, bnHolder map[string]string, bnMethodsBlockNumber map[string][]*rpc.BlockNumberOrHash, originalMethod string) error {
	blockNumber := getBlockNumber(res, bnHolder, bnMethodsBlockNumber)

	switch originalMethod {
	case "eth_callAndBlockNumber":
		res.Result = callResultAndBlockNumber{
			Result:      res.Result,
			BlockNumber: blockNumber[0],
		}
	case "eth_getBalanceAndBlockNumber":
		res.Result = balanceAndBlockNumber{
			Balance:     res.Result,
			BlockNumber: blockNumber[0],
		}
	case "eth_getStorageAtAndBlockNumber":
		res.Result = storageAndBlockNumber{
			Storage:     res.Result,
			BlockNumber: blockNumber[0],
		}
	case "eth_getTransactionCountAndBlockNumber":
		res.Result = transactionCountAndBlockNumber{
			TransactionCount: res.Result,
			BlockNumber:      blockNumber[0],
		}
	case "eth_getCodeAndBlockNumber":
		res.Result = codeAndBlockNumber{
			Code:        res.Result,
			BlockNumber: blockNumber[0],
		}
	case "eth_getBlockTransactionCountAndBlockNumberByNumber":
		res.Result = blockTransactionCountAndBlockNumber{
			TransactionCount: res.Result,
			BlockNumber:      blockNumber[0],
		}
	case "eth_getUncleCountAndBlockNumberByBlockNumber":
		res.Result = uncleCountAndBlockNumber{
			UncleCount:  res.Result,
			BlockNumber: blockNumber[0],
		}
	case "eth_getLogsAndBlockRange":
		fromBlock := blockNumber[0]
		toBlock := blockNumber[0]
		if len(blockNumber) > 1 {
			toBlock = blockNumber[1]
		}
		res.Result = logsAndBlockRange{
			Logs:          res.Result,
			StartingBlock: fromBlock,
			EndingBlock:   toBlock,
		}
	}

	return nil
}
```


```go
// RPC Request/Response Attestation Module

package main

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
)

type Attestation struct {
	SignatureFormat string `json:"signatureFormat,omitempty"`
	HashAlgo        string `json:"hashAlgo,omitempty"`
	Identiy         string `json:"identity,omitempty"`
	ResMsgHash      string `json:"resMsg"`
	ResSignature    string `json:"resSignature"`
	ReqMsgHash      string `json:"reqMsg"`
	ReqSignature    string `json:"reqSignature"`
}

type RPCResJSONAttested struct {
	JSONRPC     string          `json:"jsonrpc,omitempty"`
	ID          json.RawMessage `json:"id,omitempty"`
	Error       *RPCErr         `json:"error,omitempty"`
	Result      interface{}     `json:"result,omitempty"`
	Attestation *Attestation    `json:"attestation,omitempty"`
}

func newErrorResponse(err *RPCErr, id json.RawMessage) RPCResJSONAttested {
	return RPCResJSONAttested{
		JSONRPC: "2.0",
		Error:   err,
	}
}

func AttestableError(jsonErr *RPCErr) ([]byte, error) {
	return json.Marshal(jsonErr)
}

func AttestableJSON(result interface{}) ([]byte, error) {
	return json.Marshal(result)
}

func hashAndSign(data []byte, signer *ecdsa.PrivateKey) (string, string, error) {
	msgFixed := sha256.Sum256(data)
	msg := msgFixed[:]
	sig, err := Sign(msg, signer)
	if err != nil {
		return "", "", err
	}

	return hex.EncodeToString(msg), hex.EncodeToString(sig), nil
}

func Attest(resData []byte, reqData []byte, identity string, signer *ecdsa.PrivateKey, full bool) (Attestation, error) {
	resMsg, resSig, err := hashAndSign(resData, signer)
	if err != nil {
		return Attestation{}, nil
	}

	reqMsg, reqSig, err := hashAndSign(reqData, signer)
	if err != nil {
		return Attestation{}, nil
	}

	var attestation Attestation
	if full {
		attestation = Attestation{
			SignatureFormat: "secp256k1",
			ResMsgHash:      resMsg,
			HashAlgo:        "sha256",
			Identiy:         identity,
			ResSignature:    resSig,
			ReqMsgHash:      reqMsg,
			ReqSignature:    reqSig,
		}
	} else {
		attestation = Attestation{
			ResMsgHash:   resMsg,
			ResSignature: resSig,
			ReqMsgHash:   reqMsg,
			ReqSignature: reqSig,
		}

	}
	return attestation, nil
}

func Attestor(res *RPCResJSON, req *RPCReq, identity string, signer *ecdsa.PrivateKey, full bool) (*RPCResJSONAttested, error) {
	var resAttestable []byte
	var err error
	if res.Result == nil {
		resAttestable, err = AttestableError(res.Error)
		if err != nil {
			return nil, err
		}
	} else {
		resAttestable, err = AttestableJSON(res.Result)
		if err != nil {
			return nil, err
		}
	}

	reqAttestable, err := AttestableJSON(req)
	if err != nil {
		return nil, err
	}

	attestation, err := Attest(resAttestable, reqAttestable, identity, signer, full)
	if err != nil {
		return nil, err
	}
	attested := &RPCResJSONAttested{
		Result:      res.Result,
		Error:       res.Error,
		JSONRPC:     res.JSONRPC,
		ID:          res.ID,
		Attestation: &attestation,
	}
	return attested, nil
}

func AttestRess(ress []*RPCResJSON, reqMap map[string]*RPCReq, identity string, signer *ecdsa.PrivateKey) ([]*RPCResJSONAttested, error) {
	var attestedRess []*RPCResJSONAttested
	for i, result := range ress {
		attested, err := Attestor(result, reqMap[string(result.ID)], identity, signer, i == 0)
		if err != nil {
			return nil, err
		}
		attestedRess = append(attestedRess, attested)
	}

	return attestedRess, nil
}
```

## Security Considerations

This EIP comes in response to a previous Security Disclosure. The changes
proposed are targeted at the API level, and leverage existing dependencies and
tools that are otherwise existing client dependencies. Further discussions
are needed about addressing these patterns in RPC client methods that are not
formally included in the Ethereum RPC API specification, as the scope of this
EIP is restricted solely to the official specification.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
