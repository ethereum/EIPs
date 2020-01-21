---
eip: <to be assigned>
title: Contract-Based MetaTransaction Standard
author: Nick Mudge <nick@perfectabstractions.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2020-01-21
optional: EIP 712
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Provides a single generic function for handling *all* meta transactions of a contract.


## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
There are different ways to implement meta transactions. This standard addressess the contract-based approach.

Existing implementations of contract-based meta transactions consist of a single meta transaction function for each task or function in the contract. This standard provides a single, generic function for handling *all* meta transactions of a contract.

The aim of this standard is to provide the sweet spot between flexibility and consistancy, while maintaining security and useability.

This standard has no dependencies on third-party contracts, libraries or other software. It requires only the Solidity programming language.

This standard is not limited to ERC20 token or other token transactions. This standard supports a very broad range of meta transactions. 

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Standardizing how to display function calls to users for signing meta transactions will improve the user experience of executing meta transactions and improve security.

Standardizing contract-based meta transactions will reduce the time and effort required for developers to develop and understand contracts with meta transactions. Standardizing contract-based meta transactions will facilitate the creation of contract and UI programming libraries and other software for implementing or interacting with meta transactions.

A single generic function for handling meta transactions reduces the contract overhead of having many functions handling different meta transactions.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
This standard provides the following single function:
```solidity
function metaTransaction(address account, uint8 v, bytes32 r, bytes32 s, bytes calldata data) external payable
```
1. The `account` variable is the user's account address. 
2. `v`, `r`, `s` are the signature values used to validate that the user signed the data within the `data` variable.
3. The `data` argument contains any data that is needed, including the signed data that is verified with the signed values.

The `data` argument enables any number of arguments or data to be passed to the function. This generalizes the function. Values in `data` are easily decoded using the builtin `abi.decode` function.

This standard specifies two different uses of the `metaTransaction` function:
1. Generalized meta transaction. Used to call any function in a contract as a meta transaction.
2. Custom meta transaction. Custom code is executed and a custom message is displayed to the user to be signed.

## Generalized MetaTransactions

Any public or external function in a contract can be executed as a meta transaction by using the following message format. A message using this format is displayed to a user using EIP 712 in client software (such as MetaMask) and is signed by the user.

Message format:
```
FunctionCall(string description,string functionSignature,bytes functionCall,...)
```
The `description` field is used to display to the user a description of the function call. It should tell the user clearly what the function will do.

The `functionSignature` field contains the string signature of the function. The `functionCall` field contains the ABI encoded function call which includes the four byte function selector and the ABI encoded function arguments.

The first three fields are mandatory. Additional fields may be added and are not specified. For example a `nonce` could be added to implement replay protection. Or a `relayer` field could be added for paying third-party relayers.

The reason that other fields such as `nonce` and `relayer` are not specified in this standard is because these and other functionality may be implemented in different ways or according to other standards. This standard is flexible enough to accommodate various circumstances.

### Client Software
Client software that recieves a `FunctionCall` message for the user to sign should decode the `functionCall` byte string using the `functionSignature` string. **The client software should display to the user the human-readable function call, with arguments, that will be executed.** Otherwise the user will see a byte string which is not ideal.

All that a client needs to show the human-readable function call is the function signature string and the function call bytes. Those are provided in the `FunctionCall` message.

The client software should also check that the first four bytes of a keccak256 hash of `functionSignature` matches the first four bytes of the `functionCall` byte string. This is to ensure that the function signature string does indeed match the function call bytes.

### Example Implementation of Generalized MetaTransactions
```solidity
  function metaTransaction(address account, uint8 v, bytes32 r, bytes32 s, bytes calldata data) external payable {
    (bytes32 descriptionHash, bytes32 functionSignatureHash, bytes memory functionCall) = abi.decode(data, (bytes32,bytes32,bytes));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(
            FUNCTIONCALL_TYPEHASH,
            descriptionHash,
            functionSignatureHash,
            functionCall))
      ));
      require(ecrecover(digest, v, r, s) == account);
      (bool success,) = address(this).call(data);
      require(success);
    }
```

## Custom MetaTransactions

Custom meta transactions can be executed with custom EIP 712 messages. A selector value can be used to determine what code to execute.

### Example Implementation of Custom MetaTransactions

Below is an example of implementing custom meta transactions . In this example the `selector` variable is used to determine what code to execute. Custom EIP 712 messages are used.
```solidity
    function metaTransaction(address account, uint8 v, bytes32 r, bytes32 s, bytes calldata data) external payable {
        (bytes32 selector, bytes memory functionArguments) = abi.decode(data, (bytes32,bytes));
        if(keccak256("transfer tokens") == selector) {
            (address _from, address _to, uint256 _value) = abi.decode(functionArguments, (address,address,uint256));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSFERFROM_TYPEHASH,
                    _from,
                    _to,
                    _value
                ))
            ));
            require(ecrecover(digest, v, r, s) == account);
            transferFrom(_from, _to, _value);
        }
        else if(keccak256("approve(address,uint256)") == selector) {
            (address _from, uint256 _value) = abi.decode(functionArguments, (address,uint256));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    APPROVE_TYPEHASH,
                    _from,
                    _value
                ))
            ));
            require(ecrecover(digest, v, r, s) == account);
            approve(_from, _value);
        }
        else {
            revert();
        }
    }
```
The above function implements [EIP 712](https://eips.ethereum.org/EIPS/eip-712) for functions `transferFrom` and `approve`.

Many more `if else` blocks can be added to the above function to support more meta transactions. In testing 44 `if else` blocks were used before the 24KB max contract size limit was reached. Removing the max contract size limit is also an option by using [EIP1538](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1538.md).

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
This standard provides the maximum flexibility in terms of what code can be executed, what data can be used, and what data can be shown to the user and signed and verified.

This standard is designed so that other functionality or standards such as paying third-party relayers and replay protection can be built on top of it.

### Standard EIP 721 Messages

Other standards can build on top of this one by defining standard EIP 721 messages for certain use cases to be displayed to users and signed by them. For example [ERC-1776](https://github.com/ethereum/EIPs/issues/1776) proposes a standard EIP 721 message for ERC20 transactions.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This standard works best with Solidity 0.5.0 and higher for the following reasons:
1. The builtin `abi.decode` function is not available until Solidity 0.5.0.
2. Before Solidity 0.5.0 the maximum number of local variables in a function was 16. Solidity 0.5.0 and higher does not have this limitation.

<!--
## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

<!--
## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
It is best not to display byte strings to users when signing data. A user can't know what he/she is signing if what is displayed includes a byte string. EIP 712 was created to get rid of signing byte strings. 

If clients implement this standard then the function call byte string will be shown in a human readable format to users.

### Replay Protection

Transaction replay protection and other security measures can be built on top of this standard.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
