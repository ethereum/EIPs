---
eip: tbd
title: Minimal intent-centric EOA smart account standard
description: Minimal effort intent-centric standard interfaces for EOA accounts with contract code (EIP-7702) to support account abstraction features
author: hellohanchen (@hellohanchen)
discussions-to: https://ethereum-magicians.org/t/erc-intent-7702-minimal-intent-centric-eoa-smart-account-standard/21565
status: Draft
type: Standards Track
category: ERC
created: 2024-11-02
requires: EIP-7702
---

## Abstract
This proposal defines interfaces to build intent-centric smart accounts under [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702), allowing EOA account owners to define their intents of a transaction and let relayers (solvers) to validate and execute the requests.

# Motivation
AA (Account abstraction) is a hot topic in blockchain industry because it gives accounts programmablility features, including but not limited to:
* **BatchExecution**
* **GasSponsorship**
* **AccessControl**

With [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337), engineers built a permissionless AA standard. While unlocking enormous number of useful features, ERC-4337 still has several limitations:

* **Complexity**: Requiring multiple components: Account, EntryPoint, Paymaster, Bundler, and Plugins ([ERC-6900](https://eips.ethereum.org/EIPS/eip-6900), [ERC-7579](https://eips.ethereum.org/EIPS/eip-7579)). Services like bundler has a high original cost and requires high engineer skills to run and maintain.
* **Compatibility**: Compatibility issue between components forces developers to upgrade multiple smart contracts within one version update
* **Cost**: `UserOperation` processing costs high gas units
* **Trust**: Although this standard is designed to be permissionless, there are still centralized processes. Paymaster is usually a centralized service because it needs to either trust the account owner to payback the sponsored gas or the transaction is beneficial for Paymaster. Bundlers are running on MEV based and accounts need to trust bundler providers.

[ERC-7521](https://eips.ethereum.org/EIPS/eip-7521) discusses an SCA solution with intent-centric design. It enables solvers to fulfill account owners' intents by acting "on behalf of" account owners. ERC-7521 allows arbitrary intents and verification logics while trying to keep the whole solution forward-compatible. 

With EIP-7702 _Set EOA account code_ allowing EOA accounts to set contract code, EOA accounts will gain similar programmability as SCA (Smart Contact Account). A new standard, that provides EOA with highly-demanded AA features while potentially resolving some of the above challenges, will help bringing seamless user experience and drive mass adoptions. 

The above EIPs inspired the author to build an intent-centric standard for EIP-7702 smart accounts.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### UserIntent struct
`UserIntent` is a packed data structure defining the intents of executing a transaction.

| Field          | Type      | Description                                                                                                                                              |
|----------------|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `sender`       | `address` | The wallet making the intent                                                                                                                             |
| `standard`     | `address` | The `IStandard` implementation to validate and parse this `UserIntent`                                                                                   |
| `header`       | `bytes`   | The metadata of this `UserIntent`, used by `standard`, using `bytes` type to keep flexibility                                                            |
| `instructions` | `bytes[]` | The detailed content of this `UserIntent`, used by `standard` to determine the `Operation`s need to be executing, using `bytes` type to keep flexibility |
| `signatures`   | `bytes[]` | Validatable signatures, used by `standard`                                                                                                               |

### IStandard interface
The above `standard` means how to parse and validate an `UserIntent`, it implements the following `IStandard` interface:

```solidity
interface IStandard {
    /**
     * Validate user's intent
     * @dev returning validation result, the type uses bytes4 for extensibility purpose
     * @return result: values representing validation outcomes
     */
    function validateUserIntent(UserIntent calldata intent) external returns (bytes4 result);

    /**
     * Unpack user's intent
     * @dev returning validation result, the type uses bytes for extensibility purpose
     * @return header: metadata of the unpacked instructions
     * @return instructions: unpacked instructions, NOT REQUIRED to match UserIntent.instructions
     */
    function unpackUserIntent(UserIntent calldata intent) external returns (bytes header, bytes[] instructions);
}
```
Notice that `IStandard` fully controls the validation process, so similar as `EntryPoint` in ERC-4337 and ERC-7521, each `standard` MUST be pre-audited and SHOULD NOT be upgradable. 

### IAccount interface
On the `account` side, `IAccount` is the interface to execute `UserIntent`:
```solidity
interface IAccount {
    /**
     * Execute user's intent
     * @dev returning execution result, the type uses bytes4 for extensibility purpose
     * @return result: values representing execution outcomes
     */
    function executeUserIntent(UserIntent calldata intent) external returns (bytes result);
}
```
Following EIP-7702 definition, `account` will be the contract code delegated by the EOA, which MAY have full control of EOA's assets, so each `account` MUST be pre-audited. Since different EOAs can set their contract code to the same smart contract, an audited `IAccount` implementation is ALWAYS publicly shared. But it has to be the EOA account owners' responsibility to delegate to a safe `account`. 

It is RECOMMENDED that each `account` leverages `standard` to validate and unpack `UserIntent`, here is a very simple example:
```solidity
abstract contract StandardAccount is IAccount {
    IStandard _myStandard = IStandard("0xstandard");

    function executeUserIntent(UserIntent calldata intent) external returns (bytes result) {
        require(intent.standard == address(_myStandard), "invalid standard");
        bytes4 validationResult = _myStandard.validateUserIntent(intent);
        require(validationResult == MAGIC_VALUE, "validation failed");

        (bytes header, bytes[] instructions) = _myStandard.unpackUserIntent(intent);
        
        // continue execution using header and instructions ...
    }
}
```

`account` MAY be implemented as a stateless smart contract.

### Usage of Bytes
There are many objects defined with `bytes` type for extensibility, future-compatibility purpose. All those objects are optional and their usages depends on `standard`. For the `UserIntent` struct:

* `UserIntent.header`: The `UserIntent.header` can carry information about how to validate the intent or how to prevent double-spending. For example, let `UserIntent.header` be an `uint256 nonce` and the `standard` can check if the `nonce` is used already.
* `UserIntent.instructions`: These `instructions` can just be concatenated `(address,value,calldata)` or can be standard-defined values, for example `(erc20TokenAddress,1000)` means the `instructions` can use up to 1000 of the specified ERC20 token. It is NOT REQUIRED that all `instructions` MUST be provided by the EOA owner, some of them MAY be provided by relayer or third party.
* `UserIntent.signatures`: These `signatures` can support different signing methods. It is NOT REQUIRED that all `signatures` MUST be provided by the EOA owner, some of them MAY be provided by relayer or third party. 

## Rationale

> The main challenge with a generalized intent standard is being able to adapt to the evolving world of intents. Users need to have a way to express their intents in a seamless way without having to make constant updates to their smart contract wallets. --- ERC-7521

The interface designs proposed in this EIP is inspired by ERC-7521, and the author tries to avoid turning EIP into a real implementation.

### Execution in EOA contract code
EIP-7702 gives EOA the ability to execute code. Executing from the EOA brings some benefits:
* Aligned with the nature of EOA that the execution is fully controlled by the account owner. EOA owner can easily turn off all smart contract features by un-delegating the contract code.
* `msg.sender` is always EOA address
* Execution code can be stateless, this allows `account` to store no state data.

In the case that the EOA doesn't need to execute its contract code, or the intent cost is too high. The owner can use the account as EOA.

### Validation in standard contract
Validation logic commonly relies on contract state, for example, weighted multi-owner signature needs to track the weight of each signer. Keeping the functionality of intent validate purely inside `IStandard` makes it similar to the `EntryPoint` concept in ERC-4337, but a simpler version. Standard only taking responsibility of validation makes it easier for contract engineer to build, audit and maintain.

Also, the `IStandard` interface can be considered as "modular". There can be a "compound" standard that breaks `UserIntent` into smaller pieces and call other standards to validate each piece and later combine the results together.

### Gas abstraction defined in standard
This EIP enables standard to use content stored in `UserIntent.header` to define the "reward" of solving this intent. For example, `UserIntent.header` can contain `(erc20TokenAddress, amount)` and the standard can convert this into an instruction to send these tokens to the `tx.origin` and returns this instruction through `unpackInstruction` ABI.

### Auditability of both validation and execution
It is very important both the standard and account implementation can be publicly audited and shared. The most important reason is security. And this can also help mediate the compatibility issues between standard and account.

### Solver is relayer, relayer is paymaster, paymaster is bundler
Within a intent-centric system, solvers are helping account owners to fulfill the intent and solvers are rewarded. EIP-7702 allows any solver to execute the intent, bringing a positive competitive environment. And supported by gas abstraction, solvers will pay the native token as gas fee and take other tokens back from the EOA account. Besides, solvers can further reduce the cost of their side by bundling multiple intent executions into one blockchain transaction. 

Each solver needs to develop its own strategy to maximize its profit. And this EIP doesn't define anything about how a solver executes the intents, meaning there is no limitation.

### Intents can be rewarded, repeatable
And another fact, which is easy to be ignored, is that intent has value by itself. For example, if an EOA is always willing to swap 1000 USDC to 1000 USDT and vice versa, this EOA will be considered as a "liquidity provider" in the market. The account can send the signed intent to exchanges and make the exchange reward the account every time the intent is executed.

## Backwards Compatibility
This EIP shares the same backwards compatibility issue as EIP-7702. This EIP is not compatible with ERC-7521.

## Reference Implementation
To be added

## Security Considerations
This is mainly controlled by the standard and account implementation to make sure the account is safe. Solver needs to responsible for its own security when executing intents. 

More discussion needed.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
