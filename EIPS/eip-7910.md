---
eip: 7910
title: eth_config JSON-RPC Method
description: A JSON-RPC method that describes the configuration of the current and next fork
author: Danno Ferrin (@shemnon)
discussions-to: https://ethereum-magicians.org/t/eth-config-json-rpc-method/23183
status: Final
type: Standards Track
category: Interface
created: 2025-03-18
---

## Abstract

This document describes an RPC method that provides node-relevant configuration data for the current, next, and last known forks.

## Motivation

Throughout Ethereum's history, there have been multiple instances where a client was not correctly configured for an upcoming hard fork, causing it to fall out of consensus when the fork boundary was crossed. Most incidents have been minor, such as a single client forking the chain in proof-of-work or having its blocks orphaned in proof-of-stake.

The most significant occurrence was during the Pectra activation on the Holešky testnet. Four out of six clients on the network had an incorrect configuration for the deposits contract. Instead of being orphaned, the incorrect chain was justified, and the side effects persist on Holešky even after reaching finality.

By providing an RPC method that allows clients to report key configuration variables before the next hard fork, operations teams can gain greater confidence that clients are correctly configured and prepared for upcoming forks.

### Target Audience and Use Cases

This method is intended for node operators, validator teams, and network monitoring tools to verify client readiness for upcoming forks. Use cases include:

- Automated pre-fork validation scripts comparing `eth_config` outputs across nodes.
- Manual checks by validator operators to ensure alignment with fork specifications.
- Debugging by client developers to identify configuration mismatches.
- Automated checks by Consensus Layer counterparties.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Clients MUST expose a new RPC method to report the current functional configuration and the expected next configuration via the standard JSON-RPC port.

Clients MAY also expose this method through the Engine API.

Clients MAY use these configuration objects to manage their per-fork configurations, though they SHOULD NOT simply return unprocessed configuration data.

When reporting the current, next and last configurations, clients MUST include every configuration parameter specified in this EIP.

Clients MUST return up-to-date configuration values, reflecting the most recent block header they provide. If clients cache the configuration, they MUST ensure such caches are purged when fork boundaries are crossed.

### Configuration RPC

A new JSON-RPC API, `eth_config`, is introduced. It takes no parameters and returns the result object specified in the next section.

### Result Object Structure

The RPC response contains three members: "current", "next", and "last". These members contain the configuration object currently in effect, the next configuration, and the last known configuration, respectively. "next" and "last" will be `null` if the client is not configured to support a future fork. "next" and "last" members will contain the same configuration in the case where the next configured fork is also the last configured fork.

### Members of the Configuration Object

Each configuration object MUST contain the following members, presented in alphabetical order. This RPC assumes the network is post-merge, and no accommodations are specified for proof-of-work-related issues.

Future forks may add, adjust, remove, or update members. The respective changes MUST be defined in either their EIPs or their respective meta-EIPs. Added members MUST be alphabetically sorted, so simply naming the new members is sufficient definition.

#### `activationTime`

The fork activation timestamp, represented as a JSON number in Unix epoch seconds (UTC). For the "current" configuration, this reflects the actual activation time; for "next" and "last", it is the scheduled time.

Activation time is required. If a fork is activated at genesis, the value `0` is used. If the fork is not scheduled to be activated or its activation time is unknown, it should not be in the RPC results.

#### `blobSchedule`

The blob configuration parameters for the specific fork, as defined in the genesis file. This is a JSON object with three members—`baseFeeUpdateFraction`, `max`, and `target`—all represented as JSON numbers.

#### `chainId`

The chain ID of the current network, presented as a string with an unsigned `0x`-prefixed hexadecimal number, with all leading zeros removed, in lower case. This specification does not support chains without a chain ID or with a chain ID of zero.

For purposes of canonicalization, this value must always be a string.

#### `forkId`

The `FORK_HASH` value as specified in [EIP-6122](./eip-6122.md) of the specific fork, presented as an unsigned `0x`-prefixed hexadecimal number, with zeros left-padded to a four-byte length, in lower case.

#### `precompiles`

