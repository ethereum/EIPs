### SPDX License Identifier: MIT
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC721Royalties {
    
    
    /**
    @notice This event is emitted when royalties are received.

    @dev The marketplace would call royaltiesRecieved() function so that the NFT contracts emits this event.

    @param creator The original creator of the NFT entitled to the royalties
    @param buyer The person buying the NFT on a secondary sale
    @param amount The amount being paid to the creator
  */
    event RecievedRoyalties (address indexed creator, address indexed buyer, uint256 indexed amount);
    
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    
     /**
     * @dev Returns true if implemented
     * 
     * @dev this is how the marketplace can see if the contract has royalties, other than using the supportsInterface() call.
     */
    function hasRoyalties() external view returns (bool);

     /**
     * @dev Returns uint256 of the amount of percentage the royalty is set to. For example, if 1%, would return "1", if 50%, would return "50"
     * 
     * @dev Marketplaces would need to call this during the purchase function of their marketplace - and then implement the transfer of that amount on their end
     */
    function royaltyAmount() external view returns (uint256);
    
      /**
     * @dev Returns royalty amount as uint256 and address where royalties should go. 
     * 
     * @dev Marketplaces would need to call this during the purchase function of their marketplace - and then implement the transfer of that amount on their end
     */
    function royaltyInfo() external view returns (uint256, address);
    
      /**
     * @dev Called by the marketplace after the transfer of royalties has happened, so that the contract has a record 
     * @dev emits RecievedRoyalties event;
     * 
     * @param _creator The original creator of the NFT entitled to the royalties
     * @param _buyer The person buying the NFT on a secondary sale
     * @param _amount The amount being paid to the creator
     */
    function royaltiesRecieved(address _creator, address _buyer, uint256 _amount) external view;
}
