---
eip: <to be assigned>
title: Fractional nft with Royalty Distribution system
author: Yongjun Kim (@PowerStream3604)
discussions-to: https://github.com/ethereum/EIPs/issues/3601
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
By sending ether to the address of the ERC-20 Contract Address(owner of NFT) it will distribute the amount of ether per holders and keep it inside the chain.
Whenever the owner of the contract calls the function for withdrawing their proportion of royalty, they will receive the exact amount of compensation according to their amount 
of share at that very moment of being compensated.

## Motivation
It is evident that many industries need cryptographically verifiable method to represent shared ownership.
ERC-721 Non-Fungible Token standards are ubiquitously used to represent ownership of assets from digital assets such as Digital artworks, Game items(characters), Virtual real estate
to real-world assets such as Real estate, Artworks, Cars, etc.
As more assets are registered as ERC-721 Non-Fungible Token demands for fractional ownership will rise.

Fractional ownership does not only mean that we own a portion of assets.
But It also means that we need to obtain financial compensation whenever the asset is making profit through any kinds of financial activities.
For instance, token holders of NFT representing World Trade Center should receive monthly rent from tenants.
Token holders of NFT representing "Everydays-The First 5000 days" should receive advertisement charge, exhibition fees whenever their artwork is being used for financial activities.
It is crucial for smart-contract(verifable system) to implement this distribution system to prevent any kinds of fraud regarding royalty compensation. Following the fair royalty distribution system which works on top of completely verifable environment(blockchain) will the flourish the NFT market by giving back compensation to investors.

To make this possible this proposal implements a rule-of-reason logic to distribute income fairly to the holders.
In order to make this royalty-distribution-system work with little changes from the standard and comply with distribution logic, several math operations and mappings are additionally used.
By implementing this standard, wallets will be able to determine if a erc20 token is representing NFT and that means
everywhere that supports the ERC-20 and this proposal(standard) will support fractional NFT tokens.

## Specification

**Smart Contracts Implementing this Standard MUST implement all of the functions in BELOW**
  
**Smart contracts implementing the FNFT standard MUST implement the ERC-165 `supportsInterface()`
     and MUST return the constant value `true` if `0xdb453760` is passed through the `interfaceID` argument**
```solidity
pragma solidity >=0.7.0 <0.9.0;

/*  
  @title Fractional-NFT with Royalty distribution system
  Note: The ERC-165 identifier for this interface is 0xdb453760;
*/
interface FNFT /* is ERC20, ERC165 */{
  
  /**
    @dev 'RoyaltySent' MUST emit when royalty is given.
    The '_sender' argument MUST be the address of the account sending(giving) royalty to token owners.
    The '_value' argument MUST be the value(amount) of ether '_sender' is sending to the token owners.
  **/
  event RoyaltySent(address indexed _sender, uint256 _value);

  /**
    @dev 'RoyaltyWithdrawn' MUST emit when royalties are withdrawn.
    The '_withdrawer' argument MUST be the address of the account withdrawing royalty of his portion.
    The '_value' argument MUST be the value(amount) of ether '_withdrawer' is withdrawing.
  **/
  event RoyaltyWithdrawn(address indexed _withdrawer, uint256 _value);  

  /**
    This function is to get the NFT Token information this FNFT token is pointing to.
    The '_nftToken' return value should return contract address this FNFT is pointing to (representing).
    The '_nftTokenId' return value should return token Id of NFT token this FNFT is pointing to (representing)
  **/
  function targetNFT() external view returns(address _nftToken, uint256 _nftTokenId);
                                
  /**
    This function is for sending royalty to token owners.
  **/
  function sendRoyalty() external payable;
                                
  /**
    This function is for withdrawing the amount of royalty received.
    Only called by the owner of tokens.
    Or addresses that used to own this token.
  **/
  function withdrawRoyalty() external;
}
 
```
                                
**(1) Third parties need to distinguish Fractional-NFT from other token standards.**
  
ERC-165 Standard Interface Detection `supportsInterface()` needs to be included to determine whether this contract supports this standard.
In this proposal, we use `targetNFT()` to retrieve the contract address of NFT and the token ID of NFT, `sendRoyalty()` to send royalty to token holders, `withdrawRoyalty()` to withdraw royalty they received with `sendRoyalty()`.

