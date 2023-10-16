// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./IERC6956.sol";

/**
 * @title Anchor-validating Asset-Bound NFT
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0x051c9bd8
 */
interface IERC6956ValidAnchors is IERC6956 {
    /**
     * @notice Emits when the valid anchors for the contract are updated.
     * @param validAnchorHash Hash representing all valid anchors. Typically Root of MerkleTree
     * @param maintainer msg.sender updating the hash
     */
    event ValidAnchorsUpdate(bytes32 indexed validAnchorHash, address indexed maintainer);

    /**
     * @notice Indicates whether an anchor is valid in the present contract
     * @dev Typically implemented via MerkleTrees, where proof is used to verify anchor is part of the MerkleTree 
     *      MUST return false when no ValidAnchorsUpdate-event has been emitted yet
     * @param anchor The anchor in question
     * @param proof Proof that the anchor is valid, typically MerkleProof
     * @return isValid True, when anchor and proof can be verified against validAnchorHash (emitted via ValidAnchorsUpdate-event)
     */
    function anchorValid(bytes32 anchor, bytes32[] memory proof) external view returns (bool isValid);        
}