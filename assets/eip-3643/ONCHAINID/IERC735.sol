// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.17;

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when addClaim was successfully called on an existing claimId.
     */
    event ClaimChanged(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Add or update a claim from an issuer.
     *
     * _signature is a signed message of the following structure:
     * `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     */
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri)
    external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId)
    external view returns(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);
}