```solidity
  /* Smart contracts implementing the FNFT standard MUST implement the ERC-165 "supportsInterface()" 
     and MUST return the constant value 'true' if '0xdb453760' is passed through the interfaceID argument.*/
  function supportsInterface(bytes4 interfaceID) external view returns(bool) {
   return
      interfaceID == this.supportsInterface.selector || //ERC165
      interfaceID == this.targetNFT.selector || // targetNFT()
      interfaceID == this.sendRoyalty.selector || // sendRoyalty()
      interfaceID == this.withdrawRoyalty.selector || // withdrawRoyalty()
      interfaceID == this.targetNFT.selector ^ this.sendRoyalty.selector ^ this.withdrawRoyalty.selector;// FNFT
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

off-chain scenario:
                                
using ethers.js in javascript:
```javascript
async function checkFNFT(ethers) {                              
  const FNFTABI = [...]; // abi for FNFT
  const FNFTAddress = '0x9874563210123456789asdfdsa'; // address for the deployed FNFT contract
  const ERC721ABI = [...]; // abi for ERC-721 NFT
  const provider = ethers.getDefaultProvider(); // connection to mainnet
                                
  const FNFTContract = new ethers.Contract(FNFTAddress, FNFTABI, provider); // instance of  deployed FNFT contract
  const [ERC721Address, ERC721TokenId] = await FNFTContract.targetNFT(); // retrieve the address of the NFT
  
  const ERC721Contract = new ethers.Contract(ERC721ABI, ERC721Address, provider); // deployed NFT contract according to FNFT return data
  const isERC721 = await ERC721Contract.supportsInterface('0x80ac58cd'); // check if it is ERC-721
  const NFTownerOf = await ERC721Contract.ownerOf(ERC721TokenId); // retrieve the owner of NFT Token
  return NFTownerOf.toLowerCase() === FNFTAddress.toLowerCase(); // check if the owner of NFT is the FNFT Contract
 
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
  
  return NFTownerOf.toLowerCase() === FNFTAddress.toLowerCase(); // check if the owner of NFT is the FNFT Contract
}                                
```

**Royalty-Distribution-Logic :**
Although it is easy to abstractly say what to do in certain function, implementing rule-of-reason logic of distributing royalty needs much consideration.
There are some **KEY PRINCIPLES** that we have to comply with when designing this logic.

**(1)** Royalty must be distributed by the ratio of my current stake(share) on totalsupply.

**(2)** Royalty must be distributed by the ratio of royalty sent at the time compensated(given).

*For instance, A owned 80% and B owned 20% of totalsupply in 2020 which is when 100ether was given as Royalty.
But, in 2021 B owns 80% and A owns 20% of totalsupply. Both of them didn't withdraw their royalty until now and no royalty was given in 2021. When A withdraws his royalty now which A should receive 80ethers since he owned 80% of totalsupply at the very moment of royalty given. When B withdraws his royalty he receives 20ethers since he owned 20% of totalsupply at the very moment the royalty was given. Only the ratio of my stake at the moment royalty is given needs to be the only factor that matters because  the timing
of withdrawal totally depends on the owner's decision.*

**(3)** Cannot withdraw Royalty you already did.
## Rationale
The design of royalty receiver withdrawing their royalty was considered due to gas efficiency. If any of functions in this contract send ether to all of the holders whenever or regularly royalty is received, huge amount of gas consumption is inevitable.
In order to handle those issues, this standard(proposal) makes the withdrawer to do most of the calculation for his own withdrawal and 
the sender to do the least as impossible.
                           
## Backwards Compatibility
This contract is compatible with the existing EIPs since it doesn't modify the existing specifications but just adds 3 functions to provide  Royalty distribution systems.
Depending on the implementaion, data type, logic and additional validations and manipulations might be needed.
However, complying with the existing standards won't be an issue but additional gas might be needed for calling `functions`
in this standard.

## Reference Implementation
This is an implementation of some smart of FNFT contract.
It is an extension of ERC-20 Token Contract.
                                
```solidity
pragma solidity ^0.8.0;

