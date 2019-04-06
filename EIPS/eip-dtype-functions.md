---
eip: <to be assigned>
title: dType - Extending the Decentralized Type System for Functions
author: Loredana Cirstea (@loredanacirstea), Christian Tzurcanu (@ctzurcanu)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2019-04-06
requires: 1900
---


## Simple Summary
In the context of dType, the Decentralized Type System described in [EIP-1900](https://github.com/ethereum/EIPs/pull/1900), we are proposing to add support for registering functions in the dType Registry.


## Abstract

This proposal is part of a series of EIPs focused on expanding the concept of a Decentralized Type System, as explained in EIP-1900.
The current EIP specifies the data definitions and interfaces needed to support registering individual smart contract functions, as entries in the dType Registry.


## Motivation

In order to evolve the EVM into a Singleton Operating System, we need a way to register, find and address contract functions that we want to run in an automated way.
This implies having access to all the data needed to run the function inside the EVM.

Aside from the above motivation, there are also near future benefits for this proposal. Having a globally available, non-custodial functions registry, will democratize development of tools, such as those targeting: blockchain data analysis (e.g. block explorers), smart contract IDEs, security analysis of smart contracts.

Registering new smart contract functions can be done through the same consensus mechanism as EIP-1900 mentions, in order to avoid burdening the chain state with redundant or improper records.


## Specification

For each smart contract function, we must store:
* unique function name
* smart contract `address`
* reference to the file containing the function source code
* the type data and label of each input
* the type data and label of each output

The first four are handled by EIP-1900.
Base types will not have output values. However, they may have optional components. Therefore, we are proposing to store these optional components together with function output interfaces in a separate mapping:

```
mapping(bytes32 => dTypes[]) public optionals;
```

The `dTypes` `struct` is defined in EIP-1900.

We can then have an interface to register these optional inputs/outputs for an already registered type, referenced by `typeHash`.

```
function setOptionals(
    bytes32 typeHash,
    dTypes[] memory optionalValues
)
    public
```

Further, the `dType` Registry can be extended to have a function which calculates the function signature, based on the stored information:

```
function getSignature(bytes32 typeHash)
    view
    public
    returns (bytes4 signature)
```

We also propose to extend the `dType` Registry with wrapper functions that are able to call the registered functions with user given input arguments or input arguments referenced by their storage hash, if they are part of a type's storage contract.
This can be further extended to add chaining and composition capabilities.

An example would be a base `run()` function, which takes the ABI encoded input data and the function's `typeHash`. The output will be the ABI encoded output data of the function, referenced by `typeHash`.

```
function run(bytes memory inputData, bytes32 memory typeHash)
    public
    returns(bytes memory outputData)
```

These wrapper functions can be defined in their own library, enabling chaining and composition:

```
using dTypeWrapperLibrary for bytes;
...
function () {
    inputData.run(typeHash1).run(typeHash2).run(typeHash3)
}
```

An example of the data object that is given when registering a function:

```
{
    "name": "setStaked",
    "types": [
        {"name": "TypeA", "label": "typeA", "relation":0, "dimensions":[]}
    ],
    "lang": 0,
    "typeChoice": 4,
    "contractAddress": <address of the deployed smart contract where the function is defined>,
    "source": <a SWARM hash for source files>,
    "optionals": [
        {"name": "TypeB", "label": "typeB", "relation":0, "dimensions":[]}
    ]
}
```
Note that the input and output types are based on types that have already been registered. This lowers the amount of ABI information needed to be stored for each function and enables developers to aggregate and find functions that use the same types for their I/O. This can be a powerful tool for interoperability and smart contract composition.


## Rationale

The suggestion to treat each function as a separate entity instead of having a contract-based approach allows us to:
* have a global context of readily available functions
* scale designs through functional programming patterns rather than contract-encapsulated logic (which can be successfully used to scale development efforts independently)
* bidirectionally connect functions with the types they use, making automation easier
* cherry pick functions from already deployed contracts if the other contract functions do not pass community consensus
* have scope-restricted improvements - instead of redeploying entire contracts, we can just redeploy the new function versions that we want added to the registry

The proposal to store the minimum ABI information on-chain, for each function, allows us to:
* enable on-chain automation (e.g. function chaining and composition)
* be backwards compatible in case the function signature format changes (e.g. from `bytes4` to `bytes32`)

Concerns about this design might be:
* redundancy of storing `contractAddress` for each function that is part of the same contract

We think that state/storage cost will be compensated through DRYness across the chain, due to reusing types and functions that have already been registered and are now very easy to find. Other state/storage cost calculations will be added once the specification and implementation is closer to be finalized.

## Backwards Compatibility

This proposal does not affect extant Ethereum standards or implementations. Registering functions for existing contract deployments should be fully supported.
The EIP implementation currently requires the experimental version of ABIEncoderV2.

## Test Cases

Will be added.


## Implementation

In work implementation examples can be found at https://github.com/ctzurcanu/dType/tree/master/contracts/contracts.
This proposal will be updated with an appropriate implementation when consensus is reached on the specifications.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
