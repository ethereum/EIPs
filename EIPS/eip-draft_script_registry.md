---
title: Permissionless Script Registry
description: Permissionless registry to fetch executable scripts for contracts
author: Victor Zhang (@zhangzhongnan928) James Brown (@JamesSmartCell)
discussions-to: https://ethereum-magicians.org/t/eip-script-registry/20503
status: Draft
type: Standards Track
category: ERC
created: 2024-07-01
requires: None
---
## Abstract

This EIP provides a means to create a standard registry for locating executable scripts associated with contracts.

## Motivation

[ERC-5169](https://github.com/ethereum/ERCs/blob/master/ERCS/erc-5169.md) (`scriptURI`) provides a client script lookup method for contracts. This requires the contract to have implemented the ERC-5169 interface at the time of construction (or allow an upgrade path).

This proposal outlines a contract that can supply prototype and certified scripts. The contract would be a singleton instance multichain that would be deployed at identical addresses on supported chains.

### Overview

The registry contract will supply a set of URI links for a given contract address. These URI links point to script programs that can be fetched by a wallet, viewer or mini-dapp.

The pointers can be set using a setter in the registry contract.

The scripts provided could be authenticated in various ways:

1. The target contract which the setter specifies implements the `Ownable` interface. Once the script is fetched, the signature can be verified to match the Owner(). In the case of TokenScript this can be checked by a dapp or wallet using the TokenScript SDK, the TokenScript online verification service, or by extracting the signature from the XML, taking a keccak256 of the script and ecrecover the signing key address.
2. If the contract does not implement Ownable, further steps can be taken:
 a. The hosting app/wallet can acertain the deployment key using 3rd party API or block explorer. The implementing wallet, dapp or viewer would then check the signature matches this deployment key.
 b. Signing keys could be pre-authenticated by a hosting app, using an embedded keychain.
 c. A governance token could allow a script council to authenticate requests to set and validate keys.

If these criteria are not met:
- For mainnet implementations the implementing wallet should be cautious about using the script - it would be at the app and/or user's discretion.
- For testnets, it is acceptable to allow the script to function, at the discretion of the wallet provider.

## Specification

The keywords “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY” and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

The contract MUST implement the IDecentralisedRegistry interface.
The contract MUST emit the ScriptUpdate event when the script is updated.
The contract SHOULD order the scriptURI returned so that the owner script is returned first (in the case of simple implementations the wallet will pick the first scriptURI returned).

```solidity
interface IDecentralisedRegistry {
    /// @dev This event emits when the scriptURI is updated, 
    /// so wallets implementing this interface can update a cached script
    event ScriptUpdate(address indexed contractAddress, string[] newScriptURI);

    /// @notice Get the scriptURI for the contract
    /// @return The scriptURI
    function scriptURI(address contractAddress) external view returns (string[] memory);

    /// @notice Update the scriptURI 
    /// emits event ScriptUpdate(address indexed contractAddress, scriptURI memory newScriptURI);
    function setScriptURI(address contractAddress, string[] memory scriptURIList) external;
}
```

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

This method allows contracts written without the ERC-5169 interface to associate scripts with themselves, and avoids the need for a centralised online server, with subsequent need for security and the requires an organisation to become a gatekeeper for the database.

## Reference Implementation

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralisedRegistry is IDecentralisedRegistry {
    struct ScriptEntry {
        mapping(address => string[]) scriptURIs;
        address[] addrList;
    }

    mapping(address => ScriptEntry) private _scriptURIs;

    function setScriptURI(
        address contractAddress,
        string[] memory scriptURIList
    ) public {
        require (scriptURIList.length > 0, "> 0 entries required in scriptURIList");
        bool isOwnerOrExistingEntry = Ownable(contractAddress).owner() == msg.sender 
            || _scriptURIs[contractAddress].scriptURIs[msg.sender].length > 0;
        _scriptURIs[contractAddress].scriptURIs[msg.sender] = scriptURIList;
        if (!isOwnerOrExistingEntry) {
            _scriptURIs[contractAddress].addrList.push(msg.sender);
        }
        
        emit ScriptUpdate(contractAddress, msg.sender, scriptURIList);
    }

    // Return the list of scriptURI for this contract.
    // Order the return list so `Owner()` assigned scripts are first in the list
    function scriptURI(
        address contractAddress
    ) public view returns (string[] memory) {
        //build scriptURI return list, owner first
        address contractOwner = Ownable(contractAddress).owner();
        address[] memory addrList = _scriptURIs[contractAddress].addrList;
        uint256 i;

        //now calculate list length
        uint256 listLen = _scriptURIs[contractAddress].scriptURIs[contractOwner].length;
        for (i = 0; i < addrList.length; i++) {
            listLen += _scriptURIs[contractAddress].scriptURIs[addrList[i]].length;
        }

        string[] memory ownerScripts = new string[](listLen);
        uint256 scriptIndex = 0;

        // Add owner strings
        for (i = 0; i < _scriptURIs[contractAddress].scriptURIs[contractOwner].length; i++) {
            ownerScripts[scriptIndex++] = _scriptURIs[contractAddress].scriptURIs[contractOwner][i];
        }

        // remainder
        for (i = 0; i < addrList.length; i++) {
            for (uint256 j = 0; j < _scriptURIs[contractAddress].scriptURIs[addrList[i]].length; j++) {
                string memory thisScriptURI = _scriptURIs[contractAddress].scriptURIs[addrList[i]][j];
                if (bytes(thisScriptURI).length > 0) {
                    ownerScripts[scriptIndex++] = thisScriptURI;
                }
            }
        }

        //fill remainder of any removed strings
        for (i = scriptIndex; i < listLen; i++) {
            ownerScripts[scriptIndex++] = "";
        }

        return ownerScripts;
    }
}
```

## Security Considerations

Mostly outlined in "Overview", subject to further discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).