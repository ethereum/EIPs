// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

interface IERC7231 {

    /**
     * @notice emit the use binding informain
     * @param id nft id 
     * @param identitiesRoot new identity root
     */
    event SetIdentitiesRoot(
        uint256 id,
        bytes32 identitiesRoot
    );

    /**
     * @notice 
     * @dev set the user ID binding information of NFT with identitiesRoot
     * @param id nft id 
     * @param identitiesRoot multi UserID Root data hash
     * MUST allow external calls
     */
    function setIdentitiesRoot(
        uint256 id,
        bytes32 identitiesRoot
    ) external;

    /**
     * @notice 
     * @dev get the multi-userID root by  NFTID
     * @param id nft id 
     * MUST return the bytes32 multiUserIDsRoot
     * MUST NOT modify the state
     * MUST allow external calls
     */
    function getIdentitiesRoot(
        uint256 id
    ) external returns(bytes32);

    /**
     * @notice 
     * @dev verify the userIDs binding 
    * @param id nft id 
     * @param userIDs userIDs for check
     * @param identitiesRoot msg hash to veriry
     * @param signature ECDSA signature 
     * MUST If the verification is passed, return true, otherwise return false
     * MUST NOT modify the state
     * MUST allow external calls
     */
    function verifyIdentitiesBinding(
        uint256 id,address nftOwnerAddress,string[] memory userIDs,bytes32 identitiesRoot, bytes calldata signature
    ) external returns (bool);
    
}