A representation of the active precompile contracts for the fork. If a precompiled contract is replaced by an on-chain contract—or removed—then it is not included.

This is a JSON object where the members are the agreed-upon names for each contract, typically specified in the EIP defining that contract, and the values are the 20-byte `0x`-prefixed hexadecimal addresses of the precompiles (with zeros preserved), in lower case.

For Cancun, the contract names are (in order): `ECREC`, `SHA256`, `RIPEMD160`, `ID`, `MODEXP`, `BN254_ADD`, `BN254_MUL`, `BN254_PAIRING`, `BLAKE2F`, `KZG_POINT_EVALUATION`.

For Prague, the added contracts are (in order): `BLS12_G1ADD`, `BLS12_G1MSM`, `BLS12_G2ADD`, `BLS12_G2MSM`, `BLS12_PAIRING_CHECK`, `BLS12_MAP_FP_TO_G1`, `BLS12_MAP_FP2_TO_G2`.

For Osaka, the added contract is: `P256VERIFY`.

#### `systemContracts`

A JSON object representing system-level contracts relevant to the fork, as introduced in their defining EIPs. Keys are the contract names (e.g., `BEACON_ROOTS_ADDRESS`) from the first EIP where they appeared, sorted alphabetically. Values are 20-byte addresses in `0x`-prefixed hexadecimal form, with leading zeros preserved, in lower case. Omitted for forks before Cancun.

For Cancun, the only system contract is `BEACON_ROOTS_ADDRESS`.

For Prague, the system contracts are (in order) `BEACON_ROOTS_ADDRESS`, `CONSOLIDATION_REQUEST_PREDEPLOY_ADDRESS`, `DEPOSIT_CONTRACT_ADDRESS`, `HISTORY_STORAGE_ADDRESS`, and `WITHDRAWAL_REQUEST_PREDEPLOY_ADDRESS`.

Future forks MUST define the list of system contracts in their meta-EIPs.

### Blob Parameter Only (BPO) Forks

BPO forks should be interpreted as new forks, taking the parent fork as base (recursively, if the parent fork is also a BPO) and updating only the appropriate values in the `blobSchedule` object to produce the new fork configuration.

## Rationale

### Why Enumerate Precompiles? (And in General, Why Track a Particular Config Item?)

The purpose of this specification is to enable nodes to advertise, prior to a fork, that they have the correct configurations loaded and ready. Past testnet and Ethereum Mainnet forks have revealed clients with incorrect precompile sets, chain IDs, deposit contract addresses, and other configuration errors.

For precompiles in particular there has been discussion about removing or replacing precompiles in future forks, so a full enumeration of precompiles will reflect removal.

Generally, if a configurable variable or constant causes a client to diverge at a fork—whether on Ethereum Mainnet, a testnet, a devnet, or a public rollup—that variable or constant is a candidate for inclusion in the reportable configuration.

### Full Configs Instead of Deltas

An initial design considered using a partial configuration for the "next" fork instead of a complete one. However, analysis of past events showed that some parameters causing divergence (e.g., the deposit contract) were introduced in earlier forks, with consensus failures occurring in later forks due to unrelated EIPs relying on those configurations. A partial "next" configuration hash would not have detected such errors.

An alternative—embedding the prior fork’s hash in the next fork—would require defining rules for extracting differences and merging configurations, as well as specifying all prior fork configuration hashes. This would also complicate retroactively adding parameters (e.g., gas schedule constants and variables). The use of config hashes was also removed in a subsequent update.

### Nested vs. Flat Variables

Nested structures are easier to read, while flat structures are easier to merge. Since this specification uses full configurations for the current and next forks, merging is unnecessary, making readability the priority.

### Serving Data Not Specified in genesis.json

Some reported values are specification-level constants, which many clients do not include in their configuration files. However, certain EIP constants (e.g., the deposit contract) have become variables in testnets, necessitating their inclusion.

### JSON as Config Format

