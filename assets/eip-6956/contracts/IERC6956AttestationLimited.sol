// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./IERC6956.sol";

/**
 * @title Attestation-limited Asset-Bound NFT
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0x75a2e933
 */
interface IERC6956AttestationLimited is IERC6956 {
    enum AttestationLimitPolicy {
        IMMUTABLE,
        INCREASE_ONLY,
        DECREASE_ONLY,
        FLEXIBLE
    }
        
    /// @notice Returns the attestation limit for a particular anchor
    /// @dev MUST return the global attestation limit per default
    ///      and override the global attestation limit in case an anchor-based limit is set
    function attestationLimit(bytes32 anchor) external view returns (uint256 limit);

    /// @notice Returns number of attestations left for a particular anchor
    /// @dev Is computed by comparing the attestationsUsedByAnchor(anchor) and the current attestation limit 
    ///      (current limited emitted via GlobalAttestationLimitUpdate or AttestationLimt events)
    function attestationUsagesLeft(bytes32 anchor) external view returns (uint256 nrTransfersLeft);

    /// @notice Indicates the policy, in which direction attestation limits can be updated (globally or per anchor)
    function attestationLimitPolicy() external view returns (AttestationLimitPolicy policy);

    /// @notice This emits when the global attestation limt is updated
    event GlobalAttestationLimitUpdate(uint256 indexed transferLimit, address updatedBy);

    /// @notice This emits when an anchor-specific attestation limit is updated
    event AttestationLimitUpdate(bytes32 indexed anchor, uint256 indexed tokenId, uint256 indexed transferLimit, address updatedBy);

    /// @dev This emits in the transaction, where attestationUsagesLeft becomes 0
    event AttestationLimitReached(bytes32 indexed anchor, uint256 indexed tokenId, uint256 indexed transferLimit);
}
