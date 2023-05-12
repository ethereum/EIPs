---
eip: TBD
title: Purpose bound money
description: An interface extending EIP-1155 for <placeholder>, supporting use case such as <placeholder>
authors: Victor Liew (@Alcedo), Wong Tse Jian (@wongtsejian)
discussions-to: https://ethereum-magicians.org (Create a discourse here for early feedback)
status:  DRAFT
type: Standards Track
category: ERC
created: 2023-04-01
requires: 165, 173, 1155
---

<!-- Notes: replace PRBMRC with EIP upon creating a PR to EIP Main repo -->
## Abstract

This PBMRC outlines a smart contract interface that builds upon the [ERC-1155](./eip-1155.md) standard to introduce the concept of a purpose bound money (PBM) defined in the [Project Orchid Whitepaper](../assets/eip-pbmrc1/MAS-Project-Orchid.pdf).

It builds upon the [ERC-1155](./eip-1155.md) standard, by leveraging pre-existing, widespread support that wallet providers have implemented, to display the PBM and trigger various transfer logic.

## Motivation

The establishment of this protocol seeks to forestalls technology fragmentation and consequently a lack of interoperability. By making the PBM specification open, it gives new participants easy and free access to the pre-existing market standards, enabling interoperability across different platforms, wallets, payment systems and rails. This would lower cost of entry for new participants, foster a vibrant payment landscape and prevent the development of walled gardens and monopolies, ultimately leading to more efficient, affordable services and better user experiences.

## Definitions

A PBM based architecture has several distinct components:

- **Spot Token** - a ERC-20 or ERC-20 compatible digital currency (e.g. ERC-777, ERC-1363) serving as the collateral backing the PBM Token.
  - Digital currency referred to in this PBMRC paper **SHOULD** possess the following properties:
    - a good store of value;
    - a suitable unit of account; and
    - a medium of exchange;
- **Spot Token Issuer** - is a regulated financial institution providing the underlying digital currency backing the PBM Token. Spot Token Issuer mints a compatible digital currency when it receives fiat currencies from a PBM Creator and burns digital currency when a PBM Token recipient wishes to exchange unwrapped PBM Tokens for fiat currencies.
- **PBM Wrapper** - a smart contract, which wraps the Spot Token, by specifying condition(s) that has/have to be met (referred to as PBM business logic in subsequent section of this paper). The smart contract verifies that condition(s) has/have been met before unwrapping the underlying Spot Token;
- **PBM Token** - the Spot Token and its PBM wrapper are collectively referred to as a PBM Token. PBM Tokens are represented as a [ERC-1155](./eip-1155.md) token.
  - PBM Tokens are bearer instruments, with self-contained programming logic, and can be transferred between two parties without involving intermediaries. It combines the concept of:
    - programmable payment - automatic execution of payments once a pre-defined set of conditions are met; and
    - programmable money - the possibility of embedding rules within the medium of exchange itself that defines or constraints its usage.
- **PBM Creator** defines the conditions of the PBM Wrapper to create PBM Tokens. A PBM Creator is able to issue any amount of PBM Tokens, provided that the PBM Creator deposits equivalent amounts of fiat currencies with the Spot Token Issuer.
- **PBM Infrastructure** - consisting of a ledger-based infrastructure. While a PBM can be either distributed ledger technology (DLT) based or non-DLT based, the scope of this PBMRC paper is limited to a DLT-based infrastructure build upon the Ethereum blockchain;
- **PBM Wallet** - cryptographic wallets which holds users' private keys, granting them access to PBMs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview

- Whether a PBM Token **SHOULD** have an expiry time will be decided by the PBM Creator, the spec itself should not enforce an expiry time.
  - To align with our goals of making PBM Token a suitable construct for all kinds of business logic that could occur in the real world.

  - Should an expiry time not be needed, the expiry time can be set to infinity.

- PBM **SHALL** adhere to the definition of “wrap” or “wrapping” to mean bounding a token in accordance with PBM business logic during its lifecycle stage.

- PBM **SHALL** adhere to the definition of “unwrap” or “unwrapping” to mean the release of a token in accordance with the PBM business logic during its lifecycle stage.

