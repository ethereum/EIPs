// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
*    @dev The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface ERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

/// The EIP-165 identifier of this interface is 0xf4cedd5a
interface IERC5679Ext1155 {
   function safeMint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
   function safeMintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
   function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata _data) external;
   function burnBatch(address _from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata _data) external;
}

/// @title Subclass this contract to adhere to the PBMRC1 standard
/// @dev PBM creator must assign an overall owner to the smart contract. 
/// if fine grain access controls are required, EIP-5982 can be used on top of ERC173
abstract contract PBMRC1 is IPBMRC1, ERC1155Metadata_URI, IERC173, IERC5679Ext1155 {

    // Underlying ERC-20 compaitible token of value.
    address public spotToken = address(0); 

    /// @notice Returns the Uniform Resource Identifier (URI) metadata information for the PBM with the corresponding tokenId
    /// @dev URIs are defined in RFC 3986. 
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    /// Developer may choose to adhere strictly to the ERC1155Metadata_URI extension interface
    /// or returns an uri that adheres to the ERC-1155 Metadata URI JSON Schema
    /// @param tokenId The id for the PBM in query
    /// @return Returns the metadata URI string for the PBM
    function uri(uint256 tokenId) external virtual view returns (string memory);

    /// @notice Creates new PBM copies ( ERC1155 NFT ) of an existing PBM token type.
    /// @dev See {IERC5679Ext1155} 
    /// @param receiver The wallet address to which the created PBMs need to be transferred to
    /// @param tokenId The identifier of the PBM token type
    /// @param amount The number of the PBMs that are to be created
    /**
     * @dev See {IERC5679Ext1155}.
     *     
     * IMPT: Before minting, the caller should approve the contract address to spend ERC-20 tokens on behalf of the caller.
     *       This can be done by calling the `approve` or `increaseMinterAllowance` functions of the ERC-20 contract and specifying `_spender` to be the PBM contract address. 
             Ref : https://eips.ethereum.org/EIPS/eip-20

       WARNING: Any contracts that externally call these mint() and batchMint() functions should implement some sort of reentrancy guard procedure (such as OpenZeppelin's ReentrancyGuard).
     *
     * Requirements:
     *
     * - contract must not be paused
     * - tokens must not be expired
     * - `tokenId` should be a valid id that has already been created
     * - caller should have the necessary amount of the ERC-20 tokens required to mint
     * - caller should have approved the PBM contract to spend the ERC-20 tokens
     * - receiver should not be blacklisted
     */
    function safeMint(address receiver, uint256 tokenId, uint256 amount, bytes calldata _data) external;
   
    /// @param tokenId The identifier of the PBM token type
    /// @param receiver The wallet address to which the created PBMs need to be transferred to
    /// @param amounts The number of the PBMs that are to be created
    /**
     * @dev See {IERC5679Ext1155}.
     *     
     * IMPT: Before minting, the caller should approve the contract address to spend ERC-20 tokens on behalf of the caller.
     *       This can be done by calling the `approve` or `increaseMinterAllowance` functions of the ERC-20 contract and specifying `_spender` to be the PBM contract address. 
             Ref : https://eips.ethereum.org/EIPS/eip-20

       WARNING: Any contracts that externally call these mint() and batchMint() functions should implement some sort of reentrancy guard procedure (such as OpenZeppelin's ReentrancyGuard).
     *
     * Requirements:
     *
     * - contract must not be paused
     * - tokens must not be expired
     * - `tokenIds` should all be valid ids that have already been created
     * - `tokenIds` and `amounts` list need to have the same number of values
     * - caller should have the necessary amount of the ERC-20 tokens required to mint
     * - caller should have approved the PBM contract to spend the ERC-20 tokens
     * - receiver should not be blacklisted
     */
    function safeMintBatch(address receiver, uint256[] calldata tokenIds, uint256[] calldata amounts, bytes calldata data) external;


    function burn(address _from, uint256 tokenId, uint256 _amount, bytes[] calldata _data) external;
    function burnBatch(address _from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata _data) external;

    // enforce the implementation of this function to make it clear that PBM must unwrap a token of value
    // the definition of unwrap is the unbounding of the underlyiung token of value to an end point. 
    function unwrap(address to) internal; 

    function getExpiry(); 

    // init compuslory with a spot token. 
    function initialise(address _spotToken, uint256 _expiry, address _pbmAddressList) external; 

    // change this:
    // we need this to enforce each PBM must have an underlying token of value 
    function getUnderlyingSpotToken()

    // Transfers PBM around 
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data) external; 
    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts, bytes memory data) external; 


    function revokePBM(uint256 tokenId) external;
    
    // PBMToken is defined as a struct. 
    function getTokenDetails(uint256 tokenId) external view returns(PBMToken memory); 


    /// LIST OF EVENTS TO BE EMITTED

}


