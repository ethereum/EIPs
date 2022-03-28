---
eip: <to be assigned>
title: NFT with wallet
description: An ERC721-compatible single-token NFT
author: Victor Munoz (@victormunoz)
discussions-to: https://ethereum-magicians.org/t/erc721-minting-only-one-token/8602/2
status: Draft
type: Standards Track
category: ERC
created: 2022-03-25
requires (*optional): 721
---

## Abstract
NFT associated uniquely with a single contract address.

## Motivation
If the ERC721 was modified to mint only 1 token (per contract), then the contract address could be identified uniquely with that minted token (instead of the tuple contract address + token id, as ERC721 requires).
This change would enable automatically all the capabilities of composable tokens ERC-998 (own other ERC721 or ERC20) natively without adding any extra code, just forbidding to mint more than one token per deployed contract.
Then the NFT minted with this contract could operate with his "budget" (the ERC20 he owned) and also trade with the other NFTs he could own. Just like an autonomous agent, that could decide what to do with his properties (sell his NFTs, buy other NFTs, etc).

The first use case that is devised is for value preservation. Digital assets, as NFTs, have value that has to be preserved in order to not be lost. If the asset has its own budget (in other ERC20 coins), could use it to autopreserve itself.

## Specification
The constructor should mint the unique token of the contract, and then the mint function should add a restriction to avoid further minting.

Also, a `tokenTransfer` function should be added in order to allow the contract owner to transact with the ERC20 tokens owned by the contract/NFT itself.

## Rationale
The main motivation is to keep the contract compatible with current ERC721 platforms. That's why we maintain all the functions of the ERC721 standard even if they cannot be used (eg. mint) instead of just removing them.

## Backwards Compatibility
No backwards compatibility issues devised.

## Reference Implementation
Add the variable `_minted` in the contract:

    bool private _minted;

In the constructor, automint the first token and set the variable to true:

    constructor(string memory name, string memory symbol, string memory base_uri) ERC721(name, symbol) {
        baseUri = base_uri;
        mint(msg.sender,0);
        _minted = true;
    }

Add additional functions to interact with the NFT properties (for instance, ERC20):

    modifier onlyOwner() {
        require(balanceOf(msg.sender) > 0, "Caller is not the owner of the NFT");
        _;
    }

    function transferTokens(IERC20 token, address recipient, uint256 amount) public onlyOwner {
        token.transfer(recipient, amount);
    }


## Security Considerations
No security issues found.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