- A valid PBM Token **MUST** consists of an underlying Spot Token and the PBM Wrapper.
  - The wrapping of the Spot Token can be done either upon the creation of the PBM Token or at a later date prior to its issuance.
  
  - A Spot Token can implement any widely accepted ERC-20 compatible ERC e.g. ERC-20, ERC-777, ERC-1363.

- PBM Wrapper **MUST** provide a mechanism for all transacting parties to verify that all necessary condition(s) have been met before allowing the PBM Token to be unwrapped. Refer to Auditability section for elaborations.

- The PBM Creator **MUST** be an owner (i.e. PBM Creator) responsible for the creation and maintenance of the PBM.
  
- This paper defines a base specification of what a PBM should entail. Extensions to this base specification can be implemented as separate specifications.

### Auditability

PBM Wrapper **SHOULD** provide mechanism(s) to verify that specified conditions for unwrapping a PBM is met. Such mechanisms could involve automated validation or asynchronous user inputs from transacting parties and/or whitelisted third parties validators. As the fulfilment of PBM conditions is likely to be subjected to audits, all necessary evidence to support such audits shall be documented:

- The interface/events emitted **SHOULD** allow a finegrained recreation of the transaction history.
- The source code **SHOULD** be verified and formally published on a blockchain explorer.
- Depending on the sensitivity of the information, the evidence **MAY** need to be encrypted and stored in secure, private storage locations outside of the public blockchain.

### Fungibility

A PBM Wrapper **SHOULD** be able to wrap multiple types of compatible Spot Tokens. Spot Tokens wrapped by the same PBM wrapper may or may not be fungible to one another. The standard does NOT mandate how an implementation must do this.

### A Note on Implementing Interfaces

In order to allow the implementors of this PBM standard to have maximum flexibility in the way they structure the PBM business logic, a PBM can implement this interface in two ways:

- directly by declaring that (`contract ContractName is InterfaceName`); or
- indirectly by adding all functions from this interface into the contract. The indirect method allows the contract to implement additional interfaces.

### PBM token details

A state variable consisting of all additional details required to facilitate the business logic for a particular PBM type MUST be defined. The compulsory fields are listed in the `struct PBMToken` (below), additional, optional state variables may be defined by later proposals.

An external function may be exposed to create new PBM Token as well at a later date.

Example of token details:

```solidity
pragma solidity ^0.8.0;

abstract contract IPBMRC1_TokenManager {
    /// @dev Mapping of each ERC-1155 tokenId to its corresponding PBM Token details.
    mapping (uint256 => PBMToken) internal tokenTypes ; 

    /// @dev Structure representing all the details corresponding to a PBM tokenId.
    struct PBMToken {
        //Compulsory state variables (name, faceValue, expiry, creator, balanceSupply and uri) MUST be included for all PBM token implementing this interface.
        // Name of the token.
        string name;
        // Value of the underlying wrapped ERC20-compatible Spot Token. It is typically denominated in a fiat currency as most merchants only accept fiat currency.
        uint256 faceValue;
        // Token will be rendered useless after this time (expressed in Unix Epoch time).
        uint256 expiry;
        // Address of the creator of this PBM type on this smart contract.
        address creator;
        // Address of the owner of this PBM type on this smart contract.
        address owner;
        // Remaining balance of the PBM Token.
        uint256 balanceSupply;
        // Metadata URI for ERC1155 display purposes.
        string uri;

        //List of optional state variables
        // A abbreviation for the PBM token name may be assigned
        string tokenSymbol;
        // ISO4217 three character alphabetic code may be needed for the faceValue in a multicurrency PBM use cases
        string currencySymbol
        
        // Add other optional state variables below...

    }

    /// @notice Creates a new PBM Token type with the provided data.
    /// @dev The caller of createPBMTokenType shall be responsible for setting the owner and creator address.
    /// Example response of token URI (reference: https://docs.opensea.io/docs/metadata-standards):
    /// {
    ///     "name": "StraitsX-12",
    ///     "description": "$12 SGD test voucher",
    ///     "image": "https://gateway.pinata.cloud/ipfs/QmQ1x7NHakFYin9bHwN7zy4NdSYS84w6C33hzxpZwCAFPu",
    ///     "attributes": [
    ///         {
    ///             "trait_type": "Value",
    ///             "value": "12"
    ///         }
    ///     ]
    /// }
    function createPBMTokenType(
        string memory _name,
        uint256 _faceValue,
        uint256 _tokenExpiry,
        address _creator,
        address _owner,
        string memory _tokenURI
    ) external;


    /// @notice Retrieves the details of a PBM Token type given its tokenId.
    /// @dev This function fetches the PBMToken struct associated with the tokenId and returns it.
    /// @param _tokenId The identifier of the PBM token type.
    /// @return A PBMToken struct containing all the details of the specified PBM token type.
    function getTokenDetails(uint256 _tokenId) external view returns(PBMToken memory); 
}
```

