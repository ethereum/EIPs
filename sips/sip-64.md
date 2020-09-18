---
sip: 64
title: Flexible Contract Storage
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: <https://discordapp.com/invite/AEdUHzt>

created: 2020-05-28
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Provide a reusable storage location for any Synthetix contract.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Take the `EternalStorage` contract pattern and generalize it for use in any number of various contracts.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Currently the `EternalStorage` contract pattern is useful as storage for a single contract. However, using it means every new section of Synthetix requires its own instance of the storage contract, which continues to expand surface area of the project and requires more maintainence as each is paired to one single contract. Instead, this SIP proposes to create one central storage contract, where any contract can access storage mapped to it by contract name using the `AddressResolver`.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
-->

### Overview

<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

This SIP proposes to create a new version of the `EternalStorage` contract that instead of being limited to a single `associatedContract` via the `State` mixin, it can support any number of contracts that wish to use it in a safe and segregated manner.

All getters and setters from `EternalStorage` will be used, yet with an extra initial parameter, `contractName`. This property will be the mapping for the storage entries. For any setter function, the `msg.sender` must match the address that the Synthetix `AddressResolver` has for it. As such, this storage contract must manage a reference to the `AddressResolver` (and this can be done one-time using the `ReadProxyAddressResolver`).

This contract will be called `FlexibleStorage`. It is designed to be deployed once and used by many contracts as a flexible storage location.

Additionally, this SIP will create a reusable abstract contract - `ContractStorage` - which `FlexibleStorage` will build upon. The abstract contract will have the `onlyContract` modifier and the ability to migrate.

## Resolved Questions

> 1.  **Should the getters be limited to only be read the contract as well?** This would prevent other internal Synthetix contracts from reading directly from the storage contract on behalf of another contract and would prevent third party contracts from reading these values on-chain. The cost is that this limitation may have unforeseen consequences for integrations down the line, moreover it is slightly more gas efficint to look up the storage directly, whereas the benefit is that the contracts themselves are the abstraction for viewing storage, and it could be problematic to allow third party contracts to expect the storage to be formatted a certain way, and break those expectations in future releases.
>     - Decision: No. This would add unnecessary friction to the process.

> 2.  **How to handle future refactoring of contracts?** If we were to store data for `Issuer` say, and then we split out burning from `Issuer` into `Burner`, how could we reuse storage from `Issuer` in `Burner`?
>
>     1. Use contract-auth calls to migrate the data over to the new mapping, one key at a time. This is manageable in the case of settings and properties, but much more onerous for address-based keys such as how [Issuer uses EternalStorage](https://github.com/Synthetixio/synthetix/blob/v2.21.15/contracts/Issuer.sol#L104).
>
>     2. A potentially better solution (though it could get ugly) is having an available contract mapping. Initially the mapping is empty but it could be added to by a contract that allows other named contracts in the `AddressResolver` to set/get on its behalf. So for the above example, `Issuer` would have something added to itself that says `Storage.addContractMapping("Issuer", "Burner")` that would allow `Burner` to pass through `Issuer` as a key and still have write access to that space. This isn't great because then `Burner` needs to keep a reference to the `"Issuer"` storage key, but is manageable. Any other suggestions?

> - Decision: A version of #2 based off the proposal by @zyzek. The key to the entry can be stored in a mapping and if a migration is allowed then an additional mapping entry is created for the new contract to the old one.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The current `EternalStorage` contract is quite flexible in how it stores state, it makes sense to double down on this useful pattern, hence a new version based off of it (but not extending it as we don't want to use the `State` mixin here). One trade-off of this approach however is the storage of packed structs. If a struct condenses it's entries down to maximize space: e.g. [`SystemStatus.Suspension`](https://github.com/Synthetixio/synthetix/blob/v2.21.15/contracts/SystemStatus.sol#L17-L22) (which uses a `bool` that is `uint8` in Solidity, combined with a `uint248` reason code which makes up the remainder of the 32 bytes in the storage slot), then it would be less efficient to store the individual components into two separate storage slots.

Unfortunately, there's no easy solution to generalizing the storage of structs. The usage of this storage contract will come down to whether or not the contract in question can efficiently compress and decompress its required data before going in and out of the storage contract.

Additionally, there will be a slightly higher gas cost when persisting storage now as each contract will need to do a cross-contract call both a) to the new `Storage` contract and then b) from the new `Storage` contract to the `AddressResolver` to ascertain if `msg.sender` is indeed the address it expects from the `AddressResolver`. This second step cannot be alleviated by having `Storage` use `MixinResolver` as other Synthetix contracts do because `Storage` is not an upgradable contract, and thus we can't hard-code the names of the contracts it needs to store in its cache.

### Technical Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

The API is nearly identical to `EternalStorage` with a few exceptions:

