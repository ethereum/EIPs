## Preamble

    EIP: <to be assigned>
    Title: Weighted Distinguishable Asset Registry
    Author: Alex Sherbuck <Alex@igave.io>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2018-02-06
    Requires EIP 821


##  Summary
Not all NFTs are created equal. Nothing exists to distinguish one NFT from another. Weight allows a DAO or other external actors to recognize some value for unique asset holdings.

## Motivation
This allows DAOs to form based on asset/NFT holdings instead of just ERC-20 token holdings. Asset holders may decide how to set their token weight.

## Specification
The Weighted Digital Asset Registry is an extension for ERC-821 that tracks asset weight. This follows the standard set in [ERC821](https://github.com/ethereum/EIPs/issues/821) and adds:

## Weighted DAR
Extension to ERC-821

#### totalWeight
`function totalWeight() public view returns (uint256);`
Returns the total weight tracked by the DAR

#### isWeighted
`function isWeighted() public view returns (bool);`
This method returns true.

#### weightOfAsset
`function weightOfAsset(uint256 assetId) public view returns (uint64);`
Returns the total weight of an individual asset.

#### weightOfHolder
`function weightOfHolder(address holder) public view returns (uint256);`
Returns the total weight of the assets controlled by the holder.

#### changeWeight
`function changeWeight(uint256 assetId, uint64 weight) public;`
Changes the weight of the asset to the given value.

#### Events
```
event TransferWeight(
    address indexed from,
    address indexed to,
    uint256 indexed assetId,
    uint64 weight
  );
event ChangeWeight(
    uint256 indexed assetId,
    uint64 weight
  );
```

## DAR Adapter
An adapter that exposes a `balanceOf`.

#### voteWeightAddress
`function voteWeightAddress() public view returns (address);`
Returns the address of the Weighted DAR.

#### balanceOf
`function balanceOf(address holder) public view returns  (uint256);`
Calls the `weightOfHolder` function of the Weighted DAR.

## Implementation

[Weighted Digital Asset Registry](https://github.com/I-Gave/erc821/tree/weighted-registry/contracts) - w/ DAO voting

## Rationale
Including an adapter for the DAO to reference holder weight minimizes the impact on current DAO code that references an ERC-20's `balanceOf`

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
