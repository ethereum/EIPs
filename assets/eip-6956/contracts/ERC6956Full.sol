// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC6956.sol";
import "./IERC6956AttestationLimited.sol";
import "./IERC6956Floatable.sol";
import "./IERC6956ValidAnchors.sol";

/**
 * @title ASSET-BOUND NFT implementation with all interfaces
 * @author Thomas Bergmueller (@tbergmueller)
 * @notice Extends ERC6956.sol with additional interfaces and functionality
 * 
 * @dev Error-codes
 * ERROR | Message
 * ------|-------------------------------------------------------------------
 * E1-20 | See ERC6956.sol
 * E21   | No permission to start floating
 * E22   | No permission to stop floating
 * E23   | allowFloating can only be called when changing floating state
 * E24   | No attested transfers left
 * E25   | data must contain merkle-proof
 * E26   | Anchor not valid
 * E27   | Updating attestedTransferLimit violates policy
 */
contract ERC6956Full is ERC6956, IERC6956AttestationLimited, IERC6956Floatable, IERC6956ValidAnchors {
    Authorization public floatStartAuthorization;
    Authorization public floatStopAuthorization;

    /// ###############################################################################################################################
    /// ##############################################################################################  IERC6956AttestedTransferLimited
    /// ###############################################################################################################################
    
    mapping(bytes32 => uint256) public attestedTransferLimitByAnchor;
    mapping(bytes32 => FloatState) public floatingStateByAnchor;

    uint256 public globalAttestedTransferLimitByAnchor;
    AttestationLimitPolicy public attestationLimitPolicy;

    bool public allFloating;

    /// @dev The merkle-tree root node, where proof is validated against. Update via updateValidAnchors(). Use salt-leafs in merkle-trees!
    bytes32 private _validAnchorsMerkleRoot;

    function _requireValidLimitUpdate(uint256 oldValue, uint256 newValue) internal view {
        if(newValue > oldValue) {
            require(attestationLimitPolicy == AttestationLimitPolicy.FLEXIBLE || attestationLimitPolicy == AttestationLimitPolicy.INCREASE_ONLY, "ERC6956-E27");
        } else {
            require(attestationLimitPolicy == AttestationLimitPolicy.FLEXIBLE || attestationLimitPolicy == AttestationLimitPolicy.DECREASE_ONLY, "ERC6956-E27");
        }
    }

    function updateGlobalAttestationLimit(uint256 _nrTransfers) 
        public 
        onlyMaintainer() 
    {
       _requireValidLimitUpdate(globalAttestedTransferLimitByAnchor, _nrTransfers);
       globalAttestedTransferLimitByAnchor = _nrTransfers;
       emit GlobalAttestationLimitUpdate(_nrTransfers, msg.sender);
    }

    function updateAttestationLimit(bytes32 anchor, uint256 _nrTransfers) 
        public 
        onlyMaintainer() 
    {
       uint256 currentLimit = attestationLimit(anchor);
       _requireValidLimitUpdate(currentLimit, _nrTransfers);
       attestedTransferLimitByAnchor[anchor] = _nrTransfers;
       emit AttestationLimitUpdate(anchor, tokenByAnchor[anchor], _nrTransfers, msg.sender);
    }

    function attestationLimit(bytes32 anchor) public view returns (uint256 limit) {
        if(attestedTransferLimitByAnchor[anchor] > 0) { // Per anchor overwrites always, even if smaller than globalAttestedTransferLimit
            return attestedTransferLimitByAnchor[anchor];
        } 
        return globalAttestedTransferLimitByAnchor;
    }

    function attestationUsagesLeft(bytes32 anchor) public view returns (uint256 nrTransfersLeft) {
        // FIXME panics when attestationsUsedByAnchor > attestedTransferLimit 
        // since this should never happen, maybe ok?
        return attestationLimit(anchor) - attestationsUsedByAnchor[anchor];
    }

    /// ###############################################################################################################################
    /// ##############################################################################################  FLOATABILITY
    /// ###############################################################################################################################
    
    function updateFloatingAuthorization(Authorization startAuthorization, Authorization stopAuthorization) public
        onlyMaintainer() {
            floatStartAuthorization = startAuthorization;
            floatStopAuthorization = stopAuthorization;
            emit FloatingAuthorizationChange(startAuthorization, stopAuthorization, msg.sender);
    }

    function floatAll(bool doFloatAll) public onlyMaintainer() {
        require(doFloatAll != allFloating, "ERC6956-E23");
        allFloating = doFloatAll;
        emit FloatingAllStateChange(doFloatAll, msg.sender);
    }


    function _floating(bool defaultFloatState, FloatState anchorFloatState) internal pure returns (bool floats) {
        if(anchorFloatState == FloatState.Default) {
            return defaultFloatState;
        }
        return anchorFloatState == FloatState.Floating; 
    }

    function float(bytes32 anchor, FloatState newFloatState) public 
    {
        bool currentFloatState = floating(anchor);
        bool willFloat = _floating(allFloating, newFloatState);

        require(willFloat != currentFloatState, "ERC6956-E23");

        if(willFloat) {
            require(_roleBasedAuthorization(anchor, createAuthorizationMap(floatStartAuthorization)), "ERC6956-E21");
        } else {
            require(_roleBasedAuthorization(anchor, createAuthorizationMap(floatStopAuthorization)), "ERC6956-E22");
        }

        floatingStateByAnchor[anchor] = newFloatState;
        emit FloatingStateChange(anchor, tokenByAnchor[anchor], newFloatState, msg.sender);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual
        override(ERC6956)  {
            bytes32 anchor = anchorByToken[tokenId];
                    
            if(!_anchorIsReleased[anchor]) {
                // Only write when not already released - this saves gas, as memory-write is quite expensive compared to IF
                if(floating(anchor)) {
                    _anchorIsReleased[anchor] = true; // FIXME OPTIMIZATION, we do not need 
                }
            }
             
            super._beforeTokenTransfer(from, to, tokenId, batchSize);
        }
    function _beforeAttestationUse(bytes32 anchor, address to, bytes memory data) internal view virtual override(ERC6956) {
        // empty, can be overwritten by derived conctracts.
        require(attestationUsagesLeft(anchor) > 0, "ERC6956-E24");

        // IERC6956ValidAnchors check anchor is indeed valid in contract
        require(data.length > 0, "ERC6956-E25");
        bytes32[] memory proof;
        (proof) = abi.decode(data, (bytes32[])); // Decode it with potentially more data following. If there is more data, this may be passed on to safeTransfer
        require(anchorValid(anchor, proof), "ERC6956-E26");

        super._beforeAttestationUse(anchor, to, data);
    }


    /// @notice Update the Merkle root containing the valid anchors. Consider salt-leaves!
    /// @dev Proof (transferAnchor) needs to be provided from this tree. 
    /// @dev The merkle-tree needs to contain at least one "salt leaf" in order to not publish the complete merkle-tree when all anchors should have been dropped at least once. 
    /// @param merkleRootNode The root, containing all anchors we want validated.
    function updateValidAnchors(bytes32 merkleRootNode) public onlyMaintainer() {
        _validAnchorsMerkleRoot = merkleRootNode;
        emit ValidAnchorsUpdate(merkleRootNode, msg.sender);
    }

    function anchorValid(bytes32 anchor, bytes32[] memory proof) public virtual view returns (bool) {
        return MerkleProof.verify(
            proof,
            _validAnchorsMerkleRoot,
            keccak256(bytes.concat(keccak256(abi.encode(anchor)))));
    }

    function floating(bytes32 anchor) public view returns (bool){
        return _floating(allFloating, floatingStateByAnchor[anchor]);
    }    

    constructor(
        string memory _name, 
        string memory _symbol, 
        AttestationLimitPolicy _limitUpdatePolicy)
        ERC6956(_name, _symbol) {          
            attestationLimitPolicy = _limitUpdatePolicy;

        // Note per default no-one change floatability. canStartFloating and canStopFloating needs to be configured first!        
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC6956)
        returns (bool)
    {
        return
            interfaceId == type(IERC6956AttestationLimited).interfaceId ||
            interfaceId == type(IERC6956Floatable).interfaceId ||
            interfaceId == type(IERC6956ValidAnchors).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
