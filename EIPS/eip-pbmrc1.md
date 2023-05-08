---
title: Purpose bound money
description: An interface extending EIP-1155 for <placeholder>, supporting use case such as <placeholder>
author: Victor Liew (@Alcedo),
discussions-to: https://ethereum-magicians.org (Create a discourse here for early feedback)
status:  DRAFT
type: Standards Track
category: ERC
created: 2023-04-01
requires: 165, 173, 1155
---

<!-- Notes: replace PRBMRC with an EIP number upon creating a PR to EIP Main repo -->
## Abstract

This PBMRC outlines a smart contract interface that builds upon the [ERC-1155](./eip-1155.md) standard to introduce the concept of a purpose bound money (PBM) defined in the [Project Orchid Whitepaper](../assets/eip-pbmrc1/MAS-Project-Orchid.pdf) 

It builts upon the [ERC-1155](./eip-1155.md) standard to leverage upon existing widespread support that wallet providers has implemeneted to display the PBM and to trigger various transfer logic.


## Motivation

Purpose Bound Money (PBM) refers to a protocol that specifies the conditions under which an underlying digital token of value can be used. PBMs can be a bearer or order instruments with self-contained programming logic, and can be transferred between two parties without intermediaries. 

It combines the concept of programmable payments - automatic execution of payments once a pre-defined set of conditions are met and programmable money - the possibility of embedding rules within the medium of exchange itself that defines or constraints its usage.

This standard is critical to ensure that introducing PBM does not lead to fragmentation of various proprietary standard. By making the PBM specification open, it allows for interoperability across different platforms, wallets, payment systems and rails.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “NOT RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview 
- Whether a PBM **SHOULD** have an expiry time will be decided by the PBM creator, the spec itself should not enforce an expiry time.
    - In lieu of our goals of making PBM a suitable construct for all kinds of business logic that could occur in the real world.
    - Should an expiry time not be needed, the expiry time can be set to infinity.
- PBM **MUST** provide a mechanism for all transacting parties to verify the condition by which the token of value can be unwrapped
- PBM **MUST** wrap an underlying token of value.
    - The wrapping of the token can be done either upon the creation of the PBM or wrapped on the fly at a later date.
    - A token of value can be implemented in any widely accepted ERC. E.g. ERC-20, ERC-777, ERC-1363
        - The definition of the word value goes beyond the current scope of our work - refer to project orchid white paper page 14 for details.
    - Consequently, the semantic use of the words "wrap" and "unwrap" would convey the bounding and unbounding of the underlying token.
- PBM **SHALL** adhere to the definition of “wrapping” or “wrap” to mean bounding a token in accordance with PBM business logic during its lifecycle stage.
- PBM **SHALL** adhere to the definition of “unwrap” or “unwrapping” to mean the release of a token in accordance with the PBM business logic during its lifecycle stage.
- There **MUST** be an owner responsible for the creation and maintenance of the PBM
- The definition of purpose bound refers to:
    - A set of conditions that determines the mechanism by which the underlying token of value is being unwrapped to an intended recipient
- We would define a base specification of what a PBM should entail, with extensions to the base specification implemented as another specification on top of the base specification.

### Fungibility 
It is possible to create multiple types of PBM token sets within the same smart contract. Each PBM token may or may not be fungible to one another within the same contract.The standard does NOT mandate how an implementation must do this.

### A Note on Implementing Interfaces
In order to allow the implementors of the PBM token standards to have maximum flexibility in the way they structure the PBM business logic, a PBM can implement an interface in one of two ways: directly (`contract ContractName is InterfaceName`), or by adding functions to it from one or more interfaces. For the purposes of this specification, when a PBM is said to implement an interface, either method of implementation is permitted.


### Terms
1. **PBM Token** Refers to purpose bound money, represented as a [ERC-1155](./eip-1155.md) token. Each token would hold specific details that is required by the PBM business logic. A PBM smart contract is able to issue any amount of PBM Tokens
1. **Spot Token** Underlying ERC-20 compaitible token of value that is to be held by the smart contract. The term spot token was chosen to refer to a specific digital token or asset traded in the spot market and hence would convey that the token has an underlying value ascribe to it. 


