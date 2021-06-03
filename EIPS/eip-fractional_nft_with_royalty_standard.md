---
eip: <to be assigned>
title: Fractional nft with Royalty Distribution system
author: Yongjun Kim (@PowerStream3604)
discussions-to: <URL>
status: Draft
type: Standards Track
category : ERC
created: 2021-06-01
requires : 20, 165, 721
---
  
## Simple Summary
A ERC-20 contract becoming the owner of a nft token.
Fractionalizing the ownership of NFT into multiple ERC-20 tokens by making the ERC-20 contract as the owner of NFT.
Distributing the royalty(income) to the shareholders who own the specific ERC-20 token.
  
## Abstract
The intention of this proposal is to extend the functionalities of ERC-20 to represent it as a share of nft and provide automated and trusted method to distribute royalty
to ERC-20 token holders.
Utilizing ERC-165 Standard Interface Detection, it detects if a ERC-20 token is representing the shared ownership of ERC-721 Non-Fungible Token.
ERC-165 implementation of this proposal makes it possible to verify from both contract and offchain level if it adheres to this proposal(standard).
This proposal makes small changes to existing ERC-20 Token Standard and ERC-721 Token Standard to support most of software working on top of this existing token standard.
By sending ether to the address of the ERC-20 Contract it will distribute the amount of ether per holders and keep it inside the chain.
Whenever the owner of the contract calls the function for withdrawing their proportion of royalty, they will receive the exact amount of compensation according to their amount 
of share at that very moment.

## Motivation
It is evident that many industries need cryptographically verifiable method to represent shared ownership.
ERC-721 Non-Fungible Token standards are ubiquitously used to represent ownership of assets from digital assets such as Digital artworks, Game items(characters), Virtual real estate
to real-world assets such as Real estate, artworks, cars, etc.
As more assets are registered as ERC-721 Non-Fungible Token demands for fractional ownership will rise.

Fractional ownership does not only mean that we own a portion of assets.
But It also means that we need to obtain financial compensation whenever the asset is making profit through any kinds of financial activities.
For instance, token holders of NFT representing World Trade Center should receive monthly rent from tenants.
Token holders of NFT representing "Everydays-The First 5000 days" should receive advertisement charge, exhibition fees whenever their artwork is being used for financial activities.
It is crucial for smart-contract(verifable system) to implement this distribution feature to prevent any kinds of fraud regarding royalty compensation. Following the fair royalty distribution system which works on top of completely verifable environment(blockchain) will the flourish the NFT market by giving back compensation to investors.

To make this possible this proposal implements a rule-of-reason logic to distribute income fairly to the holders.
In order to make this royalty-distribution-system work with little changes from the standard and comply with distribution logic, several math operations and mappings are additionally used.
By implementing this standard, wallets will be able to determine if a erc20 token is representing NFT and that means
everywhere that supports the ERC-20 and this proposal(standard) will support fractional NFT tokens.

## Specification
**(1) Third parties need to distinguish Fractional-NFT from other token standards.**
  
ERC-165 Standard Interface Detection `supportsInterface()` needs to be included to determine whether this contract supports this standard.
In this proposal, we use `targetNFT()` to retrieve the contract address of NFT and the token ID of NFT, `sendRoyalty()` to send royalty to token holders, `withdrawRoyalty()` to withdraw royalty they received with `sendRoyalty()`.
  
```solidity
pragma solidity >=0.7.0 <0.9.0;

/*  
  @title Fractional-NFT with Royalty distribution system
  Note: The ERC-165 identifier for this interface is 0xdb453760;
*/
interface FNFT /* is ERC20, ERC165 */{
  /* Smart contracts implementing the FNFT standard MUST implement the ERC-165 "supportsInterface()" 
     and MUST return the constant value 'true' if '0xdb453760' is passed through the interfaceID argument.*/
  function supportsInterface(bytes4 interfaceID) external view returns(bool) {
   return
      interfaceID == this.supportsInterface.selector || //ERC165
      interfaceID == this.targetNFT.selector || // targetNFT()
      interfaceID == this.sendRoyalty.selector || // sendRoyalty()
      interfaceID == this.withdrawRoyalty.selector ||
      interfaceID == this.targetNFT.selector ^ this.sendRoyalty.selector ^ this.withdrawRoyalty.selector;// FNFT
  }
  function targetNFT() external view returns(address _nftToken, uint256 _nftTokenId);
  function sendRoyalty() external;
  function withdrawRoyalty() external;
}
 
```
**(2) Third parties need to know the NFT contract address this FNFT is pointing to and the tokenID of the NFT.**
                                
This is the on-chain scenario:                                
```solidity
pragma solidity >=0.7.0 <0.9.0;

import './FNFT.sol';
import './ERC721.sol';

contract CheckFNFT {
  function checkFNFT(address _FNFT) external view returns(bool) {
     address _NFT;
     uint256 _tokenId;                           
     (NFT, tokenId) = FNFT(_FNFT).targetNFT(); // returns address of NFT contract
     
     return
       NFT(_NFT).supportsInterface(0x80ac58cd) &&// check if it is ERC-721
       NFT(_NFT).ownerOf(_tokenId) == _FNFT; // check if the owner of NFT is FNFT contract address
  }                              
}                                
```  

off-chain scenario using ethers.js in javascript:
```
async function checkFNFT(ethers) {                              
  const FNFTABI = [...]; // abi for FNFT
  const FNFTAddress = '0x9874563210123456789asdfdsa'; // address for the deployed FNFT contract
  const ERC721ABI = [...]; // abi for ERC-721 NFT
  const provider = ethers.getDefaultProvider(); // connection to mainnet
                                
  const FNFTContract = new ethers.Contract(FNFTAddress, FNFTABI, provider);
  
}                                
```                                
web3.js                                
```javascript
async function checkFNFT(web3) {
  const FNFTABI = [...]; // abi for FNFT
  const FNFTAddress = '0x0123456789abcdef0123456789abcdef'; // address for the deployed FNFT contract
  const ERC721ABI = [...]; // abi for ERC-721 NFT
  
  const FNFTContract = new web3.eth.Contract(FNFT, FNFTAddress); // instance of deployed FNFT contract
  const [ERC721Address, ERC721TokenId] = await FNFTContract.methods.targetNFT().call();// retrieve the address of the NFT Contract, and the Token ID
  
  const ERC721Contract = new web3.eth.Contract(ERC721ABI, ERC721Address); // deployed NFT contract according to FNFT return data
  const isERC721 = await ERC721Contract.methods.supportsInterface('0x80ac58cd').call(); // check if it is ERC-721
  const NFTownerOf = await ERC721Contract.methods.ownerOf(ERC721TokenId).call(); // retrieve the owner of NFT token
  
  return NFTownerOf.toLowerCase() === RFTAddress.toLowerCase(); // check if the owner of NFT is the FNFT Contract
}                                
```
