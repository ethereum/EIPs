// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC6956.sol";
import "./IERC6956AttestationLimited.sol";
import "./IERC6956Floatable.sol";

contract ERC6956Full is ERC6956, IERC6956AttestationLimited, IERC6956Floatable {

    uint8 canStartFloatingMap;
    uint8 canStopFloatingMap;

    /// ###############################################################################################################################
    /// ##############################################################################################  IERC6956AttestedTransferLimited
    /// ###############################################################################################################################
    
    mapping(bytes32 => uint256) attestedTransferLimitByAnchor;
    
    uint256 public globalAttestedTransferLimitByAnchor;
    AttestationLimitUpdatePolicy public transferLimitPolicy;

    /// @dev Counts the number of attested transfers by Anchor
    bool public canFloat; // Indicates whether tokens can "float" in general, i.e. be transferred without attestation
    bool public allFloating;
    bool public floatingByDefault;

    function requireValidLimitUpdate(uint256 oldValue, uint256 newValue) internal view {
        if(newValue > oldValue) {
            require(transferLimitPolicy == AttestationLimitUpdatePolicy.FLEXIBLE || transferLimitPolicy == AttestationLimitUpdatePolicy.INCREASE_ONLY, "EIP-6956: Updating attestedTransferLimit violates policy");
        } else {
            require(transferLimitPolicy == AttestationLimitUpdatePolicy.FLEXIBLE || transferLimitPolicy == AttestationLimitUpdatePolicy.DECREASE_ONLY, "EIP-6956: Updating attestedTransferLimit violates policy");
        }
    }

    function _afterAnchorMint(address /*to*/, bytes32 anchor, uint256 /*tokenId*/) internal override(ERC6956) virtual {
        _allowFloating(anchor, floatingByDefault);        
    }

    function updateAnchorFloatingByDefault(bool _floatsByDefault) public 
    onlyRole(MAINTAINER_ROLE) {
        floatingByDefault = true;
        emit DefaultFloatingStateChange(_floatsByDefault, msg.sender);      
    }

    function updateGlobalAttestationLimit(uint256 _nrTransfers) 
        public 
        onlyRole(MAINTAINER_ROLE) 
    {
       requireValidLimitUpdate(globalAttestedTransferLimitByAnchor, _nrTransfers);
       globalAttestedTransferLimitByAnchor = _nrTransfers;
       emit GlobalAttestationLimitUpdate(_nrTransfers, msg.sender);
    }

    function updateAttestationLimit(bytes32 anchor, uint256 _nrTransfers) 
        public 
        onlyRole(MAINTAINER_ROLE) 
    {
       uint256 currentLimit = attestedTransferLimit(anchor);
       requireValidLimitUpdate(currentLimit, _nrTransfers);
       attestedTransferLimitByAnchor[anchor] = _nrTransfers;
       emit AttestationLimitUpdate(anchor, tokenByAnchor[anchor], _nrTransfers, msg.sender);
    }

    function attestedTransferLimit(bytes32 anchor) public view returns (uint256 limit) {
        if(attestedTransferLimitByAnchor[anchor] > 0) { // Per anchor overwrites always, even if smaller than globalAttestedTransferLimit
            return attestedTransferLimitByAnchor[anchor];
        } 
        return globalAttestedTransferLimitByAnchor;
    }

    function attestationUsagesLeft(bytes32 anchor) public view returns (uint256 nrTransfersLeft) {
        // FIXME panics when attestationsUsedByAnchor > attestedTransferLimit 
        // since this should never happen, maybe ok?
        return attestedTransferLimit(anchor) - attestationsUsedByAnchor[anchor];
    }

    /// ###############################################################################################################################
    /// ##############################################################################################  FLOATABILITY
    /// ###############################################################################################################################
    function canStartFloating(ERC6956Authorization op) public
        onlyRole(MAINTAINER_ROLE) {
        canStartFloatingMap = createAuthorizationMap(op);
        emit CanStartFloating(op, msg.sender);
    }
        
    function canStopFloating(ERC6956Authorization op) public
        onlyRole(MAINTAINER_ROLE) {
        canStopFloatingMap = createAuthorizationMap(op);
        emit CanStopFloating(op, msg.sender);
    } 

    function _allowFloating(bytes32 anchor, bool _doFloat) internal {
        anchorIsReleased[anchor] = _doFloat;
        emit AnchorFloatingStateChange(anchor, tokenByAnchor[anchor], _doFloat);
    }

    function allowFloating(bytes32 anchor, bool _doFloat)    
     public 
     {        
        if(_doFloat) {
            require(roleBasedAuthorization(anchor, canStartFloatingMap), "ERC-6956: No permission to start floating");
        } else {
            require(roleBasedAuthorization(anchor, canStopFloatingMap), "ERC-6956: No permission to stop floating");
        }

        require(_doFloat != isFloating(anchor), "EIP-6956: allowFloating can only be called when changing floating state");
        _allowFloating(anchor, _doFloat);        
    }

    function _beforeAttestationIsUsed(bytes32 anchor, address to) internal view virtual override(ERC6956) {
        // empty, can be overwritten by derived conctracts.
        require(attestationUsagesLeft(anchor) > 0, "ERC-6956: No attested transfers left");
        super._beforeAttestationIsUsed(anchor, to);
    }

    function isFloating(bytes32 anchor) public view returns (bool){
        return anchorIsReleased[anchor];
    }    

    constructor(
        string memory _name, 
        string memory _symbol, 
        AttestationLimitUpdatePolicy _limitUpdatePolicy)
        ERC6956(_name, _symbol) {          
            transferLimitPolicy = _limitUpdatePolicy;

        // Note per default no-one change floatability. canStartFloating and canStopFloating needs to be configured first!        
    }
}
