---
title: Upgradeable Clone Standard (UCS)
description: A versatile proxy standard with easy cloning and function-based upgradability.
author: Shogo Ochiai (shogo.ochiai@pm.me), Kai Hiroi (kai.hiroi@pm.me)
discussions-to: https://ethereum-magicians.org/t/XXXXX
status: Draft
type: Standards Track
category: ERC
created: 2023-10-25
requires: ERC-165, ERC-1967, ERC-7201
---

## Abstract
This EIP proposes an upgradeable proxy standard that's compatible with the factory (clone) pattern.

This standard is comprised of the following:
1. **Dictionary Contract** that manages implementation contract addresses paired with function selectors.
2. **Proxy Contract** that delegatecalls to the implementation address registered in the Dictionary.
3. **Interface** that represents the behavior of the Proxy as a collection of implementations.
4. **Storage Layout** that ensures no conflicts when shared among multiple implementations.


## Motivation
This standard caters to:

1. Users seeking the factory pattern for cloning contracts with common, upgradeable implementations.
2. Scenarios requiring simultaneous upgrades of cloned contracts.
3. Desires for flexible, per-function upgradeability.


## Specification
> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### 1. Dictionary Contract
This contract manages a mapping of function selectors to corresponding implementation addresses to cater to calls from the Proxy.

#### 1.1 Storage & Events
The Dictionary MUST maintain a mapping of function selectors to implementation addresses.

Here is the reference example written in Solidity:
```solidity
mapping(bytes4 functionSelector => address implementation) internal implementations;
```

Changes to this mapping SHOULD be communicated through an event (or log).
```solidity
event ImplementationUpgraded(bytes4 indexed functionSelector, address indexed implementation);
```

Additionally, the Dictionary SHOULD store an admin account address with rights to modify the mapping.
```solidity
address internal admin;
```

Changes to this admin address SHOULD also be noticed:
```solidity
event AdminChanged(address previousAdmin, address newAdmin);
```

#### 1.2 Functions
The Dictionary SHOULD provide functions to retrieve and set implementations.

##### 1.2.1 `getImplementation`
```solidity
function getImplementation(bytes4 functionSelector) external view returns (address);
```

##### 1.2.2 `setImplementation`
```solidity
function setImplementation(bytes4 functionSelector, address implementation) external;
```
The implementation contract MUST implement the function selector to be registered as a key in the mapping (section 3.1). Therefore, it is RECOMMENDED to verify this during registration.

### 2. Proxy Contract
This contract checks the Dictionary for the associated implementation address based on its function selector and delegatecalls to it.

#### 2.1 Storage & Events
The Proxy MUST reference the Dictionary address while ensuring a minimal chance of storage clashes. This is because the Dictionary's registered implementations will use this shared storage.

Changes to the Dictionary address SHOULD be noticed:
```solidity
event DictionaryUpgraded(address indexed dictionary);
```

