---
eip: 
title: ERC-721 Time Extension
description: Add start time and end time to ERC-721 tokens.
author: Anders (@0xanders), Lance (@LanceSnow), Shrug <shrug@emojidao.org>
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2022-04-13
requires: 165, 721
---

## Abstract

This standard is an extension of [ERC-721](./eip-721.md). It proposes some additional property( `startTime`, `endTime`,`originalTokenId`) to help with the on-chain time management.

## Motivation

Some NFTs have a defined usage period and cannot be used when they are not at a specific time. If you want to make NFT invalid when it is not in use period, or make NFT enabled at a specific time, while the NFT does not contain time information, you often need to actively submit the chain transaction, this process is both cumbersome and a waste of gas.

There are also some NFTs contain time functions, but the naming is different, third-party platforms are difficult to develop based on it.

By introducing (`startTime`, `endTime`) and unifying the naming, it is possible to enable and disable NFT automatically on chain.

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
interface ITimeNFT  {

    /// @notice Emitted when the `startTime` or `endTime` of a NFT is changed 
    /// @param tokenId  The tokenId of the NFT
    /// @param startTime  The new start time of the NFT
    /// @param endTime  The new end time of the NFT
    event TimeUpdate(uint256 tokenId,uint64 startTime,uint64 endTime);

    /// @notice Get the start time of the NFT 
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The start time of the NFT
    function startTime(uint256 tokenId) external view returns (uint64);
    
    /// @notice Get the end time of the NFT  
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The end time of the NFT
    function endTime(uint256 tokenId) external view returns (uint64);

    /// @notice Get the token id which this NFT mint from
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The token id which this NFT mint from
    function originalTokenId(uint256 tokenId) external view returns (uint256);

    /// @notice Check the NFT is valid now 
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The the NFT is valid now
    /// if(startTime <= now <= endTime) {return true;} else {return false;} 
    function isValidNow(uint256 tokenId) external view returns (bool);

    /// @notice Mint a new token from an old token  
    /// @dev Throws if `tokenId` is not valid token 
    /// @param originalTokenId_  The token id which the new token mint from
    /// @param newTokenStartTime  The start time of the new token
    /// @param newTokenOwner  The owner of the new token
    /// @return newTokenId The the token id of the new token
    function split(uint256 originalTokenId_, uint64 newTokenStartTime, address newTokenOwner) external returns(uint256);

    /// @notice Merge two time NFTs into one time NFT  
    /// @dev Throws if `firstTokenId` or `secondTokenId` is not valid token 
    /// @param firstTokenId   The id of the first token
    /// @param secondTokenId  The id of the second token
    /// @param newTokenOwner  The owner of the new token
    /// @return newTokenId The id of the new token
    function merge(uint256 firstTokenId,uint256 secondTokenId, address newTokenOwner) external returns(uint256);
}
```

## Rationale

todo 

## Backwards Compatibility

As mentioned in the specifications section, this standard can be fully ERC721 compatible by adding an extension function set.


## Test Cases
### Test Contract
```solidity
pragma solidity 0.8.10;
import "./TimeNFT.sol";

contract TimeNFTDemo is TimeNFT{

    constructor(string memory name_, string memory symbol_)TimeNFT(name_, symbol_){        
    }

    /// @notice mint a new original time NFT  
    /// @param to_  The owner of the new token
    /// @param startTime_  The start time of the new token
    /// @param endTime_  The end time of the new token
    /// @return newTokenId The id of the new token
    function mint(address to_, uint64 startTime_, uint64 endTime_) internal virtual returns(uint256 newTokenId) {
       newTokenId = _mintOriginalToken(to_, startTime_, endTime_);
    }    
}
```

### Test Code
 

## Reference Implementation
```solidity
pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ITimeNFT.sol";

