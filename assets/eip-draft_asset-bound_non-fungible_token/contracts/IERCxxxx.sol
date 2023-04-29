// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title IERCxxxx Asset-Bound Non-Fungible Tokens 
 * @author Thomas Bergmueller (@tbergmueller) <tb@authenticvision.com>
 * @notice Asset-bound Non-Fungible Tokens anchor a token 1:1 to a (physical or digital) asset and token transfers are authorized through attestation of control over the asset
 * @dev See EIP-XXXX (todo link) for details
 */
interface IERCxxxx {
    /// Used for several authorization mechansims, e.g. who can burn, who can set approval, ... 
    /// @dev Specifying the role in the ERC-XXX ecosystem. Used in conjunction with ERCxxxxAuthorization
    enum ERCxxxxRole {
        OWNER,  // =0, The owner of the digital token
        ISSUER, // =1, The issuer (ERC-XXXX contract) of the tokens, typically represented through a MAINTAINER_ROLE, the contract owner etc.
        ASSET,  // =2, The asset identified by the anchor
        INVALID // =3, Reserved, do not use.
    }

    /// @dev Authorization, typically mapped to authorizationMaps, where each bit indicates whether a particular ERCxxxxRole is authorized 
    ///      Typically used in constructor (hardcoded or params) to set burnAuthorization and approveAuthorization
    ///      Also used in optional ERC-XXXX updateBurnAuthorization, updateApproveAuthorization 
    enum ERCxxxxAuthorization {
        NONE,               // = 0,      // None of the above
        OWNER,              // = (1<<OWNER), // The owner of the token, i.e. the digital representation
        ISSUER,             // = (1<<ISSUER), // The issuer of the tokens, i.e. this smart contract
        ASSET,              // = (1<<ASSET), // The asset, i.e. via attestation
        OWNER_AND_ISSUER,   // = (1<<OWNER) | (1<<ISSUER),
        OWNER_AND_ASSET,    // = (1<<OWNER) | (1<<ASSET),
        ASSET_AND_ISSUER,   // = (1<<ASSET) | (1<<ISSUER),
        ALL                 // = (1<<OWNER) | (1<<ISSUER) | (1<<ASSET) // Owner + Issuer + Asset
    }

    event OracleUpdate(address indexed oracle, bool indexed trusted);
    event AnchorTransfer(address indexed from, address indexed to, bytes32 indexed anchor, uint256 tokenId);
    event AttestationUsed(address indexed to, bytes32 indexed anchor, bytes32 indexed attestationHash, uint256 totalUsedAttestationsForAnchor);
    event ValidAnchorsUpdate(bytes32 indexed validAnchorHash, address indexed maintainer);

    // state requesting methods
    function anchorByToken(uint256 tokenId) external view returns (bytes32 anchor);
    function tokenByAnchor(bytes32 anchor) external view returns (uint256 tokenId);
    function attestationsUsedByAnchor(bytes32 anchor) external view returns (uint256 usageCount);
    function decodeAttestationIfValid(bytes memory attestation) external view returns (address to, bytes32 anchor, bytes32 attestationHash);
    function anchorIsReleased(bytes32 anchor) external view returns (bool isReleased);


    /**
     * @notice Adds or removes a trusted oracle, used when verifying signatures in `decodeAttestationIfValid()`
     * @dev Emits OracleUpdate
     * @param _oracle address of oracle
     * @param _isTrusted true to add, false to remove
     */
    function updateOracle(address _oracle, bool _isTrusted) external;

    /**
     * @notice Transfers the ownership of an NFT mapped to attestation.anchor to attestation.to address. Uses ERC721 safeTransferFrom and safeMint.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation. 
     *      When using centralized "transaction-signers" (paying for gas), implement IERCxxxxAttestationLimited!
     *      
     *      Throws when attestation invalid or already used, 
     *      Throws when attestation.to == ownerOf(tokenByAnchor(attestation.anchor)). See EIP-XXXX
     *      Emits AnchorTransfer and AttestationUsed  
     *  
     * @param attestation Attestation, refer EIP-XXXX for details
     * 
     * @return anchor The anchor, which is mapped to `tokenId`
     * @return to The `to` address, where the token with `tokenId` was transferd
     * @return tokenId The tokenId, which is mapped to the `anchor`     * 
     */
    function transferAnchor(bytes memory attestation) external returns (bytes32 anchor, address to, uint256 tokenId);

     /**
     * @notice Approves attestation.to the token mapped to attestation.anchor. Uses ERC721.approve(to, tokenId).
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *      When using centralized "transaction-signers" (paying for gas), implement IERCxxxxAttestationLimited!
     * 
     *      Throws when attestation invalid or already used
     *      Throws when ERCxxxxRole.ASSET is not authorized to approve
     * 
     * @param attestation Attestation, refer EIP-XXXX for details 
     */
    function approveAnchor(bytes memory attestation) external;

    /**
     * @notice Burns the token mapped to attestation.anchor. Uses ERC721._burn.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *      When using centralized "transaction-signers" (paying for gas), implement IERCxxxxAttestationLimited!
     * 
     *      Throws when attestation invalid or already used
     *      Throws when ERCxxxxRole.ASSET is not authorized to burn
     * 
     * @param attestation Attestation, refer EIP-XXXX for details 
     */
    function burnAnchor(bytes memory attestation) external;

    
    /// @notice Update the Merkle root containing the valid anchors. Consider salt-leaves!
    /// @dev Proof (transferAnchor) needs to provided from this tree. 
    /// @dev The merkle-tree needs to contain at least one "salt leaf" in order to not publish the complete merkle-tree when all anchors should have been dropped at least once. 
    /// @param merkleRootNode The root, containing all anchors we want validated.
    function updateValidAnchors(bytes32 merkleRootNode) external;
}