contract FNFT /*is ERC20, ERC165*/ {
    mapping (address => uint256) userIndex;
    mapping (address => bool) ownerHistory;
    uint totalsupply = 0;
    //uint[] balances;
    
    struct Info {
        uint256 balances;
        uint256 royaltyIndex;
    }
    Info[] userInfo;
    
    struct RoyaltyInfo {
        Info[] userInfo;
        uint256 royalty;
    }
    RoyaltyInfo[] royaltyInfo;
    uint256 royaltyCounter = 0;
    
    /**
    @dev 'RoyaltySent' MUST emit when royalty is given.
    The '_sender' argument MUST be the address of the account sending(giving) royalty to token owners.
    The '_value' argument MUST be the value(amount) of ether '_sender' is sending to the token owners.
    **/
    event RoyaltySent(address indexed _sender, uint256 _value);
    
    /**
    @dev 'RoyaltyWithdrawal' MUST emit when royalties are withdrawn.
    The '_withdrawer' argument MUST be the address of the account withdrawing royalty of his portion.
    The '_value' argument MUST be the value(amount) of ether '_withdrawer' is withdrawing.
    **/
    event RoyaltyWithdrawal(address indexed _withdrawer, uint256 _value); 

    function supportsInterface(bytes4 interfaceID) external view returns(bool) {
    return
      interfaceID == this.supportsInterface.selector || //ERC165
      interfaceID == this.targetNFT.selector || // targetNFT()
      interfaceID == this.sendRoyalty.selector || // sendRoyalty()
      interfaceID == this.withdrawRoyalty.selector || // withdrawRoyalty()
      interfaceID == this.targetNFT.selector ^ this.sendRoyalty.selector ^ this.withdrawRoyalty.selector;// FNFT
    }
    /* OpenZeppelin */
     function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        //require(recipient != address(0), "ERC20: transfer to the zero address");
        //_beforeTokenTransfer(sender, recipient, amount);
        //uint256 senderBalance = _balances[sender];
        //require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        //unchecked {
        //    _balances[sender] = senderBalance - amount;
        //}
        //_balances[recipient] += amount;
        
        /* FNFT logic, below this added  */
        if(ownerHistory[recipient] != true) {
            ownerHistory[recipient] == true;
            userIndex[recipient] = userInfo.length;
            userInfo.push(Info(amount, royaltyCounter));
        }
        /* FNFT */
        
        //emit Transfer(sender, recipient, amount);
    }
    
    /**
     * Functions such as balanceOf should return balance according to 
     * the different logic(structure) of contract unlike 
     * the conventional balances[tokenOwner]
     **/
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return userInfo[userIndex[tokenOwner]].balances;
    }
    
    function targetNFT() public returns(address _nftContract, uint _tokenId) {
        return (_nftContract, _tokenId);
    }
    
    function sendRoyalty() public payable returns(bool){
        royaltyInfo[royaltyCounter++] = RoyaltyInfo({userInfo: userInfo, royalty: msg.value});
        // Emit RoyaltySent Event
        emit RoyaltySent(msg.sender, msg.value);
        return true;
    }
    
    function withdrawRoyalty () public payable {
        if(!ownerHistory[msg.sender] || userInfo[userIndex[msg.sender]].royaltyIndex == royaltyCounter) return;/* maybe throwing Error logic is needed */
        uint royaltySum = 0; // temporary holder of royalty sum
        for(uint i = userInfo[userIndex[msg.sender]].royaltyIndex; i < royaltyCounter; i++) {
            /* Should consider using safe math library to divide and multiply safely. 
             * Overflow and underflow should be prevented.                                                                         
             */
            royaltySum += (royaltyInfo[i].userInfo[userIndex[msg.sender]].balances * royaltyInfo[i].royalty) / totalsupply;
        }
        userInfo[userIndex[msg.sender]].royaltyIndex = royaltyCounter;
        msg.sender.transfer(royaltySum);
        emit RoyltyWithdrawn(msg.sender, royaltySum);
    }    
}
```
## Security Considerations
There might be many flaws that might exist when implementing this standard since math operations and complex logic is underlying 
the royalty distribution logic.
**Major Security Risks To Consider**

**(1)** Math operation in `withdrawRoyalty()`
* Using external library that has been verified is recommended
* Prevent underflow, overflow
* Round off, Round up issues when dividing and multiplying

**(2)** Variables that holds the state of royalty should not be modified outside the contract
* Only functions and operations should be able to change their state in the right situation.

### Usage
Although this standard is intended for NFTs. This can also be used for distributing royalty or compensation to ERC-20 token holders.
This standard is also applicable to be used solely for distributing compensation to ERC-20 token holders without any correlations with ERC-721(NFT);
### Compatibility with EIP-2981
When complying with this standard I recommend people to ensure compatibility with EIP-2981 
by adding `royaltyInfo()` and returning the information needed to compensation the creator of the asset whenever the asset is sold and resold.       
                                                                               
## References
* [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
* [ERC-721 Non-Fungible Token Standard](https://eips.ethereum.org/EIPS/eip-721)
* [ERC-1633 Re-Fungible Token Standard(RFT)](https://eips.ethereum.org/EIPS/eip-1633)
* [OpenZeppelin ERC-20](https://docs.openzeppelin.com/contracts/2.x/api/token/erc20)

## Copyright
Please cite this document as:

[Kim yongjun](mailto:helloyongjun3604@gmail.com) "EIP-<to-be-considered>: NFT Royalty Distribution Standard" June 2021