contract TimeNFT is ERC721, ITimeNFT  {

    struct TimeNftInfo {
        uint256 originalTokenId;
        uint64 startTime; 
        uint64 endTime; 
    }

    uint256 private _nextTokenId = 1;

    mapping(uint256 /* tokenId */ => TimeNftInfo) internal _timeNftMapping;


    constructor(string memory name_, string memory symbol_)ERC721(name_, symbol_){        
    }

    /// @notice Get the start time of the token 
    /// @dev Throws if `tokenId` is not valid token 
    /// @param tokenId  The tokenId of the token
    /// @return The start time of the token
    function startTime(uint256 tokenId) public view virtual override returns (uint64) {
        require(_exists(tokenId),"invalid tokenId");
        return _timeNftMapping[tokenId].startTime;
    }
    
    /// @notice Get the end time of the token  
    /// @dev Throws if `tokenId` is not valid token 
    /// @param tokenId  The tokenId of the token
    /// @return The end time of the token
    function endTime(uint256 tokenId) public view virtual override returns (uint64) {
        require(_exists(tokenId),"invalid tokenId");
        return _timeNftMapping[tokenId].endTime;
    }

    /// @notice Get the token id which this token mint from
    /// @dev Throws if `tokenId` is not valid token 
    /// @param tokenId  The tokenId of the token
    /// @return The token id which this token mint from
    function originalTokenId(uint256 tokenId) public view virtual override  returns (uint256) {
        require(_exists(tokenId),"invalid tokenId");
        return _timeNftMapping[tokenId].originalTokenId;
    }

    /// @notice Check the NFT is valid now 
    /// @dev Throws if `tokenId` is not valid token 
    /// @param tokenId  The tokenId of the token
    /// @return The the NFT is valid now
    /// if(startTime <= now <= endTime) {return true;} else {return false;} 
    function isValidNow(uint256 tokenId) public view virtual override returns (bool) {
        require(_exists(tokenId),"invalid tokenId");
        return uint256(_timeNftMapping[tokenId].startTime) <= block.timestamp  
               && block.timestamp <= uint256(_timeNftMapping[tokenId].endTime);
    }

    /// @notice Mint a new token from an old token  
    /// @dev Throws if `tokenId` is not valid token 
    /// @param originalTokenId_  The token id which the new token mint from
    /// @param newTokenStartTime  The start time of the new token
    /// @param newTokenOwner  The owner of the new token
    /// @return newTokenId The the token id of the new token
    function split(uint256 originalTokenId_, uint64 newTokenStartTime, address newTokenOwner) public virtual override returns(uint256 newTokenId){
        require(_isApprovedOrOwner(_msgSender(), originalTokenId_), "error: caller is not owner nor approved");

        uint64 oldTokenStartTime =  _timeNftMapping[originalTokenId_].startTime;
        uint64 oldTokenEndTime = _timeNftMapping[originalTokenId_].endTime;
        require( oldTokenStartTime < newTokenStartTime  && newTokenStartTime < oldTokenEndTime, "invalid newTokenStartTime");
        
        _timeNftMapping[originalTokenId_].endTime = newTokenStartTime - 1;          
        uint64 newTokenEndTime = oldTokenEndTime;
        emit TimeUpdate(originalTokenId_, oldTokenStartTime ,_timeNftMapping[originalTokenId_].endTime);

        newTokenId = _mintTimeNft(newTokenOwner, originalTokenId_, newTokenStartTime, newTokenEndTime);
    }

    /// @notice Merge two time NFTs into one time NFT  
    /// @dev Throws if `firstTokenId` or `secondTokenId` is not valid token 
    /// @param firstTokenId   The id of the first token
    /// @param secondTokenId  The id of the second token
    /// @param newTokenOwner  The owner of the new token
    /// @return newTokenId The id of the new token
    function merge(uint256 firstTokenId,uint256 secondTokenId, address newTokenOwner) public virtual override returns(uint256 newTokenId) {
        require(_isApprovedOrOwner(_msgSender(), firstTokenId) &&  _isApprovedOrOwner(_msgSender(), secondTokenId),
          "error: caller is not owner nor approved");

        TimeNftInfo memory firstToken = _timeNftMapping[firstTokenId];
        TimeNftInfo memory secondToken = _timeNftMapping[secondTokenId];

        require(firstToken.originalTokenId == secondToken.originalTokenId 
                && firstToken.startTime <= firstToken.endTime 
                && (firstToken.endTime + 1) == secondToken.startTime 
                && secondToken.startTime <= secondToken.endTime, "invalid tokenId");

        _burn(firstTokenId);
        _burn(secondTokenId);

        newTokenId = _mintTimeNft(newTokenOwner, firstToken.originalTokenId, firstToken.startTime, secondToken.endTime);
    }

    /// @notice mint a new time NFT  
    /// @param to_  The owner of the new token
    /// @param originalTokenId_    The token id which the new token mint from
    /// @param startTime_  The start time of the new token
    /// @param endTime_  The end time of the new token
    /// @return newTokenId The id of the new token
    function _mintTimeNft(address to_, uint256 originalTokenId_, uint64 startTime_, uint64 endTime_) internal virtual returns(uint256 newTokenId)  {
        newTokenId = _nextTokenId;
        _nextTokenId++;

        TimeNftInfo storage info = _timeNftMapping[newTokenId];
        info.originalTokenId = originalTokenId_;
        info.startTime = startTime_;
        info.endTime = endTime_;

        _mint(to_, newTokenId);
    }

    /// @notice mint a new original time NFT  
    /// @param to_  The owner of the new token
    /// @param startTime_  The start time of the new token
    /// @param endTime_  The end time of the new token
    /// @return newTokenId The id of the new token
    function _mintOriginalToken(address to_, uint64 startTime_, uint64 endTime_) internal virtual returns(uint256 newTokenId) {
        newTokenId = _nextTokenId;
        _nextTokenId++;
    
        TimeNftInfo storage info = _timeNftMapping[newTokenId];
        info.originalTokenId = newTokenId;
        info.startTime = startTime_;
        info.endTime = endTime_;

        _mint(to_, newTokenId );
    }

    /// @notice burn a time NFT  
    /// @param tokenId  The id of the token
    function _burn(uint256 tokenId) internal  virtual override{
        super._burn(tokenId);
        delete _timeNftMapping[tokenId];
    }
}

```

## Security Considerations

todo

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