### PBM token details
A state variable consisting of all additional details required to facilitate the business logic for a particular PBM type MUST be defined. The compulsory fields are not defined, but may be defined by later proposals. 

An external function may be exposed to create new PBMToken as well at a later date.

Example of token details:

```solidity

    /// @dev Mapping of each ERC-1155 tokenId to its corresponding PBM token details.
    mapping (uint256 => PBMToken) internal tokenTypes ; 

    /// @dev Structure representing all the details corresponding to a PBM tokenId.
    struct PBMToken {
        // Name of the token.
        string name;
        // Value of the token in the context of the underlying wrapped ERC20-compatible token.
        uint256 faceValue;
        // Token will be rendered useless after this time.
        uint256 expiry;
        // Address of the creator of this PBM type on this smart contract.
        address creator;
        // Remaining balance of the token.
        uint256 balanceSupply;
        // Metadata URI for ERC1155 display purposes.
        string uri;

        // Add other state variables...
    }

    /// @notice Creates a new PBM token type with the provided data.
    /// @dev Example response of token URI (reference: https://docs.opensea.io/docs/metadata-standards):
    /// {
    ///     "name": "StraitsX-12",
    ///     "description": "12$ SGD test voucher",
    ///     "image": "https://gateway.pinata.cloud/ipfs/QmQ1x7NHakFYin9bHwN7zy4NdSYS84w6C33hzxpZwCAFPu",
    ///     "attributes": [
    ///         {
    ///             "trait_type": "Value",
    ///             "value": "12"
    ///         }
    ///     ]
    /// }
    function createPBMTokenType(
        string memory name,
        uint256 faceValue,
        uint256 tokenExpiry,
        address creator,
        string memory tokenURI
    ) external;


    /// @notice Retrieves the details of a PBM token type given its tokenId.
    /// @dev This function fetches the PBMToken struct associated with the tokenId and returns it.
    /// @param tokenId The identifier of the PBM token type.
    /// @return A PBMToken struct containing all the details of the specified PBM token type.
    function getTokenDetails(uint256 tokenId) external view returns(PBMToken memory); 
``` 

### PBM Address List
A list of targeted addresses for PBM unwrapping must be specified in an address list. 

```solidity

/// @title PBM Address list Interface. 
/// @notice The PBM address list stores and manages whitelisted merchants address for the PBMs 
/// a merchant in general is anyone who is providing goods or services and is hence deemed to be able to unwrap a PBM.
interface IPBMAddressList {

    /// @notice Checks if the given address is whitelisted as a merchant.
    /// @param _address The address to check
    /// @return True if address is a merchant, else false
    function isMerchant(address _address) external returns (bool);

}

```

### PBMRC1 - Base Interface

<!-- TBD Copy from assets/eip-pbmrc1/contracts/IPBMRC1.sol  -->

```solidity


```


## Extensions

### PBMRC1 - Token Receiver
Smart contracts MUST implement all of the functions in the PBMRC1_TokenReceiver interface to subscribe to PBM unwrap callbacks 