### PBM Address List

A list of targeted addresses for PBM unwrapping must be specified in an address list.

```solidity

pragma solidity ^0.8.0;

/// @title PBM Address list Interface. Functions and events relating to whitelisting of merchant stores 
/// and blacklisting of wallet addresses.
/// @notice This interface defines a scheme to manage whitelisted merchant addresses and blacklisted  
/// wallet addresses for the PBMs. A merchant in general is anyone who is providing goods or services 
/// and is hence deemed to be able to unwrap a PBM.
/// Implementers will define the appropriate logic to whitelist or blacklist specific merchant addresses.

interface IPBMAddressList {

    /// @notice Adds wallet addresses to the blacklist, preventing them from receiving PBM tokens.
    /// @param _addresses An array of wallet addresses to be blacklisted.
    /// @param _metadata Optional comments or notes about the blacklisted addresses.
    function blacklistAddresses(address[] memory _addresses, string memory _metadata) external; 

    /// @notice Removes wallet addresses from the blacklist, allowing them to receive PBM tokens.
    /// @param _addresses An array of wallet addresses to be removed from the blacklist.
    /// @param _metadata Optional comments or notes about the removed addresses.
    function unBlacklistAddresses(address[] memory _addresses, string memory _metadata) external; 

    /// @notice Checks if the address is one of the blacklisted addresses
    /// @param _address The address to query
    /// @return _bool True if address is blacklisted, else false
    function isBlacklisted(address _address) external returns (bool) ; 

    /// @notice Registers merchant wallet addresses to differentiate between users and merchants.
    /// @dev The 'unwrapTo' function is called when invoking the PBM 'safeTransferFrom' function for valid merchant addresses.
    /// @param _addresses An array of merchant wallet addresses to be added.
    /// @param _metadata Optional comments or notes about the added addresses.
    function addMerchantAddresses(address[] memory _addresses, string memory _metadata) external; 

    /// @notice Unregisters wallet addresses from the merchant list.
    /// @dev Removes the specified wallet addresses from the list of recognized merchants.
    /// @param _addresses An array of merchant wallet addresses to be removed.
    /// @param _metadata Optional comments or notes about the removed addresses.
    function removeMerchantAddresses(address[] memory _addresses, string memory _metadata) external; 

    /// @notice Checks if the address is one of the whitelisted merchant
    /// @param _address The address to query
    /// @return _bool True if the address is a merchant that is NOT blacklisted, otherwise false.
    function isMerchant(address _address) external returns (bool) ; 
    
    /// @notice Event emitted when the Merchant List is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of merchant wallet addresses that was whitelisted
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event MerchantList(string _action, address[] _addresses, string _metadata);
    
    /// @notice Event emitted when the Blacklist is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of wallet addresses that was blacklisted
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event Blacklist(string _action, address[] _addresses, string _metadata);
}

```

### PBMRC1 - Base Interface

This interface contains the essential functions required to implement a pre-loaded PBM.

<!-- TBD Copy from assets/eip-pbmrc1/contracts/IPBMRC1.sol  -->

```solidity


```

## Extensions

### PBMRC1 - Token Receiver

