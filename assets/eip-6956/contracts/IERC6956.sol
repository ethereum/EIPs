// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title IERC6956 Asset-Bound Non-Fungible Tokens 
 * @notice Asset-bound Non-Fungible Tokens anchor a token 1:1 to a (physical or digital) asset and token transfers are authorized through attestation of control over the asset
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0xa9cf7635
 */
interface IERC6956 {
   
    /** @dev Authorization, typically mapped to authorizationMaps, where each bit indicates whether a particular ERC6956Role is authorized 
     *      Typically used in constructor (hardcoded or params) to set burnAuthorization and approveAuthorization
     *      Also used in optional updateBurnAuthorization, updateApproveAuthorization, I
     */ 
    enum Authorization {
        NONE,               // = 0,      // None of the above
        OWNER,              // = (1<<OWNER), // The owner of the token, i.e. the digital representation
        ISSUER,             // = (1<<ISSUER), // The issuer of the tokens, i.e. this smart contract
        ASSET,              // = (1<<ASSET), // The asset, i.e. via attestation
        OWNER_AND_ISSUER,   // = (1<<OWNER) | (1<<ISSUER),
        OWNER_AND_ASSET,    // = (1<<OWNER) | (1<<ASSET),
        ASSET_AND_ISSUER,   // = (1<<ASSET) | (1<<ISSUER),
        ALL                 // = (1<<OWNER) | (1<<ISSUER) | (1<<ASSET) // Owner + Issuer + Asset
    }
    
    /**
     * @notice This emits when approved address for an anchored tokenId is changed or reaffirmed via attestation
     * @dev This emits when approveAnchor() is called and corresponds to ERC-721 behavior
     * @param owner The owner of the anchored tokenId
     * @param approved The approved address, address(0) indicates there is no approved address
     * @param anchor The anchor, for which approval has been chagned
     * @param tokenId ID (>0) of the anchored token
     */
    event AnchorApproval(address indexed owner, address approved, bytes32 indexed anchor, uint256 tokenId);

    /**
     * @notice This emits when the ownership of any anchored NFT changes by any mechanism
     * @dev This emits together with tokenId-based ERC-721.Transfer and provides an anchor-perspective on transfers
     * @param from The previous owner, address(0) indicate there was none.
     * @param to The new owner, address(0) indicates the token is burned
     * @param anchor The anchor which is bound to tokenId
     * @param tokenId ID (>0) of the anchored token
     */
    event AnchorTransfer(address indexed from, address indexed to, bytes32 indexed anchor, uint256 tokenId);
    /**
     * @notice This emits when an attestation has been used indicating no second attestation with the same attestationHash will be accepted
     * @param to The to address specified in the attestation
     * @param anchor The anchor specificed in the attestation
     * @param attestationHash The hash of the attestation, see ERC-6956 for details
     * @param totalUsedAttestationsForAnchor The total number of attestations already used for the particular anchor
     */
    event AttestationUse(address indexed to, bytes32 indexed anchor, bytes32 indexed attestationHash, uint256 totalUsedAttestationsForAnchor);

    /**
     * @notice This emits when the trust-status of an oracle changes. 
     * @dev Trusted oracles must explicitely be specified. 
     *      If the last event for a particular oracle-address indicates it's trusted, attestations from this oracle are valid.
     * @param oracle Address of the oracle signing attestations
     * @param trusted indicating whether this address is trusted (true). Use (false) to no longer trust from an oracle.
     */
    event OracleUpdate(address indexed oracle, bool indexed trusted);

    /**
     * @notice Returns the 1:1 mapped anchor for a tokenId
     * @param tokenId ID (>0) of the anchored token
     * @return anchor The anchor bound to tokenId, 0x0 if tokenId does not represent an anchor
     */
    function anchorByToken(uint256 tokenId) external view returns (bytes32 anchor);
    /**
     * @notice Returns the ID of the 1:1 mapped token of an anchor.
     * @param anchor The anchor (>0x0)
     * @return tokenId ID of the anchored token, 0 if no anchored token exists
     */
    function tokenByAnchor(bytes32 anchor) external view returns (uint256 tokenId);