```solidity 
pragma solidity ^0.8.0;

/// @notice Smart contracts MUST implement the ERC-165 `supportsInterface` function and signify support for the `PBMRC1_TokenReceiver` interface to accept callbacks.
/// It is optional for a receiving smart contract to implement the `PBMRC1_TokenReceiver` interface
/// @dev WARNING: Reentrancy guard procedure, Non delegate call, or the check-effects-interaction pattern must be adhere to when calling an external smart contract.
/// The interface functions MUST only be called at the end of the `unwrap` function.
interface PBMRC1_TokenReceiver {
    /**
        @notice Handles the callback from a PBM smart contract upon unwrapping
        @dev An PBM smart contract MUST call this function on the token recipient contract, at the end of a `unwrap` if the
        receiver smart contract supports type(PBMRC1_TokenReceiver).interfaceId
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being unwrapped
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onPBMRC1Unwrap(address,address,uint256,uint256,bytes)"))`
    */
    function onPBMRC1Unwrap(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handles the callback from a PBM smart contract upon unwrapping a batch of tokens
        @dev An PBM smart contract MUST call this function on the token recipient contract, at the end of a `unwrap` if the
        receiver smart contract supports type(PBMRC1_TokenReceiver).interfaceId

        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being unwrapped
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onPBMRC1BatchUnwrap(address,address,uint256,uint256,bytes)"))`
    */
    function onPBMRC1BatchUnwrap(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

```

### PBMRC2 - Non preloaded PBM Interface

The **Non Preloaded** PBM extension is OPTIONAL for compliant smart contracts. This allows contracts to bind an underlying token of value to the PBM at a later date instead of during a minting process.

Compliant contract **MUST** implement the following interface:

<!-- TBD Copy from assets/eip-pbmrc1/contracts/IPBMRC2.sol  -->

```solidity


```


## Rationale

### Overview

This design extends the [ERC-1155](./eip-1155.md) standards in order to acheive ease of adoption across wallet providers as most wallet providers are able to support and display ER-C20, ERC-1155 and ERC-721 standards with ease. An implementation which doesn't extends these standards will require the wallet provider to build a custom user interface and interfacing logic which will impede the go to market process.

This standard sticks to the push transaction model where the transfer of PBM is initiated on the senders side. By embedding the unwrapping logic within the [ERC-1155](./eip-1155.md) `safeTransfer` function, modern wallets are able to support the required PBM logic immediately. 


### Customisabiltiy 
Each ERC-1155 PBM Token would map to an underlying `PBMToken` data structure that implementors are free to customize in accordance to the business logic.

By mapping the underlying ERC-1155 token model with an additional data structure, it allows for the flexibility in the management of multiple token types within the same smart contract with multiple conditional unwrapping logic attached to each token type which reduces the gas costs as there is no need to deploy multiple smart contracts for each token types.

This EIP makes no assumption on access control and under what conditions can a function be executed. It is the responsibility of the PBM creator to determine what a user is able to do and the conditions by which it is useable. 

2. The event notifies subscribers whoever are interested to learn an asset is being consumed.

3. To keep it simple, this standard *intentionally* contains no functions or events related to the creation of a consumable asset. because of XYZ

4. Metadata associated to the consumables is not included the standard. If necessary, related metadata can be created with a separate metadata extension interface like `ERC721Metadata` from [EIP-721](./eip-721.md)

or refer to opensea 

5. MAYBE We choose to include an `address consumer` for `consume` function and `isConsumableBy` so that an NFT MAY be consumed for someone other than the transaction initiator.

6. We choose to include an extra `_data` field for future extension, such as
adding crypto endorsements.

7. We explicitly stay opinion-less about whether EIP-721 or EIP-1155 shall be required because
while we design this EIP with EIP-721 and EIP-1155 in mind mostly, we don't want to rule out
the potential future case someone use a different token standard or use it in different use cases.


## Backwards Compatibility
This interface is designed to be compatible with [ERC-1155](./eip-1155.md). 

## Reference Implementation
Reference implementations can be found in [`README.md`](../assets/eip-pbmrc1/README.md).

## Security Considerations
<!-- TBD Improvement: Think of other security considerations + Read up other security considerations in various EIPS and add on to this.  Improve grammer, sentence structure -->

Malicious users are able to clone existing PBM in tricking users, or creating a PBM with no underlying token of value, or falsifying the face value of each PBM token.

Compliant contracts should pay attention to the balance change for each user when a token is being consumed or minted. 

When the contract is being paused, or the user is being restricted from transferring a token, the unwrap function should be consistent with the transfer restriction

Security audits and tests should be used to verify that unwrap logic behaves as expected or if any complex business logic is being implemented that involves calling an external smart contract to prevent re-entrancy attacks and other forms of call chain attacks.

This EIP depends on the security soundness of the underlying book keeping behavior of the token implementation.

- The PBM contract should carefully design the access control for which role is granted permission to mint a new token. Failing to safe guard such behavior can cause fraudulent issuance and an elevation of total supply.

- The mapping of each PBM tokens to the amount of underlying spot token held by the smart contract should be carefully accounted for and audited.

It is recommended to adopt a token standard that is compaitible with ERC-20. Examples of such tokens will be ERC-777, ERC-1363. ERC-20 however remains the most used as a result of the high degree of confidence in its security and simplicity.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).