Smart contracts MUST implement all of the functions in the PBMRC1_TokenReceiver interface to subscribe to PBM unwrap callbacks.

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
        @param _operator  The address which initiated the transfer (either the address which previously owned the token or the address authorised to make transfers on 
                          the owner's behalf) (i.e. msg.sender)
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

        @param _operator  The address which initiated the transfer (either the address which previously owned the token or the address authorised to make transfers on 
                          the owner's behalf) (i.e. msg.sender)
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

The **Non Preloaded** PBM extension is OPTIONAL for compliant smart contracts. This allows contracts to bind an underlying Spot Token to the PBM at a later date instead of during a minting process.

Compliant contract **MUST** implement the following interface:

<!-- TBD Copy from assets/eip-pbmrc1/contracts/IPBMRC2.sol  -->

```solidity


```

## Rationale

This paper extends the [ERC-1155](./eip-1155.md) standards in order to enable easy adoption by existing wallet providers. Currently, most wallet providers are able to support and display ERC-20, ERC-1155 and ERC-721 standards. An implementation which doesn't extend these standards will require the wallet provider to build a custom user interface and interfacing logic which increases the implementation cost and lengthen the time-to-market.

This standard sticks to the push transaction model where the transfer of PBM is initiated on the senders side. Modern wallets can support the required PBM logic by embedding the unwrapping logic within the [ERC-1155](./eip-1155.md) `safeTransfer` function.

### Customisability

Each ERC-1155 PBM Token would map to an underlying `PBMToken` data structure that implementers are free to customize in accordance to the business logic.

By mapping the underlying ERC-1155 token model with an additional data structure, it allows for the flexibility in the management of multiple token types within the same smart contract with multiple conditional unwrapping logic attached to each token type which reduces the gas costs as there is no need to deploy multiple smart contracts for each token types.

1. This EIP makes no assumption on access control and under what conditions can a function be executed. It is the responsibility of the PBM Creator to determine what a user is able to do and the conditions by which a asset is consumed.

2. The event notifies subscribers who are interested to learn whenever an PBM Token is being consumed.

3. To keep it simple, this standard *intentionally* omits functions or events related to the creation of a consumable asset. because of XYZ

4. Metadata associated to the consumables is not included the standard. If necessary, related metadata can be created with a separate metadata extension interface, e.g. `ERC721Metadata` from [EIP-721](./eip-721.md). Refer to Opensea's metadata-standards for an implementation example.

5. It is **OPTIONAL** to include an parameter `address consumer` for `consume` and `isConsumableBy` functions so that an NFT **MAY** be consumed for someone other than the transaction initiator.

6. To allow for future extensibility, it is **RECOMMENDED** that developers read and adopt the specifications for building general extensibility for method behaviours ([ERC-5750](./eip-5750.md)).

## Backwards Compatibility

This interface is designed to be compatible with [ERC-1155](./eip-1155.md).

## Reference Implementation

Reference implementations can be found in [`README.md`](../assets/eip-pbmrc1/README.md).

## Security Considerations
<!-- TBD Improvement: Think of other security considerations + Read up other security considerations in various EIPS and add on to this.  Improve grammer, sentence structure -->

- Malicious users may attempt to:

  - clone existing PBM Tokens to perform double-spending;
  - create invalid PBM Token with no underlying Spot Token; or
  - falsifying the face value of PBM token through wrapping of fraudulent/invalid/worthless Spot Tokens.

- Compliant contracts should pay attention to the balance change for each user when a token is being consumed or minted.

- If PBM Tokens are sent to a recipient wallet that is not compatible with PBM Wrapper the transaction **MUST** fail and PBM Tokens should remain in the sender's PBM Wallet.

- To ensure consistency, when the contract is being suspended, or a user is being restricted from transferring a token, due to suspected fraud, erroneous transfers etc, similar restrictions **MUST** be applied to the user's requests to unwrap the PBM Token.

- Security audits and tests should be performed to verify that unwrap logic behaves as expected or if any complex business logic is being implemented that involves calling an external smart contract to prevent re-entrancy attacks and other forms of call chain attacks.

- This EIP depends on the security soundness of the underlying book keeping behavior of the token implementation.

  - The PBM Wrapper should be carefully designed to ensure effective control over permission to mint a new token. Failing to safeguard permission to mint a new PBM Token can cause fraudulent issuance and and unauthorised inflation of total token supply.

  - The mapping of each PBM Tokens to the amount of underlying spot token held by the smart contract should be carefully accounted for and audited.

- It is recommended to adopt a token standard that is compatible with ERC-20. Examples of such compatible tokens includes tokens implementing ERC-777 or ERC-1363. However, ERC-20 remains the most widely accepted because of its simplicity and there is a high degree of confidence in its security.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
