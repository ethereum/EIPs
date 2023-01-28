//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ERC5727 Soulbound Token Interface
 * @dev The core interface of the ERC5727 standard.
 */
interface IERC5727 is IERC165 {
    /**
     * @dev MUST emit when a token is minted.
     * @param owner The address that the token is minted to
     * @param tokenId The token minted
     * @param value The value of the token minted
     */
    event Minted(address indexed owner, uint256 indexed tokenId, uint256 value);

    /**
     * @dev MUST emit when a token is revoked.
     * @param owner The owner of the revoked token
     * @param tokenId The revoked token
     */
    event Revoked(address indexed owner, uint256 indexed tokenId);

    /**
     * @dev MUST emit when a token is charged.
     * @param tokenId The token to charge
     * @param value The value to charge
     */
    event Charged(uint256 indexed tokenId, uint256 value);

    /**
     * @dev MUST emit when a token is consumed.
     * @param tokenId The token to consume
     * @param value The value to consume
     */
    event Consumed(uint256 indexed tokenId, uint256 value);

    /**
     * @dev MUST emit when a token is destroyed.
     * @param owner The owner of the destroyed token
     * @param tokenId The token to destroy.
     */
    event Destroyed(address indexed owner, uint256 indexed tokenId);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param tokenId The token of which slot is set or changed
     * @param oldSlot The previous slot of the token
     * @param newSlot The updated slot of the token
     */
    event SlotChanged(
        uint256 indexed tokenId,
        uint256 indexed oldSlot,
        uint256 indexed newSlot
    );

    /**
     * @notice Get the value of a token.
     * @dev MUST revert if the `tokenId` does not exist
     * @param tokenId the token for which to query the balance
     * @return The value of `tokenId`
     */
    function valueOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @dev MUST revert if the `tokenId` does not exist
     * @param tokenId the token for which to query the slot
     * @return The slot of `tokenId`
     */
    function slotOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get the owner of a token.
     * @dev MUST revert if the `tokenId` does not exist
     * @param tokenId the token for which to query the owner
     * @return The address of the owner of `tokenId`
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Get the validity of a token.
     * @dev MUST revert if the `tokenId` does not exist
     * @param tokenId the token for which to query the validity
     * @return If the token is valid
     */
    function isValid(uint256 tokenId) external view returns (bool);

    /**
     * @notice Get the issuer of a token.
     * @dev MUST revert if the `tokenId` does not exist
     * @param tokenId the token for which to query the issuer
     * @return The address of the issuer of `tokenId`
     */
    function issuerOf(uint256 tokenId) external view returns (address);
}
