// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Distributor interface dictates how the holder of any ERC721 compliant tokens (parent token) 
 * can create editions that collectors can conditionally mint child tokens from. Parent token holder can 
 * use the setEdition to specify the condition for minting an edition of the parent token. An edition is 
 * defined by the contractAddress and tokenId to the parent token, the address of the validator contract that specifies
 *  the rules to obtain the child token, the actions that is allowed after obtaining the token.
 *   
 * A Collector can mint a child token of an Edition given that the rules specified by the Validator are 
 * fulfilled.
 *
 * Parent tokens holder can set multiple different editions, each with different set of rules, and a 
 * different set of actions that the token holder will be empowered with after the minting of the token.
 */
interface IDistributor {

    /**
     * @dev Emitted when a nedition is created
     * 
     * @param editionHash The hash of the edition configuration
     * @param tokenContract The token contract of the NFT descriptor
     * @param tokenId The token id of the NFT descriptor
     * @param validator The address of the validator contract
     * @param actions The functions in the descriptor contract that will be permitted.
     */
    event SetEdition(bytes32 editionHash, address tokenContract, uint256 tokenId, address validator, uint96 actions);
    
    /**
     * @dev Emitted when an edition is paused
     * 
     * @param editionHash The hash of the edition configuration
     * @param isPaused The state of the edition
     */
    event PauseEdition(bytes32 editionHash, bool isPaused);

    /**
     * @dev The parent token holder can set an edition that enables others
     * to mint child tokens given that they fulfil the given rules
     *
     * @param tokenContract the token contract of the Parent token
     * @param tokenId the token id of the Parent token
     * @param validator the address of the validator contract
     * @param actions the functions in the descriptor contract that will be permitted.
     * @param initData the data to be input into the validator contract for seting up the rules, 
     * it can also be used to encode more parameters for the edition
     * 
     * @return editionHash Returns the hash of the edition conifiguration 
     */
    function setEdition(
        address tokenContract,
        uint256 tokenId,
        address validator,
        uint96  actions,
        bytes calldata initData
    ) external returns (bytes32 editionHash);
    
    /**
     * @dev The parent token holder can pause the edition
     *
     * @param editionHash the hash of the edition
     * @param isPaused the state of the edition
     */ 
    function pauseEdition(
        bytes32 editionHash,
        bool isPaused
    ) external;

}