//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5489 {
    /**
     * @dev this event emits when the slot on `tokenId` is authorzized to `slotManagerAddr`
     */
    event SlotAuthorizationCreated(uint256 indexed tokenId, address indexed slotManagerAddr);

    /**
     * @dev this event emits when the authorization on slot `slotManagerAddr` of token `tokenId` is revoked.
     * So, the corresponding DApp can handle this to stop on-going incentives or rights
     */
    event SlotAuthorizationRevoked(uint256 indexed tokenId, address indexed slotManagerAddr);

    /**
     * @dev this event emits when the uri on slot `slotManagerAddr` of token `tokenId` has been updated to `uri`.
     */
    event SlotUriUpdated(uint256 indexed tokenId, address indexed slotManagerAddr, string uri);

    /**
     * @dev
     * Authorize a hyperlink slot on `tokenId` to address `slotManagerAddr`.
     * Indeed slot is an entry in a map whose key is address `slotManagerAddr`.
     * Only the address `slotManagerAddr` can manage the specific slot.
     * This method will emit SlotAuthorizationCreated event
     */
    function authorizeSlotTo(uint256 tokenId, address slotManagerAddr) external;

    /**
     * @dev
     * Revoke the authorization of the slot indicated by `slotManagerAddr` on token `tokenId`
     * This method will emit SlotAuthorizationRevoked event
     */
    function revokeAuthorization(uint256 tokenId, address slotManagerAddr) external;

    /**
     * @dev
     * Revoke all authorizations of slot on token `tokenId`
     * This method will emit SlotAuthorizationRevoked event for each slot
     */
    function revokeAllAuthorizations(uint256 tokenId) external;

    /**
     * @dev
     * Set uri for a slot on a token, which is indicated by `tokenId` and `slotManagerAddr`
     * Only the address with authorization through {authorizeSlotTo} can manipulate this slot.
     * This method will emit SlotUriUpdated event
     */
    function setSlotUri(
        uint256 tokenId,
        string calldata newUri
    ) external;

    /**
     * @dev
     * returns the latest uri of an slot on a token, which is indicated by `tokenId`, `slotManagerAddr`
     */
    function getSlotUri(uint256 tokenId, address slotManagerAddr)
        external
        view
        returns (string memory);
}