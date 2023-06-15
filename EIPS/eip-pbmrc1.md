---
eip: TBD
title: Purpose bound money
description: An interface extending EIP-1155 for <placeholder>, supporting use case such as <placeholder>
authors: Victor Liew (@alcedo), Wong Tse Jian (@wongtsejian), Chin Sin Ong (@chinsinong)
discussions-to: https://ethereum-magicians.org (Create a discourse here for early feedback)
status: DRAFT
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

The establishment of this proposal seeks to forestalls technology fragmentation and consequently a lack of interoperability. By making the PBM specification open, it gives new participants easy and free access to the pre-existing market standards, enabling interoperability across different platforms, wallets, payment systems and rails. This would lower cost of entry for new participants, foster a vibrant payment landscape and prevent the development of walled gardens and monopolies, ultimately leading to more efficient, affordable services and better user experiences.

## Definitions

A PBM based architecture has several distinct components:

- **Spot Token** - a ERC-20 or ERC-20 compatible digital currency (e.g. ERC-777, ERC-1363) serving as the collateral backing the PBM Token.
  - Digital currency referred to in this PBMRC paper **SHOULD** possess the following properties:
    - a good store of value;
    - a suitable unit of account; and
    - a medium of exchange;
- **PBM Wrapper** - a smart contract, which wraps the Spot Token, by specifying condition(s) that has/have to be met (referred to as PBM business logic in subsequent section of this proposal). The smart contract verifies that condition(s) has/have been met before unwrapping the underlying Spot Token;
- **PBM Token** - the Spot Token and its PBM wrapper are collectively referred to as a PBM Token. PBM Tokens are represented as a [ERC-1155](./eip-1155.md) token.
  - PBM Tokens are bearer instruments, with self-contained programming logic, and can be transferred between two parties without involving intermediaries. It combines the concept of:
    - programmable payment - automatic execution of payments once a pre-defined set of conditions are met; and
    - programmable money - the possibility of embedding rules within the medium of exchange itself that defines or constraints its usage.
- **PBM Creator** defines the conditions of the PBM Wrapper to create PBM Tokens.
- **PBM Wallet** - cryptographic wallets which can either be an EOA (Externally Owned Account) that is controlled by a private key, or a smart contract wallet.
- **Merchant / Redeemer** - In the context of this proposal, a Merchant or a Redeemer is broadly defined as the ultimate recipient, or endpoint, for PBM tokens, to which these tokens are intrinsically directed or purpose-bound to.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview

- Whether a PBM Token **SHOULD** have an expiry time will be decided by the PBM Creator, the spec itself should not enforce an expiry time.

  - To align with our goals of making PBM Token a suitable construct for all kinds of business logic that could occur in the real world.
  - Should an expiry time not be needed, the expiry time can be set to infinity.

- PBM **SHALL** adhere to the definition of “wrap” or “wrapping” to mean bounding a token in accordance with PBM business logic during its lifecycle stage.

- PBM **MUST** incorporate both a whitelist and a blacklist of addresses as a key element of the conditions that must be satisfied prior to unwrapping the underlying Spot Token

- PBM **SHALL** adhere to the definition of “unwrap” or “unwrapping” to mean the release of a token in accordance with the PBM business logic during its lifecycle stage.

- A valid PBM Token **MUST** consists of an underlying Spot Token and the PBM Wrapper.

  - The Spot Token can be wrapped either upon the creation of the PBM Token or at a later date.

  - A Spot Token can be implemented as any widely accepted ERC-20 compatible token, such as ERC-20, ERC-777, or ERC-1363.

- PBM Wrapper **MUST** provide a mechanism for all transacting parties to verify that all necessary condition(s) have been met before allowing the PBM Token to be unwrapped. Refer to Auditability section for elaborations.

- The PBM Token **MUST** be burnt upon being fully unwrapped and used.

- This proposal defines a base specification of what a PBM should entail. Extensions to this base specification can be implemented as separate specifications.

### Auditability

PBM Wrapper **SHOULD** provide mechanism(s) to make it easy for the public to verify the smart contract logic for unwrapping a PBM. Such mechanisms could then be leveraged by automated validation or asynchronous user verifications from transacting parties and/or whitelisted third parties attestations.

As the fulfilment of PBM conditions is likely to be subjected to audits to ensure trust amongst all transacting parties, the following evidence shall be documented to support audits:

