// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title PBM Specification
/// @notice The PBM (purpose bound money) allows us to add logical requirements on the use of ERC-20 tokens. 
/// The PBM acts as wrapper around the ERC-20 tokens and implements the necessary logic. 
interface IPBMRC1 {
    
    /// @notice Initialise the contract by specifying an underlying ERC20-compatible token address,
    /// contract expiry, and the PBM address list.
    /// @param spotToken_ The address of the underlying ERC20 token.
    /// @param expiry_ The contract-wide expiry timestamp (in Unix epoch time).
    /// @param merchantAddressList_ The address of the PBMAddressList smart contract.
    function initialise(address spotToken_, uint256 expiry_, address merchantAddressList_) external; 

    /// @notice Returns the Uniform Resource Identifier (URI) metadata information for the PBM with the corresponding tokenId
    /// @dev URIs are defined in RFC 3986. 
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    /// Developer may choose to adhere strictly to the ERC1155Metadata_URI extension interface
    /// or returns an uri that adheres to the ERC-1155 Metadata URI JSON Schema
    /// @param tokenId The id for the PBM in query
    /// @return Returns the metadata URI string for the PBM
    function uri(uint256 tokenId) external  view returns (string memory);
    
    /**
        @notice Creates a PBM copy ( ERC1155 NFT ) of an existing PBM token type.
        @dev See {IERC5679Ext1155} on further implementation notes
        @param receiver The wallet address to which the created PBMs need to be transferred to
        @param tokenId The identifier of the PBM token type to be copied.
        @param amount The number of the PBMs that are to be created
        @param data
            
        IMPT: Before minting, the caller should approve the contract address to spend ERC-20 tokens on behalf of the caller.
            This can be done by calling the `approve` or `increaseMinterAllowance` functions of the ERC-20 contract and specifying `_spender` to be the PBM contract address. 
            Ref : https://eips.ethereum.org/EIPS/eip-20

        WARNING: Any contracts that externally call these safeMint() and safeMintBatch() functions should implement some sort of reentrancy guard procedure 
        (such as OpenZeppelin's ReentrancyGuard) or a Checks-effects-interactions pattern.

        As per ERC-5679 standard: When the token is being minted, the transfer events MUST be emitted as if the token in the `amount` for EIP-1155 
        and `tokenId` being _id for EIP-1155 were transferred from address 0x0 to the recipient address identified by receiver. 
        The total supply MUST increase accordingly.

        Requirements:
        - contract must not be paused
        - tokens must not be expired
        - `tokenId` should be a valid id that has already been created
        - caller should have the necessary amount of the ERC-20 tokens required to mint
        - caller should have approved the PBM contract to spend the ERC-20 tokens
        - receiver should not be blacklisted
     */
    function safeMint(address receiver, uint256 tokenId, uint256 amount, bytes calldata data) external;

    /**
        @dev See {IERC5679Ext1155}.
        @param tokenIds The identifier of the PBM token type
        @param receiver The wallet address to which the created PBMs need to be transferred to
        @param amounts The number of the PBMs that are to be created

@param _data    Additional data with no specified format, 
        IMPT: Before minting, the caller should approve the contract address to spend ERC-20 tokens on behalf of the caller.
            This can be done by calling the `approve` or `increaseMinterAllowance` functions of the ERC-20 contract and specifying `_spender` to be the PBM contract address. 
            Ref : https://eips.ethereum.org/EIPS/eip-20

        WARNING: Any contracts that externally call these safeMint() and safeMintBatch() functions should implement some sort of reentrancy guard procedure 
        (such as OpenZeppelin's ReentrancyGuard) or a Checks-effects-interactions pattern.

        As per ERC-5679 standard: When the token is being minted, the transfer events MUST be emitted as if the token in the `amount` for EIP-1155 
        and `tokenId` being _id for EIP-1155 were transferred from address 0x0 to the recipient address identified by receiver. 
        The total supply MUST increase accordingly.

        Requirements:
        - contract must not be paused
        - tokens must not be expired
        - `tokenIds` should all be valid ids that have already been created
        - `tokenIds` and `amounts` list need to have the same number of values
        - caller should have the necessary amount of the ERC-20 tokens required to mint
        - caller should have approved the PBM contract to spend the ERC-20 tokens
        - receiver should not be blacklisted
     */
    function safeMintBatch(address receiver, uint256[] calldata tokenIds, uint256[] calldata amounts, bytes calldata data) external;

    /**


    
    
     */
    function burn(address _from, uint256 tokenId, uint256 _amount, bytes[] calldata _data) external;


    
    function burnBatch(address _from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata _data) external;

    /// @notice Transfers the PBM(NFT) from one wallet to another. 
    /// If the receving wallet is a whitelisted merchant wallet address, the PBM(NFT) will be burnt and the underlying ERC-20 tokens will be transferred to the merchant wallet instead.
    /// @param from The account from which the PBM ( NFT ) is moving from 
    /// @param to The account which is receiving the PBM ( NFT )
    /// @param id The identifier of the PBM token type
    /// @param amount The number of (quantity) the PBM type that are to be transferred of the PBM type
    /// @param data To record any data associated with the transaction, can be left blank if none
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data) external; 

    /// @notice Transfers the PBM(NFT)(s) from one wallet to another. 
    /// If the receving wallet is a whitelisted merchant wallet address, the PBM(NFT)(s) will be burnt and the underlying ERC-20 tokens will be transferred to the merchant wallet instead.
    /// @param from The account from which the PBM ( NFT )(s) is moving from 
    /// @param to The account which is receiving the PBM ( NFT )(s)
    /// @param ids The identifiers of the different PBM token type
    /// @param amounts The number of ( quantity ) the different PBM types that are to be created
    /// @param data To record any data associated with the transaction, can be left blank if none. 
    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts, bytes memory data) external; 

    /// @notice Allows the creator of the PBM type to retrive all the locked up ERC-20 once they have expired for that particular token type
    /// @param tokenId The identifier of the PBM token type
    function revokePBM(uint256 tokenId) external;

    /// @notice Emitted when underlying ERC-20 tokens are transferred to a whitelisted merchant ( payment )
    /// @param from The account from which the PBM ( NFT )(s) is moving from 
    /// @param to The account which is receiving the PBM ( NFT )(s)
    /// @param tokenIds The identifiers of the different PBM token type
    /// @param amounts The number of ( quantity ) the different PBM types that are to be created
    /// @param ERC20Token The address of the underlying ERC-20 token 
    /// @param ERC20TokenValue The number of underlying ERC-20 tokens transferred
    event MerchantPayment(address from , address to, uint256[] tokenIds, uint256[] amounts,address ERC20Token, uint256 ERC20TokenValue); 

    /// @notice Emitted when a PBM type creator withdraws the underlying ERC-20 tokens from all the remaining expired PBMs
    /// @param beneficiary the address ( PBM type creator ) which receives the ERC20 Token
    /// @param PBMTokenId The identifiers of the different PBM token type
    /// @param ERC20Token The address of the underlying ERC-20 token 
    /// @param ERC20TokenValue The number of underlying ERC-20 tokens transferred 
    event PBMrevokeWithdraw(address beneficiary, uint256 PBMTokenId, address ERC20Token, uint256 ERC20TokenValue);
}