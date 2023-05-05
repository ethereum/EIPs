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

    function getExpiry(); 

    // change this:
    // we need this to enforce each PBM must have an underlying token of value 
    function getUnderlyingSpotToken()

    function revokePBM(uint256 tokenId) external;
    
    // PBMToken is defined as a struct. 
    function getTokenDetails(uint256 tokenId) external view returns(PBMToken memory); 

    /// LIST OF EVENTS TO BE EMITTED
    // TBD: check the parameters of the events 
    // TBD: consider these events to be added into safeMint functions if they are going to wrap an underlying eRC20tokens
    // TBD: consider other events to be EMITTED 
    // TBD: event logs emitted by the smart contract will provide enough data to create an accurate record of all current token balances.
    // A database or explorer may listen to events and be able to provide indexed and categorized searches

/**
    TokenUnwrapMerchantPayment
 */
    /// @notice Emitted when the underlying tokens are unwrapped and transferred to a specific purpose-bound address.
    /// This event signifies the end of the PBM lifecycle, as all necessary conditions have been met to release the underlying tokens to the recipient.
    /// @param from The address from which the PBM tokens are being unwrapped.
    /// @param to The purpose-bound address receiving the unwrapped underlying tokens.
    /// @param tokenIds An array containing the identifiers of the unwrapped PBM token types.
    /// @param amounts An array containing the quantities of the corresponding unwrapped PBM tokens.
    /// @param ERC20Token The address of the underlying ERC-20 token.
    /// @param ERC20TokenValue The amount of unwrapped underlying ERC-20 tokens transferred.
    event TokenUnwrappedForTarget(address from, address to, uint256[] tokenIds, uint256[] amounts, address ERC20Token, uint256 ERC20TokenValue);

    /// @notice Emitted when PBM tokens are burned, resulting in the unwrapping of the underlying tokens for the designated recipient.
    /// This event is required if there is an unwrapping of the underlying tokens during the PBM (NFT) burning process.
    /// @param from The address from which the PBM tokens are being burned.
    /// @param to The address receiving the unwrapped underlying tokens.
    /// @param tokenIds An array containing the identifiers of the burned PBM token types.
    /// @param amounts An array containing the quantities of the corresponding burned PBM tokens.
    /// @param ERC20Token The address of the underlying ERC-20 token.
    /// @param ERC20TokenValue The amount of unwrapped underlying ERC-20 tokens transferred.
    event TokenUnwrapForPBMBurn(address from, address to, uint256[] tokenIds, uint256[] amounts, address ERC20Token, uint256 ERC20TokenValue);

    /// Indicates the wrapping of an token into the PBM smart contract. 
    /// @notice Emitted when underlying tokens are wrapped within the PBM smart contract.

    /// This event signifies the beginning of the PBM lifecycle, as tokens are now managed by the conditions within the PBM contract.
    /// @param from The address initiating the token wrapping process, and 
    /// @param tokenIds An array containing the identifiers of the token types being wrapped.
    /// @param amounts An array containing the quantities of the corresponding wrapped tokens.
    /// @param ERC20Token The address of the underlying ERC-20 token.
    /// @param ERC20TokenValue The amount of wrapped underlying ERC-20 tokens transferred.
    event TokenWrap(address from, uint256[] tokenIds, uint256[] amounts,address ERC20Token, uint256 ERC20TokenValue); 

    /// Indicates that the PBM has been revoked 
    event PBMrevoked(address beneficiary, uint256 PBMTokenId, address ERC20Token, uint256 ERC20TokenValue);
    event PBMspotTokenWithdraw(address beneficiary, uint256 PBMTokenId, address ERC20Token, uint256 ERC20TokenValue);
    event NewPBMTypeCreated(uint256 tokenId, string tokenName, uint256 amount, uint256 expiry, address creator);
}


/// @notice Smart contracts MUST implement the ERC-165 `supportsInterface` function and signify support for the `PBMRC1_TokenReceiver` interface to accept callbacks.
/// It is optional for a receiving smart contract to implement the `PBMRC1_TokenReceiver` interface
/// @dev WARNING: Reentrancy guard procedure, Non delegate call, or the check-effects-interaction pattern must be adhere to when calling an external smart contract.
/// The interface functions MUST only be called at the end of the `unwrap` function.
interface PBMRC1_TokenReceiver {
    /**
        @notice Handles the callback from a PBM smart contract upon unwrapping
        @dev An PBM smart contract MUST call this function on the token recipient contract, at the end of a `unwrap` if the
        receiver smart contract supports type(PBMRC1_TokenReceiver).interfaceId
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being unwrapped
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onPBMRC1Unwrap(address,address,uint256,uint256,bytes)"))`
    */
    function onPBMRC1Unwrap(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handles the callback from a PBM smart contract upon unwrapping a batch of tokens
        @dev An PBM smart contract MUST call this function on the token recipient contract, at the end of a `unwrap` if the
        receiver smart contract supports type(PBMRC1_TokenReceiver).interfaceId

        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being unwrapped
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onPBMRC1BatchUnwrap(address,address,uint256,uint256,bytes)"))`
    */
    function onPBMRC1BatchUnwrap(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}