While it is possible to store the Dictionary address in the code area (e.g., using Solidity's immutable or constant), it SHOULD be designed with caution, considering the possibility that if the Dictionary's admin is not the same as the Proxy's admin, the ability to manipulate the implementation could be permanently lost.

#### 2.2 Functions
All calls to the Proxy MUST be forwarded to the implementation address registered in the Dictionary through the fallback function. Furthermore, as there is a possibility of collisions with function selectors registered in the Dictionary, Proxy SHOULD NOT have external functions.

##### 2.2.1 `constructor`
It is RECOMMENDED to initialize contracts, other than setting up the Dictionary address, through the Dictionary as well.

##### 2.2.2 `fallback`
It is RECOMMENDED to utilize well-established and widely-used logic from libraries like Zeppelin or Safe for the logic used in the fallback function. The implementation address to which delegatecall MUST be the returned value queried to the Dictionary (stored in the slot specified in section 2.1) using the `getImplementation(bytes4 functionSelector)` function defined in section 1.2.1.


### 3. Interfaces
The implementation contract MUST have the same function selector registered in the Dictionary. If not, the Proxy's delegatecall will fail.

For transparency, it's RECOMMENDED for the Proxy to support interface queries from both on-chain and off-chain entities.

#### 3.1 For on-chain support:
To allow external contracts to ascertain the Proxy's behavior, the Dictionary and implementation contracts are RECOMMENDED to provide certain functions and interfaces.

##### 3.1.1 Dictionary:
###### 3.1.1.1 `supportsInterface`
`supportsInterface(bytes4 interfaceID)` as defined in [ERC-165](https://eips.ethereum.org/EIPS/eip-165).
###### 3.1.1.2 `supportsInterfaces`
Implement `supportsInterfaces()` to return a list of registered interfaceIDs.
```solidity
function supportsInterfaces() public view returns (bytes4[] memory);
```

##### 3.1.2 Implementation Contracts:
Since the Proxy MUST forward all calls to the Dictionary, the implementation for ERC-165 is RECOMMENDED to be registered in the Dictionary's mapping instead.

Furthermore, it is RECOMMENDED for each implementation contract to implement ERC-165's `supportsInterface(bytes4 interfaceID)` to ensure that it correctly implements the function selector being registered when added to the Dictionary.

#### 3.2 For off-chain support:
Even though the Proxy doesn't present an external interface, one can determine the Dictionary address that controls the actual behavior and retrieve a list of function selectors associated with registered implementations.

1. Obtain the address of the Dictionary, which manages the implementation contracts defining the actual behavior, from the Proxy's specific slot (section 4) using an `eth_getStorageAt()` JSON-RPC request.
2. Use the `supportsInterfaces()` interface of the Dictionary to retrieve a list of function selectors corresponding to the implementation contracts registered in the Dictionary.
3. Utilize the `getImplementation(bytes4 functionSelector)` function of the Dictionary to obtain the actual implementation address.
If the implementation contracts managed by the Dictionary corresponding to the Proxy are properly verified, tools like Etherscan can verify the behavior of the Proxy.

### 4. Storage Layout
The Proxy shares storage with several implementation contracts, making it prone to storage conflicts when using a sequential slot allocation starting from slot 0.

Storage MUST be managed properly. The matter of storage management techniques has been a subject of debate for years, both at the EIP level and the language level. However, there is still no definitive standard. Therefore, this EIP does not go into the specifics of storage management techniques.

It is RECOMMENDED to choose the storage management method that is considered most appropriate at the time.

For instance, the Dictionary address is stored in accordance with the method defined in ***[ERC-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)***, as follows, and other storage is arranged according to useful storage layout patterns, such as ***[ERC-7201: Namespaced Storage Layout](https://eips.ethereum.org/EIPS/eip-7201)***.


## Rationale
- ### Separating the Dictionary and Proxy contracts:
  The separation of the Dictionary from the Proxy was driven by two primary motivations:

  1. Enabling the cloning of a Proxy with an upgradeable common implementation template.
  2. Allowing the upgrade of implementations for all Clones simultaneously.

  To achieve these goals, the implementation addresses were externalized as the Dictionary instead of including them within the Proxy, a concept akin to the Beacon Proxy approach.

- ### Utilizing the mapping of function selectors and implementation addresses:

  The utilization of the mapping of function selectors to corresponding implementation addresses of the Dictionary by the Proxy, followed by delegatecalling to the returned implementation address, aligns with the third motivation: "Desire flexible upgradeability on a per-function basis, divided into separate functions."

  By adopting this approach, the Proxy emulates the behavior of possessing a set of implementations registered within the Dictionary. This specification closely resembles the pattern outlined in the Diamond Standard.

- ### Use Cases for Adopting the Upgradeable Clone Standard (UCS)

  Over time, various smart contract design patterns have been proposed and utilized. In comparison to these patterns, we have considered scenarios where utilizing UCS makes sense. To facilitate this comparison, we will define some terms:

  - **Contract-level Upgradeability**: One Proxy corresponds to one Implementation, and the Implementation is responsible for all logic of the Proxy.

  - **Function-level Upgradeability**: One Proxy corresponds to multiple Implementations, with each Implementation handling a specific function of the Proxy.

  - **Factory**: Users utilize a Factory contract to clone Proxies with a common implementation. When considering with upgradeability, it also implies that a common implementation can be upgraded simultaneously.

  Here are the use cases:

  1. When Upgradeability is not needed, and the Factory is not also required, ***Regular smart contract deployment*** suffices.

  2. When Upgradeability is not needed, but the Factory is required; ***[ERC-1167: Minimal Proxy Contract](https://eips.ethereum.org/EIPS/eip-1167)*** can be used.

  3. When Contract-level Upgradeability is needed, but the Factory is not required, ***[ERC-1822: Universal Upgradeable Proxy Standard (UUPS)](https://eips.ethereum.org/EIPS/eip-1822)*** is available.

  4. When Contract-level Upgradeability is needed, and the Factory is also required, ***[The Beacon defined in ERC-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)*** can be utilized.

  5. When Function-level Upgradeability is needed, but the Factory is not required, ***[ERC-2535: Diamonds, Multi-Facet Proxy](https://eips.ethereum.org/EIPS/eip-2535)*** is available.

  6. When Function-level Upgradeability is needed, and the Factory is also required, This ***Upgradeable Clone Standard*** is convenient to use.


## Reference Implementations & Test Cases
There are reference implementations and tests as a foundry project.

It includes the following contents:
- Reference Implementations
  - [Dictionary Contract](../assets/eip-draft/src/dictionary/Dictionary.sol)
  - [Proxy Contract](../assets/eip-draft/src/proxy/ERC0000Proxy.sol)
- Tests
  - [ERC0000Test](../assets/eip-draft/test/ERC0000Test.t.sol)


## Security Considerations
- ### Delegation of Implementation Management
  This pattern of delegating all implementations for every call to the Dictionary relies on the assumption that the Dictionary Admin acts in good faith and does not introduce vulnerabilities through negligence.

  You should not clone a Dictionary provided by an untrusted Admin. Moreover, it is recommended to be provided an option for switching to a Dictionary managed by a different Admin later, even in cases where the Proxy itself becomes the Admin.

- ### Storage Conflict
  As mentioned in the section4: Storage Layout of the specification, this design pattern involves multiple implementation contracts sharing a single storage. Therefore, it's essential to exercise caution to prevent storage conflicts.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
