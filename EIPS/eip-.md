---
title: Multi-chain Deterministic Deployment Factory
description: A minimal `CREATE2` factory for use across EVM chains.
author: Francisco Giordano (@frangio)
discussions-to: https://ethereum-magicians.org/t/eip-tbd-multi-chain-deterministic-deployment-factory/24998
status: Draft
type: Standards Track
category: Core
created: 2025-08-03
requires: 211, 1014, 3855
---

## Abstract

A minimal `CREATE2` factory is inserted at a chosen address to enable deterministic deployments across EVM chains.

## Motivation

There are now a large number of EVM chains where users want to transact and developers want to deploy applications, and we can expect this number to continue to grow in line with Ethereum's rollup-centric roadmap and the general adoption of programmable blockchains.

Most applications support multiple chains and aspire to support as many as possible. Their developers widely prefer to deploy contracts at identical addresses across all chains, which we'll call a *multi-chain deterministic deployment*.

This kind of deployment reduces the number of addresses that must be distributed to use the application, so that it no longer scales with the number of supported chains. This simplification has many benefits throughout the stack: interfaces and SDKs need to embed and trust fewer addresses, and other contracts that depend on them do not require chain-specific customization (which in turn makes them amenable to multi-chain deployment).

Another important motivation is account abstraction. Accounts tied to a single chain are difficult to explain to users and can cause loss of funds. Smart contract accounts must be multi-chain like EOAs or they offer downgraded UX and are more prone to error.

There is currently no native or fully robust way to perform multi-chain deterministic deployments. While `CREATE2` enables deterministic deployments, the created address is computed from that of the contract that invokes the instruction, so a *factory* that is itself multi-chain is required for bootstrapping. Four workarounds are currently known to deploy such a factory, each with their own issues:

1. A keyless transaction is crafted using Nick's method that can be posted permissionlessly to new chains. For this to work, the chain must support legacy transactions without EIP-155 replay protection, and the fixed gas price and gas limit must be sufficiently high, but not so high as to exceed the limits of the chain.
2. Private keys held by some party are used to sign creation transactions for each chain as needed. This creates a dependency on that party, does not provide a hard guarantee that the factory will be available on every chain, and can also irreversibly fail if transactions are not properly parameterized.
3. ERC-7955: A private key is intentionally leaked so that any party can permissionlessly create an EIP-7702 signed delegation and deploy a factory from the leaked account. While this approach improves on the previous two, its reliance on ECDSA keys makes it non-quantum-resistant, and will fail once chains stop supporting ECDSA keys.
4. Factories already deployed on other chains are manually inserted in a new chain at genesis or via a hard fork. This has not been widely adopted by chains, despite the standardization efforts of RIP-7740.

This EIP aims to coordinate a widely available multi-chain `CREATE2` factory.

## Specification

### Parameters

* `FORK_BLOCK_NUMBER` = `TBD`
* `FACTORY_ADDRESS` = `TBD` (precompile range)

### Factory Contract

As of `FORK_BLOCK_NUMBER`, set the code of `FACTORY_ADDRESS` to `5f356020361160203603028060205f375f34f580601e573d5f5f3e3d5ffd5b5f5260205ff3`, the bytecode corresponding to the following assembly:

```
;; inputs: salt (32 bytes) || initcode (variable length)

;; load salt
push0
calldataload

;; compute initcodesize as saturated calldatasize - 32
push1 32
calldatasize
gt
push1 32
calldatasize
sub
mul

;; copy initcode to memory
dup1
push1 32
push0
calldatacopy

;; invoke create2 with salt and initcode, forward all callvalue
push0
callvalue
create2

;; if create2 produced nonzero jump to success
dup1
push1 @success
jumpi

;; else revert with creation returndata
returndatasize
push0
push0
returndatacopy
returndatasize
push0
revert

;; on success return the created address
success:
push0
mstore
push1 32
push0
return
```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Security Considerations

### Front-runnable deployments

The deployment of contracts that read the environment (`ORIGIN`, `NUMBER`, etc.) may be front-run and created with attacker-chosen parameters. It's recommended to use this factory to deploy fully deterministic contracts only. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
