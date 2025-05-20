---
eip: <TBD>
title: Genesis File Format Standardization
author: Justin Florentine (@jflo) <justin@florentine.us>
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-genesis-json-standardization/24271
status: Draft
type: Informational
category: Core
created: 2025-05-19
requires: 
---

## Simple Summary

Standardize the format of the `genesis.json` file used to initialize modern (post-merge) Ethereum chains, aligning it with Geth’s current implementation and providing a JSON Schema for validation.

## Abstract

This EIP defines a canonical structure for Ethereum genesis files (`genesis.json`) used to bootstrap Ethereum networks. The standard aligns with the de facto structure implemented by Geth (Go-Ethereum) and introduces a JSON Schema to ensure consistency and tool compatibility across clients.

## Motivation

The lack of an official standard for the `genesis.json` file has led to incompatibilities, bugs and confusion, as well as added workload for those running multiple clients together in test networks. This EIP aims to reduce ambiguity by defining a consistent structure and enabling tooling through schema-based validation.

## Specification

The canonical genesis file MUST be a JSON object with the following top-level fields:

### Top-Level Fields

| Field           | Type              | Required | Description                                                     |
|-----------------|-------------------|----------|-----------------------------------------------------------------|
| `config`        | `object`          | Yes      | Chain configuration parameters.                                 |
| `alloc`         | `object`          | No       | Map of addresses to pre-allocated balances and/or code/storage. |
| `blobSchedule`    | `object`          | No       | EIP-4844 DAS configuration parameters.                          |
| `nonce`         | `string`          | No       | Hex-encoded nonce (8 bytes).                                    |
| `timestamp`     | `string`          | No       | Hex-encoded UNIX timestamp.                                     |
| `extraData`     | `string`          | No       | Arbitrary extra data (max 32 bytes for Ethereum Mainnet).       |
| `gasLimit`      | `string`          | Yes      | Hex-encoded block gas limit.                                    |
| `difficulty`    | `string`          | Yes      | Hex-encoded block difficulty.                                   |
| `mixhash`       | `string`          | No       | Hex-encoded mix hash.                                           |
| `coinbase`      | `string`          | No       | Hex-encoded address.                                            |
| `gasUsed`       | `string`          | No       | Initial gas used, defaults to `"0x0"`.                          |
| `baseFeePerGas` | `string`          | No       | Initial base fee per gas.                                       |

### `config` Object

The `config` object contains hardfork activation block numbers and fork configurations. Known keys include:

| Field     | Type     | Description                                      |
|-----------|----------|--------------------------------------------------|
| `chainId` | `number` | unique identifier for the blockchain.            |
| `<hardforkName>`| `number` | block height or timestamp to activate the named hardfork.|
|`terminalTotalDifficulty`| `number` | difficulty after which to switch from PoW to PoS.|
|`terminalTotalDifficultyPassed`| `boolean` | PoS at genesis or not |
|`depositContractAddress` | `string` | Ethereum address for the deposit contract |

### `blobSchedule` Object

| Field    | Type     | Description                                  |
|----------|----------|----------------------------------------------|
| `target` | `number` | desired number of blobs to include per block |
| `max` | `number` | maximum number of blobs to include per block |
| `updateFraction` | `number` | input to pricing formula per EIP-4844 |

### `alloc` Object

The `alloc` field is optional and maps addresses (as lowercase hex strings) to the following object:

| Field         | Type     | Description                                     |
|---------------|----------|-------------------------------------------------|
| `balance`     | `string` | decimal balance in wei.                         |
| `code`        | `string` | Hex-encoded EVM bytecode.                       |
| `nonce`      | `string` | decimal value.
| `storage`     | `object` | Key-value hex map representing initial storage. |

## JSON Schema


```json

{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$defs": {
  	"hexOrDecimal48": {
    		"type": "string",
    		"pattern": "^(0x[0-9a-fA-F]{1,12}|[0-9]{1,12})$"
  	},
    "address": {
      "type": "string",
      "pattern":  "^0x[0-9a-fA-F]{40}$"
    },
    "hash": {
      "type": "string",
      "pattern": "^0x[0-9a-fA-F]{64}$"
    }
  },
  "title": "Ethereum Genesis File",
  "type": "object",
  "required": ["config"],
  "properties": {
    "config": {
      "type": "object",
      "required": ["chainId"],
      "properties": {
        "chainId": { "type": "integer" },
        "homesteadBlock": { "type": "integer" },
        "daoForkBlock": { "type": "integer" },
        "eip150Block": { "type": "integer" },
        "eip155Block": { "type": "integer" },
        "eip158Block": { "type": "integer" },
        "byzantiumBlock": { "type": "integer" },
        "constantinopleBlock": { "type": "integer" },
        "petersburgBlock": { "type": "integer" },
        "istanbulBlock": { "type": "integer" },
        "berlinBlock": { "type": "integer" },
        "londonBlock": { "type": "integer" },
        "arrowGlacierBlock": { "type": "integer" },
        "grayGlacierBlock": { "type": "integer" },
        "terminalTotalDifficulty": { "type": "integer" },
        "terminalTotalDifficultyPassed": { "type": "boolean" },
        "mergeNetsplitBlock": { "type": "integer"},
        "shanghaiTime": { "type": "integer"},
        "cancunTime": { "type": "integer"},
        "blobSchedule": {
          "type": "object",
          "additionalProperties": {
              "type": "object",
              "properties": {
                "target": { "type": "integer" },
                "max": { "type" : "integer" },
                "baseFeeUpdateFraction": { "type" : "integer" }
              }
          }
        },
        "depositContractAddress": { "$ref": "#/$defs/address"},
        "pragueTime": { "type": "integer"},
        "osakaTime": { "type": "integer"},
        "ethash": { "type": "object" },
        "clique": {
          "type": "object",
          "properties": {
            "period": { "type": "integer" },
            "epoch": { "type": "integer" }
          }
        },
        "proofOfStake": { "type": "object" }
      },
      "additionalProperties": false
    },
    "nonce": { "$ref": "#/$defs/hexOrDecimal48" },
    "timestamp": { "$ref": "#/$defs/hexOrDecimal48" },
    "extraData": { 
	    "anyOf": [ 
		    {"type": "string", "const": "" },
		    {"type": "string", "pattern": "^0x([0-9a-fA-F]{2})*$" }
	    ]
    },
    "gasLimit": { "$ref": "#/$defs/hexOrDecimal48" },
    "difficulty": { "$ref": "#/$defs/hexOrDecimal48" },
    "mixhash": { "$ref": "#/$defs/hash" },
    "coinbase": { "$ref": "#/$defs/address" },
    "number": { "$ref": "#/$defs/hexOrDecimal48" },
    "gasUsed": { "$ref": "#/$defs/hexOrDecimal48" },
    "parentHash": { "$ref": "#/$defs/hash" },
    "excessBlobGas": { "$ref": "#/$defs/hexOrDecimal48" },
    "blobGasUsed": { "$ref": "#/$defs/hexOrDecimal48" },
    "alloc": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "balance": { "type": "string", "pattern": "^[0-9]+$" },
    	  "nonce": { "type": "string", "pattern": "^[0-9]+$" },
          "code": { "type": "string", "pattern": "^0x([0-9a-fA-F])*$" },
          "storage": {
            "type": "object",
            "additionalProperties": {
              "type": "string",
              "pattern": "^0x[0-9a-fA-F]+$"
            }
          }
        },
        "additionalProperties": false
      }
    },
	"additionalProperties": false
  },
  "additionalProperties": false
}



