// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC6956.sol";

/** Used for several authorization mechansims, e.g. who can burn, who can set approval, ... 
 * @dev Specifying the role in the ecosystem. Used in conjunction with IERC6956.Authorization
 */
enum Role {
    OWNER,  // =0, The owner of the digital token
    ISSUER, // =1, The issuer (contract) of the tokens, typically represented through a MAINTAINER_ROLE, the contract owner etc.
    ASSET,  // =2, The asset identified by the anchor
    INVALID // =3, Reserved, do not use.
}

/**
 * @title ASSET-BOUND NFT minimal reference implementation 
 * @author Thomas Bergmueller (@tbergmueller)
 * 
 * @dev Error messages
 * ```
 * ERROR | Message
 * ------|-------------------------------------------------------------------
 * E1    | Only maintainer allowed
 * E2    | No permission to burn
 * E3    | Token does not exist, call transferAnchor first to mint
 * E4    | batchSize must be 1
 * E5    | Token not transferable
 * E6    | Token already owned
 * E7    | Not authorized based on ERC6956Authorization
 * E8    | Attestation not signed by trusted oracle
 * E9    | Attestation already used
 * E10   | Attestation not valid yet
 * E11   | Attestation expired 
 * E12   | Attestation expired (contract limit)
 * E13   | Invalid signature length
 * E14-20| Reserved for future use
 * ```
 */
