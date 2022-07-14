---
eip: 2981
title: NFT Royalty Standard
author: Zach Burks (@vexycats), James Morgan (@jamesmorgan), Blaine Malone (@blmalone), James Seibel (@seibelj)
discussions-to: https://github.com/ethereum/EIPs/issues/2907
status: Final
type: Standards Track
category: ERC
created: 2020-09-15
requires: 165
---

## Simple Summary

A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal support for royalty payments across all NFT marketplaces and ecosystem participants.

## Abstract

This standard allows contracts, such as NFTs that support [ERC-721](./eip-721.md) and [ERC-1155](./eip-1155.md) interfaces, to signal a royalty amount to be paid to the NFT creator or rights holder every time the NFT is sold or re-sold. This is intended for NFT marketplaces that want to support the ongoing funding of artists and other NFT creators. The royalty payment must be voluntary, as transfer mechanisms such as `transferFrom()` include NFT transfers between wallets, and executing them does not always imply a sale occurred. Marketplaces and individuals implement this standard by retrieving the royalty payment information with `royaltyInfo()`, which specifies how much to pay to which address for a given sale price. The exact mechanism for paying and notifying the recipient will be defined in future EIPs. This ERC should be considered a minimal, gas-efficient building block for further innovation in NFT royalty payments.

## Motivation
There are many marketplaces for NFTs with multiple unique royalty payment implementations that are not easily compatible or usable by other marketplaces. Just like the early days of ERC-20 tokens, NFT marketplace smart contracts are varied by ecosystem and not standardized. This EIP enables all marketplaces to retrieve royalty payment information for a given NFT. This enables accurate royalty payments regardless of which marketplace the NFT is sold or re-sold at.

Many of the largest NFT marketplaces have implemented bespoke royalty payment solutions that are incompatible with other marketplaces. This standard implements standardized royalty information retrieval that can be accepted across any type of NFT marketplace. This minimalist proposal only provides a mechanism to fetch the royalty amount and recipient. The actual funds transfer is something which the marketplace should execute.

This standard allows NFTs that support [ERC-721](./eip-721.md) and [ERC-1155](./eip-1155.md) interfaces, to have a standardized way of signalling royalty information. More specifically, these contracts can now calculate a royalty amount to provide to the rightful recipient.

Royalty amounts are always a percentage of the sale price. If a marketplace chooses *not* to implement this EIP, then no funds will be paid for secondary sales. It is believed that the NFT marketplace ecosystem will voluntarily implement this royalty payment standard; in a bid to provide ongoing funding for artists/creators. NFT buyers will assess the royalty payment as a factor when making NFT purchasing decisions.

Without an agreed royalty payment standard, the NFT ecosystem will lack an effective means to collect royalties across all marketplaces and artists and other creators will not receive ongoing funding. This will hamper the growth and adoption of NFTs and demotivate NFT creators from minting new and innovative tokens.

Enabling all NFT marketplaces to unify on a single royalty payment standard will benefit the entire NFT ecosystem.

While this standard focuses on NFTs and compatibility with the ERC-721 and ERC-1155 standards, EIP-2981 does not require compatibility with ERC-721 and ERC-1155 standards. Any other contract could integrate with EIP-2981 to return royalty payment information. ERC-2981 is, therefore, a universal royalty standard for many asset types.

At a glance, here's an example conversation summarizing NFT royalty payments today:

>**Artist**: "Do you support royalty payments on your platform?"          
>**Marketplace**: "Yes we have royalty payments, but if your NFT is sold on another marketplace then we cannot enforce this payment."              
>**Artist**: "What about other marketplaces that support royalties, don't you share my royalty information to make this work?"              
>**Marketplace**: "No, we do not share royalty information."

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

**ERC-721 and ERC-1155 compliant contracts MAY implement this ERC for royalties to provide a standard method of specifying royalty payment information.**

Marketplaces that support this standard **SHOULD** implement some method of transferring royalties to the royalty recipient. Standards for the actual transfer and notification of funds will be specified in future EIPs.

Marketplaces **MUST** pay the royalty in the same unit of exchange as that of the `_salePrice` passed to `royaltyInfo()`. This is equivalent to saying that the `_salePrice` parameter and the `royaltyAmount` return value **MUST** be denominated in the same monetary unit. For example, if the sale price is in ETH, then the royalty payment must also be paid in ETH, and if the sale price is in USDC, then the royalty payment must also be paid in USDC.

Implementers of this standard **MUST** calculate a percentage of the `_salePrice` when calculating the royalty amount. Subsequent invocations of `royaltyInfo()` **MAY** return a different `royaltyAmount`. Though there are some important considerations for implementers if they choose to perform different percentage calculations between `royaltyInfo()` invocations.

The `royaltyInfo()` function is not aware of the unit of exchange for the sale and royalty payment. With that in mind, implementers **MUST NOT** return a fixed/constant `royaltyAmount`, wherein they're ignoring the `_salePrice`. For the same reason, implementers **MUST NOT** determine the `royaltyAmount` based on comparing the `_salePrice` with constant numbers. In both cases, the `royaltyInfo()` function makes assumptions on the unit of exchange, which **MUST** be avoided.

The percentage value used must be independent of the sale price for reasons previously mentioned (i.e. if the percentage value 10%, then 10% **MUST** apply whether `_salePrice` is 10, 10000 or 1234567890). If the royalty fee calculation results in a remainder, implementers **MAY** round up or round down to the nearest integer. For example, if the royalty fee is 10% and `_salePrice` is 999, the implementer can return either 99 or 100 for `royaltyAmount`, both are valid.

