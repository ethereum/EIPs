---
title: Domain-contracts two-way binding
description: A standward way to enable a two-way binding between domain and its official contracts to prevent DNS attacks
author: Venkat Kunisetty (@VenkatTeja)
discussions-to: https://ethereum-magicians.org/t/eip-domain-contracts-two-way-binding/13209
status: Draft
type: Standards Track
category: ERC
created: 2023-03-08
---

## Abstract

This EIP proposes a standard way for dapps to maintain their official domains and contracts that are linked through an on-chain and off-chain two-way binding mechanism. 

## Motivation

Web3 users sometimes get attacked due to vulnerebilities in web2 systems. For example, in Nov 2022, Curve.fi suffered a DNS attack. This attack would have been prevented if there was a standard way to allow dapp developers to disclose their official contracts. If this was possible, wallets could have easily detected un-official contracts and warned users. 
  
An added advantage to this approach is to predictably find the the official contract addresses of a dapp. Most dapp's docs are non-standard and it is difficult to find the official contract addresses.

## Specification

### Terms

  1. `Two-way` binding: Being able to verify what official contracts of a domain are offchain and onchain
  2. `Dapp Registry contract (DRC)`: This is a contract that is to be deployed by dapp developer that validates if a contract address is official
  3. `Registry contract`: This is a contract that maintains the mapping between domain and its DRC.
  4. `DApp Developer (DAD)`: The one who is developing the decentralised application
  
### Implementation

  The DAD must create a custom file on their domain at `/contracts.json` route. The file must return the information about the official contracts in the following structure:
  
  ```javascript
    // Returns the array of this structure
    {
      contractAddress: "0x...abc",
      name: "Your contract name",
      description?: "your contract description",
      code?: "Link to sol file of this contract"
    }[]
  ```
  
  Further, DAD must deploy a DRC that has the following structure:
  
  ```solidity
    interface IDAppRegistry {
      
      function isMyContract(address _address) external view returns (bool);
    }
  ```
  
  We define the Registry contract as:
  
  ```solidity
    contract DomainContractRegistry {
      struct RegistryInfo {
        address dappRegistry;
        address admin;
      }
      
      mapping(string => RegistryInfo) public registryMap;
  
      function setDappRegistry(string memory _domain, address _dappRegistry) external {
        // check if a domain already has a dapp registry mapped
        // if yes, check if owner is same. if so, allow the change
        // if no, recordTransition(_domain, _dappRegistry);
        
        IDappRegistry dappRegistry = IDappRegistry(_dappRegistry);
        // Use chainlink to the call `{{domain}}/contracts.json`. 
        // Check for each contract listed in contracts.json by calling 
        // dappRegistry.isMyContract(_address)
        
        // If all addresses match, update registryMap
      }
      
      // In case of a domain transfer, register that there is potential change in registry mapping
      // and a new owner may be attempting to update registry
      // A cool-off period is applied on the domain marking a potential transfer in ownership
      // Cool-off period can be 7 days
      function recordTransition(string memory _domain, address _dappRegistry) internal
       
    }
  ```
  
  DAD must register their domain in this registry to validate domain ownership. 

## Rationale

Wallets need official contract addresses of a domain to warn users if the domain is sending transaction to a different address. This could have been solved by allowing DADs to provide a standard url (e.g. /contracts.json) to wallets. However, in the event of a DNS attack, even this information can be tampered. By deploying a registry contract on chain, the DAD is able to have a second source of their official contracts that they can set when they have full control of their domain. If registry's information gets tampered, wallets can always use standard url to cross-check. This system ensures the attackers has to get access to both admin private keys and domain control to do the attack which is highly difficult relatively. This is analogous to 2FA. 
  
More details - TBD

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

TBD

## Reference Implementation

A sample implementation is being worked here. This is currently under progress. [link](https://github.com/Vigilance-DAO/Domain-Contracts-Binding-POC)

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
