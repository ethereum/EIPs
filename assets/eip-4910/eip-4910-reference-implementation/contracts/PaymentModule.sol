// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import './StorageStructure.sol';
import 'abdk-libraries-solidity/ABDKMathQuad.sol';

contract PaymentModule is StorageStructure, Ownable {
    mapping(uint256 => RegisteredPayment) private registeredPayment; //A mapping with a struct for a registered payment
    mapping(uint256 => ListedNFT) private listedNFT; //A mapping for listing NFTs to be sold
    mapping(uint256 => bool) private tokenLock; // lock listed token for sure one time list

    uint256[] private listedNFTList; // List of all listed NFT

    uint256 private _maxListingNumber; //Max token count int listing

    constructor(address owner, uint256 maxListingNumber) {
        transferOwnership(owner);
        require(maxListingNumber > 0, 'Max number must be > 0');
        _maxListingNumber = maxListingNumber;
    }

    function updatelistinglimit(uint256 maxListingNumber) public onlyOwner returns (bool) {
        require(maxListingNumber > 0, 'Max number must be > 0');
        _maxListingNumber = maxListingNumber;
        return true;
    }

    function addListNFT(
        address seller,
        uint256[] calldata tokenIds,
        uint256 price,
        string calldata tokenType
    ) public virtual onlyOwner {
        require(price > 0, 'Zero Price not allowed');
        require(!existsInListNFT(tokenIds), 'Already exists');
        require(tokenIds.length <= _maxListingNumber, 'Too many NFTs listed');
        listedNFT[tokenIds[0]] = ListedNFT({seller: seller, listedtokens: tokenIds, tokenType: tokenType, price: price});
        //lock tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenLock[tokenIds[i]] = true;
        }
        //add to list index
        listedNFTList.push(tokenIds[0]);
    }

    function existsInListNFT(uint256[] memory tokenIds) public view virtual returns (bool) {
        if (listedNFT[tokenIds[0]].seller != address(0)) return true;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenLock[tokenIds[i]]) return true;
        }
        return false;
    }

    function removeListNFT(uint256 tokenId) public virtual onlyOwner {
        require(registeredPayment[tokenId].buyer == address(0), 'RegisterPayment exists for NFT');
        //unlock token
        for (uint256 i = 0; i < listedNFT[tokenId].listedtokens.length; i++) {
            tokenLock[listedNFT[tokenId].listedtokens[i]] = false;
        }
        //delete from index
        for (uint256 i = 0; i < listedNFTList.length; i++) {
            if (listedNFTList[i] == tokenId) {
                listedNFTList[i] = listedNFTList[listedNFTList.length - 1];
                listedNFTList.pop();
                break;
            }
        }

        delete listedNFT[tokenId];
    }

    function getListNFT(uint256 tokenId) public view returns (ListedNFT memory) {
        require(listedNFT[tokenId].seller != address(0), 'Listing not exist');
        return listedNFT[tokenId];
    }

    function getAllListNFT() public view returns (uint256[] memory) {
        return listedNFTList;
    }

    function isValidPaymentMetadata(
        address seller,
        uint256[] calldata tokenIds,
        uint256 payment,
        string calldata tokenType
    ) public view virtual returns (bool) {
        //check if NFT(s) are even listed
        require(listedNFT[tokenIds[0]].seller != address(0), 'NFT(s) not listed');
        //check if seller is really a seller
        require(listedNFT[tokenIds[0]].seller == seller, 'Submitted Seller is not Seller');
        //check if payment is sufficient
        require(listedNFT[tokenIds[0]].price <= payment, 'Payment is too low');
        //check if token type supported
        require(_isSameString(listedNFT[tokenIds[0]].tokenType, tokenType), 'Payment token does not match list token type');
        //check if listed NFT(s) match NFT(s) in the payment and are controlled by seller
        uint256[] memory listedTokens = listedNFT[tokenIds[0]].listedtokens;
        for (uint256 i = 0; i < listedTokens.length; i++) {
            require(tokenIds[i] == listedTokens[i], 'One or more tokens are not listed');
        }
        return true;
    }

    function addRegisterPayment(
        address buyer,
        uint256[] calldata tokenIds,
        uint256 payment,
        string calldata tokenType
    ) public virtual onlyOwner {
        require(registeredPayment[tokenIds[0]].buyer == address(0), 'RegisterPayment already exists');
        registeredPayment[tokenIds[0]] = RegisteredPayment({buyer: buyer, boughtTokens: tokenIds, tokenType: tokenType, payment: payment});
    }

    function getRegisterPayment(uint256 tokenId) public view virtual returns (RegisteredPayment memory) {
        return registeredPayment[tokenId];
    }

    function checkRegisterPayment(uint256 tokenId, address buyer) public view virtual returns (uint256) {
        if (registeredPayment[tokenId].buyer == buyer) return registeredPayment[tokenId].payment;
        else return 0;
    }

    function checkRegisterPayment(
        uint256 tokenId,
        address buyer,
        string memory tokenType
    ) public view virtual returns (uint256) {
        if (registeredPayment[tokenId].buyer == buyer) {
            require(_isSameString(tokenType, registeredPayment[tokenId].tokenType), 'TokenType mismatch');
            return registeredPayment[tokenId].payment;
        } else return 0;
    }

    function removeRegisterPayment(address buyer, uint256 tokenId) public virtual onlyOwner {
        require(registeredPayment[tokenId].buyer == buyer, 'RegisterPayment not found');
        delete registeredPayment[tokenId];
    }
}