1. It will support `uint`, `int`, `bool`, `address` and `bytes32` only. `bytes` and `string` are of dynamic sizes and if needed should be a separate contract instance.
1. All getters and setters take an additional first parameter, the `contractName` as `bytes32`
1. All getters and setters will additionally take a memory array of records and values (for setters) to reduce external calls where possible
1. Basic migration functionality to move keys over to a new `contractName`. This addresses [question](#questions) 2a above. 2b would require more functionality.

```solidity

// abstract
contract ContractStorage {

    // onlyContract(fromContractName)
    function migrateContractKey(bytes32 fromContractName, bytes32 toContractName, bool removeAccessFromPreviousContract) external onlyContract(fromContractName) {
        // ...
    }

    modifier onlyContract(bytes32 contractName) {
        // ...
    }
}


interface IFlexibleStorage is ContractStorage {

    function getUintValue(bytes32 contractName, bytes32 record) external view returns (uint);

    function getUintValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory);

    // onlyContract(contractName)
    function setUIntValue(bytes32 contractName, bytes32 record, uint value) external;

    // onlyContract(contractName)
    function setUIntValues(bytes32 contractName, bytes32[] calldata records, uint[] values) external;


    // onlyContract(contractName)
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    // (as above for int, bool, address and bytes32 values)
    // ...

}
```

Additionally, contracts now need to know their own `contractName`. To solve this, we can add another constructor argument to `MixinResolver` with the contract's name added to itself as a public property, which it can then use for getting and setting storage. Though this may be superceded if a refactor occurs - see [Question](#questions) 2 above.

#### Usages

- `IssuanceEternalStorage` should be replaced by wholesale by `FlexibleStorage` and removed from Synthetix
- All SCCP configurable settings, managed by a new contract `SystemSettings`. This contract will be owned specifically by the `protocolDAO` in order to expedite any SCCP change without requiring a migration contract (from [SIP-59](https://github.com/Synthetixio/SIPs/pull/127)).

| Contract         | Property                                                                                                                         | Type                       | Notes                                                                                                                 |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `Exchanger`      | `exchangeFeeRateForSynths`                                                                                                       | `mapping(bytes32 => uint)` | (currently on [`FeePool`](https://docs.synthetix.io/contracts/source/contracts/feepool/#setexchangefeerateforsynths)) |
| `Exchanger`      | [`priceDeviationThresholdFactor`](https://docs.synthetix.io/contracts/source/contracts/exchanger/#pricedeviationthresholdfactor) | `uint`                     |                                                                                                                       |
| `Exchanger`      | [`waitingPeriodSecs`](https://docs.synthetix.io/contracts/source/contracts/exchanger/#waitingperiodsecs)                         | `uint`                     |                                                                                                                       |
| `ExchangeRates`  | [`rateStalePeriod`](https://docs.synthetix.io/contracts/source/contracts/ExchangeRates#ratestaleperiod)                          | `uint`                     |                                                                                                                       |
|                  |
| `FeePool`        | [`feePeriodDuration`](https://docs.synthetix.io/contracts/source/contracts/feepool/#feeperiodduration)                           | `uint`                     |                                                                                                                       |
| `FeePool`        | [`targetThreshold`](https://docs.synthetix.io/contracts/source/contracts/feepool/#targetthreshold)                               | `uint`                     |                                                                                                                       |
| `Issuer`         | [`minimumStakeTime`](https://docs.synthetix.io/contracts/source/contracts/issuer/#minimumstaketime)                              | `uint`                     |                                                                                                                       |
| `Liquidations`   | [`liqudationDelay`](https://docs.synthetix.io/contracts/source/contracts/liquidations/#liquidationdelay)                         | `uint`                     |
| `Liquidations`   | [`liqudationPenalty`](https://docs.synthetix.io/contracts/source/contracts/liquidations/#liquidationpenalty)                     | `uint`                     |
| `Liquidations`   | [`liqudationRatio`](https://docs.synthetix.io/contracts/source/contracts/liquidations/#liquidationratio)                         | `uint`                     |
| `SynthetixState` | [`issuanceRatio`](https://docs.synthetix.io/contracts/source/contracts/synthetixstate/#issuanceratio)                            | `uint`                     | Cannot be modified directly, so all references need to be updated instead                                             |

```solidity

interface ISystemSettings {

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    function issuanceRatio() external view returns (uint);

    function feePeriodDuration() external view returns (uint);

    function targetThreshold() external view returns (uint);

    function liquidationDelay() external view returns (uint);

    function liquidationRatio() external view returns (uint);

    function liquidationPenalty() external view returns (uint);

    function rateStalePeriod() external view returns (uint);

    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint);

    function minimumStakeTime() external view returns (uint);
}
```

#### Potential Other Future Uses

- The list of [`synths`](https://docs.synthetix.io/contracts/source/contracts/synthetix/#synths) managed by `Issuer` (previously in `Synthetix` until [SIP-48](sip-48.md)).
- `FeePoolEternalStorage` can be replaced by this by additionally storing the data from fee periods into this as well as `FeePoolEternalStorage` during the transition period (two week claim window). The following upgrade can then remove this.

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
