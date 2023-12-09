---
eip: <to be assigned>
title: Recallable Token Standard for Real World Assets & Crowdfunding
description: A standard for tokenizing real-world assets with a recall function, enabling flexible ownership and investment opportunities.
author: Hojay Lee (@hojayxyz), Saud Iqbal (@SaudxInu), Mehul Gaidhani (@MehulG), Kalpita Mandal (@KalpitaMandal), Vikas Kashyap (@vikashyap)
discussions-to: https://ethereum-magicians.org/t/new-eip-recallable-token-standard-for-rwa-crowdfunding/17170
status: Draft
type: Standards Track
category: ERC
created: 2023-12-09
---

## Abstract

This EIP introduces a novel token standard for the Ethereum blockchain, designed to facilitate the tokenization of real-world assets (RWAs) with an innovative recall function. This standard enables asset owners to issue tokens representing a share of their real-world assets, such as real estate or art, while retaining the capability to recall these tokens at a later stage. This recall feature adds a layer of flexibility and control over the asset, allowing owners to manage their investments more dynamically. The standard is intended to enhance the Ethereum ecosystem by broadening the scope of asset tokenization, making it more adaptable and appealing for a wider range of use cases.

## Motivation

The primary motivation behind this EIP is to overcome the inherent limitations present in the current landscape of RWA tokenization. Presently, once an asset is tokenized and its tokens are distributed among investors, the original asset owner loses the ability to manage the asset as a unified entity. This situation poses significant challenges, especially when there's a need to sell or leverage the entire asset, rather than its fractionalized parts. 

Our proposed standard introduces a mechanism for recall, which allows asset owners to effectively retract the tokens they have issued, in exchange for a predefined recall price. This capability ensures that the original owners retain a higher degree of control over their assets, enabling them to respond to changing market conditions or personal circumstances. For investors, this mechanism provides a clear exit strategy, potentially with a predefined profit if the recall price is set above the initial selling price. By addressing these limitations, the new standard is poised to make RWA tokenization a more viable and attractive investment model, enhancing liquidity and flexibility in the market.

## Specification

### Token Creation

- The token contract MUST allow for the creation of tokens that represent a share of a real-world asset (RWA).
- The creator of the contract MUST be able to define the total supply of tokens, which represents the total share of the RWA.

### Token Recall Functionality

- The token contract MUST implement a `recallTokens` function that allows the original issuer to recall all outstanding tokens.
- Upon calling `recallTokens`, the contract MUST transfer the specified recall price from the issuer to all current token holders and burn the tokens.
- The recall price MAY be set at the time of token creation and MAY be modified by the original issuer under certain conditions specified in the contract.

### Recall Price

- The contract MUST allow the original issuer to set a `recallPrice` for the tokens, which can be higher, equal to, or lower than the initial token sale price.
- The `recallPrice` MUST be distributable among the current token holders proportionally to their token holdings at the time of recall.

### Token Transfer

- The token MUST be transferable between parties.
- Transfer of tokens MUST adhere to the standard ERC transfer rules to ensure compatibility with wallets and other contracts.

### Events

- The contract MUST emit a `Recall` event logging the details when tokens are recalled.
- The contract MUST emit `Transfer` events according to the ERC token standard when tokens are transferred.

### Interfaces

```solidity
interface IRecallableToken {
    function recallTokens() external returns (bool);
    function setRecallPrice(uint256 _recallPrice) external returns (bool);
    // Include other functions as per ERC standards and additional ones necessary for the RWA tokenization.
}
```

## Rationale

The primary rationale behind this EIP is to introduce a flexible and secure mechanism for real-world asset (RWA) tokenization, addressing the current inflexibility in asset management post-tokenization. The key aspects of this proposal include:

- **Recall Functionality**: This feature is at the heart of the proposal, allowing asset owners to recall tokens. This addresses a significant limitation in current RWA tokenization, where once an asset is tokenized and distributed among multiple owners, consolidating back the ownership is complex and often not feasible. The recall function provides a solution, offering flexibility in asset management and liquidity.

- **Recall Price Setting**: The ability for the asset owner to set and modify the recall price offers strategic flexibility. It ensures that investors can potentially receive a return on their investment, making the tokens more attractive and reducing investment risk.

- **Token Transferability**: Ensuring the standard supports the transferability of tokens is crucial for maintaining liquidity in the market. This aligns the proposed standard with the core principles of tokenization - democratizing asset ownership and investment.

- **Compliance with Existing Standards**: The EIP is designed to be compatible with existing Ethereum token standards, specifically ERC-20 and ERC-721, to leverage the established ecosystem of tools and wallets.

- **Security and Robustness**: Emphasis on security and robust execution of the recall function and other contract interactions is a key aspect of the rationale. It's crucial to ensure that the recall mechanism cannot be exploited and operates transparently and fairly.

## Backwards Compatibility

The proposed standard is designed to be backward compatible with existing Ethereum token standards, such as ERC-20 and ERC-721. It does not intend to modify any existing functionality but rather to extend it with additional features specific to RWA tokenization. 

- **ERC-20 Compatibility**: The token transfer, balance management, and other basic functionalities will follow the ERC-20 standard, ensuring that the new tokens can be integrated into current platforms and wallets supporting ERC-20.

- **ERC-721 Compatibility**: For unique or non-fungible real-world assets, the standard also aligns with ERC-721 to support non-fungible tokenization, ensuring integration with existing NFT platforms and wallets.

- **Smart Contract Interaction**: The proposal is designed to ensure that the new tokens will operate seamlessly with existing smart contracts that are compatible with standard ERC tokens, ensuring broad applicability and integration potential.

By maintaining compatibility with existing standards, the proposed EIP aims to foster quick adoption and integration within the existing Ethereum ecosystem, leveraging the established infrastructure and user base.

## Test Cases

- **Test for Token Creation**: Verify that tokens representing a real-world asset can be created and the total supply is set correctly.
- **Test for Token Distribution**: Ensure tokens can be distributed to multiple addresses correctly.
- **Test for Recall Functionality**: Validate that the recall function works as expected, correctly calculating and distributing recall price, and burning tokens post-recall.
- **Test for Recall Price Adjustment**: Check the functionality to adjust the recall price and its correct implementation in recall calculations.
- **Test for Token Transferability**: Confirm tokens can be transferred between addresses and adhere to ERC standards.
- **Edge Case Handling**: Include tests for handling situations like zero token holders during recall or insufficient balance for recall price coverage.

## Reference Implementation

A reference implementation in Solidity will be provided, demonstrating the recallable token standard. This implementation includes:

- Smart Contract Code: Implementing the proposed standard with functions for token creation, transfer, recall, and recall price setting.
- Unit Tests: Covering all functionalities and edge cases to ensure contract reliability.
- Deployment Scripts: For deploying and testing the contract on Ethereum test networks.

## Security Considerations

Security is a primary concern for the recallable token standard. Considerations include:

- **Recall Function Security**: Protect against reentrancy attacks and ensure fair and transparent fund distribution.
- **Smart Contract Audits**: Conduct comprehensive audits to identify and address potential vulnerabilities.
- **Access Control**: Robust mechanisms to restrict critical function execution to authorized users.
- **Gas Limitations and DoS Risks**: Mitigate denial of service risks, particularly in scenarios where the recall function might run out of gas.
- **Integration Security**: Ensure secure integration with external systems and services.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
