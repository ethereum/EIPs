---
eip: TBD
title: New `eth_checkMethodSupport` for JSON-RPC
description: List supported JSON-RPC methods of an endpoint by quering `eth_checkMethodSupport`.
author: Raphaël Deknop (@0xSileo) <github@sileo.dev>
discussions-to: https://ethereum-magicians.org/t/eip-create-an-eth-supportsmethod-method-for-json-rpc/19247
status: Draft
type: Standards Track
category: Interface
created: 2024-03-26
---

## Abstract

We're introducing a new JSON-RPC method named `eth_checkMethodSupport`, which returns the JSON-RPC methods supported by an endpoint if no parameter is given, or the supported statuses of the methods given in the parameters, if any. In both cases, the returned data is a JSON object type with method names as keys and booleans as values. The booleans correspond to the supported status of the methods. 


## Motivation

As of now, there is no easy way to know which JSON-RPC methods are supported (understand implemented and working) by the endpoint one wants to make its queries to. This creates some friction and unnecessary overhead. Indeed, one could make the query and check if the result is an error or not but :

1. Some calls require signing a transaction, thus paying a fee
2. Ususally an example query has to be written, increasing the amount of data transmitted
3. The error code -32603, per its JSON-RPC specification, says nothing about what went wrong in the code, and there's no standard among Ethereum RPC providers for this. 

This also allows for easier development of tools comparing endpoints and constitutes a first step towards a modular node architecture.


## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Query

The JSON-RPC query MUST have the `"method"` be set to `eth_checkMethodSupport` and MAY contain parameters. If so, the parameters MUST be a list of unique strings consisting of method names as specified by the Ethereum JSON-RPC spec. The parameters MUST NOT be in any other form.

### Response

The response MUST be a JSON object having the values given in the parameter list as keys and booleans corresponding to whether it is supported by the endpoint responding as values for those keys. If no parameter is given, the response MUST be a JSON object having all methods listed in the Ethereum JSON-RPC specification as keys, and booleans corresponding to whether they are supported by the enpoint as values.

It is RECOMMENDED that the order of the object follows the order of the parameters. If no parameter is given, it is RECOMMENDED that the order is the same as in the ETH JSON-RPC specification.

Since the parameters have to be Ethereum JSON-RPC method names, and that the response has to use it as keys, it follows that the keys in the returned JSON object MUST be Ethereum JSON-RPC method names as well.


For completeness' sake, this EIP is also applicable to the `eth_supportsMethod` method, which means that it MUST be included in the response if no params are given, or if `eth_supportsMethod` is in the parameters. 


## Rationale

There has been discussion on implementing multiple methods to distinguish querying *all* the supported methods, or querying a subset of them. By returning a JSON object, we allow the types to be the same. This also makes sure the boolean values are attached to their corresponding method names, and removes the need for the querier to store its query order.

Due to there being only one method, the name has to be descriptive in both cases. Initially, `eth_supportsMethod` or `eth_getSupportedMethods` were proposed, but `eth_checkMethodSupport` is convenient whether a method name is passed as a parameter or not.

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

Suppose an endpoint is sent the following query: 


```json
{
    "jsonrpc": 2.0, 
    "method":"eth_checkMethodSupport", 
    "params":["eth_getBalance", "eth_call", "eth_sendTransaction"], 
    "id":1
}
```

and suppose it only supports querying address balances. Then, the response should be :


```json
{
    "jsonrpc": 2.0,
    "result": 
        {
            "eth_getBalance": true,
            "eth_call": false,
            "eth_sendTransaction": false
        },
    "id":1
}
```

## Reference Implementation

None yet

## Security Considerations

There is currently no way to enforce that the methods work as expected. This proposed method is no different, thus an endpoint could provide false values, that do not reflect the way they work. This, however, is a more general risk and consideration, applicable to any method. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