contract ERC6956 is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    IERC6956 
{
    using Counters for Counters.Counter;

    mapping(bytes32 => bool) internal _anchorIsReleased; // currently released anchors. Per default, all anchors are dropped, i.e. 1:1 bound
    
    mapping(address => bool) public maintainers;

    /// @notice Resolves tokenID to anchor. Inverse of tokenByAnchor
    mapping(uint256 => bytes32) public anchorByToken;

    /// @notice Resolves Anchor to tokenID. Inverse of anchorByToken
    mapping(bytes32 => uint256) public tokenByAnchor;

    mapping(address => bool) private _trustedOracles;

    /// @dev stores the anchors for each attestation
    mapping(bytes32 => bytes32) private _anchorByUsedAttestation;

    /// @dev stores handed-back tokens (via burn)
    mapping (bytes32 => uint256) private _burnedTokensByAnchor;


     /**
     * @dev Counter to keep track of issued tokens
     */
    Counters.Counter private _tokenIdCounter;

    /// @dev Default validity timespan of attestation. In validateAttestation the attestationTime is checked for MIN(defaultAttestationvalidity, attestation.expiry)
    uint256 public maxAttestationExpireTime = 5*60; // 5min valid per default

    Authorization public burnAuthorization;
    Authorization public approveAuthorization;


    /// @dev Records the number of transfers done for each attestation
    mapping(bytes32 => uint256) public attestationsUsedByAnchor;

    modifier onlyMaintainer() {
        require(isMaintainer(msg.sender), "ERC6956-E1");
        _;
    }

    /**
     * @notice Behaves like ERC721 burn() for wallet-cleaning purposes. Note only the tokenId (as a wrapper) is burned, not the ASSET represented by the ANCHOR.
     * @dev 
     * - tokenId is remembered for the anchor, to ensure a later transferAnchor(), which would mint, assigns the same tokenId. This ensures strict 1:1 relation
     * - For burning, the anchor needs to be released. This forced release FOR BURNING ONLY is allowed for owner() or approvedOwner().
     * 
     * @param tokenId The token that shall be burned
     */
    function burn(uint256 tokenId) public override
    {
        // remember the tokenId of burned tokens, s.t. one can issue the token with the same number again
        bytes32 anchor = anchorByToken[tokenId];
        require(_roleBasedAuthorization(anchor, createAuthorizationMap(burnAuthorization)), "ERC6956-E2");
        _burn(tokenId);
    }

    function burnAnchor(bytes memory attestation, bytes memory data) public virtual
        authorized(Role.ASSET, createAuthorizationMap(burnAuthorization))
     {
        address to;
        bytes32 anchor;
        bytes32 attestationHash;
        (to, anchor, attestationHash) = decodeAttestationIfValid(attestation, data);
        _commitAttestation(to, anchor, attestationHash);
        uint256 tokenId = tokenByAnchor[anchor];
        // remember the tokenId of burned tokens, s.t. one can issue the token with the same number again
        _burn(tokenId);
    }

    function burnAnchor(bytes memory attestation) public virtual {
        return burnAnchor(attestation, "");
    }

    function approveAnchor(bytes memory attestation, bytes memory data) public virtual 
        authorized(Role.ASSET, createAuthorizationMap(approveAuthorization))
    {
        address to;
        bytes32 anchor;
        bytes32 attestationHash;
        (to, anchor, attestationHash) = decodeAttestationIfValid(attestation, data);
        _commitAttestation(to, anchor, attestationHash);
        require(tokenByAnchor[anchor]>0, "ERC6956-E3");
        _approve(to, tokenByAnchor[anchor]);
    }

    // approveAuth == ISSUER does not really make sense.. so no separate implementation, since ERC-721.approve already implies owner...

    function approve(address to, uint256 tokenId) public virtual override(ERC721,IERC721)
        authorized(Role.OWNER, createAuthorizationMap(approveAuthorization))
    {
        super.approve(to, tokenId);
    }

    function approveAnchor(bytes memory attestation) public virtual {
        return approveAnchor(attestation, "");
    }
    
    /**
     * @notice Adds or removes a trusted oracle, used when verifying signatures in `decodeAttestationIfValid()`
     * @dev Emits OracleUpdate
     * @param oracle address of oracle
     * @param doTrust true to add, false to remove
     */
    function updateOracle(address oracle, bool doTrust) public
        onlyMaintainer() 
    {
        _trustedOracles[oracle] = doTrust;
        emit OracleUpdate(oracle, doTrust);
    }

    /**
     * @dev A very simple function wich MUST return false, when `a` is not a maintainer
     *      When derived contracts extend ERC6956 contract, this function may be overridden
     *      e.g. by using AccessControl, onlyOwner or other common mechanisms
     * 
     *      Having this simple mechanism in the reference implementation ensures that the reference
     *      implementation is fully ERC-6956 compatible 
     */
    function isMaintainer(address a) public virtual view returns (bool) {
        return maintainers[a];
    } 
      

    function createAuthorizationMap(Authorization _auth) public pure returns (uint256)  {
       uint256 authMap = 0;
       if(_auth == Authorization.OWNER 
            || _auth == Authorization.OWNER_AND_ASSET 
            || _auth == Authorization.OWNER_AND_ISSUER 
            || _auth == Authorization.ALL) {
        authMap |= uint256(1<<uint256(Role.OWNER));
       } 
       
       if(_auth == Authorization.ISSUER 
            || _auth == Authorization.ASSET_AND_ISSUER 
            || _auth == Authorization.OWNER_AND_ISSUER 
            || _auth == Authorization.ALL) {
        authMap |= uint256(1<<uint256(Role.ISSUER));
       }

       if(_auth == Authorization.ASSET 
            || _auth == Authorization.ASSET_AND_ISSUER 
            || _auth == Authorization.OWNER_AND_ASSET 
            || _auth == Authorization.ALL) {
        authMap |= uint256(1<<uint256(Role.ASSET));
       }

       return authMap;
    }

    function _roleBasedAuthorization(bytes32 anchor, uint256 authorizationMap) internal view returns (bool) {
        uint256 tokenId = tokenByAnchor[anchor];        
        Role myRole = Role.INVALID;
        Role alternateRole = Role.INVALID;
        
        if(_isApprovedOrOwner(_msgSender(), tokenId)) {
            myRole = Role.OWNER;
        }

        if(isMaintainer(msg.sender)) {
            alternateRole = Role.ISSUER;
        }

        return hasAuthorization(myRole, authorizationMap) 
                    || hasAuthorization(alternateRole, authorizationMap);
    }
   
    ///@dev Hook executed before decodeAttestationIfValid returns. Override in derived contracts
    function _beforeAttestationUse(bytes32 anchor, address to, bytes memory data) internal view virtual {}
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual
        override(ERC721, ERC721Enumerable)
    {
        require(batchSize == 1, "ERC6956-E4");
        bytes32 anchor = anchorByToken[tokenId];
        emit AnchorTransfer(from, to, anchor, tokenId);

        if(to == address(0)) {
            // we are burning, ensure the mapping is deleted BEFORE the transfer
            // to avoid reentrant-attacks
            _burnedTokensByAnchor[anchor] = tokenId; // Remember tokenId for a potential re-mint
            delete tokenByAnchor[anchor];
            delete anchorByToken[tokenId]; 
        }        
        else {
            require(_anchorIsReleased[anchor], "ERC6956-E5");
        }

        delete _anchorIsReleased[anchor]; // make sure anchor is non-released after the transfer again
   }

    /// @dev hook called after an anchor is minted
    function _afterAnchorMint(address to, bytes32 anchor, uint256 tokenId) internal virtual {}

    /**
     * @notice Add (_add=true) or remove (_add=false) a maintainer
     * @dev Note this is a trivial implementation, which can leave the contract without a maintainer.
     * Since the function is access-controlled via onlyMaintainer, this results in the contract
     * becoming unmaintainable. 
     * This may be desired behavior, for example if the contract shall become immutable until 
     * all eternity, therefore making a project truly trustless. 
     */
    function updateMaintainer(address _maintainer, bool _add) public onlyMaintainer() {
        maintainers[_maintainer] = _add;
    }

    /// @dev Verifies a anchor is valid and mints a token to the target address.
    /// Internal function to be called whenever minting is needed.
    /// Parameters:
    /// @param to Beneficiary account address
    /// @param anchor The anchor (from Merkle tree)
    function _safeMint(address to, bytes32 anchor) internal virtual {
        assert(tokenByAnchor[anchor] <= 0); // saftey for contract-internal errors
        uint256 tokenId = _burnedTokensByAnchor[anchor];

        if(tokenId < 1) {
            _tokenIdCounter.increment();
            tokenId = _tokenIdCounter.current();
        }

        assert(anchorByToken[tokenId] <= 0); // saftey for contract-internal errors
        anchorByToken[tokenId] = anchor;
        tokenByAnchor[anchor] = tokenId;
        super._safeMint(to, tokenId);

        _afterAnchorMint(to, anchor, tokenId);
    }

    function _commitAttestation(address to, bytes32 anchor, bytes32 attestationHash) internal {
        _anchorByUsedAttestation[attestationHash] = anchor;
        uint256 totalAttestationsByAnchor = attestationsUsedByAnchor[anchor] +1;
        attestationsUsedByAnchor[anchor] = totalAttestationsByAnchor;
        emit AttestationUse(to, anchor, attestationHash, totalAttestationsByAnchor );
    }

    function transferAnchor(bytes memory attestation, bytes memory data) public virtual
    {      
        bytes32 anchor;
        address to;
        bytes32 attestationHash;
        (to, anchor, attestationHash) = decodeAttestationIfValid(attestation, data);
        _commitAttestation(to, anchor, attestationHash); // commit already here, will be reverted in error case anyway

        uint256 fromToken = tokenByAnchor[anchor]; // tokenID, null if not exists
        address from = address(0); // owneraddress or 0x00, if not exists
        
        _anchorIsReleased[anchor] = true; // Attestation always temporarily releases the anchor       

        if(fromToken > 0) {
            from = ownerOf(fromToken);
            require(from != to, "ERC6956-E6");
            _safeTransfer(from, to, fromToken, "");
        } else {
            _safeMint(to, anchor);
        }
    }

    function transferAnchor(bytes memory attestation) public virtual {
        return transferAnchor(attestation, "");
    }
    

    function hasAuthorization(Role _role, uint256 _auth ) public pure returns (bool) {
        uint256 result = uint256(_auth & (1 << uint256(_role)));
        return result > 0;
    }

    modifier authorized(Role _role, uint256 _authMap) {
        require(hasAuthorization(_role, _authMap), "ERC6956-E7");
        _;
    }

    // The following functions are overrides required by Solidity, EIP-165.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC6956).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns whether a certain address is registered as trusted oracle, i.e. attestations signed by this address are accepted in `decodeAttestationIfValid`
     * @dev This function may be overwritten when extending ERC-6956, e.g. when other oracle-registration mechanics are used
     * @param oracleAddress Address of the oracle in question
     * @return isTrusted True, if oracle is trusted
     */
    function isTrustedOracle(address oracleAddress) public virtual view returns (bool isTrusted) {
        return _trustedOracles[oracleAddress];
    }
    

    function decodeAttestationIfValid(bytes memory attestation, bytes memory data) public view returns (address to, bytes32 anchor, bytes32 attestationHash) {
        uint256 attestationTime;
        uint256 validStartTime;
        uint256 validEndTime;
        bytes memory signature;
        bytes32[] memory proof;

        attestationHash = keccak256(attestation);
        (to, anchor, attestationTime, validStartTime, validEndTime, signature) = abi.decode(attestation, (address, bytes32, uint256, uint256, uint256, bytes));
                
        bytes32 messageHash = keccak256(abi.encodePacked(to, anchor, attestationTime, validStartTime, validEndTime, proof));
        address signer = _extractSigner(messageHash, signature);

        // Check if from trusted oracle
        require(isTrustedOracle(signer), "ERC6956-E8");
        require(_anchorByUsedAttestation[attestationHash] <= 0, "ERC6956-E9");

        // Check expiry
        uint256 timestamp = block.timestamp;
        require(timestamp > validStartTime, "ERC6956-E10");
        require(attestationTime + maxAttestationExpireTime > block.timestamp, "ERC6956-E11");
        require(validEndTime > block.timestamp, "ERC6956-E112");

        
        // Calling hook!
        _beforeAttestationUse(anchor, to, data);
        return(to,  anchor, attestationHash);
    }

    /// @notice Compatible with ERC721.tokenURI(). Returns {baseURI}{anchor}
    /// @dev Returns when called for tokenId=5, baseURI=https://myurl.com/collection/ and anchorByToken[5] =  0x12345
    /// Example:  https://myurl.com/collection/0x12345
    /// Works for non-burned tokens / active-Anchors only.
    /// Anchor-based tokenURIs are needed as an anchor's corresponding tokenId is only known after mint. 
    /// @param tokenId TokenID
    /// @return tokenURI Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {        
        bytes32 anchor = anchorByToken[tokenId];
        string memory anchorString = Strings.toHexString(uint256(anchor));
        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), anchorString)) : "";
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseUri;
    }

    /**
    * @dev Base URI, MUST end with a slash. Will be used as `{baseURI}{tokenId}` in tokenURI() function
    */
    string internal _baseUri = ""; // needs to end with '/'

    /// @notice Set a new BaseURI. Can be used with dynamic NFTs that have server APIs, IPFS-buckets
    /// or any other suitable system. Refer tokenURI(tokenId) for anchor-based or tokenId-based format.
    /// @param tokenBaseURI The token base-URI. Must end with slash '/'.
    function updateBaseURI(string calldata tokenBaseURI) public onlyMaintainer() {
        _baseUri = tokenBaseURI;
    }
    event BurnAuthorizationChange(Authorization burnAuth, address indexed maintainer);

    function updateBurnAuthorization(Authorization burnAuth) public onlyMaintainer() {
        burnAuthorization = burnAuth;
        emit BurnAuthorizationChange(burnAuth, msg.sender);
        // TODO event
    }
    
    event ApproveAuthorizationChange(Authorization approveAuth, address indexed maintainer);

    function updateApproveAuthorization(Authorization approveAuth) public onlyMaintainer() {
        approveAuthorization = approveAuth;
        emit ApproveAuthorizationChange(approveAuth, msg.sender);

        // TODO event
    }

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol) {            
            maintainers[msg.sender] = true; // deployer is automatically maintainer
            // Indicates general float-ability, i.e. whether anchors can be digitally dropped and released

            // OWNER and ASSET shall normally be in sync anyway, so this is reasonable default 
            // authorization for approve and burn, as it mimicks ERC-721 behavior
            burnAuthorization = Authorization.OWNER_AND_ASSET;
            approveAuthorization = Authorization.OWNER_AND_ASSET;
    }
  
    /*
     ########################## SIGNATURE MAGIC, 
     ########################## adapted from https://solidity-by-example.org/signature/
    */
   /**
    * Returns the signer of a message.
    *  
    *   OFF-CHAIN: 
    *   const [alice] = ethers.getSigners(); // = 0x3c44...
    *   const messageHash = ethers.utils.solidityKeccak256(["address", "bytes32"], [a, b]);
        const sig = await alice.signMessage(ethers.utils.arrayify(messageHash));

        ONCHAIN In this contract, call from 
        ```
        function (address a, bytes32 b, bytes memory sig) {
            messageHash = keccak256(abi.encodePacked(to, b));
            signer = extractSigner(messageHash, sig); // signer will be 0x3c44...
        }
        ```    * 
    * @param messageHash A keccak25(abi.encodePacked(...)) hash
    * @param sig Signature (length 65 bytes)
    * 
    * @return The signer
    */
   function _extractSigner(bytes32 messageHash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "ERC6956-E13");
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the r, s, and v parameters from the signature
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Ensure the v parameter is either 27 or 28
        // TODO is this needed?
        if (v < 27) {
            v += 27;
        }

        // Recover the public key from the signature and message hash
        // and convert it to an address
        address signer = ecrecover(ethSignedMessageHash, v, r, s);       
        return signer;
    }
}