- The interface/events emitted **SHOULD** allow a fine-grained recreation of the transaction history, token types and token balances
- The source code **SHOULD** be verified and formally published on a blockchain explorer.

### Fungibility

A PBM Wrapper **SHOULD** be able to wrap multiple types of compatible Spot Tokens. Spot Tokens wrapped by the same PBM wrapper may or may not be fungible to one another. The standard does NOT mandate how an implementation must do this.

### PBM token details

The ERC-1155 Multi Token Standard enables each token ID to correspond to a unique, configurable token type. All essential details facilitating the business or display logic for a specific PBM type **MUST** be defined for each token type. The mandatory fields for this purpose are outlined in the `struct PBMToken` (below). Future proposals may define additional, optional state variables as needed. Once a token detail has been defined, it **MUST** be immutable.

Example of token details:

```solidity
pragma solidity ^0.8.0;

abstract contract IPBMRC1_TokenManager {
    /// @dev Mapping of each ERC-1155 tokenId to its corresponding PBM Token details.
    mapping (uint256 => PBMToken) internal tokenTypes ;

    /// @notice A PBM token MUST include compulsory state variables (name, faceValue, expiry, and uri) to adhere to this standard.
    /// @dev Represents all the details corresponding to a PBM tokenId.
    struct PBMToken {
        // Name of the token.
        string name;

        // Value of the underlying wrapped ERC20-compatible Spot Token. Additional information on the `faceValue` can be specified by
        // adding the optional variables: `currencySymbol` or `tokenSymbol` as indicated below
        uint256 faceValue;

        // Time after which the token will be rendered useless (expressed in Unix Epoch time).
        uint256 expiry;

        // Metadata URI for ERC-1155 display purposes.
        string uri;

        // OPTIONAL: Indicates if the PBM token can be transferred to a non merchant/redeemer wallet.
        bool isTransferable;

        // OPTIONAL: Determines whether the PBM will be burned or revoked upon expiry, under certain predefined conditions, or at the owner's discretion.
        bool burnable;

        // OPTIONAL: Number of decimal places for the token.
        uint8 decimals;

        // OPTIONAL: The address of the creator of this PBM type on this smart contract.
        address creator;

        // OPTIONAL: The smart contract address of the spot token.
        address tokenAddress;

        // OPTIONAL: The running balance of the PBM Token type that has been minted.
        uint256 totalSupply;

        // OPTIONAL: An ISO4217 three-character alphabetic code may be needed for the faceValue in multicurrency PBM use cases.
        string currencySymbol;

        // OPTIONAL: An abbreviation for the PBM token name may be assigned.
        string tokenSymbol;

        // Add other optional state variables below...
    }
}
```

An implementer has the option to define all token types upon PBM contract deployment. If needed, they can also expose an external function to create new PBM tokens at a later time.
All token types created **SHOULD** emit a NewPBMTypeCreated event.

```solidity
    /// @notice Creates a new PBM Token type with the provided data.
    /// @dev The caller of createPBMTokenType shall be responsible for setting the creator address. 
    /// Example of uri can be found in [`sample-uri`](../assets/eip-pbmrc1/sample-uri/stx-10-static)
    /// Must emit {NewPBMTypeCreated}
    /// @param _name Name of the token.
    /// @param _faceValue Value of the underlying wrapped ERC20-compatible Spot Token.
    /// @param _tokenExpiry Time after which the token will be rendered useless (expressed in Unix Epoch time).
    /// @param _tokenURI Metadata URI for ERC-1155 display purposes
    function createPBMTokenType(
        string memory _name,
        uint256 _faceValue,
        uint256 _tokenExpiry,
        string memory _tokenURI
    ) external returns (uint256 tokenId_);

```

Implementors of the standard **MUST** define a method to retrieve a PBM token detail

```solidity
    /// @notice Retrieves the details of a PBM Token type given its tokenId.
    /// @dev This function fetches the PBMToken struct associated with the tokenId and returns it.
    /// @param tokenId The identifier of the PBM token type.
    /// @return A PBMToken struct containing all the details of the specified PBM token type.
    function getTokenDetails(uint256 tokenId) external view returns(PBMToken memory);
```

### PBM Address List

A targeted address list for PBM unwrapping must be specified. This list can be supplied either 
through the initialization function as part of a composite contract that contains various business logic elements, 
or it can be coded directly as a state variable within a PBM smart contract

<!-- TBD Copy from assets/eip-pbmrc1/contracts/IPBM_AddressList.sol  -->