The implementer **MAY** choose to change the percentage value based on other predictable variables that do not make assumptions about the unit of exchange. For example, the percentage value may drop linearly over time. An approach like this **SHOULD NOT** be based on variables that are unpredictable like `block.timestamp`, but instead on other more predictable state changes. One more reasonable approach **MAY** use the number of transfers of an NFT to decide which percentage value is used to calculate the `royaltyAmount`. The idea being that the percentage value could decrease after each transfer of the NFT. Another example could be using a different percentage value for each unique `_tokenId`.

Marketplaces that support this standard **SHOULD NOT** send a zero-value transaction if the `royaltyAmount` returned is `0`. This would waste gas and serves no useful purpose in this EIP.

Marketplaces that support this standard **MUST** pay royalties no matter where the sale occurred or in what currency, including on-chain sales, over-the-counter (OTC) sales and off-chain sales such as at auction houses. As royalty payments are voluntary, entities that respect this EIP must pay no matter where the sale occurred - a sale conducted outside of the blockchain is still a sale. The exact mechanism for paying and notifying the recipient will be defined in future EIPs.

Implementers of this standard **MUST** have all of the following functions:

```solidity
pragma solidity ^0.6.0;
import "./IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```

### Examples

This standard being used on an ERC-721 during deployment:

#### Deploying an ERC-721 and signaling support for ERC-2981

```solidity
constructor (string memory name, string memory symbol, string memory baseURI) {
        _name = name;
        _symbol = symbol;
        _setBaseURI(baseURI);
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
        // Royalties interface
        _registerInterface(_INTERFACE_ID_ERC2981);
    }
```

#### Checking if the NFT being sold on your marketplace implemented royalties

```solidity  
bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

function checkRoyalties(address _contract) internal returns (bool) {
    (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
    return success;
 }
```

## Rationale

### Optional royalty payments

It is impossible to know which NFT transfers are the result of sales, and which are merely wallets moving or consolidating their NFTs. Therefore, we cannot force every transfer function, such as `transferFrom()` in ERC-721, to involve a royalty payment as not every transfer is a sale that would require such payment. We believe the NFT marketplace ecosystem will voluntarily implement this royalty payment standard to provide ongoing funding for artists/creators. NFT buyers will assess the royalty payment as a factor when making NFT purchasing decisions.

### Simple royalty payments to a single address

This EIP does not specify the manner of payment to the royalty recipient. Furthermore, it is impossible to fully know and efficiently implement all possible types of royalty payments logic. With that said, it is on the royalty payment receiver to implement all additional complexity and logic for fee splitting, multiple receivers, taxes, accounting, etc. in their own receiving contract or off-chain processes. Attempting to do this as part of this standard, it would dramatically increase the implementation complexity, increase gas costs, and could not possibly cover every potential use-case. This ERC should be considered a minimal, gas-efficient building block for further innovation in NFT royalty payments. Future EIPs can specify more details regarding payment transfer and notification.

### Royalty payment percentage calculation

This EIP mandates a percentage-based royalty fee model. It is likely that the most common case of percentage calculation will be where the `royaltyAmount` is always calculated from the `_salePrice` using a fixed percent i.e. if the royalty fee is 10%, then a 10% royalty fee must apply whether `_salePrice` is 10, 10000 or 1234567890.

As previously mentioned, implementers can get creative with this percentage-based calculation but there are some important caveats to consider. Mainly, ensuring that the `royaltyInfo()` function is not aware of the unit of exchange and that unpredictable variables are avoided in the percentage calculation. To follow up on the earlier `block.timestamp` example, there is some nuance which can be highlighted if the following events ensued:

1. Marketplace sells NFT.
2. Marketplace delays `X` days before invoking `royaltyInfo()` and sending payment.
3. Marketplace receives `Y` for `royaltyAmount` which was significantly different from the `royaltyAmount` amount that would've been calculated `X` days prior if no delay had occurred.
4. Royalty recipient is dissatisfied with the delay from the marketplace and for this reason, they raise a dispute.

Rather than returning a percentage and letting the marketplace calculate the royalty amount based on the sale price, a `royaltyAmount` value is returned so there is no dispute with a marketplace over how much is owed for a given sale price. The royalty fee payer must pay the `royaltyAmount` that `royaltyInfo()` stipulates.

### Unit-less royalty payment across all marketplaces, both on-chain and off-chain

This EIP does not specify a currency or token used for sales and royalty payments. The same percentage-based royalty fee must be paid regardless of what currency, or token was used in the sale, paid in the same currency or token. This applies to sales in any location including on-chain sales, over-the-counter (OTC) sales, and off-chain sales using fiat currency such as at auction houses. As royalty payments are voluntary, entities that respect this EIP must pay no matter where the sale occurred - a sale outside of the blockchain is still a sale. The exact mechanism for paying and notifying the recipient will be defined in future EIPs.

### Universal Royalty Payments

Although designed specifically with NFTs in mind, this standard does not require that a contract implementing EIP-2981 is compatible with either ERC-721 or ERC-1155 standards. Any other contract could use this interface to return royalty payment information, provided that it is able to uniquely identify assets within the constraints of the interface. ERC-2981 is, therefore, a universal royalty standard for many other asset types.

## Backwards Compatibility

This standard is compatible with current ERC-721 and ERC-1155 standards.

## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
