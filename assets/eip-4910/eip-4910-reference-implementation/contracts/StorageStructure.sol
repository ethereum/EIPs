// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.10;

contract StorageStructure {
    struct RoyaltyAccount {
        //assetId is the tokenId of the NFT the RA belongs to
        uint256 assetId;
        //parentId is the tokenId of the NFT from which this NFT is derived
        uint256 parentId;
        //royaltySplit to be paid to RA from its direct offspring
        uint256 royaltySplitForItsChildren;
        //tokenType of the balance in this RA account
        string tokenType;
        //Account balance is the total RA account balance and must be equal to the sum of the subaccount balances
        uint256 balance;
        //the struct array for sub accounts (Not supported in eth)
        //RASubAccount[] rasubaccount;
    }

    struct RASubAccount {
        //accounttype is defined as isIndividual, and is a boolean variable, and if set to true, the account is that of an individual, if set to false, the account is an RA account ID
        bool isIndividual;
        // royalty split gives the percentage as a decimal value smaller than 1
        uint256 royaltySplit;
        //balance of the subaccount
        uint256 royaltyBalance;
        //we need the account id which we define as a bytes32 such that it is easy to convert to an address and can also be used to identity an RA acount by a hash value
        address accountId;
    }

    struct Child {
        //link to parent token
        uint256 parentId;
        //maximum number of children
        uint256 maxChildren;
        //ancestry level of NFT used to determine level of children
        uint256 ancestryLevel; //new in v1.3
        //link to children tokens
        uint256[] children;
    }

    struct NFTToken {
        //the parent of the (child) token, if 0 then there is no parent
        uint256 parent;
        //whether the token can be a parent
        bool canBeParent;
        //how many children the token can have
        uint256 maxChildren;
        //what the Royalty Split For Its Child is
        uint256 royaltySplitForItsChildren;
        //token URI
        string uri;
    }

    struct RegisteredPayment {
        //Buyer
        address buyer;
        //tokens bought
        uint256[] boughtTokens;
        //Type of Payment Token
        string tokenType;
        //Payment amount
        uint256 payment;
    }

    struct ListedNFT {
        //Seller
        address seller;
        //tokens listed
        uint256[] listedtokens;
        //Type of Payment Token
        string tokenType;
        //List price
        uint256 price;
    }

    function _isSameString(string memory left, string memory right) internal pure returns (bool) {
        return keccak256(abi.encodePacked(left)) == keccak256(abi.encodePacked(right));
    }
}