```solidity


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
        @param _operator  The address which initiated the transfer (either the address which previously owned the token or the address authorised to make transfers on the owner's behalf) (i.e. msg.sender)
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

        @param _operator  The address which initiated the transfer (either the address which previously owned the token or the address authorised to make transfers on the owner's behalf) (i.e. msg.sender)
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

1. To keep it simple, this standard *intentionally* omits functions or events that doesn't add to definition and concept of a PBM.

2. This EIP makes no assumptions about access control or the conditions under which a function can be executed. It is the responsibility of the PBM creator to determine the various roles involved in each specific PBM business flow.

3. Metadata associated to the PBM standard is not included the standard. If necessary, related metadata can be created with a separate metadata extension interface, e.g. `ERC721Metadata` from [EIP-721](./eip-721.md). Refer to Opensea's metadata-standards for an implementation example.

4. To allow for future extensibility, it is **RECOMMENDED** that developers read and adopt the specifications for building general extensibility for method behaviours ([ERC-5750](./eip-5750.md)).

## Backwards Compatibility

This interface is designed to be compatible with [ERC-1155](./eip-1155.md).

## Reference Implementation

Reference implementations can be found in [`README.md`](../assets/eip-pbmrc1/README.md).

## Security Considerations

- Everything used in a smart contract is publicly visible, even local variables and state variables marked `private`.

- Due to gas limit, loops that do not have a fixed number of iterations have to be used cautiously.

- Never use tx.origin to check for authorization. `msg.sender` should be used to check for authorization.

- If library code is used as part of a `delegatecall`, make sure library code is stateless to prevent malicious actors from changing state in your contract via `delegatecall`.

- Malicious actors may try to front run transactions. As transactions take some time before they are mined, an attacker can watch the transaction pool and send a transaction, have it included in a block before the original transaction. This mechanism can be abused to re-order transactions to the attacker's advantage. A commitment scheme can be used to prevent front running.

- Don't use block.timestamp for a source of entropy and random number.

- Signing messages off-chain and having a contract that requires that signature before executing a function is a useful technique. However, the same signature can be exploited by malicious actors to execute a function multiple times. This can be harmful if the signer's intention was to approve a transaction once. To prevent signature replay, messages should be signed with nonce and address of the contract.

- Malicious users may attempt to:
  - Double spend through reentrancy.
  - clone existing PBM Tokens to perform double-spending;
  - create invalid PBM Token with no underlying Spot Token; or
  - falsifying the face value of PBM token through wrapping of fraudulent/invalid/worthless Spot Tokens.

- For consistency, when the contract is suspended or a user's token transfer is restricted due to suspected fraudulent activity or erroneous transfers, corresponding restrictions **MUST** be applied to the user's unwrap requests for the PBM Token.

- Security audits and tests should be performed to verify that unwrap logic behaves as expected or if any complex business logic is being implemented that involves calling an external smart contract to prevent re-entrancy attacks and other forms of call chain attacks.

- This EIP relies on the secure and accurate bookkeeping behavior of the token implementation.
  - Contracts adhering to this standard should closely monitor balance changes for each user during token consumption or minting.

  - The PBM Wrapper must be meticulously designed to ensure effective control over the permission to mint new tokens. Failure to secure the minting permission can lead to fraudulent issuance and unauthorized inflation of the total token supply.

  - The mapping of each PBM Token to the corresponding amount of underlying spot token held by the smart contract requires careful accounting and auditing.

  - The access control over permission to burn tokens should be carefully designed. Typically, only the following two roles are entitled to burn a token:

    - Role 1. Prior to a PBM expiry, only whitelisted merchants/redeemers with non-blacklisted wallet addresses are allowed to unwrap and burn tokens that they holds.
    - Role 2. After a PBM has expired:
      - whitelisted merchants/redeemers with non-blacklisted wallet addresses are allowed to unwrap and burn tokens that they hold; and
      - PBM owners are allowed to burn unused PBM Tokens remaining in the hands of non-whitelisted merchants/redeemers to retrieve underlying Spot Tokens.

  - Nevertheless, we do recognize there are potentially other use cases where a third type of role may be entitled to burning. Implementors should be cautious when designing access control over burning of PBM Tokens.

- It is recommended to adopt a token standard that is compatible with ERC-20. Examples of such compatible tokens includes tokens implementing ERC-777 or ERC-1363. However, ERC-20 remains the most widely accepted because of its simplicity and there is a high degree of confidence in its security.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
