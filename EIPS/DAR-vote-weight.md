

## Preamble

    EIP: <to be assigned>
    Title: NFT Extension for DAO Voting Weight
    Author: Alex Sherbuck <Alex@igave.io>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2018-02-06
    Requires EIP 821


##  Summary
The ERC-721 NFT `balanceOf` returns the count of assets owned by an address. ERC-821 moved this functionality into `assetCount` and maintains `balanceOf` as an alias to `assetCount`. This change proposes `balanceOf` return an abstract weight representing the NFTs value in the system.

## Abstract
A DAO shareholder association relies on the ERC-20 `balanceOf` to obtain the number of votes controlled by an address. Replacing an ERC-20 address with an ERC-721/821 permits the DAO to use the NFT `balanceOf` as votes. The nature of NFTs is that their values are distinct from one another. This change allows for a unique weight to represent this distinction for each NFT.

## Motivation
The ERC-20 `balanceOf` works well for DAO voting. A fungible tokens value corresponds 1:1 with its asset count. The NFT `balanceOf` should represent the tokens value.

E.g. Each Cryptokitty has a generation. Each plot of LAND has an auction price. An NFT is like a receipt for that value. 'Weight' is the abstraction of that property.

Voting based on asset weight permits DAOs to form around NFC voting or a combination of ERC-20 and NFC voting. Instead of associations of token holders this permits associations of LAND holders, for instance.

## Specification

An ERC-721 example exists but the recent ERC-821 DAR is better suited for this extension. The ERC-721 example is included at the end, the ERC-821 rework is taking place. This spec will be updated to reflect the completion of that work.

## Rationale
Changing `balanceOf` to a weight requires no changes to the current DAOs relying on ERC-20's `balanceOf` function. DAOs may reference an individual ERC-721 contract or array of shareHolder addresses, mixing both ERC-20 and ERC-721.

Changing balanceOf of the ERC-721 is favorable to creating a comparable voteWeight function as that would complicate the DAO executeProposal code - it would require duplicate existing ERC-20 logic due to function naming.

## Backwards Compatibility
While `balanceOf` requires no changes to its function signature. Apps and contracts that previously relied on some combination of `totalSupply` and `balanceOf` will have breaking issues as this will represent a different ratio.

## Implementation

This is being re-worked into the ERC-821 Digital Asset Registry. For now an example lives as part of an ERC-721 contract

[ERC-721 Example](https://github.com/tenthirtyone/zeppelin-solidity/tree/voting-weight)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
