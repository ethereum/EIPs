---
title: ERC-6680: NFT Flashloans
description: Minimal interface for ERC-721 NFT flashloans
author: out.eth (@outdoteth)
status: Draft
type: Standards Track
category: ERC
created: 2023-03-12
requires: EIP-3156
---

## Abstract

This standard is an extension of the existing flashloan standard ([EIP-3156](./eip-3156.md)) to support ERC-721 NFT flashloans. It proposes a way for flashloan providers to lend NFTs to contracts, with the condition that the loan is repaid in the same transaction along with some fee.

## Motivation

The current flashloan standard, [EIP-3156](./eip-3156.md), only supports ERC-20 tokens. ERC-721 tokens are sufficiently different from ERC-20 tokens that they require an extension of this existing standard to support them. 

In most cases, the handling of fee payments will be desired to be paid in a seperate currency to the loaned NFTs because NFTs themselves cannot always be fractionalized. Consider the following example where the flashloan provider charges a 0.1 ETH fee on each NFT that is flashloaned; The interface must provide methods that allow the borrower to determine the fee rate on each NFT and also the currency that the fee should be paid in.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Contract Interface

```solidity
pragma solidity ^0.8.19;

interface IERC6680 {
    /// @dev The address of the token used to pay flash loan fees.
    function flashFeeToken() external view returns (address);

    /// @dev Whether or not the NFT is available for a flash loan.
    /// @param token The address of the NFT contract.
    /// @param tokenId The ID of the NFT.
    function availableForFlashLoan(address token, uint256 tokenId) external view returns (bool);
}
```

The `flashFeeToken` function MUST return the address of the token used to pay flash loan fees.

If the token used to pay the flash loan fees is ETH then `flashFeeToken` MUST return `address(0)`.

The `availableForFlashLoan` function MUST return whether or not the `tokenId` of `token` is available for a flashloan. If the `tokenId` is not currently available for a flashloan `availableForFlashLoan` MUST return `false` instead of reverting.

## Rationale

The above modifications are the simplest possible additions to the existing flashloan standard to support NFTs.

We choose to extend as much of the existing flashloan standard (EIP-3156) as possible instead of creating a wholly new standard because the flashloan standard is already widely adopted and the changes required to support NFTs are minimal.

## Backwards Compatibility

This EIP is fully backwards compatible with [EIP-3156](./eip-3156.md) with the exception of the `maxFlashLoan` method. This method does not make sense within the context of NFTs because NFTs are not fungible. However it is part of the existing flashloan standard and so it is not possible to remove it without breaking backwards compatibility. It is RECOMMENDED that any contract implementing this EIP without the intention of supporting ERC20 flashloans should always return `0` from `maxFlashLoan`. For example:

```solidity
function maxFlashLoan(address token) public pure override returns (uint256) {
    // if a contract also supports flash loans for ERC20 tokens then it can
    // return some value here instead of 0
    return 0;
}
```

## Reference Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";
import "../interfaces/IERC6680.sol";

contract ExampleFlashLender is IERC6680, IERC3156FlashLender {
    uint256 internal _feePerNFT;
    address internal _flashFeeToken;

    constructor(uint256 feePerNFT_, address flashFeeToken_) {
        _feePerNFT = feePerNFT_;
        _flashFeeToken = flashFeeToken_;
    }

    function flashFeeToken() public view returns (address) {
        return _flashFeeToken;
    }

    function availableForFlashLoan(address token, uint256 tokenId) public view returns (bool) {
        // return if the NFT is owned by this contract
        try IERC721(token).ownerOf(tokenId) returns (address result) {
            return result == address(this);
        } catch {
            return false;
        }
    }

    function flashFee(address token, uint256 tokenId) public view returns (uint256) {
        return _feePerNFT;
    }

    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 tokenId, bytes calldata data)
        public
        returns (bool)
    {
        // check that the NFT is available for a flash loan
        require(availableForFlashLoan(token, tokenId), "IERC6680: NFT not available for flash loan");

        // transfer the NFT to the borrower
        IERC721(token).safeTransferFrom(address(this), address(receiver), tokenId);

        // calculate the fee
        uint256 fee = flashFee(token, tokenId);

        // call the borrower
        bool success =
            receiver.onFlashLoan(msg.sender, token, tokenId, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan");

        // check that the NFT was returned by the borrower
        require(IERC721(token).ownerOf(tokenId) == address(this), "IERC6680: NFT not returned by borrower");

        // transfer the fee from the borrower
        IERC20(flashFeeToken()).transferFrom(msg.sender, address(this), fee);

        return success;
    }

    function maxFlashLoan(address token) public pure override returns (uint256) {
        // if a contract also supports flash loans for ERC20 tokens then it can
        // return some value here instead of 0
        return 0;
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
```

## Security Considerations

It's possible that the `flashFeeToken` method could return a malicious contract. Borrowers who intend to call the address that is returned from the `flashFeeToken` method should take care to ensure that the contract is not malicious. One way they could do this is by verifying that the returned address from `flashFeeToken` matches that of a user input.

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
