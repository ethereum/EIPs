## Preamble

    EIP: 884
    Title: Regulation A+ Token
    Author: "Dave Sag <davesag@gmail.com>"
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2018-02-14
    Requires: ["ERC20"]

# Regulation A+ Token

Ref: http://forum.ethereum.org/discussion/17200/proposing-an-eip-for-regulation-a-tokens

## Simple Summary

An `ERC20` compatible Token that conforms to [Delaware State Senate, 149th General Assembly, Senate Bill No. 69: An act to Amend Title 8 of the Delaware Code Relating to the General Corporation Law.](https://legis.delaware.gov/json/BillDetail/GenerateHtmlDocument?legislationId=25730&legislationTypeId=1&docTypeId=2&legislationName=SB69), 'The Act', aka ['Regulation A+'](https://en.wikipedia.org/wiki/Regulation_A#Regulation_A+).

## Abstract

The recently amended Title 8 of the Delaware Code Relating to the General Corporation Law now explicitly allows for the use of blockchains to maintain corporate stock ledgers.  This means it is now possible to create a tradable `ERC20` token where each token represents a share issued by a Delaware corporation.  Such a token must conform to the following principles over and above the `ERC20` standard.

1. Token owners must have their identity verified.
2. The Token contract must provide the following 3 functions of a `Corporations Stock ledger` (Ref: Section 224):

    1. Reporting:

        It must enable the corporation to prepare the list of stockholders specified in Sections 219 and 220

    2. It must record the information specified in Sections 156, 159, 217(a) and 218:

        - Partly paid shares
        - Total amount paid
        - Total amount to be paid

    3. Transfers of stock as per section 159:

        It must record transfers of stock as governed by Article 8 of subtitle I of Title 6.

3. Each Token will correspond to a single share, each of which would be paid for in full, so there is no need to record information concerning partly paid shares, and there are no partial Tokens.

## Motivation

By using a Regulation A+ compatible token, a firm may be able to raise funds via IPO, conforming to Deleware Corporations Law, but bypassing the need for integration with a major stock exchange.

The are currently no Token standards that conform to the `Regulation A+` rules.  `ERC20` tokens do not support KYC/AML rules required by the General Corporation Law, and do not provide facilities for the exporting of lists of stock owners. While the `ERC721` Token proposal allows for some association of metadata with an Ethereum address, its uses are not completely aligned with the `Regulation A+` rules.

## Specification

The `ERC20` Token provides the following basic features:

    interface ERC20 {
      function totalSupply() public view returns (uint256);
      function balanceOf(address who) public view returns (uint256);
      function transfer(address to, uint256 value) public returns (bool);
      function allowance(address owner, address spender) public view returns (uint256);
      function transferFrom(address from, address to, uint256 value) public returns (bool);
      function approve(address spender, uint256 value) public returns (bool);
      event Approval(address indexed owner, address indexed spender, uint256 value);
      event Transfer(address indexed from, address indexed to, uint256 value);
    }

This will be extended as follows:

    /**
     *  An `ERC20` compatible Token that conforms to Delaware State Senate,
     *  149th General Assembly, Senate Bill No. 69: An act to Amend Title 8
     *  of the Delaware Code Relating to the General Corporation Law.
     *
     *  Implementation Details.
     *  An implementation of this token standard SHOULD provide the following:
     *
     *  `name` - for use by wallets and exchanges.
     *  `symbol` - for use by wallets and exchanges.
     *
     *  In addition to the above the following optional ERC20 function MUST be defined.
     *
     *  `decimals` — MUST return 0 as each token represents a single share and shares are non-divisible.
     */
    interface ERC884 is ERC20 {

      /**
       *  By counting the number of token owners using `totalSupply`
       *  one can retrieve the complete list of token owners, one at a time.
       *  @param index The index of the owner. Must be > 1. Index 0 MUST return `address(0)`.
       *  @return the address of the Token owner with the given index.
       *  @throw if the supplied index is > totalSupply()
       */
      function ownerAt(uint256 index) public view returns (address);

      /**
       *  Add a verified address, along with an associated verification hash to the contract.
       *  Upon successful addition of a verified address the contract must emit
       *  `VerifiedAddressAdded(addr, hash, msg.sender)`.
       *  @param addr The address of the person represented by the supplied hash.
       *  @param hash A cryptographic hash of the address owner's verified information.
       *  @throw if the supplied address or hash are zero, or if the address has already been supplied.
       */
      function addVerified(address addr, bytes32 hash) public;

      /**
       *  Remove a verified address, and the associated verification hash. If the address is
       *  unknown to the contract then this does nothing. If the address is successfully removed this
       *  function must emit `VerifiedAddressRemoved(addr, msg.sender)`.
       *  @param addr The verified address to be removed.
       */
      function removeVerified(address addr) public;

      /**
       *  Update the hash for a verified address known to the contract.
       *  Upon successful update of a verified address the contract must emit
       *  `VerifiedAddressUpdated(addr, hash, msg.sender)`.
       *  @param addr The verified address of the person represented by the supplied hash.
       *  @param hash A cryptographic hash of the address owner's verified information.
       *  @throw if the supplied address or hash are zero, or if the address is unknown to the contract.
       */
      function updateVerified(address addr, bytes32 hash) public;

      /**
       *  Tests that the supplied address is known to the contract.
       *  @param addr The address to test.
       *  @return true if the address is known to the contract.
       */
      function isVerified(address addr) public view returns (bool);

      /**
       *  Returns the `Identity` hash that is associated with the given address.
       *  @param addr The address to test.
       *  @return the hash that was supplied with the address in `addVerified`.
       *  @throw if the address is unknown to the contract.
       */
      function hashFor(address addr) public view returns (bytes32);

      /**
       *  The `transfer` function must not allow transfers to addresses that
       *  have not been verified and added to the contract.
       */
      function transfer(address to, uint256 value) public returns (bool);

      /**
       *  The `transferFrom` function must not allow transfers to addresses that
       *  have not been verified and added to the contract.
       */
      function transferFrom(address from, address to, uint256 value) public returns (bool);

      /**
       *  This event is emitted when a verified address and associated identity hash are
       *  added to the contract.
       *  @param addr The address that was added.
       *  @param hash The identity hash associated with the address.
       *  @param sender The address that caused the address to be added.
       */
      event VerifiedAddressAdded(
          address indexed addr,
          bytes32 hash,
          address indexed sender
      );

      /**
       *  This event is emitted when a verified address its associated identity hash are
       *  removed to the contract.
       *  @param addr The address that was removed.
       *  @param sender The address that caused the address to be removed.
       */
      event VerifiedAddressRemoved(address indexed addr, address indexed sender)`.

      /**
       *  This event is emitted when the identity hash associated with a verified address is updated.
       *  @param addr The address whose has was updated.
       *  @param oldHash The identity hash that was associated with the address.
       *  @param hash The identity hash now associated with the address.
       *  @param sender The address that caused the hash to be updated.
       */
      event VerifiedAddressUpdated(
          address indexed addr,
          bytes32 oldHash,
          bytes32 hash,
          address indexed sender
      );
    }

### Other SEC Requirements

The SEC has additional requirements as to how a Crowdsale ought to be run, and what information must be made available to the general public. This information is however out of scope from this standard, though the standard does support the requirements.

For example the SEC requires a Crowdsale's website display the amount of money raised in USD.  To support this a crowdsale contract minting these tokens must maintain a USD to ETH conversion rate (via Oracle or some other mechanism) and must record the conversion rate used at time of minting.

### Use of the Identity `hash` value.

Implementers of a crowdsale, or order to comply with The Act, must be able to produce an up-to-date list of the names and addresses of all stockholders. However it is not desirable to include those details in a public blockchain, both for reasons of privacy, and also for reasons of economy.  Storing arbitrary string data on the blockchain is strongly discouraged.

Instead the implementers must maintain an off-chain private database that records the owner's name, residential address, and Ethereum address.  The implementer must then be able to extract the name and address for any address, and hash the name + address data and compare that hash to the hash recorded in the contract.  The specific details of this system are left to the implementer.

It is also desirable that the implementers offer a REST API endpoint along the lines of

    GET https://<host>/<pathPrefix>/:ethereumAddress -> [true|false]

That enables 3rd party auditors to verify that a given Ethereum address is known to the implementers as a verified address.

How the implementers verify a person's identity is up to them and beyond the scope of this standard.

### Permissions management

It is not desirable that anyone can add, remove, or update verified addresses, however the specifics of how access to those functions is controlled is outside of the scope of this standard.

## Rationale

The proposed standard offers as minimal as possible extension over the existing ERC20 standard in order to conform to the requirements of The Act. However, rather than return a boolean for successful or unsuccessful completion of state changing functions such as `addVerified`, `removeVerified`, and `updateVerified`, we have opted to require that implementations `throw` (preferably by using the [forthcoming `require(condition, 'fail message')` syntax](https://github.com/ethereum/solidity/issues/1686#issuecomment-328181514).)

## Backwards Compatibility

The proposed standard is designed to maintain compatibility with ERC20 tokens with the following provisos.

1. The `decimals` function MUST return `0` as the Tokens MUST NOT be divisible,
2. The `transfer` and `transferFrom` functions MUST NOT allow transfers to non-verified addresses.

Proviso 1 will not break compatibility with modern wallets or exchanges as they all appear to use that information if available.

Proviso 2 will cause transfers to fail if an attempt is made to transfer tokens to a non-verified address. This is implicit in the design and implementers are encouraged to make this abundantly clear to market participants. We appreciate that this will make the standard unpalatable to some exchanges, but it is an SEC requirement that stockholders of a corporation provide verified names and addresses.

## Test Cases

Test cases and a reference implementations will be provided separately.

## Implementation

A reference implementation will be provided separately.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