    /**
     * @notice The number of attestations already used to modify the state of an anchor or its bound tokens
     * @param anchor The anchor(>0)
     * @return attestationUses The number of attestation uses for a particular anchor, 0 if anchor is invalid.
     */
    function attestationsUsedByAnchor(bytes32 anchor) view external returns (uint256 attestationUses);
    /**
     * @notice Decodes and returns to-address, anchor and the attestation hash, if the attestation is valid
     * @dev MUST throw when
     *  - Attestation has already been used (an AttestationUse-Event with matching attestationHash was emitted)
     *  - Attestation is not signed by trusted oracle (the last OracleUpdate-Event for the signer-address does not indicate trust)
     *  - Attestation is not valid yet or expired
     *  - [if IERC6956AttestationLimited is implemented] attestationUsagesLeft(attestation.anchor) <= 0
     *  - [if IERC6956ValidAnchors is implemented] validAnchors(data) does not return true. 
     * @param attestation The attestation subject to the format specified in ERC-6956
     * @param data Optional additional data, may contain proof as the first abi-encoded argument when IERC6956ValidAnchors is implemented
     * @return to Address where the ownership of an anchored token or approval shall be changed to
     * @return anchor The anchor (>0)
     * @return attestationHash The attestation hash computed on-chain as `keccak256(attestation)`
     */
    function decodeAttestationIfValid(bytes memory attestation, bytes memory data) external view returns (address to, bytes32 anchor, bytes32 attestationHash);

    /**
     * @notice Indicates whether any of ASSET, OWNER, ISSUER is authorized to burn
     */
    function burnAuthorization() external view returns(Authorization burnAuth);

    /**
     * @notice Indicates whether any of ASSET, OWNER, ISSUER is authorized to approve
     */
    function approveAuthorization() external view returns(Authorization approveAuth);

    /**
     * @notice Corresponds to transferAnchor(bytes,bytes) without additional data
     * @param attestation Attestation, refer ERC-6956 for details
     */
    function transferAnchor(bytes memory attestation) external;

    /**
     * @notice Changes the ownership of an NFT mapped to attestation.anchor to attestation.to address.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *  - Uses decodeAttestationIfValid()
     *  - When using a centralized "gas-payer" recommended to implement IERC6956AttestationLimited.
     *  - Matches the behavior of ERC-721.safeTransferFrom(ownerOf[tokenByAnchor(attestation.anchor)], attestation.to, tokenByAnchor(attestation.anchor), ..) and mint an NFT if `tokenByAnchor(anchor)==0`.
     *  - Throws when attestation.to == ownerOf(tokenByAnchor(attestation.anchor))
     *  - Emits AnchorTransfer  
     *  
     * @param attestation Attestation, refer EIP-6956 for details
     * @param data Additional data, may be used for additional transfer-conditions, may be sent partly or in full in a call to safeTransferFrom
     * 
     */
    function transferAnchor(bytes memory attestation, bytes memory data) external;

     /**
     * @notice Corresponds to approveAnchor(bytes,bytes) without additional data
     * @param attestation Attestation, refer ERC-6956 for details
     */
    function approveAnchor(bytes memory attestation) external;

     /**
     * @notice Approves attestation.to the token bound to attestation.anchor. .
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *  - Uses decodeAttestationIfValid()
     *  - When using a centralized "gas-payer" recommended to implement IERC6956AttestationLimited.
     *  - Matches the behavior of ERC-721.approve(attestation.to, tokenByAnchor(attestation.anchor)).
     *  - Throws when ASSET is not authorized to approve.
     * 
     * @param attestation Attestation, refer EIP-6956 for details 
     */
    function approveAnchor(bytes memory attestation, bytes memory data) external;

    /**
     * @notice Corresponds to burnAnchor(bytes,bytes) without additional data
     * @param attestation Attestation, refer ERC-6956 for details
     */
    function burnAnchor(bytes memory attestation) external;
   
    /**
     * @notice Burns the token mapped to attestation.anchor. Uses ERC-721._burn.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *  - Uses decodeAttestationIfValid()
     *  - When using a centralized "gas-payer" recommended to implement IERC6956AttestationLimited.
     *  - Throws when ASSET is not authorized to burn
     * 
     * @param attestation Attestation, refer EIP-6956 for details
     */
    function burnAnchor(bytes memory attestation, bytes memory data) external;
}