---
eip: <TBD>
title: Genesis File Format Standardization
author: Justin Florentine (@jflo) <justin@florentine.us>, Jochem Brouwer (@jochem-brouwer) <jochem@ethereum.org>
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-genesis-json-standardization/24271
status: Draft
type: Informational
category: Core
created: 2025-05-19
requires: 
---

## Abstract

This EIP defines a canonical structure for Ethereum genesis files (`genesis.json`) used to bootstrap Ethereum networks. The standard aligns with the de facto structure implemented by Geth (Go-Ethereum), and alredy adopted by other clients. It introduces a JSON Schema to ensure consistency and tool compatibility across clients.

## Motivation

The lack of an official standard for the `genesis.json` file has led to incompatibilities, bugs and confusion, as well as added workload for those running multiple clients together in test networks. This EIP aims to reduce ambiguity by defining a consistent structure and enabling tooling through schema-based validation.

## Specification

The canonical genesis file MUST be a JSON object with the following top-level fields:

### Top-Level Fields

| Field           | Description                                                     |
|-----------------|-----------------------------------------------------------------|
| `config`        | Chain configuration object.                                     |
| `alloc`         | Map of addresses to pre-allocated balances and/or code/storage. |
| `nonce`         | Hex-encoded nonce (8 bytes).                                    |
| `timestamp`     | Hex-encoded UNIX timestamp.                                     |
| `extraData`     | Arbitrary extra data.                                           |
| `gasLimit`      | Hex-encoded block gas limit.                                    |
| `difficulty`    | Hex-encoded block difficulty.                                   |
| `mixhash`       | Hex-encoded mix hash.                                           |
| `coinbase`      | Hex-encoded address.                                            |

### `config` Object

The `config` object contains hardfork activation block numbers and fork configurations. Known keys include:

| Field                     | Description                                                                      |
|---------------------------|----------------------------------------------------------------------------------|
| `chainId`                 | unique identifier for the blockchain.                                            |
| `<hardfork(Block\|Time)>` | block height or timestamp to activate the named hardfork.                        |
| `terminalTotalDifficulty` | difficulty after which to switch from PoW to PoS.                                |
| `depositContractAddress`  | Ethereum address for the deposit contract                                        |
| `blobSchedule`            | Map of hardforks and their [EIP-4844](eip-7840.md) DAS configuration parameters. |

### `blobSchedule` Object

| Field                   | Description                                  |
|-------------------------|----------------------------------------------|
| `target`                | desired number of blobs to include per block |
| `max`                   | maximum number of blobs to include per block |
| `baseFeeUpdateFraction` | input to pricing formula per EIP-4844        |

### `alloc` Object

The `alloc` field defines the initial state at genesis. It maps addresses (as lowercase hex strings) to the following object:

| Field          | Description                                     |
|----------------|-------------------------------------------------|
| `balance`      | decimal balance in wei.                         |
| `code`         | Hex-encoded EVM bytecode.                       |
| `nonce`        | decimal value.                                  |
| `storage`      | Key-value hex map representing initial storage. |

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
  "required": ["alloc", "gasLimit", "difficulty"],
  "properties": {
    "config": {
      "type": "object",
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
        "muirGlacierBlock": {"type": "integer"},
        "berlinBlock": { "type": "integer" },
        "londonBlock": { "type": "integer" },
        "arrowGlacierBlock": { "type": "integer" },
        "grayGlacierBlock": { "type": "integer" },
        "terminalTotalDifficulty": { "type": "integer" },
        "mergeNetsplitBlock": { "type": "integer"},
        "shanghaiTime": { "type": "integer"},
        "cancunTime": { "type": "integer"},
        "pragueTime": { "type": "integer"},
        "osakaTime": { "type": "integer"},
        "depositContractAddress": { "$ref": "#/$defs/address"},
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
        }
      },
      "additionalProperties": true
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
    "alloc": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "required": ["balance"],
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
    }
  },
  "additionalProperties": true
}





