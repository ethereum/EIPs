---
eip: 1761
title: ERC-1761 Scoped Approval Interface
author: Witek Radomski <witek@enjin.com>, Andrew Cooke <andrew@enjin.com>, James Therien <james@enjin.com>, Eric Binet <eric@enjin.com>
type: Standards Track
category: ERC
status: Draft
created: 2019-02-18
discussions-to: https://github.com/ethereum/EIPs/issues/1761
requires: 165
---

## Simple Summary

A standard interface to permit restricted approval in token contracts by defining "scopes" of one or more Token IDs.

## Abstract

This interface is designed for use with token contracts that have an "ID" domain, such as ERC-1155 or ERC-721. This enables restricted approval of one or more Token IDs to a specific "scope". When considering a smart contract managing tokens from multiple different domains, it makes sense to limit approvals to those domains. Scoped approval is a generalization of this idea. Implementors can define scopes as needed.

Sample use cases for scopes:

* A company may represent it's fleet of vehicles on the blockchain and it could create a scope for each regional office.
* Game developers could share an [ERC-1155](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md) contract where each developer manages tokens under a specified scope.
* Tokens of different value could be split into separate scopes. High-value tokens could be kept in smaller separate scopes while low-value tokens might be kept in a shared scope. Users would approve the entire low-value token scope to a third-party smart contract, exchange, or other application without concern about losing their high-value tokens in the event of a problem.

## Motivation

It may be desired to restrict approval in some applications. Restricted approval can prevent losses in cases where users do not audit the contracts they're approving. No standard API is supplied to manage scopes as this is implementation specific. Some implementations may opt to offer a fixed number of scopes, or assign a specific set of scopes to certain types. Other implementations may open up scope configuration to its users and offer methods to create scopes and assign IDs to them.

# Specification

```solidity
pragma solidity ^0.5.2;

/**
    Note: The ERC-165 identifier for this interface is 0x30168307.
*/
interface ScopedApproval {
    /**
        @dev MUST emit when approval changes for scope.
    */
    event ApprovalForScope(address indexed _owner, address indexed _operator, bytes32 indexed _scope, bool _approved);

    /**
        @dev MUST emit when the token IDs are added to the scope.
        By default, IDs are in no scope.
        The range is inclusive: _idStart, _idEnd, and all IDs in between have been added to the scope.
        _idStart must be lower than or equal to _idEnd.
    */
    event AddIdsToScope(uint256 indexed _idStart, uint256 indexed _idEnd, bytes32 indexed _scope);

    /**
        @dev MUST emit when the token IDs are removed from the scope.
        The range is inclusive: _idStart, _idEnd, and all IDs in between have been removed from the scope.
        _idStart must be lower than or equal to _idEnd.
    */
    event RemoveIdsFromScope(uint256 indexed _idStart, uint256 indexed _idEnd, bytes32 indexed _scope);

    /** @dev MUST emit when a scope URI is set or changes.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "Scope Metadata JSON Schema".
    */
    event ScopeURI(string _value, bytes32 indexed _scope);

    /**
        @notice     Returns the number of scopes that contain _id.
        @param _id  The token ID
        @return     The number of scopes containing the ID
    */
    function scopeCountForId(uint256 _id) public view returns (uint32);

    /**
        @notice             Returns a scope that contains _id.
        @param _id          The token ID
        @param _scopeIndex  The scope index to  query (valid values are 0 to scopeCountForId(_id)-1)
        @return             The Nth scope containing the ID
    */
    function scopeForId(uint256 _id, uint32 _scopeIndex) public view returns (bytes32);

    /**
        @notice Returns a URI that can be queried to get scope metadata. This URI should return a JSON document containing, at least the scope name and description. Although supplying a URI for every scope is recommended, returning an empty string "" is accepted for scopes without a URI.
        @param  _scope  The queried scope
        @return         The URI describing this scope.
    */
    function scopeUri(bytes32 _scope) public view returns (string memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage the caller's tokens in the specified scope.
        @dev MUST emit the ApprovalForScope event on success.
        @param _operator    Address to add to the set of authorized operators
        @param _scope       Approval scope (can be identified by calling scopeForId)
        @param _approved    True if the operator is approved, false to revoke approval
    */
    function setApprovalForScope(address _operator, bytes32 _scope, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner, within the specified scope.
        @param _owner       The owner of the Tokens
        @param _operator    Address of authorized operator
        @param _scope       Scope to test for approval (can be identified by calling scopeForId)
        @return             True if the operator is approved, false otherwise
    */
    function isApprovedForScope(address _owner, address _operator, bytes32 _scope) public view returns (bool);
}
```

## Scope Metadata JSON Schema

This schema allows for localization. `{id}` and `{locale}` should be replaced with the appropriate values by clients.

```json
{
    "title": "Scope Metadata",
    "type": "object",
    "required": ["name"],
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the scope in a human-readable way.",
        },
        "description": {
            "type": "string",
            "description": "Describes the scope to allow users to make informed approval decisions.",
        },
        "localization": {
            "type": "object",
            "required": ["uri", "default", "locales"],
            "properties": {
                "uri": {
                    "type": "string",
                    "description": "The URI pattern to fetch localized data from. This URI should contain the substring `{locale}` which will be replaced with the appropriate locale value before sending the request."
                },
                "default": {
                    "type": "string",
                    "description": "The locale of the default data within the base JSON"
                },
                "locales": {
                    "type": "array",
                    "description": "The list of locales for which data is available. These locales should conform to those defined in the Unicode Common Locale Data Repository (http://cldr.unicode.org/)."
                }
            }
        }
    }
}
```

### Localization

Metadata localization should be standardized to increase presentation uniformity across all languages. As such, a simple overlay method is proposed to enable localization. If the metadata JSON file contains a `localization` attribute, its content may be used to provide localized values for fields that need it. The `localization` attribute should be a sub-object with three attributes: `uri`, `default` and `locales`. If the string `{locale}` exists in any URI, it MUST be replaced with the chosen locale by all client software.

## Rationale

The initial design was proposed as an extension to ERC-1155: [Discussion Thread - Comment 1](https://github.com/ethereum/EIPs/issues/1155#issuecomment-459505728). After some discussion: [Comment 2](https://github.com/ethereum/EIPs/issues/1155#issuecomment-460603439) and suggestions by the community to implement this approval mechanism in an external contract [Comment 3](https://github.com/ethereum/EIPs/issues/1155#issuecomment-461758755), it was decided that as an interface standard, this design would allow many different token standards such as ERC-721 and ERC-1155 to implement scoped approvals without forcing the system into all implementations of the tokens.

### Metadata JSON

The Scope Metadata JSON Schema was added in order to support human-readable scope names and descriptions in more than one language.

## References

**Standards**
- [ERC-1155 Multi Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md)
- [ERC-165 Standard Interface Detection](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md)
- [JSON Schema](http://json-schema.org/)

**Implementations**
- [Enjin Coin](https://enjincoin.io) ([github](https://github.com/enjin))

**Articles & Discussions**
- [Github - Original Discussion Thread](https://github.com/ethereum/EIPs/issues/1761)
- [Github - ERC-1155 Discussion Thread](https://github.com/ethereum/EIPs/issues/1155)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
