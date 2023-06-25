// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import { StrSlice, toSlice } from "@dk1a/solidity-stringutils/src/StrSlice.sol";
import "./interfaces/IERCXXXX.sol";
import "./ERC6066.sol";

contract ERCXXXX is ERC6066, IERCXXXX {

    using { toSlice } for string;
    mapping (uint256 => bytes32) _idMultiIdentitiesRootBinding;
    constructor(string memory _name, string memory _symbol) ERC6066(_name, _symbol) {}

    /**
     * @notice 
     * @dev set the user ID binding information of NFT with multiIdentitiesRoot
     * @param id nft id 
     * @param multiIdentitiesRoot multi UserID Root data hash
     */
    function setIdentitiesRoot(
        uint256 id,
        bytes32 multiIdentitiesRoot
    ) external {
        
        sign(id, multiIdentitiesRoot);
        _idMultiIdentitiesRootBinding[id] = multiIdentitiesRoot;

        emit SetIdentitiesRoot(id,multiIdentitiesRoot);
    }
    
    /**
     * @notice 
     * @dev Update the user ID binding information of NFT
     * @param id nft id 
     */
    function getIdentitiesRoot(
        uint256 id
    ) external view returns(bytes32){

        return _idMultiIdentitiesRootBinding[id];
    }

    /**
     * @notice 
     * @dev verify the userIDs binding 
     * @param id nft id 
     * @param multiIdentitiesRoot msg hash to veriry
     * @param userIDs userIDs for check
     * @param signature ECDSA signature 
     */
    function verifyIdentitiesBinding(
        uint256 id,address nftOwnerAddress,string[] memory userIDs,bytes32 multiIdentitiesRoot, bytes calldata signature
    ) external view returns (bool){

        //nft owner check
        require(ownerOf(id) == nftOwnerAddress,"nft owner is not correct");

        //user id length check
        uint256 userIDLen = userIDs.length;
        require(userIDLen > 0,"userID cannot be empty");


        for(uint i = 0 ;i < userIDLen ;i ++){
            _verifyUserID(userIDs[i]);
        }

        // bool isVerified = false;
        bytes4 sigResult = isValidSignature(id,multiIdentitiesRoot,signature);
        if(sigResult == BADVALUE){
            return false;
        }else{
            return true;
        }
    }

    function _verifyUserID(string memory userID) internal view{

        require(bytes(userID).length > 0,"userID can not be empty");

        //first part(encryption algorithm or did) check
        string memory strSplit = ":";
        bool found;
        StrSlice left;
        StrSlice right = userID.toSlice();
        (found, left, right) = right.splitOnce(strSplit.toSlice());
        require(found,"the first part delimiter does not exist");
        require(bytes(left.toString()).length > 0,"the first part does not exist");

        //second part(Organization Information) check
        (found, left, right) = right.splitOnce(strSplit.toSlice());
        require(found,"the second part delimiter does not exist");
        require(bytes(left.toString()).length > 0,"the second part does not exist");

        //id hash check
        require(bytes(right.toString()).length == 64,"id hash length is not correct");

    }

}