JSON was chosen for its ubiquity, machine and human readability, and the existence of a standardized canonical form via [RFC-8785](https://www.rfc-editor.org/rfc/rfc8785). YAML lacks a standard canonical form. No Ethereum software uses XML for configuration, and adopting it would increase every client's library size. An invented format would be possible but would require definition and standardization within this specification.

### Why no configuration hash

Initial drafts included a hash of the configuration data for quick comparison. There was disagreement about the data format used to generate the hash (plain JSON, RLP, SSZ). Because tooling can effectively diff JSON objects by alphabetizing object keys, the hash is superfluous.

## Backwards Compatibility

This EIP does not alter previous behavior. Configurations prior to Cancun are non-standard, and clients sharing pre-Cancun configurations will produce non-standard results.

Clients supporting pre-Cancun forks MAY return partial or non-standard configurations but SHOULD strive to follow the spirit of the members specified for Cancun configurations. Full compliance is REQUIRED only for Cancun and later forks.

## Test Cases

### Sample Configs

Hoodi Prague Config

```JSON
{
  "activationTime": 1742999832,
  "blobSchedule": {
    "baseFeeUpdateFraction": 5007716,
    "max": 9,
    "target": 6
  },
  "chainId": "0x88bb0",
  "forkId": "0x0929e24e",
  "precompiles": {
    "BLAKE2F": "0x0000000000000000000000000000000000000009",
    "BLS12_G1ADD": "0x000000000000000000000000000000000000000b",
    "BLS12_G1MSM": "0x000000000000000000000000000000000000000c",
    "BLS12_G2ADD": "0x000000000000000000000000000000000000000d",
    "BLS12_G2MSM": "0x000000000000000000000000000000000000000e",
    "BLS12_MAP_FP2_TO_G2": "0x0000000000000000000000000000000000000011",
    "BLS12_MAP_FP_TO_G1": "0x0000000000000000000000000000000000000010",
    "BLS12_PAIRING_CHECK": "0x000000000000000000000000000000000000000f",
    "BN254_ADD": "0x0000000000000000000000000000000000000006",
    "BN254_MUL": "0x0000000000000000000000000000000000000007",
    "BN254_PAIRING": "0x0000000000000000000000000000000000000008",
    "ECREC": "0x0000000000000000000000000000000000000001",
    "ID": "0x0000000000000000000000000000000000000004",
    "KZG_POINT_EVALUATION": "0x000000000000000000000000000000000000000a",
    "MODEXP": "0x0000000000000000000000000000000000000005",
    "RIPEMD160": "0x0000000000000000000000000000000000000003",
    "SHA256": "0x0000000000000000000000000000000000000002"
  },
  "systemContracts": {
    "BEACON_ROOTS_ADDRESS": "0x000f3df6d732807ef1319fb7b8bb8522d0beac02",
    "CONSOLIDATION_REQUEST_PREDEPLOY_ADDRESS": "0x0000bbddc7ce488642fb579f8b00f3a590007251",
    "DEPOSIT_CONTRACT_ADDRESS": "0x00000000219ab540356cbb839cbe05303d7705fa",
    "HISTORY_STORAGE_ADDRESS": "0x0000f90827f1c53a10cb7a02335b175320002935",
    "WITHDRAWAL_REQUEST_PREDEPLOY_ADDRESS": "0x00000961ef480eb55e80d19ad83579a64c007002"
  }
}
```

Hoodi Cancun Config

```JSON
{
  "activationTime": 0,
  "blobSchedule": {
    "baseFeeUpdateFraction": 3338477,
    "max": 6,
    "target": 3
  },
  "chainId": "0x88bb0",
  "forkId": "0xbef71d30",
  "precompiles": {
    "BLAKE2F": "0x0000000000000000000000000000000000000009",
    "BN254_ADD": "0x0000000000000000000000000000000000000006",
    "BN254_MUL": "0x0000000000000000000000000000000000000007",
    "BN254_PAIRING": "0x0000000000000000000000000000000000000008",
    "ECREC": "0x0000000000000000000000000000000000000001",
    "ID": "0x0000000000000000000000000000000000000004",
    "KZG_POINT_EVALUATION": "0x000000000000000000000000000000000000000a",
    "MODEXP": "0x0000000000000000000000000000000000000005",
    "RIPEMD160": "0x0000000000000000000000000000000000000003",
    "SHA256": "0x0000000000000000000000000000000000000002"
  },
  "systemContracts": {
    "BEACON_ROOTS_ADDRESS": "0x000f3df6d732807ef1319fb7b8bb8522d0beac02"
  }
}
```

#### Sample JSON-RPC

##### With Future Fork Scheduled

The following RPC command, issued on Hoodi when Prague was scheduled but not activated:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_config","id":1}' http://localhost:8545
```

would return (after formatting):

```JSON
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "current": {
      "activationTime": 0,
      "blobSchedule": {
        "baseFeeUpdateFraction": 3338477,
        "max": 6,
        "target": 3
      },
      "chainId": "0x88bb0",
      "forkId": "0xbef71d30",
      "precompiles": {
        "BLAKE2F": "0x0000000000000000000000000000000000000009",
        "BN254_ADD": "0x0000000000000000000000000000000000000006",
        "BN254_MUL": "0x0000000000000000000000000000000000000007",
        "BN254_PAIRING": "0x0000000000000000000000000000000000000008",
        "ECREC": "0x0000000000000000000000000000000000000001",
        "ID": "0x0000000000000000000000000000000000000004",
        "KZG_POINT_EVALUATION": "0x000000000000000000000000000000000000000a",
        "MODEXP": "0x0000000000000000000000000000000000000005",
        "RIPEMD160": "0x0000000000000000000000000000000000000003",
        "SHA256": "0x0000000000000000000000000000000000000002"
      },
      "systemContracts": {
        "BEACON_ROOTS_ADDRESS": "0x000f3df6d732807ef1319fb7b8bb8522d0beac02"
      }
    },
    "next": {
      "activationTime": 1742999832,
      "blobSchedule": {
        "baseFeeUpdateFraction": 5007716,
        "max": 9,
        "target": 6
      },
      "chainId": "0x88bb0",
      "forkId": "0x0929e24e",
      "precompiles": {
        "BLAKE2F": "0x0000000000000000000000000000000000000009",
        "BLS12_G1ADD": "0x000000000000000000000000000000000000000b",
        "BLS12_G1MSM": "0x000000000000000000000000000000000000000c",
        "BLS12_G2ADD": "0x000000000000000000000000000000000000000d",
        "BLS12_G2MSM": "0x000000000000000000000000000000000000000e",
        "BLS12_MAP_FP2_TO_G2": "0x0000000000000000000000000000000000000011",
        "BLS12_MAP_FP_TO_G1": "0x0000000000000000000000000000000000000010",
        "BLS12_PAIRING_CHECK": "0x000000000000000000000000000000000000000f",
        "BN254_ADD": "0x0000000000000000000000000000000000000006",
        "BN254_MUL": "0x0000000000000000000000000000000000000007",
        "BN254_PAIRING": "0x0000000000000000000000000000000000000008",
        "ECREC": "0x0000000000000000000000000000000000000001",
        "ID": "0x0000000000000000000000000000000000000004",
        "KZG_POINT_EVALUATION": "0x000000000000000000000000000000000000000a",
        "MODEXP": "0x0000000000000000000000000000000000000005",
        "RIPEMD160": "0x0000000000000000000000000000000000000003",
        "SHA256": "0x0000000000000000000000000000000000000002"
      },
      "systemContracts": {
        "BEACON_ROOTS_ADDRESS": "0x000f3df6d732807ef1319fb7b8bb8522d0beac02",
        "CONSOLIDATION_REQUEST_PREDEPLOY_ADDRESS": "0x0000bbddc7ce488642fb579f8b00f3a590007251",
        "DEPOSIT_CONTRACT_ADDRESS": "0x00000000219ab540356cbb839cbe05303d7705fa",
        "HISTORY_STORAGE_ADDRESS": "0x0000f90827f1c53a10cb7a02335b175320002935",
        "WITHDRAWAL_REQUEST_PREDEPLOY_ADDRESS": "0x00000961ef480eb55e80d19ad83579a64c007002"
      }
    },
    "last": {
      "activationTime": 1742999832,
      "blobSchedule": {
        "baseFeeUpdateFraction": 5007716,
        "max": 9,
        "target": 6
      },
      "chainId": "0x88bb0",
      "forkId": "0x0929e24e",
      "precompiles": {
        "BLAKE2F": "0x0000000000000000000000000000000000000009",
        "BLS12_G1ADD": "0x000000000000000000000000000000000000000b",
        "BLS12_G1MSM": "0x000000000000000000000000000000000000000c",
        "BLS12_G2ADD": "0x000000000000000000000000000000000000000d",
        "BLS12_G2MSM": "0x000000000000000000000000000000000000000e",
        "BLS12_MAP_FP2_TO_G2": "0x0000000000000000000000000000000000000011",
        "BLS12_MAP_FP_TO_G1": "0x0000000000000000000000000000000000000010",
        "BLS12_PAIRING_CHECK": "0x000000000000000000000000000000000000000f",
        "BN254_ADD": "0x0000000000000000000000000000000000000006",
        "BN254_MUL": "0x0000000000000000000000000000000000000007",
        "BN254_PAIRING": "0x0000000000000000000000000000000000000008",
        "ECREC": "0x0000000000000000000000000000000000000001",
        "ID": "0x0000000000000000000000000000000000000004",
        "KZG_POINT_EVALUATION": "0x000000000000000000000000000000000000000a",
        "MODEXP": "0x0000000000000000000000000000000000000005",
        "RIPEMD160": "0x0000000000000000000000000000000000000003",
        "SHA256": "0x0000000000000000000000000000000000000002"
      },
      "systemContracts": {
        "BEACON_ROOTS_ADDRESS": "0x000f3df6d732807ef1319fb7b8bb8522d0beac02",
        "CONSOLIDATION_REQUEST_PREDEPLOY_ADDRESS": "0x0000bbddc7ce488642fb579f8b00f3a590007251",
        "DEPOSIT_CONTRACT_ADDRESS": "0x00000000219ab540356cbb839cbe05303d7705fa",
        "HISTORY_STORAGE_ADDRESS": "0x0000f90827f1c53a10cb7a02335b175320002935",
        "WITHDRAWAL_REQUEST_PREDEPLOY_ADDRESS": "0x00000961ef480eb55e80d19ad83579a64c007002"
      }
    }
  }
}
```

##### Without Future Fork Scheduled

When no future forks are configured, the same RPC command would return:

```JSON
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "current": {
      "activationTime": 0,
      "blobSchedule": {
        "baseFeeUpdateFraction": 3338477,
        "max": 6,
        "target": 3
      },
      "chainId": "0x88bb0",
      "forkId": "0xbef71d30",
      "precompiles": {
        "BLAKE2F": "0x0000000000000000000000000000000000000009",
        "BN254_ADD": "0x0000000000000000000000000000000000000006",
        "BN254_MUL": "0x0000000000000000000000000000000000000007",
        "BN254_PAIRING": "0x0000000000000000000000000000000000000008",
        "ECREC": "0x0000000000000000000000000000000000000001",
        "ID": "0x0000000000000000000000000000000000000004",
        "KZG_POINT_EVALUATION": "0x000000000000000000000000000000000000000a",
        "MODEXP": "0x0000000000000000000000000000000000000005",
        "RIPEMD160": "0x0000000000000000000000000000000000000003",
        "SHA256": "0x0000000000000000000000000000000000000002"
      },
      "systemContracts": {
        "BEACON_ROOTS_ADDRESS": "0x000f3df6d732807ef1319fb7b8bb8522d0beac02"
      }
    },
    "next": null,
    "last": null
  }
}
```

## Security Considerations

- **Exposure Risks**: Incorrect configurations could leak operational details. Operators SHOULD restrict `eth_config` to trusted interfaces (e.g., local access or authenticated endpoints).
- **Dishonest Nodes**: Clients may report false configurations. Peers or monitoring tools MAY cross-check `eth_config` outputs against known fork specifications or other nodes' responses to detect anomalies.
- **DDoS Mitigation**: Clients MAY cache configuration objects internally and rate-limit `eth_config` requests to prevent resource exhaustion. Implementations MAY impose a minimum response interval (e.g., 1 second).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
